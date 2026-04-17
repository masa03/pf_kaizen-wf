# 改善提案システム 移植・デプロイ手順書

新しい環境（本番/別テナント）にシステムを一から構築するための手順書。

---

## 前提条件

### 移植先テナントで必要な権限・準備

| #   | 項目                               | 詳細                                                              | 依頼先         |
| --- | ---------------------------------- | ----------------------------------------------------------------- | -------------- |
| 1   | **SharePointサイト作成権限**       | サイトコレクション作成が可能なアカウント                          | テナント管理者 |
| 2   | **Power Platform環境アクセス**     | Power Apps / Power Automate の利用権限                            | テナント管理者 |
| 3   | **Azure AD（Entra ID）アプリ登録** | PnP PowerShell用。ClientId を取得する                             | テナント管理者 |
| 4   | **ライセンス**                     | Microsoft 365 + Power Apps / Power Automate（Per User or Seeded） | テナント管理者 |
| 5   | **PnP PowerShell**                 | `Install-Module PnP.PowerShell` でインストール                    | 移植作業者     |

### Windows環境での事前準備

移植作業をWindowsで実施する場合は、事前に `a_project/migration/pc-setup-guide.md` の手順でツールをセットアップすること。

---

## 環境変数一覧

移植時に環境に合わせて変更が必要な全変数の一覧。

### SharePoint（PnPスクリプト）

| 変数            | 値の例                                 | 対象ファイル                                         | 説明                | 設定タイミング                                                        |
| --------------- | -------------------------------------- | ---------------------------------------------------- | ------------------- | --------------------------------------------------------------------- |
| `$AppID`        | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | `scripts/set-column-formatting.ps1`                  | Power Apps アプリID | **Step 8**（Step 7のアプリ公開後に確定→スクリプト内を書き換えて実行） |
| CSVファイルパス | `./csv/test_employees.csv` or 本番CSV  | `scripts/import-employees.ps1` `-CsvPath` パラメータ | 社員マスタデータ    | **Step 3**（実行時に `-CsvPath` で指定）                              |

> **注意**: `import-employees.ps1` と `import-masters.ps1` のコメント内に開発環境のURL・ClientIdがハードコードされている（動作には影響しないが、手順書として参照する場合は注意）。

### Power Apps

| 変数                 | 値の例                             | 対象ファイル / 設定箇所          | 説明                                                    | 設定タイミング                                 |
| -------------------- | ---------------------------------- | -------------------------------- | ------------------------------------------------------- | ---------------------------------------------- |
| `gSharePointSiteUrl` | 下記「環境別URL」参照              | `powerapps/app-onstart.pfx` L175 | 添付ファイルリンク構築用URL。環境ごとに手動で切り替える | **Step 5**（App.OnStart 貼り付け時に書き換え） |
| `gTestMode`          | `false`（本番） / `true`（テスト） | `powerapps/app-onstart.pfx` L7   | テストモード切替                                        | **Step 5**（本番は `false` に変更）            |
| データソース接続     | 移植先のSharePointサイト           | Power Apps エディタ > データ     | 全10リスト + ドキュメントライブラリの接続先             | **Step 5**（データソース再接続時）             |

#### 環境別URL（`gSharePointSiteUrl`）

| 環境         | URL                                                         |
| ------------ | ----------------------------------------------------------- |
| 開発         | `https://familiar03.sharepoint.com/sites/kaizen-wf`         |
| ステージング | `https://evolut8610.sharepoint.com/sites/sck_kaizen_wf`     |
| 本番         | `https://sonyjpn.sharepoint.com/sites/S117-scksoumu/kaizen` |

> **注意**: Power Platform 環境変数等の自動切り替え機能は使用していない。デプロイ前に `powerapps/app-onstart.pfx` L175 を上記の対象環境URLに手動で書き換えること。

### Power Automate

| 変数      | 値の例                                 | 対象ファイル / 設定箇所                            | 説明                       | 設定タイミング                                                                                      |
| --------- | -------------------------------------- | -------------------------------------------------- | -------------------------- | --------------------------------------------------------------------------------------------------- |
| `{AppID}` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | メールテンプレート14ファイル（`templates/*.html`） | メール内のPower Appsリンク | **Step 8**（Step 7公開後に `scripts/env/.env.prod` の `APP_ID=` に設定し `apply-env.sh prod` 実行） |

