# Power Automate 実践知見

タスク着手前に必ず一読すること。公式ドキュメントだけでは分からない、実装で発見したハマりどころを記録。

## Get items 結果の参照パターン（標準）

SharePoint「複数の項目の取得（Get items）」の結果を参照する場合、**Apply to each + 変数セットは不要**。`first()` で直接参照できる。

```
// ✅ 標準パターン: ループ外から直接参照
first(body('アクション名')?['value'])?['列名']

// 例: 「改善提案メイン」アクションの結果から申請者名を取得
first(body('改善提案メイン')?['value'])?['ApplicantName']

// 例: Person型列のEmail
first(body('改善提案メイン')?['value'])?['ApproverManager/Email']
```

**変数を使うべきケース**: トリガー出力から直接取れない値（RequestID, ReviewOrder など、後続アクションで繰り返し参照する値）のみ変数化する。申請情報は `first()` で直接参照すれば変数は不要。

**注意**: `body('アクション名')` のアクション名はフロー上の表示名と完全一致が必須。スペース・記号も含めて一致させること。

### Get items のアクション命名ルール

「複数の項目の取得（Get items）」アクションは、デフォルト名のまま使用しないこと。**取得元のリストがわかる名前に必ず変更する。**

```
// ❌ 悪い例: デフォルト名のまま
アクション名: 複数の項目の取得
式: first(body('複数の項目の取得')?['value'])?['列名']

// ✅ 良い例: リスト名 or 取得内容で命名
アクション名: 改善提案メイン
式: first(body('改善提案メイン')?['value'])?['列名']

アクション名: 1人目の回覧メンバー
式: first(body('1人目の回覧メンバー')?['value'])?['ReviewerEmail']
```

同一フロー内に複数の Get items がある場合（申請情報 + 回覧メンバー等）、デフォルト名では区別できず式の参照先も不明確になる。メール本文の動的コンテンツ式も含め、すべての `body('アクション名')` 参照をわかりやすい名前で統一すること。

---

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

**⚠️ 重要**: UI上でパラメータに `request_id` や `reviewer_gid` などカスタム名を設定しても、`triggerBody()?['reviewer_gid']` ではアクセスできない。必ずポジション名（`text`, `text_1`, `text_2`）を使うこと。

実際のキー名はフロー実行履歴のトリガー出力（入力）で確認すること。

## 「項目の更新」アクションの必須項目

SharePointの「項目の更新」アクションは、ステータス1列だけ更新したい場合でも**UI上で必須表示される列すべてに値を入れる必要がある**。空欄のフィールドは既存値が保持されるため、必須列にはトリガーの値をそのまま渡せばよい。

**重要**: Power AutomateのUI上で必須表示される列は、SharePointリストの`Required`設定と完全には一致しない。確認済みの事実:
- **必須表示される**: テキスト型（1行）、複数行テキスト型、日付型
- **必須表示されない**: ユーザー型、選択肢型（いずれもリスト定義でRequired=TRUEでも）
- **未検証**: 数値型（本プロジェクトではRequired=TRUEの数値型列がないため未確認）

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

### SPリスト添付ファイルのファイル名取得

SharePoint「添付ファイルの取得（Get attachments V2）」でリスト添付ファイルを取得した場合:

- `?['name']` → null（空）を返す → `22_` のようにファイル名部分が空になる
- `?['id']` → URLパス（`/Lists/.../Attachments/25/%e8%25a9%25...`）を返す → そのまま使うとURLエンコードされた長い文字列になる

**正しいファイル名の取得方法**: `id` は**二重エンコード**されているため、`decodeUriComponent` を2回適用してからパスを分割する。

```
// ✅ 正しい（日本語ファイル名も正常に取得できる）
// ?['id'] の値は %252f のように二重エンコードされている
// 1回だけ decode すると %2f（スラッシュがまだエンコードされたまま）になり、split('/') が効かない
last(split(decodeUriComponent(decodeUriComponent(items('ループ名')?['id'])), '/'))

// 例: ファイル名に RequestID を prefix する場合
concat(variables('varRequestID'), '_', last(split(decodeUriComponent(decodeUriComponent(items('ループ名')?['id'])), '/')))
```

**NG例（よくある間違い）**:
```
// ❌ 誤り: split を先にすると %2f でスラッシュが認識されず分割できない
decodeUriComponent(last(split(items('ループ名')?['id'], '/')))
```

### コピーしたループのアクション名が変わり、式の参照が壊れる

「条件」ブランチをコピー＆貼り付けすると、内部の「それぞれに適用する」アクション名が自動的にリネームされる（例: `それぞれに適用する(改善後)`）。しかし**ループ内の式（`items('元の名前')?['name']`等）は古い名前のまま**残るため、ファイル名が空（`22_` など）になる。

**対処**: コピー後、ループ内の以下の式をループの実際の名前に合わせて書き換えること。
- `items('それぞれに適用する(改善後)')?['id']`
- `items('それぞれに適用する(改善後)')?['name']`

### トリガー条件の入力方法（fxタブ不要）

「トリガー」の「詳細オプション → トリガー条件」フィールドは、**式タブ（fx）を開かずにテキストを直接入力する**。
`@equals(...)` 形式の式をそのまま貼り付けてよい。

```
// 例: ステータス = "申請中" の場合だけトリガー
@equals(triggerOutputs()?['body/Status/Value'], '申請中')
```

**間違いやすいポイント**: アクション内の式入力（式タブが必要）と混同しやすいが、トリガー条件フィールドはテキストボックスに直接入力するだけでよい。fxタブを開こうとしても開けない。

---

### 「それぞれに適用する」内では動的コンテンツにトリガーパラメータが出ない

