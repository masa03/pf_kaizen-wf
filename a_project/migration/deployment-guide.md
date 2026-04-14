# 改善提案システム 移植・デプロイ手順書

新しい環境（本番/別テナント）にシステムを一から構築するための手順書。

---

## 前提条件

### 移植先テナントで必要な権限・準備

| # | 項目 | 詳細 | 依頼先 |
|---|------|------|--------|
| 1 | **SharePointサイト作成権限** | サイトコレクション作成が可能なアカウント | テナント管理者 |
| 2 | **Power Platform環境アクセス** | Power Apps / Power Automate の利用権限 | テナント管理者 |
| 3 | **Azure AD（Entra ID）アプリ登録** | PnP PowerShell用。ClientId を取得する | テナント管理者 |
| 4 | **ライセンス** | Microsoft 365 + Power Apps / Power Automate（Per User or Seeded）| テナント管理者 |
| 5 | **PnP PowerShell** | `Install-Module PnP.PowerShell` でインストール | 移植作業者 |

### Azure AD アプリ登録手順

移植先テナントで PnP PowerShell の認証に使うアプリを登録する。

```powershell
# 方法1: PnP PowerShell の自動登録（推奨）
Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP-KaizenWF" -Tenant "{tenant}.onmicrosoft.com" -Interactive

# 方法2: Azure Portal で手動登録
# 1. Azure Portal > Entra ID > アプリの登録 > 新規登録
# 2. リダイレクトURI: http://localhost
# 3. API のアクセス許可:
#    - SharePoint > Sites.FullControl.All（委任）
#    - Microsoft Graph > User.Read（委任）
# 4. 管理者の同意を付与
# 5. アプリケーション（クライアント）ID をコピー → {ClientId} として使用
```

---

## 環境変数一覧

移植時に環境に合わせて変更が必要な全変数の一覧。

### SharePoint（PnPスクリプト）

| 変数 | 値の例 | 対象ファイル | 説明 |
|------|--------|-------------|------|
| `$SiteUrl` | `https://{tenant}.sharepoint.com/sites/kaizen-wf` | `scripts/create-lists.ps1` | サイトURL |
| `$SiteUrl` | 同上 | `scripts/create-employees-list.ps1` | 同上 |
| `$SiteUrl` | 同上 | `scripts/create-doclib.ps1` | 同上 |
| `$SiteUrl` | 同上 | `scripts/set-permissions.ps1` | 同上 |
| `$SiteUrl` | 同上 | `scripts/set-column-formatting.ps1` | 同上 |
| `$AppID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | `scripts/set-column-formatting.ps1` | Power Apps アプリID（Step 8で確定） |
| `$memberGroupName` | `"{サイト名} メンバー"` | `scripts/set-permissions.ps1` L33 | SPサイトのメンバーグループ名 |
| `$visitorGroupName` | `"{サイト名} 訪問者"` | `scripts/set-permissions.ps1` L34 | SPサイトの訪問者グループ名 |
| `{ClientId}` | Azure AD アプリID | 全スクリプトの `Connect-PnPOnline` コメント | PnP認証用 |
| CSVファイルパス | `./test_employees.csv` or 本番CSV | `scripts/import-employees.ps1` `-CsvPath` パラメータ | 社員マスタデータ |

> **注意**: `import-employees.ps1` と `import-masters.ps1` のコメント内に開発環境のURL・ClientIdがハードコードされている（動作には影響しないが、手順書として参照する場合は注意）。

### Power Apps

| 変数 | 値の例 | 対象ファイル / 設定箇所 | 説明 |
|------|--------|------------------------|------|
| `gSharePointSiteUrl` | 下記「環境別URL」参照 | `powerapps/app-onstart.pfx` L175 | 添付ファイルリンク構築用URL。環境ごとに手動で切り替える |
| `gTestMode` | `false`（本番） / `true`（テスト） | `powerapps/app-onstart.pfx` L7 | テストモード切替 |
| データソース接続 | 移植先のSharePointサイト | Power Apps エディタ > データ | 全8リスト + ドキュメントライブラリの接続先 |

#### 環境別URL（`gSharePointSiteUrl`）

| 環境 | URL |
|------|-----|
| 開発 | `https://familiar03.sharepoint.com/sites/kaizen-wf` |
| ステージング | `https://evolut8610.sharepoint.com/sites/sck_kaizen_wf` |