## 全体フロー

```
Step 0: 移植先テナントの準備              [テナント管理者に依頼]
Step 1: SharePointサイト作成              [UI手作業]
Step 2: SharePointリスト一括作成           [スクリプト]
Step 3: マスタデータ投入                  [スクリプト]
Step 4: ドキュメントライブラリ作成         [スクリプト]
Step 5: Power Appsアプリ移植              [UI手作業 + Code View]
Step 6: Power Automateフロー構築（10フロー）[UI手作業 or インポート]
Step 7: アプリ公開 + フロー接続            [UI手作業]
Step 8: 公開後設定（Column Formatting + AppID置換）[スクリプト + UI]
Step 9: 権限設定                          [スクリプト]  ← 動作確認前に適用
Step 10: 動作確認テスト                   [手作業]
```

---

## Step 0: 移植先テナントの準備 `[依頼]`

テナント管理者に以下を依頼する。

1. **SharePointサイト作成権限**の付与（または管理者にサイト作成を依頼）
2. **Power Platform環境**へのアクセス権付与（Power Apps Maker / Environment Admin）
3. **Azure AD アプリ登録**（下記「0-1」参照）→ `{ClientId}` を取得
4. **ライセンス確認**: Power Apps / Power Automate が利用可能か

### 0-1. Azure AD アプリ登録

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

### 確認すべき情報

| 情報                     | 値                                                  | メモ                   |
| ------------------------ | --------------------------------------------------- | ---------------------- |
| テナント名               | `{tenant}.sharepoint.com`                           |                        |
| サイトURL                | `https://{tenant}.sharepoint.com/sites/{site-name}` |                        |
| Azure AD ClientId        | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`              |                        |
| 作業アカウント           | `user@{tenant}.onmicrosoft.com`                     | サイト管理者権限が必要 |
| SPグループ名（メンバー） | `{サイト名} メンバー`                               | サイト作成後に確認     |
| SPグループ名（訪問者）   | `{サイト名} 訪問者`                                 | サイト作成後に確認     |

---

## Step 1: SharePointサイト作成 `[UI]`

1. SharePoint管理センターからサイトコレクションを作成
2. サイトURL例: `https://{tenant}.sharepoint.com/sites/kaizen-wf`

---

## Step 2: SharePointリスト一括作成 `[スクリプト]`

> **PnP が使用できない場合**: `a_project/migration/ui_manual/ui-manual-sharepoint.html` の「Step 2: SharePoint リスト手動作成」を参照してください。列定義は `docs/spec/lists.md` を参照。

全10リスト + インデックスを一括作成する。

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

| #   | リスト名                        | 用途                                                   |
| --- | ------------------------------- | ------------------------------------------------------ |
| 1   | 社員マスタ                      | 15,000人の社員情報                                     |
| 2   | 改善分野マスタ                  | 改善分野14件                                           |
| 3   | 表彰区分マスタ                  | 表彰区分4件                                            |
| 4   | 改善提案メイン                  | 申請データ（トランザクション）                         |
| 5   | 改善メンバー                    | 申請メンバー                                           |
| 6   | 改善分野実績                    | 改善分野ごとの実績値                                   |
| 7   | 評価データ                      | 課長/部長の評価結果                                    |
| 8   | 承認履歴                        | 承認フロー履歴（★提案プラン）                          |
| 9   | 添付ファイルステージング `[v2]` | 申請フォームでのファイル一時保管（提出後に転送・削除） |
| 10  | 回覧メンバー `[v2]`             | 提案ごとの回覧者情報（1:N、最大5名）                   |

> **注意**: 承認履歴リストは提案プラン（追加オプション）。シンプルプランでは不要な場合、`create-lists.ps1` 内の該当セクションをコメントアウトして実行する。

### 参照ファイル

- `scripts/create-lists.ps1` — リスト + 列定義 + インデックス + Title列非表示

---

## Step 3: マスタデータ投入 `[スクリプト]`

> **PnP が使用できない場合**: `a_project/migration/ui_manual/ui-manual-sharepoint.html` の「Step 3: マスタデータ手動投入」を参照してください。社員マスタは `scripts/develop/employee-sharepoint-import-template.xlsx` を使用します。

### 3-1. 社員マスタ投入

#### Excel → CSV 変換（本番データの場合）