「それぞれに適用する（Apply to each）」ループの内側でアクションを設定する際、動的コンテンツパネルにトリガーのパラメータ（`RequestID`等）が表示されないことがある。**必ず fxタブ**で `@{triggerBody()['text_1']}` のように直接入力すること。

### 「Power App またはフローに応答する」は戻り値なしのフローでは削除

戻り値を返さないフロー（ステータスだけPower Apps側で判断するケース）に「Power App またはフローに応答する」アクションを入れると、保存時に「フロー実行のデータを参照しない応答が含まれています。これによりフローが応答アクションに到達するまでユーザー全員に不必要な待機が発生します」という警告が出る。このアクションは**削除してよい**。Power Apps側は `Run()` の成功/失敗でフロー実行ステータスを判断できる。

### SharePointドキュメントライブラリのフォルダーパスはURL内部パスで指定

「ファイルの作成」アクションの「フォルダーのパス」には、表示名（例: `添付ファイル`）ではなく**SharePoint上のURLパス**を指定すること。表示名を指定すると `Root folder is not found.` エラーになる。

```
// ❌ 誤り: 表示名
/添付ファイル

// ✅ 正しい: URLパス（SPのURLに含まれるパス部分）
/AttachmentFiles
```

確認方法: SharePointでライブラリを開いたときのURLから `/sites/サイト名/` より後の部分を使う。

### ユーザー型列のnull/空判定は empty() を使う

条件アクションでユーザー型列（Person型）の Email が空かどうかを判定する場合、**単純な空文字比較（`= 空欄`）ではnullが一致しないケースがある**。

**正しい方法**: `empty()` 関数を使い、右辺を `true` にする。

```
左辺（式タブ）: @{empty(first(body('複数の項目の取得')?['value'])?['ApproverManager/Email'])}
演算子: 次の値と等しい
右辺: true
```

`empty()` はnull・空文字・空配列・空オブジェクトをすべて `true` と判定するため、ユーザー型列が未設定（Blank()でPatch）の場合も正しく判定できる。

> 実証: ApproverManager列に `Blank()` をPatchした場合、`= 空欄` 比較では条件が正しく動作しなかったが、`empty()` に変更したところ正常に動作した。

### メール送信のCC/To複数アドレス
「メールの送信 (V2)」のCC/To欄に複数アドレスを指定する場合、**`;`区切りの1つの文字列**として渡す必要がある。式を`;`で並べただけでは文字列が連結されてしまい `email1@...email2@...` となり「format 'string/email'」エラーになる。`concat(式1, ';', 式2)` を使うこと。

## Power Appsトリガーへ変更後のトラブルシューティング

### フロー名変更後はPower Apps側で再接続が必要

Power Automate側でフロー名を変更しても、Power Apps側の接続名は**自動更新されない**。接続パネルの上段（接続名）と下段（実際のフロー名）が異なっている場合、古いフロー（変更前）が呼ばれ続ける。

**対処**: データパネルで古い接続を削除 → 「フローの追加」で正しいフローを再接続する。追加時は**アイコン**で判別すること（SharePointアイコン=item-createdトリガー、Power Appsアイコン=Power Appsトリガー）。

### フローが起動しない原因の切り分け方法

Power Automateの「実行履歴」で確認する:

| 実行履歴の状態 | 原因 | 対処 |
|---|---|---|
| 履歴に何も記録されない | Power Apps側の式が呼ばれていない（コメントアウト、接続名不一致、`.Run()`が未解決） | Power Apps側の式・接続を確認 |
| 「失敗」で記録されている | フローは起動しているがフロー内でエラー | 失敗したアクションのエラー内容を確認 |

### トリガーを「項目作成時」→「Power Appsから」に変更した場合の式更新

`triggerOutputs()?['body/列名']` は「項目作成時」トリガー専用の参照方法。**Power Appsトリガーに変えると列値はnullになる**。

トリガー直後に「複数の項目の取得」でRequestIDを条件にリストを取得し、以下の形式に統一すること:

```
// ❌ 旧: 項目作成時トリガー
triggerOutputs()?['body/TotalEffectAmount']

// ✅ 新: Power Appsトリガー + 複数の項目の取得
first(body('複数の項目の取得')?['value'])?['TotalEffectAmount']
```

**注意**: `formatNumber()` の第1引数がnullになるとフロー全体がエラーで止まる。メール本文のすべての `triggerOutputs()` 参照を漏れなく置換すること。メールテンプレートHTML（`powerautomate/templates/`）も同様に更新が必要。

## SharePoint Column Formatting × PnP PowerShell

### `&` のエスケープ: Set-PnPField vs Set-PnPView で挙動が異なる

Column Formatting JSON 内の URL に `&` を含む場合（例: `&EvalType=課長`）:

- **`Set-PnPField`**: `&` をそのまま書いてよい。`&amp;` と書くと URL に `&amp;` がそのまま出力される
- **`Set-PnPView`**: `&` を書くと XML パースエラー（`An error occurred while parsing EntityName`）。`&amp;` に置換が必要

原因: PnP PowerShell 内部の CSOM シリアライズで、`Set-PnPView` は XML エスケープを自動適用しないが、`Set-PnPField` は適用する（または異なるシリアライズパスを通る）。

### ビューレベルの CustomFormatter による列書式の上書きが効かない

`Set-PnPView -Values @{CustomFormatter = '{"ColumnName": {...}}'}` で列書式を上書きしようとしても、列レベルの書式（`Set-PnPField -Values @{CustomFormatter = ...}`）が優先される。

**回避策**: 列レベルの Column Formatting 内で `@me == [$PersonField.email]` 条件を使い、現在のユーザーが担当者かどうかで動的にパラメータを切り替える。ビュー固有の動作を列レベルの条件式で実現する。
