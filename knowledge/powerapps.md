# Power Apps 実践知見

タスク着手前に必ず一読すること。公式ドキュメントだけでは分からない、実装で発見したハマりどころを記録。

## YAML記法ルール（Code Viewコピペ用）
- フォーマット: `- ControlName:` から始まる配列形式
- コントロール指定: `Control: Button@0.0.44` 形式
- プロパティ値: すべて `=` で始まるPower Fx式
- `#` や `:` を含む式: マルチライン（`|`）必須
- App ObjectはCode View不可（プロパティパネルで設定）
- **App.OnStartでNavigate()は使用不可**: `Navigate は OnStart では許可されていません。代わりに StartScreen を使用してください` エラーになる。画面遷移は `App.StartScreen` プロパティに数式を設定して制御する。OnStartでは変数Setのみ行い、StartScreenでParam()等の変数値に基づいて遷移先画面を返すパターンが正解
- **StartScreen経由の画面ではOnStartの完了前にOnVisibleが発火する**: `App.StartScreen` でデフォルト以外の画面に遷移した場合、その画面の `OnVisible` が `App.OnStart` の完了より先に実行される。OnStartでセットした変数（例: `varViewMode`, `varViewRequestID`, `varEvalRequestID`）がOnVisible実行時点で空のままになり、LookUpが空振りしてデータが表示されない。**対策**: StartScreen経由で遷移する**すべての画面**のOnVisible冒頭で `Param()` から直接変数を補完するフォールバックを入れること。閲覧画面・評価画面など画面ごとに必要な変数は異なるため、各画面で個別に実装する（例: 評価画面なら `If(!IsBlank(Param("RequestID")) && IsBlank(varEvalRequestID), Set(varEvalRequestID, Param("RequestID")); Set(varEvalEvaluatorType, Param("EvalType")))`）
- **Galleryテンプレート内のレイアウト**: `X` プロパティはCode Viewペースト時に無視されるため、テンプレート直下にHorizontal AutoLayoutコンテナ（`GroupContainer@1.4.0`）を配置し、子コントロールを `FillPortions` / `Width` で並べること。X座標の固定値指定よりAutoLayoutコンテナを常に優先する
- **Galleryテンプレート直下コンテナのサイズ**: Gallery（クラシック `Gallery@2.15.0`）はAutoLayoutコンテナではないため、**直接子に `FillPortions` が効かない**。`FillPortions: =1` と書くと Code View で `Width: =1`（1ピクセル）に変換され、コンテナ内の全コントロールが見えなくなる（データはあるのに表示されない現象の原因になる）。Gallery直下コンテナには**必ず以下のように明示指定**すること:
  ```yaml
  Width: =Parent.TemplateWidth
  Height: =Parent.TemplateHeight
  ```
  ※ AutoLayoutコンテナの子（Gallery直下ではない）には `FillPortions` が正常に機能する
- モダンButton（Button@0.0.45）には `Size` プロパティがない（フォントサイズ指定不可）。ただし `FontSize` プロパティでフォントサイズ指定は可能
- モダンText（Text@0.0.51）には `VerticalAlign` プロパティがない。`TextCanvas.VerticalAlign` は認識されずエラーになる。縦方向の中央揃えは親AutoLayoutコンテナの `LayoutAlignItems: =LayoutAlignItems.Center` で制御する
- **SP画像の認証問題回避パターン**: SharePointドキュメントライブラリの画像URLをImageコントロールに設定しても、ブラウザがSPサイトとの認証セッションを確立していない場合は表示されない。`Download()` はインライン表示に使えない（別タブで開いてしまう）。SPレコード直接参照は変数型不一致エラーの原因になる。**回避策**: `Launch(url)` で別タブに画像を開き認証確立 → Timerで遅延後にURLにキャッシュバスター（`?t=Text(Now())`）を付けて変数を再Setし、Imageコントロールに再読み込みさせる
- モダンTextInput（TextInput@0.0.54）には `Format` プロパティがない（数値フォーマット指定不可）。数値入力が必要な場合は `Value()` 関数で変換
- モダンTextInput（TextInput@0.0.54）の複数行モードは `Mode: =TextMode.MultiLine`。`TextInputMode.MultiLine` という列挙体は存在せず「'TextInputMode' は認識されません」エラーになる
- モダンTextInput（TextInput@0.0.54）には `Default` プロパティがない。ただし **`Value` プロパティはCode View YAMLで設定可能**（例: `Value: =varMyDefault`）。プロパティパネルで設定すると Code View ペースト時にリセットされるため、YAMLに `Value` を直接記述すること
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
- モダンDropDown（DropDown@0.0.45）: `.Selected` + DropDownDataField子コントロール。**Items内のSort()が無視される場合がある**: `Items: =Sort(Filter(テーブル, 条件), SortOrder, SortOrder.Ascending)` と書いても表示順がSort通りにならないことがある。**対策**: `App.OnStart` で `ClearCollect(colSorted, Sort(Filter(...), SortOrder, SortOrder.Ascending))` のようにソート済みコレクションを事前に作成し、DropDownの `Items` にはそのコレクションを直接指定する（`Items: =colSorted`）
- モダンDatePicker（DatePicker@0.0.46）: `.SelectedDate`
- モダンButton（Button@0.0.45）: `.OnSelect`, `.DisplayMode`
- モダンRadio（Radio@0.0.25）: デフォルト値は `DefaultSelectedItems` プロパティで配列形式で指定。`Layout` は `='RadioGroupCanvas.Layout'.Horizontal`（`=Layout.Horizontal` はCode Viewで無視される）。`DefaultSelectedItems` 内で `Self.Items` は使用不可（グローバル変数経由で参照する）
- モダンToggle（Toggle@1.1.5）: `.Checked`（true/false）。クラシックToggleの `.Value` とは異なるので注意。バージョンも 0.0.x 系ではなく 1.1.x 系
- モダンText（Text@0.0.51）: テキスト色のプロパティは **`FontColor`**。クラシックの `Color` を使うと PA2108 エラー（`Unknown property 'Color' for control type 'Text@0.0.51'`）になる。

