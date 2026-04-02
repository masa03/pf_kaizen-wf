# UI手作業手順書: 2-7 添付ファイルコントロール

Power Apps Studio で手動操作が必要な作業の手順書。
YAML Code Viewでは接続が不安定なコントロールの配置手順。

> **§1 対応済み（2026-03-30改訂）**: AddMediaButtonは非画像ファイルを選択できないため廃止。
> EditForm + SharePointリスト添付（添付ファイルステージング）方式に変更。

---

## 前提条件

- Power Apps Studio で対象アプリを開いている
- 以下のYAMLがCode Viewで適用済み:
  - `powerapps/screen-application-form.yaml`（§1対応版 cntAttachmentSection適用済み）
  - `powerapps/screen-view.yaml`（colViewAttachments対応済み）
  - `powerapps/screen-evaluation.yaml`（colViewAttachments対応済み）
  - `powerapps/app-onstart.pfx`（colAttachments / colViewAttachments初期化済み）
- `scripts/develop/patch-staging-list.ps1` 実行済み（添付ファイルステージングリスト作成済み）

---

## 手順1: データソース接続

### 1-1. 添付ファイルドキュメントライブラリの接続

1. 左メニュー「**データ**」をクリック
2. 「**データの追加**」→ 「**SharePoint**」
3. サイト `https://xxxxx.sharepoint.com/sites/kaizen-wf` を選択
4. 「**添付ファイル**」ライブラリにチェックを入れて「**接続**」

### 1-2. 添付ファイルステージングリストの接続（§1 新規）

1. 左メニュー「**データ**」をクリック
2. 「**データの追加**」→ 「**SharePoint**」
3. サイト `https://xxxxx.sharepoint.com/sites/kaizen-wf` を選択
4. 「**添付ファイルステージング**」にチェックを入れて「**接続**」

### 1-3. Power Automateフローの接続

1. 左メニュー「**データ**」をクリック
2. 「**データの追加**」→ 「**Power Automate**」
3. 「**改善WF_ステージング転送**」フローを選択して接続

> **注意**: フローが表示されない場合は、Power Automate側でフローが保存済み・有効であることを確認してください。

---

## 手順2: EditForm（editFormAttachment）の配置（§1 新規）

AddMediaButtonに替わり、全ファイル形式対応のEditFormを配置する。

### 2-1. コントロール配置

1. **ツリービュー**で `ApplicationFormScreen` → `cntScrollable` → `cntRight` → `cntAttachmentSection` を選択
2. 上部メニュー「**挿入**」→ 「**フォーム**」→ 「**編集**」（EditForm）
3. コントロールが `cntAttachmentSection` 内に配置される

### 2-2. コントロール名の変更

1. 配置されたEditFormを選択
2. ツリービューで名前を `editFormAttachment` に変更

### 2-3. データソース接続

1. `editFormAttachment` を選択
2. 右側プロパティパネル「**データソース**」→ 「**添付ファイルステージング**」を選択

### 2-4. フィールド表示の設定

1. プロパティパネル「**フィールドの編集**」をクリック
2. 表示されているフィールド一覧で「**添付ファイル（Attachments）**」以外をすべてオフにする（非表示）
3. 「**添付ファイル**」のみ表示状態にする

### 2-5. Itemプロパティの設定

1. `editFormAttachment` を選択
2. プロパティドロップダウンで「**Item**」を選択
3. 数式バーに以下を入力:

```
varCurrentStagingItem
```

### 2-6. DefaultModeプロパティの設定

1. プロパティドロップダウンで「**DefaultMode**」を選択
2. 数式バーに以下を入力:

```
FormMode.Edit
```

### 2-7. OnSuccessプロパティの設定

1. プロパティドロップダウンで「**OnSuccess**」を選択
2. 数式バーに以下を入力:

```
RemoveIf(colStagingDisplay, Category = ddAttachFileCategory.Selected.Value);
Collect(colStagingDisplay, {FileName: "（添付済み）", Category: ddAttachFileCategory.Selected.Value});
Notify("ファイルを追加しました", NotificationType.Success)
```

> **注意**: Power Apps の静的チェックでは `LookUp(...).Attachments` が認識されないため、カテゴリ確定の表示は「（添付済み）」の1行で管理する。実際のファイル名は EditForm 内の添付ファイルコントロールで確認できる。

### 2-8. OnFailureプロパティの設定

1. プロパティドロップダウンで「**OnFailure**」を選択
2. 数式バーに以下を入力:

```
Notify("ファイルのアップロードに失敗しました: " & EditForm1.Error, NotificationType.Error)
```

> `EditForm1` の部分は実際のコントロール名 `editFormAttachment` に合わせて変更してください。

### 2-9. レイアウト調整

1. `editFormAttachment` のサイズを調整:
   - Width: `=Parent.Width`
   - Height: `160`（目安。添付ファイルの数に応じて自動調整される）
2. ツリービュー上で `editFormAttachment` を `cntAttachmentButtonArea` の直下（`lblFileNote` の上）に移動する

> **配置順序（cntAttachmentSection 内）:**
> 1. `lblAttachmentTitle`
> 2. `lblAttachmentGuide`
> 3. `cntAttachmentButtonArea`（カテゴリDropDown + 確定ボタン）
> 4. `editFormAttachment` ← ここに配置
> 5. `lblFileNote`
> 6. `galStagingFiles`（確定済みファイル一覧）
> 7. `galAttachments`（差戻再提出時の既存ファイル一覧）
> 8. `lblAttachmentCount`