人事部門から提供されるExcel組織構成データ（`データ3_(yyyy.mm.dd).xlsx`）を、社員マスタCSV形式に変換する。

方法は2つある。Python が使用できる場合はスクリプト方式、使用できない場合はExcelテンプレート方式を使う。

---

##### 方法A: Python スクリプト（推奨）

```powershell
# Excel → CSV 変換スクリプト（要: pip3 install openpyxl）
python3 scripts/develop/convert-employee-xlsx.py -i "人事データ.xlsx" -o scripts/csv/prod_employees.csv

# 変換件数を制限する場合（テスト用）
python3 scripts/develop/convert-employee-xlsx.py -i "人事データ.xlsx" -o scripts/csv/test_subset.csv --limit 10
```

---

##### 方法B: Excel テンプレート（Python が使えない場合）

`a_project/migration/employee/employee-convert-template.xlsx` を使って手動で CSV を生成する。

1. **テンプレートを開く**  
   `a_project/migration/employee/employee-convert-template.xlsx` を Excel で開く

2. **人事 Excel の「データ3」シートをコピー**
   - 人事部門から受領した Excel（`データ3_yyyy.mm.dd.xlsx`）を開く
   - 「データ3」シートタブを右クリック → **「移動またはコピー」**
   - 移動先ブック: `employee-convert-template.xlsx` を選択
   - **☑ コピーを作成する** にチェック → **OK**
   - テンプレート内の既存プレースホルダー「データ3」シートを削除

3. **「変換出力」シートを確認**  
   自動的に社員マスタCSV形式に変換・計算される

4. **CSV として保存**
   - 「変換出力」シートをアクティブにした状態で **「名前を付けて保存」**
   - ファイル形式: **CSV UTF-8（コンマ区切り）（.csv）** を選択
   - 保存先: `scripts/csv/prod_employees.csv`
     > ⚠ 「このブックには、CSV と互換性のない機能が含まれています」という警告が出るが **「はい」** を選択して続行

---

> **IsManagement判定**: 課長本人フラグ（IsManager）または部長本人フラグ（IsDirector）が1の場合にTrue。評価画面の職能換算（管理職×0.85）に使用される。

#### SharePointへの投入

```powershell
# 本番: 変換済みCSVを指定
./scripts/import-employees.ps1 -CsvPath "./scripts/csv/prod_employees.csv"

# テスト環境: scripts/csv/test_employees.csv を使用
./scripts/import-employees.ps1 -CsvPath "./scripts/csv/test_employees.csv"
```

### 3-2. 改善分野マスタ + 表彰区分マスタ投入

```powershell
./scripts/import-masters.ps1
```

### 参照ファイル

- `scripts/develop/convert-employee-xlsx.py` — Excel組織構成 → 社員マスタCSV変換スクリプト（Python方式）
- `a_project/migration/employee/employee-convert-template.xlsx` — Excel組織構成 → 社員マスタCSV変換テンプレート（Python不可時）
- `scripts/import-employees.ps1` + `scripts/csv/test_employees.csv`
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

## Step 5: Power Appsアプリ移植 `[UI + Code View]`

make.powerapps.com での操作。

### 移植方法の選択

| 方法                        | 手順                                                           | メリット                             | デメリット                       |
| --------------------------- | -------------------------------------------------------------- | ------------------------------------ | -------------------------------- |
| **エクスポート/インポート** | 元環境でエクスポート → 移植先でインポート → データソース再接続 | UIレイアウト・設定が完全に再現される | データソース再接続の手間         |
| **手動再構築（Code View）** | 空のアプリから YAML/pfx を貼り付け                             | git管理コードと完全一致              | AddMediaButton等の手動設定が必要 |

> **推奨**: 同一テナント内はエクスポート/インポート、別テナントはどちらでも可。いずれの方法でもデータソースの再接続とApp.OnStart内の変数変更は必要。

### 6-1. キャンバスアプリ作成（手動再構築の場合）

1. make.powerapps.com → **作成** → **空のアプリ** → **空のキャンバスアプリ**
2. アプリ名を入力、形式は「**タブレット**」を選択
3. 左メニュー「**データ**」→ データソース接続（全10リスト + ドキュメントライブラリ）

### 6-1'. インポートの場合

