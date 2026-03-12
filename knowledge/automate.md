# Power Automate 実践知見

タスク着手前に必ず一読すること。公式ドキュメントだけでは分からない、実装で発見したハマりどころを記録。

## Power Apps → Power Automate ファイルアップロード

`AddMediaButton` で取得したファイルを Power Automate 経由で SharePoint ドキュメントライブラリに保存する場合、以下の手順が必須:

1. **Power Apps側**: `AddMediaButton.Media` は `appres://blobmanager/...` 内部参照を返す。`contentBytes` に直接渡すとファイル名文字列になりファイルが壊れる
2. **正しい変換**: `JSON(UploadedImage.Image, JSONFormat.IncludeBinaryData)` で data URI 文字列（`data:image/png;base64,...`）に変換してコレクションに保存
3. **フローパラメータ**: ファイル型ではなく**テキスト型**で受け取る。Power Apps (V2) トリガーの複数テキストパラメータは `text`, `text_1`, `text_2` の順にマッピングされる
4. **フローでバイナリ変換**: 「ファイルの作成」アクションのファイルコンテンツに `dataUriToBinary(triggerBody()['text_N'])` を使用

```
// Power Apps: コレクションへの格納
{Name: Self.FileName, ContentBase64: Substitute(JSON(UploadedImage1.Image, JSONFormat.IncludeBinaryData), """", "")}

// Power Apps: フロー呼び出し（3パラメータすべてテキスト）
フロー名.Run(RequestID, FileName, ThisRecord.ContentBase64)

// Power Automate: ファイルの作成アクション
ファイルコンテンツ: dataUriToBinary(triggerBody()['text_2'])
```

## Power Apps (V2) トリガーのパラメータマッピング

複数のテキスト型パラメータを定義すると、triggerBody()のキーは定義順に以下のようになる:
- 1番目: `text`
- 2番目: `text_1`
- 3番目: `text_2`
- （以降 `text_N`）

パラメータ名（RequestID, FileName等）ではアクセスできない。フロー実行履歴のトリガー出力で実際のキー名を確認すること。

## 「項目の更新」アクションの必須項目

SharePointの「項目の更新」アクションは、ステータス1列だけ更新したい場合でも**必須列すべてに値を入れる必要がある**。空欄のフィールドは既存値が保持されるため、必須列にはトリガーの値をそのまま渡せばよい。

```
// 例: ステータスだけ変更、他の必須列はトリガーの値をそのまま渡す
ID: triggerOutputs()?['body/ID']
申請者氏名: triggerOutputs()?['body/ApplicantName']
TEC: triggerOutputs()?['body/Department']
改善テーマ: triggerOutputs()?['body/Theme']
ステータス Value: 課長評価中  ← ここだけ変更
```

> 内部的にPUT相当のバリデーションが走るため。変更列だけ指定したい場合は「SharePoint に HTTP 要求を送信」アクション（REST API直接）を使う。

## 式の入力方法

Power Automateのアクション設定で `triggerOutputs()?['body/...']` 等を入力する場合、テキスト欄に直接タイプしても**文字列リテラルとして扱われる**。必ず **「式」タブ** から入力し、`fx` トークンとして挿入すること。「動的なコンテンツ」タブから選択した場合は青いトークンになる（こちらも正しく動作する）。

## SharePoint列型とtriggerOutputsの構造

トリガー出力のJSON構造は列の型によって異なる:

| 列の型 | triggerOutputsでの構造 | アクセス例 |
|---|---|---|
| テキスト/数値 | 直接値 | `triggerOutputs()?['body/ApplicantName']` |
| 選択肢（Choice） | `{Id, Value}` オブジェクト | `triggerOutputs()?['body/Status/Value']` |
| ユーザー（Person） | `{Email, DisplayName, ...}` オブジェクト | `triggerOutputs()?['body/ApproverManager/Email']` |

## 社員マスタ不要パターン（承認者判定）

改善提案メインリストにApproverManager / ApproverDirectorをユーザー型（Person）で保存している場合、承認者のEmail/DisplayNameはトリガー出力から直接取得できる。課長=申請者の判定も `ApplicantEmail/Email == ApproverManager/Email` の比較で完結するため、社員マスタへのLookUpは不要。

## デバッグTips

### 式のタイポに注意
Power Automateは式内のキー名が間違っていても**エラーを出さず `null` を返す**。`null == "値"` はFalseになるため、条件が常にFalseになる場合はキー名のスペルミスを疑う。デバッガーの「式には、デバッガーで解決できない動的な関数、変数、パラメータが含まれています」は警告であり、式自体は正常に動作する（エラーではない）。

### コードビューでの確認方法
条件やアクションが期待通り動かない場合、**コードビュー**タブでJSON定義を確認する。パラメータUI上では見切れて確認できないスペルミスや余分な改行（`\n`）を発見できる。

### メールアドレスフィールドの改行
式タブで入力後に改行が付与されることがある（`"m.kato@example.com\n"`）。テキスト系フィールドでは問題にならないが、メールの宛先（`emailMessage/To`）では `string/email` 形式の検証で弾かれる。式を入れ直して末尾に改行が入らないようにする。

### メール本文HTMLテンプレートの貼り付け方法
Power Automateの「メールの送信 (V2)」本文に `@{式}` を含むHTMLを貼り付ける場合、**body部分を先に貼り付け → その後header（style）部分を貼り付け**の2段階で行うと式が正しく認識される。一度に全体を貼り付けると式が文字列として扱われる場合がある。

### アクション名と式の参照一致
`body('アクション名')` や `outputs('アクション名')` の文字列は、フロー上の実際のアクション名と**完全一致**が必要。1文字でも異なると「無効な参照」エラーになる。アクション名を変更した場合は、そのアクションを参照するすべての式を更新すること。

### メール送信のCC/To複数アドレス
「メールの送信 (V2)」のCC/To欄に複数アドレスを指定する場合、**`;`区切りの1つの文字列**として渡す必要がある。式を`;`で並べただけでは文字列が連結されてしまい `email1@...email2@...` となり「format 'string/email'」エラーになる。`concat(式1, ';', 式2)` を使うこと。