> **注意**: Power Platform 環境変数等の自動切り替え機能は使用していない。デプロイ前に `powerapps/app-onstart.pfx` L175 を上記の対象環境URLに手動で書き換えること。

### Power Automate

| 変数 | 値の例 | 対象ファイル / 設定箇所 | 説明 |
|------|--------|------------------------|------|
| サイトのアドレス | `https://{tenant}.sharepoint.com/sites/kaizen-wf` | 全フローの全SharePointアクション | フロー設計書: `flow-*.md` 内に記載 |
| `{AppID}` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | メールテンプレート6ファイル（`templates/*.html`） | メール内のPower Appsリンク（Step 8で確定） |
| Power Apps接続 | 移植先のアプリ | 添付ファイルアップロードフローのトリガー | Power Apps V2トリガーの接続先 |
| SharePoint接続 | 移植先テナントの接続 | 全フローのSharePointコネクタ | 新テナントで接続を新規作成 |

### Power Automate フロー設計書内のURL箇所

フロー手動構築時、以下の設計書内の `https://xxxxx.sharepoint.com/sites/kaizen-wf` を移植先URLに読み替えること：

| 設計書 | URL出現箇所数 |
|--------|-------------|
| `powerautomate/flow-upload-attachment-build.html` | 2箇所 |
| `powerautomate/flow-notification-submit-build.html` | 3箇所 |
| `powerautomate/flow-approval-manager-build.html` | 5箇所 |
| `powerautomate/flow-approval-director-build.html` | 4箇所 |
| `powerautomate/flow-cancel-notify-build.html` | 2箇所 |

---

## 全体フロー

```
Step 0: 移植先テナントの準備              [テナント管理者に依頼]
Step 1: SharePointサイト作成              [UI手作業]
Step 2: SharePointリスト一括作成           [スクリプト]
Step 3: マスタデータ投入                  [スクリプト]
Step 4: ドキュメントライブラリ作成         [スクリプト]
Step 5: 権限設定                          [スクリプト]
Step 6: Power Appsアプリ移植              [UI手作業 + Code View]
Step 7: Power Automateフロー構築          [UI手作業 or インポート]
Step 8: アプリ公開 + フロー接続            [UI手作業]
Step 9: 公開後設定（Column Formatting + AppID置換）[スクリプト + UI]
Step 10: 動作確認テスト                   [手作業]
```

---

## Step 0: 移植先テナントの準備 `[依頼]`

テナント管理者に以下を依頼する。

1. **SharePointサイト作成権限**の付与（または管理者にサイト作成を依頼）
2. **Power Platform環境**へのアクセス権付与（Power Apps Maker / Environment Admin）
3. **Azure AD アプリ登録**（前提条件セクション参照）→ `{ClientId}` を取得
4. **ライセンス確認**: Power Apps / Power Automate が利用可能か

### 確認すべき情報

| 情報 | 値 | メモ |
|------|---|------|
| テナント名 | `{tenant}.sharepoint.com` | |
| サイトURL | `https://{tenant}.sharepoint.com/sites/{site-name}` | |
| Azure AD ClientId | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | |
| 作業アカウント | `user@{tenant}.onmicrosoft.com` | サイト管理者権限が必要 |
| SPグループ名（メンバー） | `{サイト名} メンバー` | サイト作成後に確認 |
| SPグループ名（訪問者） | `{サイト名} 訪問者` | サイト作成後に確認 |

---

## Step 1: SharePointサイト作成 `[UI]`

