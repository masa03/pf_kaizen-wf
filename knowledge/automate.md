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