## SharePointドキュメントライブラリの列名

SharePointドキュメントライブラリをPower Appsのデータソースとして接続した場合、システム列の名前は**日本語の表示名**になる。REST APIの英語内部名（`{Name}`, `{Link}`）は使えない。

| 用途 | Power Apps上の列名 | 備考 |
|---|---|---|
| ファイル名 | `拡張子付きのファイル名` | シングルクォート不要 |
| ファイルURL | `'完全パス '` | 末尾にスペースあり、シングルクォート必須 |
| リクエストID | `リクエストID` | カスタム列（create-doclib.ps1で作成） |
| ファイル種別 | `ファイル種別` | 選択肢型 → `.Value` でテキスト取得 |

**列名の調べ方**: 一時ギャラリーを追加 → Items にデータソースを設定 → テンプレート内で `ThisItem.` と入力 → オートコンプリートで候補確認。`添付ファイル.` では候補が出ない場合がある。`JSON()` はメディア列を含むレコードに使用不可。

**注意**: 列名は環境（言語設定）によって異なる可能性がある。新しい環境にデプロイする際は上記の方法で列名を再確認すること。

## 横並びAutoLayoutコンテナでAutoHeightテキストの高さ揃え

横並び（Horizontal）AutoLayoutコンテナ内に縦並び（Vertical）子コンテナを配置し、その中にAutoHeightテキストを入れた場合、**親コンテナのHeightを省略しても子の高い方に自動で合わない**（短い方の高さで切られる）。

**対策**: 親コンテナのHeightに `=Max(lblA.Height, lblB.Height) + オフセット` を明示的に指定する。AutoHeight=trueのテキストコントロールの `.Height` は計算済みの高さを返すので、Max()で参照可能。

```yaml
# 例: 改善前/改善後テキストの高さ揃え
Height: =Max(lblViewProblem.Height, lblViewImprovement.Height) + 38
# +38 = タイトル(30) + LayoutGap(8)
```

## プレビューラベル値パーツ（読み取り専用の項目名＋値パーツ）

編集不可の「項目名　値」形式の情報表示行に使う標準パーツ。値の下にアンダーラインが付く。
閲覧画面・評価画面など、入力項目ではなく読み取り専用の情報表示に使用。

**ユーザー指示例**:
- 「プレビューラベル値パーツで申請者行を作って」→ このパターンで行を作成
- 「ラベル幅120、Gap=10で」→ ラベルのWidth・外側コンテナのLayoutGapを調整

### 構造図

```
cntXxx (横・H=36, DropShadow.None)
  ├── lblXxxLabel         … 項目名（固定幅, AlignInContainer.Center）
  └── cntXxxValue (縦・AlignInContainer.End, H=32)
        ├── lblXxx        … 値テキスト（Width=Parent.Width, Align=Start）
        └── rectXxxLine   … 下線（1px, Width=Parent.Width）
```

### テンプレート（コピペ用）