1. 元環境: make.powerapps.com → アプリ一覧 →「...」→「**エクスポートパッケージ**」
2. 移植先: make.powerapps.com → **アプリ** →「**キャンバスアプリのインポート**」
3. **データソースの再接続**: アプリ編集 → データ → 各リストの接続先を移植先サイトに変更

### 6-2. App.OnStart設定

1. `powerapps/app-onstart.pfx` の内容を App.OnStart に貼り付け
2. 以下の変数を移植先に合わせて変更：

| 変数                 | 変更内容                                          | 行   |
| -------------------- | ------------------------------------------------- | ---- |
| `gTestMode`          | `false` に変更（本番時）                          | L7   |
| `gSharePointSiteUrl` | 「環境変数一覧 > Power Apps > 環境別URL」表を参照 | L175 |

### 6-3. 各画面のYAML適用（Code View）

以下の順序でYAMLを貼り付け：

| 順序 | ファイル                                 | 画面                                       |
| ---- | ---------------------------------------- | ------------------------------------------ |
| 1    | `powerapps/screen-application-form.yaml` | 申請フォーム画面                           |
| 2    | `powerapps/screen-view.yaml`             | 閲覧画面                                   |
| 3    | `powerapps/screen-evaluation.yaml`       | 評価画面                                   |
| 4    | `powerapps/screen-thankyou.yaml`         | サンクス画面（申請完了・承認完了後）`[v2]` |

### 6-4. UI手作業（Code Viewでは対応できない操作）

- `a_project/migration/ui_manual/ui-manual-2-7.md` の手順に従い、添付ファイル関連のUI設定を実施
  - AddMediaButton配置
  - Power Automateフロー接続（Step 6完了後に実施）

### 6-5. App.StartScreen設定

`powerapps/app-startscreen.pfx` の数式を、プロパティパネル > App > StartScreen に手動で設定：

```
If(
    !IsBlank(Param("EvalType")),
    EvaluationScreen,
    !IsBlank(Param("RequestID")) && Param("Mode") = "Reviewer",
    EvaluationScreen,
    !IsBlank(Param("RequestID")) && Param("Mode") = "Edit",
    ApplicationFormScreen,
    !IsBlank(Param("RequestID")),
    ViewScreen,
    ApplicationFormScreen
)
```

> **注意**: App.OnStart では `Navigate()` は使用不可。画面遷移は必ず `App.StartScreen` プロパティで制御する。
>
> **v2変更点（§3）**: `Param("Mode") = "Reviewer"` の分岐を追加。回覧者がメールリンクから評価画面（回覧モード）に遷移するために必要。

---

## Step 6: Power Automateフロー構築 `[UI]`

以下の10フローを構築する（No.10は No.1 と同一フローのため個別構築不要）。

| 順序 | フロー名                                      | 設計書                                                | メールテンプレート                           |
| ---- | --------------------------------------------- | ----------------------------------------------------- | -------------------------------------------- |
| 1    | 改善提案\_添付ファイルアップロード            | `powerautomate/flow-upload-attachment-build.html`     | —                                            |
| 2    | 改善提案\_申請通知                            | `powerautomate/flow-notification-submit-build.html`   | `templates/3-1_*.html`（3ファイル）          |
| 3    | 改善提案\_課長承認                            | `powerautomate/flow-approval-manager-build.html`      | `templates/3-2_*.html`（3ファイル）          |
| 4    | 改善提案\_部長承認                            | `powerautomate/flow-approval-director-build.html`     | `templates/3-3_*.html`（2ファイル）          |
| 5    | 取下げ通知フロー `[v2]`（§4）                 | `powerautomate/pending/flow-cancel-notify-build.html` | `templates/3-4_取下げ通知.html`              |
| 6    | ステージング転送フロー `[v2]`（§1）           | `powerautomate/flow-staging-transfer-build.html`      | —                                            |
| 7    | ステージングクリーンアップフロー `[v2]`（§1） | `powerautomate/flow-staging-cleanup-build.html`       | —                                            |
| 8    | 回覧通知フロー `[v2]`（§3）                   | `powerautomate/flow-reviewer-notify-build.html`       | `templates/3-5_回覧通知_*.html`（3ファイル） |
| 9    | 回覧差戻フロー `[v2]`（§3）                   | `powerautomate/flow-reviewer-dismiss-build.html`      | `templates/3-5_回覧通知_差戻通知.html`       |
| —    | 申請通知フロー（再提出）`[v2]`（§5）          | No.2 と同一フロー                                     | —                                            |
| 10   | リマインダーフロー `[v2]`（§7）               | `powerautomate/flow-reminder-build.html`              | `templates/3-6_リマインダー.html`            |