1. SharePoint管理センターからサイトコレクションを作成
2. サイトURL例: `https://{tenant}.sharepoint.com/sites/kaizen-wf`
3. **作成後**: サイトの権限グループ名を確認（サイト設定 > サイトの権限）
   - メンバーグループ名 → `set-permissions.ps1` の `$memberGroupName` に使用
   - 訪問者グループ名 → `set-permissions.ps1` の `$visitorGroupName` に使用

---

## Step 2: SharePointリスト一括作成 `[スクリプト]`

全8リスト + インデックスを一括作成する。

### 実行手順

```powershell
pwsh
$SiteUrl = "https://{tenant}.sharepoint.com/sites/kaizen-wf"
$ClientId = "{ClientId}"
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

# スクリプト内の $SiteUrl を環境に合わせて編集してから実行
./scripts/create-lists.ps1
```

### 作成されるリスト

| # | リスト名 | 用途 |
|---|---|---|
| 1 | 社員マスタ | 15,000人の社員情報 |
| 2 | 改善分野マスタ | 改善分野14件 |
| 3 | 表彰区分マスタ | 表彰区分4件 |
| 4 | 改善提案メイン | 申請データ（トランザクション） |
| 5 | 改善メンバー | 申請メンバー |
| 6 | 改善分野実績 | 改善分野ごとの実績値 |
| 7 | 評価データ | 課長/部長の評価結果 |
| 8 | 承認履歴 | 承認フロー履歴（★提案プラン） |

> **注意**: 承認履歴リストは提案プラン（追加オプション）。シンプルプランでは不要な場合、`create-lists.ps1` 内の該当セクションをコメントアウトして実行する。

### 参照ファイル

- `scripts/create-lists.ps1` — リスト + 列定義 + インデックス + Title列非表示

---

## Step 3: マスタデータ投入 `[スクリプト]`

### 3-1. 社員マスタ投入

```powershell
# 本番: 人事マスタCSV（15,000件）を準備して -CsvPath で指定
# テスト環境: scripts/test_employees.csv を使用（デフォルト）
./scripts/import-employees.ps1 -CsvPath "./本番社員データ.csv"
```

### 3-2. 改善分野マスタ + 表彰区分マスタ投入

```powershell
./scripts/import-masters.ps1
```

### 参照ファイル

- `scripts/import-employees.ps1` + `scripts/test_employees.csv`
- `scripts/import-masters.ps1`

---

## Step 4: ドキュメントライブラリ作成 `[スクリプト]`

添付ファイル用ドキュメントライブラリを作成する。

```powershell
./scripts/create-doclib.ps1
```

### 参照ファイル

- `scripts/create-doclib.ps1`

---

## Step 5: 権限設定 `[スクリプト]`

**実行前に必ず確認**: スクリプト内のグループ名を移植先サイトに合わせて変更する。

```powershell
# 事前にスクリプト内の以下を変更:
#   $memberGroupName = "{サイト名} メンバー"  (L33)
#   $visitorGroupName = "{サイト名} 訪問者"   (L34)
./scripts/set-permissions.ps1
```

### 参照ファイル

- `scripts/set-permissions.ps1`

---

## Step 6: Power Appsアプリ移植 `[UI + Code View]`

make.powerapps.com での操作。

### 移植方法の選択

| 方法 | 手順 | メリット | デメリット |
|------|------|---------|-----------|
| **エクスポート/インポート** | 元環境でエクスポート → 移植先でインポート → データソース再接続 | UIレイアウト・設定が完全に再現される | データソース再接続の手間 |
| **手動再構築（Code View）** | 空のアプリから YAML/pfx を貼り付け | git管理コードと完全一致 | AddMediaButton等の手動設定が必要 |

> **推奨**: 同一テナント内はエクスポート/インポート、別テナントはどちらでも可。いずれの方法でもデータソースの再接続とApp.OnStart内の変数変更は必要。

### 6-1. キャンバスアプリ作成（手動再構築の場合）