```yaml
# ====== プレビューラベル値パーツ: Xxx ======
# 使い方: Xxx を任意のプレフィックスに一括置換
# LabelWidth / LayoutGap / LabelText / ValueText を調整
- cntXxx:
    Control: GroupContainer@1.5.0
    Variant: AutoLayout
    Properties:
      DropShadow: =DropShadow.None
      FillPortions: =0
      Height: =36
      LayoutDirection: =LayoutDirection.Horizontal
      LayoutGap: =8
    Children:
      - lblXxxLabel:
          Control: Text@0.0.51
          Properties:
            AlignInContainer: =AlignInContainer.Center
            Height: =30
            Size: =13
            Text: ="項目名"
            Width: =90
      - cntXxxValue:
          Control: GroupContainer@1.5.0
          Variant: AutoLayout
          Properties:
            AlignInContainer: =AlignInContainer.End
            DropShadow: =DropShadow.None
            Height: =32
            LayoutDirection: =LayoutDirection.Vertical
            LayoutMinHeight: =32
          Children:
            - lblXxx:
                Control: Text@0.0.51
                Properties:
                  Align: ='TextCanvas.Align'.Start
                  Height: =30
                  Size: =13
                  Text: =varXxxValue
                  Width: =Parent.Width
            - rectXxxLine:
                Control: Rectangle@2.3.0
                Properties:
                  Fill: =RGBA(210, 210, 210, 1)
                  Height: =1
                  Width: =Parent.Width
```

### カスタマイズポイント

| 項目 | プロパティ | 説明 |
|---|---|---|
| ラベル幅 | `lblXxxLabel.Width` | InfoLeft=90, InfoRight=100, 承認者=120 |
| 列間ギャップ | `cntXxx.LayoutGap` | Info行=8, 承認者行=10 |
| 値コンテナ幅 | `cntXxxValue.Width` | 省略=自動伸縮, 固定値=承認者行(400) |
| ラベル太字 | `lblXxxLabel.Weight` | `='TextCanvas.Weight'.Bold`（テーマ行等） |

### 設計ポイント
- **AlignInContainer.Center**: ラベルを横コンテナ内で垂直中央揃え
- **AlignInContainer.End**: 値コンテナを横コンテナ内で下揃え → 下線がコンテナ底辺に来る
- **LayoutMinHeight=32**: 値コンテナの最小高さ保証（H=32と同値）
- **Width=Parent.Width**: 値テキスト・下線が値コンテナ幅いっぱいに伸びる
- **Rectangleを直接配置**: 値コンテナ（Vertical AutoLayout）の直接子として配置可能。Gallery行のようなGroupContainerラッパーは不要

### 適用実績
- InfoLeft 4行: ApplicantName, AwardCategory, Theme, CompletionDate（ラベル幅90, Gap=8）
- InfoRight 5行: RequestID, ApplicantGID, Dept, Division, BuSectionUnit（ラベル幅100, Gap=8）
- 承認者 2行: Manager, Director（ラベル幅120, Gap=10, 値幅400固定）

---

## アンダーラインパーツ（Gallery行の標準パーツ）

コンテナをシャドウなし＋アンダーライン付きにする汎用パーツ。Gallery行に限らず、任意のコンテナに適用可能。
使い方: `Xxx` をプレフィックス（例: `ViewCat`, `ViewMem`, `EvalCat`）に置換してコピペ。

**ユーザー指示例**:
- 「`cntXxxRow` にアンダーラインパーツを適用して」→ 既存コンテナをこのパターンに変換
- 「アンダーラインパーツ、PaddingLeft=40で」→ 下線の左余白を指定
- 「アンダーラインパーツ、下線なしでシャドウだけ消して」→ `cntXxxUnderline` なし版

### 構造図

```
cntXxxRow (縦・Gallery直下)
  ├── cntXxxRowInner (横・コンテンツ行)
  │     ├── lblXxxNum       … 番号列（固定幅）
  │     ├── lblXxxName      … 名前列（FillPortions）
  │     └── lblXxxValue     … 値列（固定幅）
  └── cntXxxUnderline (横・下線コンテナ)
        └── rectXxxLine     … 下線（1px）
```

### テンプレート（コピペ用）

