# UI手作業手順書: 2-7 添付ファイルコントロール

Power Apps Studio で手動操作が必要な作業の手順書。
YAML Code Viewでは接続が不安定なコントロールの配置手順。

---

## 前提条件

- Power Apps Studio で対象アプリを開いている
- 以下のYAMLがCode Viewで適用済み:
  - `powerapps/screen-application-form.yaml`（cntAttachmentSection追加済み）
  - `powerapps/screen-view.yaml`（colViewAttachments対応済み）
  - `powerapps/screen-evaluation.yaml`（colViewAttachments対応済み）
  - `powerapps/app-onstart.pfx`（colAttachments / colViewAttachments初期化済み）

---

## 手順1: データソース接続

### 1-1. 添付ファイルドキュメントライブラリの接続

1. 左メニュー「**データ**」をクリック
2. 「**データの追加**」→ 「**SharePoint**」
3. サイト `https://xxxxx.sharepoint.com/sites/kaizen-wf` を選択
4. 「**添付ファイル**」ライブラリにチェックを入れて「**接続**」

### 1-2. Power Automateフローの接続

1. 左メニュー「**データ**」をクリック
2. 「**データの追加**」→ 「**Power Automate**」
3. 「**改善提案_添付ファイルアップロード**」フローを選択して接続

> **注意**: フローが表示されない場合は、Power Automate側でフローが保存済み・有効であることを確認してください。

---

## 手順2: AddMediaButton の配置

### 2-1. コントロール配置

1. **ツリービュー**で `ApplicationFormScreen` → `cntAttachmentButtonArea` を選択
2. 上部メニュー「**挿入**」→ 「**メディア**」→ 「**画像の追加**」（AddMediaButton）
3. コントロールが `cntAttachmentButtonArea` 内に配置される

### 2-2. コントロール名の変更

1. 配置されたコントロールを選択
2. ツリービューで名前を `btnAddFile` に変更

### 2-3. プロパティ設定

プロパティパネルで以下を設定:

| プロパティ | 値 |
|---|---|
| Text | `"ファイルを追加"` |
| Height | `36` |
| Width | `160` |

### 2-4. OnChange 数式の設定

1. `btnAddFile` を選択
2. プロパティパネル上部のドロップダウンで「**OnChange**」を選択
3. 数式バーに以下を入力:

```
If(
    !IsBlank(Self.FileName),
    Collect(
        colAttachments,
        {
            Name: Self.FileName,
            Content: Self.Media
        }
    )
)
```

> **動作**: ユーザーがファイルを選択するたびに `colAttachments` コレクションにファイルが追加される。同じボタンで複数回ファイルを選択することで複数ファイルの添付が可能。

---

## 手順3: OnVisible数式の手動入力（閲覧画面・評価画面）

SharePointドキュメントライブラリの日本語列名（`拡張子付きのファイル名`、`'完全パス '`）は
YAML Code Viewペーストでは解決できません。以下の数式を **Power Apps Studioの数式バーで手動入力** する必要があります。

### 3-1. 閲覧画面（ViewScreen）

1. ツリービューで `ViewScreen` を選択
2. プロパティドロップダウンで「**OnVisible**」を選択
3. 数式バーの既存コードの末尾（最後の `)` の直前）に以下の部分を探す:

```
ClearCollect(
    colViewAttachments,
    ForAll(
        Filter(添付ファイル, RequestID = varViewRequestID),
        {
            FileName: ThisRecord.拡張子付きのファイル名,
            FileLink: ThisRecord.'完全パス '
        }
    )
)
```

4. 上記のForAll部分が **エラー表示（赤い下線）** になっている場合、数式バーで直接修正する:
   - `拡張子付きのファイル名` → インテリセンス（候補一覧）から選択
   - `'完全パス '` → インテリセンスから選択（末尾にスペースがある点に注意）

### 3-2. 評価画面（EvaluationScreen）

1. ツリービューで `EvaluationScreen` を選択
2. プロパティドロップダウンで「**OnVisible**」を選択
3. 同様に以下の部分を探し、エラーがあれば修正:

```
ClearCollect(
    colViewAttachments,
    ForAll(
        Filter(添付ファイル, RequestID = varEvalRequestID),
        {
            FileName: ThisRecord.拡張子付きのファイル名,
            FileLink: ThisRecord.'完全パス '
        }
    )
);
```

> **ポイント**: `ThisRecord.` まで入力すると、SharePointの列名がインテリセンスに表示されます。日本語列名を候補から選択することで、正しい列参照が設定されます。

---

## 手順4: 動作確認

### 4-1. 添付ファイル追加テスト

1. Power Apps Studio のプレビュー（F5）を起動
2. 「ファイルを追加」ボタンをクリック
3. ファイルを選択
4. ギャラリー（galAttachments）にファイル名が表示されることを確認
5. 「削除」ボタンをクリックしてファイルが一覧から消えることを確認
6. 複数ファイルを追加して件数カウンターが正しいことを確認

### 4-2. 提出テスト（Power Automateフロー接続後）

1. テストモードで全項目入力 + ファイル添付
2. 「提出」ボタンをクリック
3. 確認ポップアップ → OK
4. SharePoint「添付ファイル」ライブラリを確認:
   - ファイルが保存されている
   - RequestID列に正しいIDが設定されている

### 4-3. 閲覧画面テスト

1. 提出後、閲覧画面に遷移
2. 添付ファイルセクションにファイル名がリンクとして表示される
3. リンクをクリックしてファイルが表示/ダウンロードされる

---

## トラブルシューティング

### ギャラリーにデータがあるのに何も表示されない

**最も多い原因**: Gallery テンプレート直下の GroupContainer に `FillPortions: =1` を使っている。

Gallery（クラシック `Gallery@2.15.0`）はAutoLayoutコンテナではないため、直接子に `FillPortions` が効かない。
Code Viewで `FillPortions: =1` → `Width: =1`（1ピクセル）に変換され、中身が全く見えなくなる。

**修正方法**: Gallery直下コンテナには以下を明示指定する:
```yaml
Width: =Parent.TemplateWidth
Height: =Parent.TemplateHeight
```

### AddMediaButton が動作しない

- Canvas Appsのバージョンが古い場合、AddMediaButtonのファイルサポートが限定されることがある
- 対処: Power Apps Studio → 設定 → 近日公開の機能 → 「従来のメディア コントロール」を確認

### Power Automateフローが表示されない

- フローの「Power Apps (V2)」トリガーを使用していることを確認（「Power Apps」ではなく「Power Apps (V2)」）
- フローが「オフ」になっていないか確認
- フローの保存が完了していることを確認

### ファイルアップロードがタイムアウトする

- 大容量ファイル（50MB超）はPower Appsの制限に達する可能性がある
- 対処: ファイルサイズの上限をユーザーに案内（推奨: 1ファイル50MB以下）

### colViewAttachments にデータが表示されない

- 「添付ファイル」ドキュメントライブラリがデータソースとして接続されているか確認
- **手順3のOnVisible手動入力が完了しているか確認** — ForAll内の日本語列名（`拡張子付きのファイル名`、`'完全パス '`）はYAMLペーストでは解決できない
- OnVisible数式バーで赤い下線（エラー）がないか確認。エラーがある場合、`ThisRecord.` の後にインテリセンスから列名を選択し直す
- SharePointドキュメントライブラリの列名は環境によって異なる可能性がある。`ThisItem.` で補完候補を確認し、実際の列名を使用すること

---

## 関連ファイル

| ファイル | 内容 |
|---|---|
| `powerapps/screen-application-form.yaml` | 添付ファイルセクションUI + 提出ロジック |
| `powerapps/submit-logic.pfx` | フロー呼び出し処理（Step 3.5） |
| `powerapps/app-onstart.pfx` | colAttachments / colViewAttachments 初期化 |
| `powerapps/screen-view.yaml` | ファイルリンク一覧表示 |
| `powerapps/screen-evaluation.yaml` | ファイルリンク一覧表示 |
| `powerautomate/flow-upload-attachment.md` | Power Automateフロー設計書 |
| `scripts/create-doclib.ps1` | ドキュメントライブラリ作成スクリプト |