### 構築方法の選択

| 方法                        | 手順                                                       | 適用場面                              |
| --------------------------- | ---------------------------------------------------------- | ------------------------------------- |
| **設計書ベースで手動構築**  | フロー設計書に従ってアクションを配置                       | 別テナント / 確実に動作させたい場合   |
| **エクスポート/インポート** | 元環境でフローをエクスポート → インポート → 全接続を再接続 | 同一テナント内 / 工数を減らしたい場合 |

> **別テナントでもインポートは可能**だが、全SharePoint接続の再設定が必要。フロー内のSharePointアクションが多い（計35箇所）ため、手動構築と比較してどちらが効率的か判断すること。

### 手動構築時の注意: サイトURL

フロー設計書内のサイトのアドレス `https://xxxxx.sharepoint.com/sites/kaizen-wf` は全て移植先URLに読み替えること。

### メールテンプレートの貼り付け方法

**推奨手順（template-dist方式）**: Step 8 で `apply-env.sh` を実行し、`templates-dist/` に環境変数（`{AppID}`）が置換済みのHTMLを生成する。各フローのメール送信アクションには、生成されたファイルの内容を貼り付ける。

**手動貼り付けの場合**:

1. メール送信アクションの本文に、HTMLテンプレートの **body部分を先に貼り付け**
2. その後 **header（style）部分を貼り付け**
3. `@{}` 内の式がPower Automateの動的コンテンツとして認識されることを確認

### メールテンプレート内の `{AppID}` 置換

テンプレート内の `{AppID}` は Step 7 でアプリ公開後に確定する。
フロー構築時点ではプレースホルダーのまま進め、Step 8 で実際のGUIDに置き換える。

### 参照ファイル

- `powerautomate/flow-*-build.html`（9ファイル） + `powerautomate/pending/flow-cancel-notify-build.html`（1ファイル）
- `powerautomate/templates/*.html`（14ファイル）

---

## Step 7: アプリ公開 + フロー接続 `[UI]`

make.powerapps.com での操作。

### 7-1. Power Automateフロー接続

Step 6でフローを構築した後、Power Appsエディタに戻って接続する：

1. 申請フォーム画面のAddMediaButton（または添付アップロードトリガー）にフローを接続
2. `btnSubmit.OnSelect` 内のフロー `.Run()` 呼び出しが正しいフロー名を指しているか確認

### 7-2. 公開

1. make.powerapps.com → 対象アプリを開く（編集モード）
2. 右上の「**公開**」ボタンをクリック

### 7-3. App ID 取得

1. make.powerapps.com → **アプリ一覧**
2. 対象アプリの「**...**」→「**詳細**」
3. **アプリID**（GUID形式）をコピー → Step 8 で使用

---

## Step 8: 公開後設定 `[スクリプト + UI]`

アプリ公開後に、App ID を使って以下を設定する。

### 8-1. カスタムビュー作成（任意）

改善提案メインリストに「自分の申請」「自分の承認待ち」ビューを作成する。初期移植時は不要で、後から必要に応じて実行する。

```powershell
./scripts/create-custom-views.ps1
```

### 8-2. Column Formatting 適用

> **PnP が使用できない場合**: `a_project/migration/ui_manual/ui-manual-sharepoint.html` の「Step 9: Column Formatting 手動適用」を参照してください。

SharePointリストの RequestID 列にリンク書式を設定し、クリックでPower Appsに遷移できるようにする。

```powershell
# スクリプト内の $AppID を実際のGUIDに置換してから実行
./scripts/set-column-formatting.ps1
```

### 8-3. メールテンプレートの AppID 置換

Power Automate の各フローで、メール本文中の `{AppID}` を実際のGUID に置換する。

#### 手順

1. `scripts/env/.env.prod` の `APP_ID=` に Step 7-3 で取得した App ID を設定する

```
# scripts/env/.env.prod
APP_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

2. スクリプトを実行する

```powershell
# PowerShell（Windows推奨）
./scripts/env/apply-env.ps1 prod