```yaml
# ====== Gallery行パーツ: Xxx ======
# 使い方: Xxx を任意のプレフィックスに一括置換
- cntXxxRow:
    Control: GroupContainer@1.5.0
    Variant: AutoLayout
    Properties:
      DropShadow: =DropShadow.None
      Height: =Parent.TemplateHeight
      LayoutDirection: =LayoutDirection.Vertical
      Width: =Parent.TemplateWidth
    Children:
      - cntXxxRowInner:
          Control: GroupContainer@1.5.0
          Variant: AutoLayout
          Properties:
            DropShadow: =DropShadow.None
            LayoutAlignItems: =LayoutAlignItems.Center
            LayoutDirection: =LayoutDirection.Horizontal
            LayoutGap: =6
            PaddingLeft: =4
            PaddingRight: =20
          Children:
            # ここにコンテンツ列を追加
            - lblXxxNum:
                Control: Text@0.0.51
                Properties:
                  Height: =30
                  Size: =11
                  Text: =Text(ThisItem.SortOrder)
                  Width: =20
            - lblXxxName:
                Control: Text@0.0.51
                Properties:
                  FillPortions: =1
                  Height: =30
                  Size: =11
                  Text: =ThisItem.Name
      - cntXxxUnderline:
          Control: GroupContainer@1.5.0
          Variant: AutoLayout
          Properties:
            DropShadow: =DropShadow.None
            FillPortions: =0
            Height: =1
            LayoutDirection: =LayoutDirection.Horizontal
            PaddingLeft: =30
            Width: =Parent.Width
          Children:
            - rectXxxLine:
                Control: Rectangle@2.3.0
                Properties:
                  Fill: =RGBA(210, 210, 210, 1)
                  Height: =1
                  Width: =Parent.Width
```

### カスタマイズポイント

| 項目 | プロパティ | 説明 |
|---|---|---|
| 下線の左余白 | `cntXxxUnderline.PaddingLeft` | 番号列幅(20)+PaddingLeft(4)+Gap(6)=30。レイアウトに応じて調整 |
| 下線の色 | `rectXxxLine.Fill` | デフォルト `RGBA(210, 210, 210, 1)` |
| 行の縦揃え | `cntXxxRowInner.LayoutAlignItems` | `.Center`（中央）or `.End`（下揃え） |
| 下線なし | `cntXxxUnderline` を削除 | シャドウなしのみにする場合 |

### 注意事項
- **Rectangleは必ずコンテナで包むこと**: Rectangle（クラシックコントロール）はAutoLayout内で`FillPortions`が効かない。直接子にすると高さが正しく割り当てられず表示されない。必ず`GroupContainer`（`cntXxxUnderline`）で包み、コンテナ側で`FillPortions: =0` + `Height: =1`を設定する
- **Inner に明示的 Height を設定**: `cntXxxRowInner` に `FillPortions: =0` + `Height: =34`（または適切な値）を設定。FillPortions デフォルトに任せると高さが不定になる場合がある
- Gallery内で使う場合、直下コンテナは `Width: =Parent.TemplateWidth` / `Height: =Parent.TemplateHeight` 必須
- Gallery外で使う場合、`Width` / `Height` は親に合わせて適宜設定
- コンテナすべてに `DropShadow: =DropShadow.None` を設定すること

### 適用実績
- `galViewCategories` → `ViewCat`（screen-view.yaml）PaddingLeft=30
- `galViewAttachments` → `ViewAttach`（screen-view.yaml）PaddingLeft=30
- `galViewMembers` → `ViewMember`（screen-view.yaml）PaddingLeft=40

## コントロールバージョンの統一ルール

同一コントロール型（例: `DropDownDataField`）は、**1つのYAMLファイル内で同じバージョンを使用する必要がある**。異なるバージョンが混在すると `PA2107: Another instance of control type has already been referenced using a different version` エラーになる。新しいコントロールを追加する際は、同ファイル内の既存インスタンスのバージョンを確認すること。

## 差戻再提出（編集モード）でデータが表示されない問題パターン

### 1. 申請者情報（gCurrentEmployee等）が空になる
**原因**: `App.OnStart` のテストモード分岐で `gCurrentGID` が空のまま → `gCurrentEmployee` もセットされない。差戻リンクから直接画面を開くと、GIDを手動入力するステップがスキップされるため。
**対策**: 編集モードの `OnVisible` で、既存レコードの `ApplicantGID` から社員マスタを逆引きし、`gCurrentEmployee` と全 `gCurrent*` 変数を復元する。

```
// 申請者情報を社員マスタから復元
Set(gCurrentEmployee, LookUp(社員マスタ, GID = req.ApplicantGID));
Set(gCurrentGID, gCurrentEmployee.GID);
Set(gCurrentName, gCurrentEmployee.EmployeeName);
// ... 以下同様
```