1. make.powerapps.com → **作成** → **空のアプリ** → **空のキャンバスアプリ**
2. アプリ名を入力、形式は「**タブレット**」を選択
3. 左メニュー「**データ**」→ データソース接続（全8リスト + ドキュメントライブラリ）

### 6-1'. インポートの場合

1. 元環境: make.powerapps.com → アプリ一覧 →「...」→「**エクスポートパッケージ**」
2. 移植先: make.powerapps.com → **アプリ** →「**キャンバスアプリのインポート**」
3. **データソースの再接続**: アプリ編集 → データ → 各リストの接続先を移植先サイトに変更

### 6-2. App.OnStart設定

1. `powerapps/app-onstart.pfx` の内容を App.OnStart に貼り付け
2. 以下の変数を移植先に合わせて変更：

| 変数 | 変更内容 | 行 |
|------|---------|-----|
| `gTestMode` | `false` に変更（本番時） | L7 |
| `gSharePointSiteUrl` | 「環境変数一覧 > Power Apps > 環境別URL」表を参照 | L175 |

### 6-3. 各画面のYAML適用（Code View）

以下の順序でYAMLを貼り付け：

| 順序 | ファイル | 画面 |
|---|---|---|
| 1 | `powerapps/screen-application-form.yaml` | 申請フォーム画面 |
| 2 | `powerapps/screen-view.yaml` | 閲覧画面 |
| 3 | `powerapps/screen-evaluation.yaml` | 評価画面 |

### 6-4. UI手作業（Code Viewでは対応できない操作）

- `docs/ui-manual-2-7.md` の手順に従い、添付ファイル関連のUI設定を実施
  - AddMediaButton配置
  - Power Automateフロー接続（Step 7完了後に実施）

### 6-5. App.StartScreen設定

`powerapps/app-onstart.pfx` 末尾のコメントにある数式を、プロパティパネル > App > StartScreen に手動で設定：

```
If(
    !IsBlank(Param("EvalType")),
    EvaluationScreen,
    !IsBlank(Param("RequestID")) && Param("Mode") = "Edit",
    ApplicationFormScreen,
    !IsBlank(Param("RequestID")),
    ViewScreen,
    ApplicationFormScreen
)
```

> **注意**: App.OnStart では `Navigate()` は使用不可。画面遷移は必ず `App.StartScreen` プロパティで制御する。

---

## Step 7: Power Automateフロー構築 `[UI]`

以下の5フローを構築する。

| 順序 | フロー名 | 設計書 | メールテンプレート |
|---|---|---|---|
| 1 | 改善提案_添付ファイルアップロード | `powerautomate/flow-upload-attachment-build.html` | — |
| 2 | 改善提案_申請通知 | `powerautomate/flow-notification-submit-build.html` | `templates/3-1_*.html` |
| 3 | 改善提案_課長承認 | `powerautomate/flow-approval-manager-build.html` | `templates/3-2_*.html` |
| 4 | 改善提案_部長承認 | `powerautomate/flow-approval-director-build.html` | `templates/3-3_*.html` |
| 5 | 取下げ通知フロー（§4） | `powerautomate/flow-cancel-notify-build.html` | `templates/3-4_取下げ通知.html` |

### 構築方法の選択

| 方法 | 手順 | 適用場面 |
|------|------|---------|
| **設計書ベースで手動構築** | フロー設計書に従ってアクションを配置 | 別テナント / 確実に動作させたい場合 |
| **エクスポート/インポート** | 元環境でフローをエクスポート → インポート → 全接続を再接続 | 同一テナント内 / 工数を減らしたい場合 |

> **別テナントでもインポートは可能**だが、全SharePoint接続の再設定が必要。フロー内のSharePointアクションが多い（計14箇所）ため、手動構築と比較してどちらが効率的か判断すること。

### 手動構築時の注意: サイトURL

フロー設計書内のサイトのアドレス `https://xxxxx.sharepoint.com/sites/kaizen-wf` は全て移植先URLに読み替えること。