---

## 手順3: 日本語列名エラーの確認と修正（閲覧画面・評価画面）

`screen-view.yaml` および `screen-evaluation.yaml` のOnVisibleには、日本語列名（`拡張子付きのファイル名`、`'完全パス '`、`ファイル種別`）を含む数式がすでに記述されています。

**YAMLペースト後に赤いエラーがなければ手順3は不要です。**

エラーが表示されている場合のみ、以下の手順で修正してください。

### 3-1. 閲覧画面（ViewScreen）

1. ツリービューで `ViewScreen` を選択
2. プロパティドロップダウンで「**OnVisible**」を選択
3. 数式バー内の `拡張子付きのファイル名`、`'完全パス '`、`ファイル種別` に赤い下線があるか確認
4. エラーがある場合: `ThisRecord.` の後ろにカーソルを置き、インテリセンス（候補一覧）から対応する列名を選択し直す
   - `'完全パス '` は末尾にスペースがある点に注意

### 3-2. 評価画面（EvaluationScreen）

1. ツリービューで `EvaluationScreen` を選択
2. プロパティドロップダウンで「**OnVisible**」を選択
3. 同様に赤い下線があれば修正

> **ポイント**: `ThisRecord.` まで入力すると、SharePointの列名がインテリセンスに表示されます。日本語列名を候補から選択することで、正しい列参照が設定されます。

---

## 手順4: 動作確認

### 4-1. 添付ファイル追加テスト（§1 新方式）

1. Power Apps Studio のプレビュー（F5）を起動
2. 申請フォームを開く（スクリーンOnVisibleでステージングレコード3件が自動作成される）
3. カテゴリDropDown（`ddAttachFileCategory`）で「改善前」を選択
4. `editFormAttachment` 内の「**ファイルの添付**」リンクをクリック
5. PDFまたはOfficeファイル（.docx, .xlsx, .pptx）を選択 ← **非画像ファイルが選択できることを確認**
6. 「**このカテゴリを確定**」ボタンをクリック
7. `galStagingFiles` ギャラリーに「改善前 + ファイル名」が表示されることを確認
8. 画像ファイル（JPG）でも同様に確認
9. 別カテゴリ（改善後/その他）でも繰り返す

### 4-2. 提出テスト（Power Automateフロー接続後）

1. テストモードで全項目入力 + ファイル添付（手順4-1完了後）
2. 「提出」ボタンをクリック
3. 確認ポップアップ → OK
4. SharePoint「添付ファイルステージング」リストを確認:
   - 提出後、ステージングレコード3件が削除されていること
5. SharePoint「添付ファイル」ドキュメントライブラリを確認:
   - ファイルが `RequestID_FileName` 形式で保存されている
   - `RequestID` 列に正しいIDが設定されている
   - `ファイル種別` 列（FileCategory）に「改善前」/「改善後」/「その他」が正しく設定されている

### 4-3. 閲覧画面テスト

1. 提出後、閲覧画面に遷移
2. 添付ファイルセクションを確認:
   - 画像ファイル: 埋め込み表示される
   - 非画像ファイル（PDF等）: ファイル名リンクとして表示される
3. 非画像ファイルのリンクをクリックして SharePoint上でファイルが開くことを確認

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

### EditForm の Item が設定されず添付ファイルコントロールが空のまま

- `varCurrentStagingItem` が Blank の場合、EditForm は Item なしの状態になる
- 対処: スクリーンのOnVisibleが正常に実行されているか確認。`varStagingBeforeID` が設定済みか確認する

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
| `powerautomate/flow-staging-transfer.md` | 改善WF_ステージング転送 フロー設計書（§1新規） |
| `scripts/create-doclib.ps1` | ドキュメントライブラリ作成スクリプト |

---

## §4 申請取消機能 — UI手作業手順

### 前提条件

- 上記の手順1〜3（データソース接続・OnVisible手動入力・フロー接続）が完了していること
- `powerautomate/flow-cancel-notify-build.html` に従い「取下げ通知フロー」が構築済みであること

---

### 手順A: 閲覧画面（screen-view.yaml）の適用

1. Power Apps Studio で対象アプリを開く
2. 閲覧画面（ViewScreen）を選択
3. 「**…（その他）**」→「**コードの編集**」で Code View を開く
4. `powerapps/screen-view.yaml` の全内容をコピーして貼り付け
5. エラーがないことを確認して保存

> **確認ポイント:**
> - `cntCancelArea` コンテナ（取消ボタン + 再編集ボタン）が表示されること
> - `cntCancelPopupOverlay` コンテナ（取消確認ポップアップ）が配置されること

---

### 手順B: 取下げ通知フローの接続

1. 閲覧画面（ViewScreen）を選択した状態で、左メニュー「**Power Automate**」を開く
2. 「**フローの追加**」→ 構築済みの「**取下げ通知フロー**」を選択
3. フローが一覧に表示されることを確認

> `btnCancelExecute.OnSelect` 内の `取下げ通知フロー.Run(...)` がフロー接続後に赤いエラーなしで解決されることを確認する。

---

### 手順C: 動作確認

1. テストモードで閲覧画面を開き、申請中の申請を表示する
2. **取消ボタン**が申請者本人のみに表示されることを確認
3. 取消ボタンを押すとポップアップが表示されることを確認
4. 「取消を実行する」でステータスが「取下げ」に変わることを確認
5. 取下げ後に**再編集ボタン**が表示されることを確認
6. 再編集ボタンで申請フォームが編集モードで開くことを確認