### 2. Code Viewペーストでプロパティパネル設定値がリセットされる
**原因**: Code Viewにyamlをペーストすると、YAML内に記述されていないプロパティはデフォルト値にリセットされる。プロパティパネルで設定した `Value`（TextInput）、`SelectedDate`（DatePicker）等が消えてフォームが白紙に戻る。
**対策**: プロパティパネルで設定できる値でも、**必ずYAMLに直接記述**すること。Code Viewペースト後も値が維持される。

### 3. 既存添付ファイルが表示されない
**原因**: 差戻時、添付ファイルはSharePointドキュメントライブラリに保存済みだが、`colAttachments` が空のまま。
**対策**: `OnVisible` でドキュメントライブラリから `ClearCollect` で読み込む。`ContentBase64: ""` をマーカーとして設定し、提出時にアップロード対象から除外する（`Filter(colAttachments, !IsBlank(ContentBase64))`）。

### 4. 差戻再提出→プレビューで画像が表示されない
**原因**: 既存ファイルは `ContentBase64: ""` で読み込まれるが、プレビューモードのViewScreenは `ContentBase64` のみを参照して画像URLを設定していた。既存ファイル（SP保存済み）と新規ファイル（メモリ上base64）が混在する状態に未対応。
**対策**: btnPreviewで既存ファイル（ContentBase64が空）にはSPのFileLinkを構築して渡し、ViewScreenのPreviewモードで `ContentBase64` が空なら `FileLink` にフォールバックする。

```
// btnPreview: ForAll As でスコープ衝突を回避しつつFileLink構築
ForAll(colAttachments As att, {
    FileLink: If(!IsBlank(varEditRequestID) && IsBlank(att.ContentBase64),
        gSharePointSiteUrl & "/" & LookUp(Filter(添付ファイル, ...), 拡張子付きのファイル名 = att.Name).'完全パス ',
        "")
})

// ViewScreen: ContentBase64 → FileLink フォールバック
With({beforeAtt: LookUp(colViewAttachments, FileCategory = "改善前")},
    Set(varViewBeforeImageLink, If(!IsBlank(beforeAtt.ContentBase64), beforeAtt.ContentBase64, beforeAtt.FileLink))
)
```

## ForAll内LookUpのThisRecordスコープ衝突

`ForAll(コレクション, { ... LookUp(SPリスト, 条件 = ThisRecord.Field) })` のように、ForAll内のLookUpで `ThisRecord` を参照すると、`ThisRecord` がLookUpのスコープ（SPリストのレコード）を指してしまい「'Field' は認識されません」エラーになる。**対策**: `ForAll(コレクション As alias, { ... LookUp(SPリスト, 条件 = alias.Field) })` で `As` エイリアスを使う。

## EditForm（Form@2.4.4）のYAML記法

`Form@2.4.4` コントロールを YAML で定義する際、`Layout` は **`Control:` と同じ階層に置く構造キー**（`Properties:` の中に書くと PA1011 エラー）。

```yaml
# ✅ 正しい
- editFormAttachment:
    Control: Form@2.4.4
    Layout: Vertical        ← Control: と同じ階層、= 不要
    Properties:
      DataSource: =添付ファイルステージング
      ...

# ❌ 誤り（PA1011: The keyword 'Layout' is required but is missing or empty）
- editFormAttachment:
    Control: Form@2.4.4
    Properties:
      Layout: =FormLayout.Vertical   ← Properties内はNG
```

バージョンは `Form@2.4.4` を使うこと（`Form@2.4.2` は古く警告が出る）。

## EditForm の `.Attachments` は Power Apps 静的チェックで解決不可

EditForm が SharePoint リストに接続されている場合、`LookUp(リスト, ID = x).Attachments` はランタイムでは動作するが、**Power Apps の静的数式チェックでは `'Attachments' は認識されません` エラーになる**。`ForAll(LookUp(...).Attachments, ...)` も同様。

**対策**: 添付済みかどうかの管理はコレクションで代替する。
```
// OnSuccess で カテゴリ別に「添付済み」フラグをコレクション管理
RemoveIf(colStagingDisplay, Category = ddCategory.Selected.Value);
Collect(colStagingDisplay, {FileName: "（添付済み）", Category: ddCategory.Selected.Value});
```

## ForAllで同じデータソースをRead+Write/Removeする制限

`ForAll(Filter(SPリスト, ...), Remove(SPリスト, ...))` のようにForAllの反復対象と操作対象が同じSPデータソースだと「この関数は、ForAll で使用されている同じデータ ソース上で操作する」エラーになる。**対策**: `ClearCollect(_temp, Filter(SPリスト, ...))` でローカルコレクションに退避してから `ForAll(_temp As rec, Remove(SPリスト, rec))` で操作する。Patch（新規登録）も同様。
