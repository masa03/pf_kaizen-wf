# Power Apps 実践知見

タスク着手前に必ず一読すること。公式ドキュメントだけでは分からない、実装で発見したハマりどころを記録。

## YAML記法ルール（Code Viewコピペ用）
- フォーマット: `- ControlName:` から始まる配列形式
- コントロール指定: `Control: Button@0.0.44` 形式
- プロパティ値: すべて `=` で始まるPower Fx式
- `#` や `:` を含む式: マルチライン（`|`）必須
- App ObjectはCode View不可（プロパティパネルで設定）
- **Galleryテンプレート内のレイアウト**: `X` プロパティはCode Viewペースト時に無視されるため、テンプレート直下にHorizontal AutoLayoutコンテナ（`GroupContainer@1.4.0`）を配置し、子コントロールを `FillPortions` / `Width` で並べること。X座標の固定値指定よりAutoLayoutコンテナを常に優先する
- **Galleryテンプレート直下コンテナのサイズ**: Gallery（クラシック `Gallery@2.15.0`）はAutoLayoutコンテナではないため、**直接子に `FillPortions` が効かない**。`FillPortions: =1` と書くと Code View で `Width: =1`（1ピクセル）に変換され、コンテナ内の全コントロールが見えなくなる（データはあるのに表示されない現象の原因になる）。Gallery直下コンテナには**必ず以下のように明示指定**すること:
  ```yaml
  Width: =Parent.TemplateWidth
  Height: =Parent.TemplateHeight
  ```
  ※ AutoLayoutコンテナの子（Gallery直下ではない）には `FillPortions` が正常に機能する
- モダンButton（Button@0.0.45）には `Size` プロパティがない（フォントサイズ指定不可）
- モダンTextInput（TextInput@0.0.54）には `Format` プロパティがない（数値フォーマット指定不可）。数値入力が必要な場合は `Value()` 関数で変換
- モダンTextInput（TextInput@0.0.54）には `Default` プロパティがない（Code View YAML非対応）。デフォルト値を設定するにはプロパティパネルで `Value` に数式を設定する
- Gallery はクラシックコントロール（Gallery@2.15.0）。モダンコントロールと混在OK

## Code View エクスポート時の注意（ラウンドトリップ差分）
手書きYAMLをCode Viewにペーストし、再度エクスポートすると以下の差分が発生する:
- **コメント消失**: `# ---` 等のYAMLコメントはCode Viewに保存されない（gitでの参照用としてのみ有効）
- **コントロール順序変更**: コンテナ内の子コントロールの表示順がCode View側で再配置される場合がある
- **プロパティ値のマルチライン化**: 単純な `Width: =400` が `Width: |` + `=400` 形式に変換される場合がある
- **デフォルト値プロパティの省略**: デフォルト値と一致するプロパティ（例: ButtonのHeight）はエクスポートに含まれない場合がある
- **運用ルール**: git管理ファイルはCode Viewエクスポート結果を正とする。手書きコメントはヘッダー部分のみ付与

## モダンコントロールのプロパティ名（クラシックとの違い）
- モダンTextInput（TextInput@0.0.54）: `.Value`（クラシックは `.Text`）
- モダンDropDown（DropDown@0.0.45）: `.Selected` + DropDownDataField子コントロール
- モダンDatePicker（DatePicker@0.0.46）: `.SelectedDate`
- モダンButton（Button@0.0.45）: `.OnSelect`, `.DisplayMode`
- モダンRadio（Radio@0.0.25）: デフォルト値は `DefaultSelectedItems` プロパティで配列形式で指定。`Layout` は `='RadioGroupCanvas.Layout'.Horizontal`（`=Layout.Horizontal` はCode Viewで無視される）。`DefaultSelectedItems` 内で `Self.Items` は使用不可（グローバル変数経由で参照する）
- モダンToggle（Toggle@1.1.5）: `.Checked`（true/false）。クラシックToggleの `.Value` とは異なるので注意。バージョンも 0.0.x 系ではなく 1.1.x 系

## SharePointドキュメントライブラリの列名

SharePointドキュメントライブラリをPower Appsのデータソースとして接続した場合、システム列の名前は**日本語の表示名**になる。REST APIの英語内部名（`{Name}`, `{Link}`）は使えない。

| 用途 | Power Apps上の列名 | 備考 |
|---|---|---|
| ファイル名 | `拡張子付きのファイル名` | シングルクォート不要 |
| ファイルURL | `'完全パス '` | 末尾にスペースあり、シングルクォート必須 |
| リクエストID | `リクエストID` | カスタム列（create-doclib.ps1で作成） |

**列名の調べ方**: 一時ギャラリーを追加 → Items にデータソースを設定 → テンプレート内で `ThisItem.` と入力 → オートコンプリートで候補確認。`添付ファイル.` では候補が出ない場合がある。`JSON()` はメディア列を含むレコードに使用不可。

**注意**: 列名は環境（言語設定）によって異なる可能性がある。新しい環境にデプロイする際は上記の方法で列名を再確認すること。