# bash（macOS / Linux）
./scripts/env/apply-env.sh prod
```

3. `powerautomate/templates-dist/` に `prod_*.html` が生成される。各フローのメール送信アクションの本文を、生成されたファイルの内容で置き換える。

> **注意**: `apply-env.sh clear` で `templates-dist/` を全削除できる。

対象フロー（全7フロー・14テンプレート分）：

- 改善提案\_申請通知（課長承認依頼 / 部長承認依頼 / 回覧依頼）
- 改善提案\_課長承認（承認完了 / 差戻通知 / 部長へ承認依頼）
- 改善提案\_部長承認（承認完了 / 差戻通知）
- 取下げ通知フロー（取下げ通知）`[v2]`
- 回覧通知フロー（回覧依頼 / 差戻通知 / 課長承認依頼 / 部長承認依頼）`[v2]`
- 回覧差戻フロー（差戻通知）`[v2]`
- リマインダーフロー（リマインダー）`[v2]`

### 参照ファイル

- `scripts/set-column-formatting.ps1`
- `scripts/env/apply-env.sh`
- `scripts/env/.env.prod`
- `powerautomate/templates/*.html`（ソーステンプレート）

---

## Step 9: 権限設定 + ナビゲーション非表示 `[スクリプト]`

動作確認テストの直前に適用する。この時点で適用することで、Step 5〜8 の構築・デバッグ中はSPリストを自由に編集でき、テスト環境の切り分けが容易になる。

> **PnP が使用できない場合**: `a_project/migration/ui_manual/ui-manual-sharepoint.html` の「Step 5: 権限設定」を参照してください。

```powershell
./scripts/set-permissions.ps1
```

### スクリプトが実行する内容

| #   | 設定内容                                                          | 対象リスト                                                             |
| --- | ----------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 1   | マスタリスト: メンバーグループの編集権限→読み取りに降格           | 社員マスタ / 改善分野マスタ / 表彰区分マスタ                           |
| 2   | 改善提案メイン: WriteSecurity=2（自分のアイテムのみ編集）         | 改善提案メイン                                                         |
| 3   | トランザクションリスト: WriteSecurity=2（自分のアイテムのみ編集） | 改善メンバー / 改善分野実績 / 評価データ                               |
| 4   | サイトナビゲーションから非表示                                    | 改善メンバー / 改善分野実績 / 評価データ / 回覧メンバー / 添付ファイル |

> **ナビゲーション非表示について**: Power Apps経由でのみ操作するリストをナビゲーションから非表示にし、SPリスト直接編集を抑止する。URL直打ちでのアクセスは可能なため、管理者のトラブルシューティングには支障なし。サイト設定から表示に戻せる。

### 参照ファイル

- `scripts/set-permissions.ps1`
- `docs/spec/security.md` — 権限設計の詳細仕様

---

## Step 10: 動作確認テスト `[手作業]`

移植完了後、以下の一連のフローを通しで確認する。

### 10-1. 基本接続確認

- [ ] Power Appsが正常に起動するか
- [ ] 全データソース（10リスト + ドキュメントライブラリ）に接続できるか
- [ ] 社員マスタからログインユーザーの情報が取得できるか（`gTestMode = false` の場合）

### 10-2. 申請フロー確認

- [ ] テストモード（`gTestMode = true`）で申請フォームを入力・提出できるか
- [ ] 添付ファイルがステージングにアップロードされ、提出時にドキュメントライブラリに転送されるか `[v2]`
- [ ] 改善提案メインリストにデータが登録されるか
- [ ] 課長へ承認依頼メールが届くか
- [ ] 下書き保存 → 再編集 → 提出ができるか `[v2]`
- [ ] サンクス画面が表示されるか `[v2]`

### 10-3. 回覧フロー確認 `[v2]`

- [ ] 回覧者を設定して提出した場合、回覧者1にメールが届くか
- [ ] 回覧者1が承認すると、回覧者2にメールが届くか（複数名設定時）
- [ ] 全回覧者が承認すると、課長（または部長）へ承認依頼メールが届くか
- [ ] 回覧者が差戻すると、申請者にNG通知メールが届くか
- [ ] 回覧メールのリンクから評価画面（Reviewerモード）に遷移できるか

### 10-4. 承認フロー確認

- [ ] メール内リンクから評価画面に遷移できるか（Param受け取り確認）
- [ ] 課長評価 → 承認で、承認完了メールが届くか
- [ ] 褒賞金額 ≥ 5,000円の場合、部長へ承認依頼メールが届くか
- [ ] 部長承認 → 完了メールが届くか
- [ ] 差戻 → 申請者にNG通知メールが届くか
- [ ] 差戻メールのリンクから申請フォーム（編集モード）に遷移できるか
- [ ] 承認完了後、サンクス画面が表示されるか `[v2]`

### 10-5. 取下げ・リマインダー確認 `[v2]`

- [ ] 申請取下げ → 承認者（または回覧者）に取下げ通知メールが届くか
- [ ] 取下げ後、閲覧画面で取下げメッセージが表示されるか
- [ ] リマインダーフロー実行後、滞留案件の担当者にリマインダーメールが届くか

### 10-6. ステージングクリーンアップ確認 `[v2]`

- [ ] 48時間経過した未提出ステージングレコードが自動削除されるか

### 10-7. SharePoint連携確認

- [ ] Column Formattingのリンクが正しくPower Appsに遷移するか
- [ ] 閲覧画面で添付ファイル画像が表示されるか
- [ ] 「自分の承認待ち」ビューのColumn Formattingリンクが正しく動作するか `[v2]`

### 10-8. 権限・セキュリティ確認 `[v2]`

- [ ] マスタリスト（社員/分野/表彰区分）が一般ユーザーから編集不可か
- [ ] 改善提案メインリストで他人の申請が編集不可か（SPリスト直接操作）
- [ ] 評価データリストで他人の評価が編集不可か（SPリスト直接操作）
- [ ] 評価者以外がURLパラメータで評価画面を開いた場合、エラーメッセージが表示されるか
- [ ] 回覧者以外がURLパラメータで回覧画面を開いた場合、エラーメッセージが表示されるか
- [ ] サイトナビゲーションに非表示リスト（改善メンバー等）が表示されていないか
- [ ] テストモードON時は評価者本人チェックがスキップされるか

---

## スクリプト一覧

### `scripts/` 直下（本番移植用）

| ファイル                    | 実行タイミング | 内容                                                                       | 要変更変数                                          |
| --------------------------- | -------------- | -------------------------------------------------------------------------- | --------------------------------------------------- |
| `create-lists.ps1`          | Step 2         | 全10リスト + 列定義 + インデックス + Title列非表示                         | `$SiteUrl`                                          |
| `create-employees-list.ps1` | —              | 社員マスタリスト単体作成（`create-lists.ps1` に含まれるため通常不要）      | `$SiteUrl`                                          |
| `import-employees.ps1`      | Step 3         | 社員マスタCSVインポート                                                    | `-CsvPath` パラメータ                               |
| `import-masters.ps1`        | Step 3         | 改善分野マスタ + 表彰区分マスタ投入                                        | —                                                   |
| `create-doclib.ps1`         | Step 4         | 添付ファイル用ドキュメントライブラリ作成                                   | `$SiteUrl`                                          |
| `set-permissions.ps1`       | Step 9         | サイト・リスト権限設定 + ナビゲーション非表示                              | `$SiteUrl`                                          |
| `create-custom-views.ps1`   | Step 8（任意） | 改善提案メインのカスタムビュー作成（§7。「自分の申請」「自分の承認待ち」） | —                                                   |
| `set-column-formatting.ps1` | Step 8         | RequestID列にリンク書式適用（§13 承認遷移リンク含む）                      | `$SiteUrl`, `$AppID`                                |

### `scripts/csv/`（社員マスタデータ）

| ファイル             | 内容                                     |
| -------------------- | ---------------------------------------- |
| `test_employees.csv` | テスト環境用社員マスタデータ（開発用）   |
| `prod_employees.csv` | §14 Excelから変換した本番用社員マスタCSV |

### `scripts/env/`（環境設定・テンプレート置換）

| ファイル        | 実行タイミング | 内容                                                                                | 要変更変数    |
| --------------- | -------------- | ----------------------------------------------------------------------------------- | ------------- |
| `apply-env.ps1` | Step 8         | メールテンプレートの `{AppID}` を一括置換して `templates-dist/` に出力（Windows用） | `.env.{環境}` |
| `apply-env.sh`  | Step 8         | 同上（macOS / Linux用）                                                             | `.env.{環境}` |
| `.env.dev`      | —              | 開発環境用の環境変数                                                                | `APP_ID`      |
| `.env.stg`      | —              | ステージング環境用の環境変数                                                        | `APP_ID`      |
| `.env.prod`     | —              | 本番環境用の環境変数                                                                | `APP_ID`      |

### `scripts/develop/`（開発環境パッチ用・本番移植不要）

| ファイル                           | 内容                                                                                                                              |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `convert-employee-xlsx.py`         | Excel組織構成 → 社員マスタCSV変換（Step 3で使用。要: `pip3 install openpyxl`）                                                    |
| `patch-update-category-01.ps1`     | 改善分野実績にConversionRate列追加                                                                                                |
| `patch-v92-evaluation-data.ps1`    | 評価データリスト再構築                                                                                                            |
| `patch-add-applicant-office.ps1`   | 申請者在籍事業所・原価単位列追加                                                                                                  |
| `patch-v10-add-filecategory.ps1`   | ドキュメントライブラリにFileCategory列追加                                                                                        |
| `patch-v10-add-division.ps1`       | Division（部門）列追加                                                                                                            |
| `patch-hide-title-columns.ps1`     | 全リストのTitle列非表示（既存環境用）                                                                                             |
| `patch-reload-employees2.ps1`      | 社員マスタデータの再投入（全削除→再登録）                                                                                         |
| `patch-add-category-sortorder.ps1` | 改善分野実績にSortOrder列追加                                                                                                     |
| `patch-staging-list.ps1`           | 添付ファイルステージングリスト作成（§1・新規環境は `create-lists.ps1` で対応済みのため不要）                                      |
| `patch-v3-reviewer.ps1`            | 回覧メンバーリスト作成（§3・新規環境は `create-lists.ps1` で対応済みのため不要）                                                  |
| `patch-v2-status-view.ps1`         | 「自分の承認待ち」ビュー作成 + CurrentAssigneeEmail列追加（§7・新規環境は `create-lists.ps1` で対応済みのため不要）               |
| `patch-employee-name-index.ps1`    | 社員マスタ EmployeeName 列インデックス追加（§8 サジェスト検索・新規環境は `create-lists.ps1` で対応済みのため不要）               |
| `patch-v13-approval-view-link.ps1` | 「自分の承認待ち」ビューにビューレベル Column Formatting 適用（§13・新規環境は `set-column-formatting.ps1` で対応済みのため不要） |

---

## 環境差分チェックリスト

移植時に環境に合わせて変更が必要な箇所（全量）：

### Step 0: テナント準備

- [ ] Azure AD アプリ登録完了、`{ClientId}` を取得済み
- [ ] SharePointサイト作成権限を確認済み
- [ ] Power Platform ライセンス・環境アクセスを確認済み

### SharePoint（スクリプト）

- [ ] `scripts/set-column-formatting.ps1` の `$AppID` を実際のGUIDに変更（Step 8後）
- [ ] 社員マスタCSVを本番データに差し替え（`convert-employee-xlsx.py` でExcelから変換）

### Power Apps

- [ ] `powerapps/app-onstart.pfx` の `gTestMode` を `false` に変更
- [ ] `powerapps/app-onstart.pfx` の `gSharePointSiteUrl` を移植先URLに変更
- [ ] データソース接続を移植先SharePointサイトに再接続

### Power Automate

- [ ] 全フローのSharePointコネクタ接続先を移植先テナントに設定
- [ ] 全フローのSharePointアクション「サイトのアドレス」を移植先URLに設定（計35箇所）
- [ ] `scripts/env/.env.prod` の `APP_ID` に実際のGUIDを設定（Step 8後）
- [ ] `./scripts/apply-env.sh prod` を実行し `templates-dist/prod_*.html` を生成、各フローのメール本文を置換（14テンプレート分）
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
   - `flow-cancel-notify`: 1箇所（取下げ通知）`[v2]`
   - `flow-reviewer-notify`: 3箇所（回覧依頼・課長承認依頼・部長承認依頼）`[v2]`
   - `flow-reviewer-dismiss`: 1箇所（回覧差戻通知）`[v2]`
   - `flow-reminder`: 1箇所（リマインダー）`[v2]`

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
