# 改善提案システム 移植・デプロイ手順書

新しい環境（本番/別テナント）にシステムを一から構築するための手順書。

---

## 前提条件

- Microsoft 365 / Power Platform ライセンスが利用可能
- PnP PowerShell がインストール済み（`Install-Module PnP.PowerShell`）
- Azure AD にアプリ登録済み（ClientId 取得済み）
- 管理者権限でSharePointサイト作成が可能

---

## 全体フロー

```
Step 1: SharePointサイト作成          [UI手作業]
Step 2: SharePointリスト一括作成       [スクリプト]
Step 3: マスタデータ投入              [スクリプト]
Step 4: ドキュメントライブラリ作成     [スクリプト]
Step 5: 権限設定                      [スクリプト]
Step 6: Power Appsアプリ移植          [UI手作業 + Code View]
Step 7: Power Automateフロー構築      [UI手作業]
Step 8: アプリ公開                    [UI手作業]
Step 9: 公開後設定（Column Formatting + AppID置換）[スクリプト]
```

---

## Step 1: SharePointサイト作成 `[UI]`

1. SharePoint管理センターからサイトコレクションを作成
2. サイトURL例: `https://{tenant}.sharepoint.com/sites/kaizen-wf`

---

## Step 2: SharePointリスト一括作成 `[スクリプト]`

全8リスト + インデックスを一括作成する。

### 実行手順

```powershell
pwsh
$SiteUrl = "https://{tenant}.sharepoint.com/sites/kaizen-wf"
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "{ClientId}"

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

### 参照ファイル

- `scripts/create-lists.ps1` — リスト + 列定義 + インデックス + Title列非表示

---

## Step 3: マスタデータ投入 `[スクリプト]`

### 3-1. 社員マスタ投入

```powershell
# CSVを環境に合わせて準備（本番: 人事マスタ15,000件）
# テスト環境: scripts/test_employees.csv を使用
./scripts/import-employees.ps1
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

```powershell
./scripts/set-permissions.ps1
```

### 参照ファイル

- `scripts/set-permissions.ps1`

---

## Step 6: Power Appsアプリ移植 `[UI + Code View]`

make.powerapps.com での操作。

### 6-1. キャンバスアプリ作成

1. make.powerapps.com → **作成** → **空のアプリ** → **空のキャンバスアプリ**
2. アプリ名を入力、形式は「**タブレット**」を選択
3. 左メニュー「**データ**」→ データソース接続（全8リスト + ドキュメントライブラリ）

### 6-2. App.OnStart設定

1. `powerapps/app-onstart.pfx` の内容を App.OnStart に貼り付け
2. **テストモード**: `gTestMode` を `false` に変更（本番時）
3. **SharePointサイトURL**: `gSharePointSiteUrl` を環境のURLに変更

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
  - Power Automateフロー接続（Step 7完了後）

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

以下の4フローをPower Automate上で手動構築する。各フロー設計書に従ってアクションを配置する。

| 順序 | フロー名 | 設計書 | メールテンプレート |
|---|---|---|---|
| 1 | 改善提案_添付ファイルアップロード | `powerautomate/flow-upload-attachment.md` | — |
| 2 | 改善提案_申請通知 | `powerautomate/flow-notification-submit.md` | `templates/3-1_*.html` |
| 3 | 改善提案_課長承認 | `powerautomate/flow-approval-manager.md` | `templates/3-2_*.html` |
| 4 | 改善提案_部長承認 | `powerautomate/flow-approval-director.md` | `templates/3-3_*.html` |

### メールテンプレートの貼り付け方法

1. メール送信アクションの本文に、HTMLテンプレートの **body部分を先に貼り付け**
2. その後 **header（style）部分を貼り付け**
3. `@{}` 内の式がPower Automateの動的コンテンツとして認識されることを確認

### メールテンプレート内の `{AppID}` 置換

テンプレート内の `{AppID}` は Step 8 でアプリ公開後に確定する。
フロー構築時点ではプレースホルダーのまま進め、Step 9 で実際のGUIDに置き換える。

### 参照ファイル

- `powerautomate/flow-*.md`（4ファイル）
- `powerautomate/templates/*.html`（6ファイル）

---

## Step 8: アプリ公開 `[UI]`

make.powerapps.com での操作。

### 8-1. 公開

1. make.powerapps.com → 対象アプリを開く（編集モード）
2. 右上の「**公開**」ボタンをクリック

### 8-2. App ID 取得

1. make.powerapps.com → **アプリ一覧**
2. 対象アプリの「**...**」→「**詳細**」
3. **アプリID**（GUID形式）をコピー → Step 9 で使用

### 本番環境への移植方法（参考）

| 方法 | 手順 | 適用場面 |
|---|---|---|
| エクスポート/インポート | アプリ一覧 →「...」→「エクスポートパッケージ」→ 本番環境でインポート | 同一テナント内 |
| 手動再構築 | YAML/pfx を Code View で貼り付けて再現 | 別テナント |

> **注意**: エクスポート/インポートの場合、データソース（SharePointリスト）の接続先が元環境のURLを指しているため、インポート後にデータソースの再接続が必要。

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

対象フロー（全4フロー・6テンプレート分）：
- 改善提案_申請通知（承認依頼メール）
- 改善提案_課長承認（承認完了 / 差戻通知 / 部長へ承認依頼）
- 改善提案_部長承認（承認完了 / 差戻通知）

### 参照ファイル

- `scripts/set-column-formatting.ps1`
- `powerautomate/templates/*.html`（AppID箇所の確認用）

---

## スクリプト一覧

### `scripts/` 直下（本番移植用）

| ファイル | 実行タイミング | 内容 |
|---|---|---|
| `create-lists.ps1` | Step 2 | 全8リスト + 列定義 + インデックス + Title列非表示 |
| `import-employees.ps1` | Step 3 | 社員マスタCSVインポート |
| `import-masters.ps1` | Step 3 | 改善分野マスタ + 表彰区分マスタ投入 |
| `create-doclib.ps1` | Step 4 | 添付ファイル用ドキュメントライブラリ作成 |
| `set-permissions.ps1` | Step 5 | サイト・リスト権限設定 |
| `set-column-formatting.ps1` | Step 9 | RequestID列にリンク書式適用（AppID必要） |

### `scripts/develop/`（開発環境パッチ用・本番移植不要）

| ファイル | 内容 |
|---|---|
| `patch-update-category-01.ps1` | 改善分野実績にConversionRate列追加 |
| `patch-v92-evaluation-data.ps1` | 評価データリスト再構築 |
| `patch-add-applicant-office.ps1` | 申請者在籍事業所・原価単位列追加 |
| `patch-v10-add-filecategory.ps1` | ドキュメントライブラリにFileCategory列追加 |
| `patch-v10-add-division.ps1` | Division（部門）列追加 |
| `patch-hide-title-columns.ps1` | 全リストのTitle列非表示（既存環境用） |

---

## 環境差分チェックリスト

移植時に環境に合わせて変更が必要な箇所：

- [ ] `scripts/*.ps1` 内の `$SiteUrl` を本番URLに変更
- [ ] `scripts/set-column-formatting.ps1` の `$AppID` を実際のGUIDに変更
- [ ] `powerapps/app-onstart.pfx` の `gSharePointSiteUrl` を本番URLに変更
- [ ] `powerapps/app-onstart.pfx` の `gTestMode` を `false` に変更
- [ ] Power Automate フロー内のメール本文中 `{AppID}` を実際のGUIDに変更
- [ ] 社員マスタCSVを本番データに差し替え