### メールテンプレートの貼り付け方法

1. メール送信アクションの本文に、HTMLテンプレートの **body部分を先に貼り付け**
2. その後 **header（style）部分を貼り付け**
3. `@{}` 内の式がPower Automateの動的コンテンツとして認識されることを確認

### メールテンプレート内の `{AppID}` 置換

テンプレート内の `{AppID}` は Step 8 でアプリ公開後に確定する。
フロー構築時点ではプレースホルダーのまま進め、Step 9 で実際のGUIDに置き換える。

### 参照ファイル

- `powerautomate/flow-*.html`（5ファイル）
- `powerautomate/templates/*.html`（7ファイル）

---

## Step 8: アプリ公開 + フロー接続 `[UI]`

make.powerapps.com での操作。

### 8-1. Power Automateフロー接続

Step 7でフローを構築した後、Power Appsエディタに戻って接続する：

1. 申請フォーム画面のAddMediaButton（または添付アップロードトリガー）にフローを接続
2. `btnSubmit.OnSelect` 内のフロー `.Run()` 呼び出しが正しいフロー名を指しているか確認

### 8-2. 公開

1. make.powerapps.com → 対象アプリを開く（編集モード）
2. 右上の「**公開**」ボタンをクリック

### 8-3. App ID 取得

1. make.powerapps.com → **アプリ一覧**
2. 対象アプリの「**...**」→「**詳細**」
3. **アプリID**（GUID形式）をコピー → Step 9 で使用

---

## Step 9: 公開後設定 `[スクリプト + UI]`

アプリ公開後に、App ID を使って以下を設定する。

### 9-1. Column Formatting 適用

SharePointリストの RequestID 列にリンク書式を設定し、クリックでPower Appsに遷移できるようにする。

```powershell
# スクリプト内の $AppID を実際のGUIDに置換してから実行
./scripts/set-column-formatting.ps1
```

### 9-2. メールテンプレートの AppID 置換

Power Automate の各フローで、メール本文中の `{AppID}` を実際のGUID に置換する。

#### 手順

1. `scripts/env/.env.prod` の `APP_ID=` に Step 8-3 で取得した App ID を設定する

```
# scripts/env/.env.prod
APP_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

2. スクリプトを実行する

```powershell
# PowerShell（Windows推奨）
./scripts/apply-env.ps1 prod

