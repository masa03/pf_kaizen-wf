# Power Automate フロー設計書: 添付ファイルアップロード

**タスク**: 2-7
**フロー名**: 改善提案_添付ファイルアップロード
**用途**: Power Apps申請フォームから添付ファイルをドキュメントライブラリにアップロード

---

## フロー概要

```
[Power Apps (V2) トリガー]
    │
    ├── 入力: RequestID (テキスト)
    ├── 入力: FileName (テキスト)
    ├── 入力: FileContent (ファイル)
    │
    ▼
[SharePoint - ファイルの作成]
    │  サイト: 改善提案システム
    │  ライブラリ: 添付ファイル (AttachmentFiles)
    │  ファイル名: FileName
    │  ファイルコンテンツ: FileContent
    │
    ▼
[SharePoint - ファイルのプロパティの更新]
       サイト: 改善提案システム
       ライブラリ: 添付ファイル (AttachmentFiles)
       ID: [ファイルの作成].ItemId
       RequestID: RequestID（入力パラメータ）
```

---

## 構築手順

### Step 1: フロー作成

1. Power Automate → **マイフロー** → **新しいフロー** → **インスタントクラウドフロー**
2. フロー名: `改善提案_添付ファイルアップロード`
3. トリガー: **Power Apps (V2)** を選択

### Step 2: トリガーの入力パラメータ設定

トリガーの「入力の追加」で以下3つを追加:

| パラメータ名 | 種類 | 必須 |
|---|---|---|
| RequestID | テキスト | はい |
| FileName | テキスト | はい |
| FileContent | テキスト | はい |

### Step 3: アクション1 — ファイルの作成

1. **新しいステップ** → 「SharePoint」→ **ファイルの作成**
2. 設定:

| プロパティ | 値 |
|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` |
| フォルダーのパス | `/AttachmentFiles` |
| ファイル名 | 動的コンテンツから「FileName」（`triggerBody()['text_1']`）を選択 |
| ファイル コンテンツ | 式: `dataUriToBinary(triggerBody()['text_2'])` |

> **注意**: 3つのテキストパラメータは `text`(RequestID), `text_1`(FileName), `text_2`(FileContent) にマッピングされる。Power Appsからはdata URI文字列（`data:image/png;base64,...`）で渡されるため、`dataUriToBinary()` でバイナリに変換が必要。

### Step 4: アクション2 — ファイルのプロパティの更新

1. **新しいステップ** → 「SharePoint」→ **ファイルのプロパティの更新**
2. 設定:

| プロパティ | 値 |
|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` |
| ライブラリ名 | `添付ファイル` |
| ID | 動的コンテンツから「ファイルの作成」→ **ItemId** を選択 |
| リクエストID | 動的コンテンツから「RequestID」を選択 |

### Step 5: 保存・テスト

1. **保存** をクリック
2. **テスト** → **手動** でテスト実行（Power Appsから呼び出し前にフロー単体で確認）

---

## Power Apps からの呼び出し

### データソース接続

1. Power Apps Studio → 左メニュー「データ」→ **データの追加**
2. 「Power Automate」→ 「改善提案_添付ファイルアップロード」フローを選択

### 呼び出しコード（submit-logic.pfx / btnSubmit.OnSelect）

```
// --- Step 3.5: 添付ファイルアップロード ---
ForAll(
    colAttachments,
    改善提案_添付ファイルアップロード.Run(
        Text(varNewRequest.ID),
        ThisRecord.Name,
        ThisRecord.ContentBase64
    )
);
```

> **重要**: `colAttachments.ContentBase64` には `JSON(UploadedImage1.Image, JSONFormat.IncludeBinaryData)` で変換したdata URI文字列が格納されている。`AddMediaButton.Media`（blob参照）を直接渡すとファイル名文字列になるため不可。

**パラメータ対応**:

| Power Fx | フロー入力パラメータ | triggerBodyキー |
|---|---|---|
| `Text(varNewRequest.ID)` | RequestID | `text` |
| `ThisRecord.Name` | FileName | `text_1` |
| `{name: ..., contentBytes: ...}` | FileContent（ファイル型） |

---

## エラーハンドリング（任意拡張）

将来的に以下の対応を追加可能:

- **ファイルサイズチェック**: フロー内で条件分岐（例: 100MB超はエラー返却）
- **同名ファイル対策**: ファイル名にタイムスタンプを付与（例: `{RequestID}_{timestamp}_{FileName}`）
- **アップロード失敗通知**: フロー失敗時のエラー通知メール

---

## 関連ファイル

- ドキュメントライブラリ作成: `scripts/create-doclib.ps1`
- 提出ロジック: `powerapps/submit-logic.pfx`（Step 3.5）
- 申請フォーム: `powerapps/screen-application-form.yaml`（btnSubmit.OnSelect）