# bash（macOS / Linux）
./scripts/apply-env.sh prod
```

3. `powerautomate/templates-dist/` に `prod_*.html` が生成される。各フローのメール送信アクションの本文を、生成されたファイルの内容で置き換える。

> **注意**: `apply-env.sh clear` で `templates-dist/` を全削除できる。

対象フロー（全3フロー・13テンプレート分）：
- 改善提案_申請通知（承認依頼メール）
- 改善提案_課長承認（承認完了 / 差戻通知 / 部長へ承認依頼）
- 改善提案_部長承認（承認完了 / 差戻通知）
- 改善提案_回覧通知（回覧依頼 / 差戻通知 / 課長承認依頼 / 部長承認依頼）

### 参照ファイル

- `scripts/set-column-formatting.ps1`
- `scripts/apply-env.sh`
- `scripts/env/.env.prod`
- `powerautomate/templates/*.html`（ソーステンプレート）

---

## Step 10: 動作確認テスト `[手作業]`

移植完了後、以下の一連のフローを通しで確認する。

### 10-1. 基本接続確認

- [ ] Power Appsが正常に起動するか
- [ ] 全データソース（8リスト + ドキュメントライブラリ）に接続できるか
- [ ] 社員マスタからログインユーザーの情報が取得できるか（`gTestMode = false` の場合）

### 10-2. 申請フロー確認

- [ ] テストモード（`gTestMode = true`）で申請フォームを入力・提出できるか
- [ ] 添付ファイルがドキュメントライブラリにアップロードされるか
- [ ] 改善提案メインリストにデータが登録されるか
- [ ] 課長へ承認依頼メールが届くか

### 10-3. 承認フロー確認

- [ ] メール内リンクから評価画面に遷移できるか（Param受け取り確認）
- [ ] 課長評価 → 承認で、承認完了メールが届くか
- [ ] 褒賞金額 ≥ 5,000円の場合、部長へ承認依頼メールが届くか
- [ ] 部長承認 → 完了メールが届くか
- [ ] 差戻 → 申請者にNG通知メールが届くか
- [ ] 差戻メールのリンクから申請フォーム（編集モード）に遷移できるか

### 10-4. SharePoint連携確認

- [ ] Column Formattingのリンクが正しくPower Appsに遷移するか
- [ ] 閲覧画面で添付ファイル画像が表示されるか

---

## スクリプト一覧

### `scripts/` 直下（本番移植用）

| ファイル | 実行タイミング | 内容 | 要変更変数 |
|---|---|---|---|
| `create-lists.ps1` | Step 2 | 全8リスト + 列定義 + インデックス + Title列非表示 | `$SiteUrl` |
| `create-employees-list.ps1` | — | 社員マスタリスト単体作成（`create-lists.ps1` に含まれるため通常不要） | `$SiteUrl` |
| `import-employees.ps1` | Step 3 | 社員マスタCSVインポート | `-CsvPath` パラメータ |
| `import-masters.ps1` | Step 3 | 改善分野マスタ + 表彰区分マスタ投入 | — |
| `create-doclib.ps1` | Step 4 | 添付ファイル用ドキュメントライブラリ作成 | `$SiteUrl` |
| `set-permissions.ps1` | Step 5 | サイト・リスト権限設定 | `$SiteUrl`, `$memberGroupName`, `$visitorGroupName` |
| `set-column-formatting.ps1` | Step 9 | RequestID列にリンク書式適用 | `$SiteUrl`, `$AppID` |
| `apply-env.ps1` | Step 9 | メールテンプレートの `{AppID}` を一括置換して `templates-dist/` に出力（Windows用） | `scripts/env/.env.{環境}` |
| `apply-env.sh` | Step 9 | 同上（macOS / Linux用） | `scripts/env/.env.{環境}` |

### `scripts/develop/`（開発環境パッチ用・本番移植不要）

| ファイル | 内容 |
|---|---|
| `patch-update-category-01.ps1` | 改善分野実績にConversionRate列追加 |
| `patch-v92-evaluation-data.ps1` | 評価データリスト再構築 |
| `patch-add-applicant-office.ps1` | 申請者在籍事業所・原価単位列追加 |
| `patch-v10-add-filecategory.ps1` | ドキュメントライブラリにFileCategory列追加 |
| `patch-v10-add-division.ps1` | Division（部門）列追加 |
| `patch-hide-title-columns.ps1` | 全リストのTitle列非表示（既存環境用） |
| `patch-employee-name-index.ps1` | 社員マスタ EmployeeName 列インデックス追加（§8 サジェスト検索・新規環境は `create-lists.ps1` で対応済みのため不要） |
| `patch-v13-approval-view-link.ps1` | 「自分の承認待ち」ビューにビューレベル Column Formatting 適用（§13・新規環境は `set-column-formatting.ps1` で対応済みのため不要） |

---

## 環境差分チェックリスト

移植時に環境に合わせて変更が必要な箇所（全量）：

### Step 0: テナント準備

- [ ] Azure AD アプリ登録完了、`{ClientId}` を取得済み
- [ ] SharePointサイト作成権限を確認済み
- [ ] Power Platform ライセンス・環境アクセスを確認済み

### SharePoint（スクリプト）

- [ ] `scripts/create-lists.ps1` の `$SiteUrl` を移植先URLに変更
- [ ] `scripts/create-employees-list.ps1` の `$SiteUrl` を移植先URLに変更
- [ ] `scripts/create-doclib.ps1` の `$SiteUrl` を移植先URLに変更
- [ ] `scripts/set-permissions.ps1` の `$SiteUrl` を移植先URLに変更
- [ ] `scripts/set-permissions.ps1` の `$memberGroupName` をサイトのグループ名に変更
- [ ] `scripts/set-permissions.ps1` の `$visitorGroupName` をサイトのグループ名に変更
- [ ] `scripts/set-column-formatting.ps1` の `$SiteUrl` を移植先URLに変更
- [ ] `scripts/set-column-formatting.ps1` の `$AppID` を実際のGUIDに変更（Step 8後）
- [ ] 社員マスタCSVを本番データに差し替え

### Power Apps

- [ ] `powerapps/app-onstart.pfx` の `gTestMode` を `false` に変更
- [ ] `powerapps/app-onstart.pfx` の `gSharePointSiteUrl` を移植先URLに変更
- [ ] データソース接続を移植先SharePointサイトに再接続

### Power Automate

- [ ] 全フローのSharePointコネクタ接続先を移植先テナントに設定
- [ ] 全フローのSharePointアクション「サイトのアドレス」を移植先URLに設定（計14箇所）
- [ ] `scripts/env/.env.prod` の `APP_ID` に実際のGUIDを設定（Step 8後）
- [ ] `./scripts/apply-env.sh prod` を実行し `templates-dist/prod_*.html` を生成、各フローのメール本文を置換（13テンプレート分）
- [ ] メール送信元の設定（下記「メール送信元の設定」セクション参照）

---

## メール送信元の設定

Power Automateの「メールの送信 (V2)」アクションは、送信元（From）を指定しない場合、**フローのOffice 365 Outlookコネクションを作成したユーザーのアドレス**が差出人になる。

個人アカウントのままだと異動・退職時にフローが停止するため、本番運用では**共有メールボックス**の利用を推奨する。

### 共有メールボックスを使用する場合

1. **Microsoft 365管理センター**で共有メールボックスを作成（例: `kaizen-system@contoso.com`）
2. **Send As（メールボックス所有者として送信）権限を付与**
   - **付与先**: フローの**接続ユーザー**（＝フロー作成・編集時にOffice 365 Outlookコネクタにサインインしたユーザー。トリガーを発動した操作者ではない）
   - **設定場所**: Microsoft 365管理センター → 共有メールボックス → メールボックスの委任 → 「メールボックス所有者として送信する」に接続ユーザーを追加
   - 権限が反映されるまで最大1時間かかる場合がある
3. Power Automateの各メール送信アクションを以下のように変更：
   - アクション: 「Office 365 Outlook」→ **共有メールボックスからメールを送信する (V2)**
   - **元のメールボックスのアドレス**: 共有メールボックスのアドレスを直接テキスト入力（ドロップダウン選択ではない）
4. 対象フロー・アクション数：
   - `flow-submit-notification`: 1箇所（申請通知メール）
   - `flow-approval-manager`: 3箇所（部長承認依頼・承認完了・差戻通知）
   - `flow-approval-director`: 2箇所（最終承認完了・差戻通知）

### 個人アカウントのまま運用する場合

追加設定は不要。ただし以下のリスクを許容する：

- コネクション作成者が異動・退職した場合、フローが停止する
- 受信者にはそのユーザーの個人名が差出人として表示される

---

## 外部ユーザーの招待手順

自テナントのSharePointサイトに外部ユーザーを招待する場合の操作手順。

### 1. サイトへのアクセス許可を付与

1. 対象サイトの **右上歯車アイコン** → **サイトのアクセス許可** を開く
2. **メンバーの追加** → **サイトの共有のみ** を選択
3. 外部メンバーの **メールアドレス** を入力
4. 権限は **編集** に設定（後から「サイトのアクセス許可」画面で変更可能）

### 2. SharePoint / Power Apps のメンバーに追加

サイトアクセス許可の付与後、以下にも招待を行う：

- **SharePointグループ**（サイトメンバー等）にメンバー追加
- **Power Apps** の共有設定でメンバー追加
