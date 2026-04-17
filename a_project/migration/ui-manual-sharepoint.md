# SharePoint 手動構築ガイド（PnP不可時の代替手順）

PnP PowerShellが使用できない環境向けの代替手順書。  
`deployment-guide.md` の Step 2〜5・9 の PnP スクリプト部分をSharePoint UIで代替する。

---

## 対象ステップ一覧

| Step | PnPスクリプト | 処理内容 | この手順書での代替方法 |
|---|---|---|---|
| Step 2 | `create-lists.ps1` | 全10リスト + 列定義 + インデックス + Title列非表示を一括作成 | SharePoint UI で手動作成 |
| Step 3 | `import-employees.ps1` / `import-masters.ps1` | 社員マスタ（〜15,000件）・改善分野マスタ（14件）・表彰区分マスタ（4件）を CSV / ハードコードデータから投入 | Excel テンプレート + Quick Edit 貼り付け / 手入力 |
| Step 4 | `create-doclib.ps1` | 添付ファイル用ドキュメントライブラリを作成 | SharePoint UI で手動作成 |
| Step 5 | `set-permissions.ps1` | マスタリストを読み取り専用化・トランザクションリストを自分のアイテムのみ編集可・指定リストをナビゲーションから非表示 | SharePoint リスト設定 UI |
| Step 9 | `set-column-formatting.ps1` | RequestID 列に Power Apps 遷移リンクの Column Formatting を適用 | リスト設定 UI から JSON 貼り付け |

---

## Step 2: SharePoint リスト手動作成 `[UI]`

### 前提

列の定義は `docs/spec/lists.md` を参照すること。  
本手順書では UI 操作の共通手順のみ記載する。

### 作成するリスト（10リスト）

| # | リスト名 | 用途 |
|---|---|---|
| 1 | 社員マスタ | 社員情報 |
| 2 | 改善分野マスタ | 改善分野14件 |
| 3 | 表彰区分マスタ | 表彰区分4件 |
| 4 | 改善提案メイン | 申請データ（トランザクション） |
| 5 | 改善メンバー | 申請メンバー |
| 6 | 改善分野実績 | 分野ごとの実績値 |
| 7 | 評価データ | 課長/部長の評価結果 |
| 8 | 承認履歴 | 承認フロー履歴 |
| 9 | 添付ファイルステージング | ファイル一時保管 |
| 10 | 回覧メンバー | 回覧者情報 |

### 共通操作手順

**リスト作成**
1. SharePoint サイトを開く → 左メニュー「サイトコンテンツ」
2. 「新規」→「リスト」→「空白のリスト」
3. リスト名を入力して「作成」

**列の追加（各リストの列定義は `docs/spec/lists.md` を参照）**
1. リストを開く → 右端の「+ 列の追加」をクリック
2. 型を選択（テキスト / 数値 / 日付 / ユーザー / 選択肢 など）
3. 列名（内部名）を設定する

> **注意**: 列の「内部名」（英語）はPower AppsおよびPower Automateが参照する。  
> 日本語の表示名を設定した場合、内部名が自動変換されてしまうため、**必ず英語で列を作成してから必要に応じて表示名を変更すること**。

---

## Step 2b（代替）: Power Automate REST API でリスト自動作成 `[Power Automate]`

UIのポチポチ操作なしに、Power Automate のHTTPリクエストアクションで REST API を呼び出して  
全リスト・列・インデックスを一括作成する。

### 使用JSONファイル（`a_project/migration/rest-api/`）

| ファイル | 内容 | 列数 |
|---|---|---|
| `01_create-lists.json` | 10リスト + 添付ファイルライブラリ作成 | — |
| `02_columns-社員マスタ.json` | 社員マスタ 列定義 | 22列 |
| `03_columns-改善提案メイン.json` | 改善提案メイン 列定義 | 23列 |
| `04_columns-改善メンバー.json` | 改善メンバー 列定義 | 6列 |
| `05_columns-改善分野実績.json` | 改善分野実績 列定義 | 10列 |
| `06_columns-評価データ.json` | 評価データ 列定義 | 17列 |
| `07_columns-承認履歴.json` | 承認履歴 列定義 | 7列 |
| `08_columns-改善分野マスタ.json` | 改善分野マスタ 列定義 | 6列 |
| `09_columns-表彰区分マスタ.json` | 表彰区分マスタ 列定義 | 6列 |
| `10_columns-添付ファイルステージング.json` | 添付ファイルステージング 列定義 | 1列 |
| `11_columns-回覧メンバー.json` | 回覧メンバー 列定義 | 7列 |
| `12_columns-添付ファイルDocLib.json` | 添付ファイルライブラリ 列定義 | 3列 |
| `13_indexes.json` | インデックス設定（15件） | — |

### フロー構成

1フロー3フェーズで構成する。各フェーズを **Compose アクション + Apply to each** の組で実装する。

```
Phase 1: リスト・ライブラリ作成    … 01_create-lists.json
Phase 2: 各リストの列追加         … 02〜12_columns-*.json（12セット）
Phase 3: インデックス設定          … 13_indexes.json
```

### 手順

#### 事前準備

1. `a_project/migration/rest-api/` フォルダのJSONファイルをテキストエディタで開けるようにしておく

#### フロー作成

1. Power Automate を開く → **「作成」→「インスタントクラウドフロー」**
2. フロー名: `kaizenn-create-lists`、トリガー: **「手動でフローをトリガーします」** → 作成

---

#### Phase 1 — リスト・ライブラリ作成

**① Compose アクション追加**

| 項目 | 設定値 |
|---|---|
| アクション名 | `Compose - list definitions` |
| 入力 | `01_create-lists.json` の内容をまるごと貼り付け |

**② Apply to each アクション追加**

| 項目 | 設定値 |
|---|---|
| 以前の手順から出力を選択 | `outputs('Compose_-_list_definitions')` |

**② 内部に「SharePoint - HTTP 要求を送信します」アクション追加**

| 項目 | 設定値 |
|---|---|
| サイトのアドレス | 対象SharePointサイトを選択 |
| メソッド | `POST` |
| URI | `_api/web/lists` |
| ヘッダー | `{"content-type": "application/json;odata=verbose", "Accept": "application/json;odata=verbose"}` |
| ボディ | 下記参照 |

ボディ（式として入力）:
```
{
  "__metadata": {"type": "SP.List"},
  "AllowContentTypes": true,
  "BaseTemplate": @{items('Apply_to_each')?['BaseTemplate']},
  "ContentTypesEnabled": false,
  "Title": "@{items('Apply_to_each')?['Title']}"
}
```

> **注意**: `BaseTemplate` の値は数値のため `"` で囲まない。`Title` は文字列のため `"` で囲む。

---

#### Phase 2 — 列追加（リストごとに繰り返し、計12セット）

以下をリストごとに 12 セット作成する。各セットのリスト名と対応JSONを変えるだけで構造は同じ。

**① Compose アクション追加**

| 項目 | 設定値（社員マスタの例） |
|---|---|
| アクション名 | `Compose - 社員マスタ columns` |
| 入力 | `02_columns-社員マスタ.json` の内容をまるごと貼り付け |

**② Apply to each アクション追加**

| 項目 | 設定値 |
|---|---|
| 以前の手順から出力を選択 | `outputs('Compose_-_社員マスタ_columns')` |

**② 内部に「SharePoint - HTTP 要求を送信します」アクション追加**

| 項目 | 設定値（社員マスタの例） |
|---|---|
| メソッド | `POST` |
| URI | `_api/web/lists/GetByTitle('社員マスタ')/fields` |
| ヘッダー | `{"content-type": "application/json;odata=verbose", "Accept": "application/json;odata=verbose"}` |
| ボディ | `@{items('Apply_to_each')}` |

> **ボディの設定方法**: ボディフィールドをクリック → 「式」タブ → `items('Apply_to_each')` と入力 → OK。  
> ループ変数名が重複しないよう、各Apply to eachには一意の名前を付けること（例: `Apply_to_each_社員マスタ`）。

**12リスト分のURI一覧:**

| Compose名 | URI |
|---|---|
| 社員マスタ columns | `_api/web/lists/GetByTitle('社員マスタ')/fields` |
| 改善提案メイン columns | `_api/web/lists/GetByTitle('改善提案メイン')/fields` |
| 改善メンバー columns | `_api/web/lists/GetByTitle('改善メンバー')/fields` |
| 改善分野実績 columns | `_api/web/lists/GetByTitle('改善分野実績')/fields` |
| 評価データ columns | `_api/web/lists/GetByTitle('評価データ')/fields` |
| 承認履歴 columns | `_api/web/lists/GetByTitle('承認履歴')/fields` |
| 改善分野マスタ columns | `_api/web/lists/GetByTitle('改善分野マスタ')/fields` |
| 表彰区分マスタ columns | `_api/web/lists/GetByTitle('表彰区分マスタ')/fields` |
| 添付ファイルステージング columns | `_api/web/lists/GetByTitle('添付ファイルステージング')/fields` |
| 回覧メンバー columns | `_api/web/lists/GetByTitle('回覧メンバー')/fields` |
| 添付ファイルDocLib columns | `_api/web/lists/GetByTitle('添付ファイル')/fields` |

---

#### Phase 3 — インデックス設定

**① Compose アクション追加**

| 項目 | 設定値 |
|---|---|
| アクション名 | `Compose - indexes` |
| 入力 | `13_indexes.json` の内容をまるごと貼り付け |

**② Apply to each アクション追加**

| 項目 | 設定値 |
|---|---|
| 以前の手順から出力を選択 | `outputs('Compose_-_indexes')` |

**③ 内部に「SharePoint - HTTP 要求を送信します」アクション追加**

| 項目 | 設定値 |
|---|---|
| メソッド | `POST` |
| URI | 下記参照（式として入力） |
| ヘッダー | `{"content-type": "application/json;odata=verbose", "Accept": "application/json;odata=verbose", "X-HTTP-Method": "MERGE", "If-Match": "*"}` |
| ボディ | `{"__metadata": {"type": "SP.Field"}, "Indexed": true}` |

URIフィールドに入力する式:
```
_api/web/lists/GetByTitle('@{items('Apply_to_each_indexes')?['list']}')/fields/GetByInternalNameOrTitle('@{items('Apply_to_each_indexes')?['field']}')
```

> **注意**: メソッドは `POST` だが、ヘッダーに `X-HTTP-Method: MERGE` を設定することでPATCH操作として実行される（SharePoint REST API の慣習）。

---

#### フロー実行

1. フローを保存
2. 「テスト」→「手動」→「テストの実行」
3. 各アクションが緑チェックになることを確認
4. SharePoint サイトの「サイトコンテンツ」で全リストが作成されていることを確認

#### 実行後の追加作業（UIで実施）

以下はREST APIで自動化が困難なため、UIで手動設定する:

| 項目 | 対象 | 手順 |
|---|---|---|
| 添付ファイル有効化 | 添付ファイルステージング | リスト設定 → 詳細設定 → 添付ファイル → **有効** |
| Title列を非表示 | 全トランザクションリスト | リスト設定 → 列 → Title → **非表示**（任意） |

---

## Step 3: マスタデータ手動投入 `[UI / Excel テンプレート]`

### 3-1. 社員マスタ（約15,000件）— Excel テンプレート使用

#### 使用ファイル

`scripts/develop/employee-sharepoint-import-template.xlsx`（事前に自分の PC で生成済み）

#### 変換手順（クライアント PC で実施）

1. **テンプレートファイルを開く**  
   USB 等でクライアント PC に転送し Excel で開く

2. **人事 Excel の「データ3」シートをコピー**  
   - 人事部門から受領した Excel（`データ3_yyyy.mm.dd.xlsx`）を開く
   - 「データ3」シートタブを右クリック → **「移動またはコピー」**
   - 移動先ブック: `employee-sharepoint-import-template.xlsx` を選択
   - **☑ コピーを作成する** にチェック → **OK**
   - テンプレート内の既存プレースホルダー「データ3」シートを削除

3. **「変換出力」シートを確認**  
   自動的に22列に変換・計算される

4. **値として貼り付け用シートを作成**  
   - 「変換出力」シートで **Ctrl+A → Ctrl+C**
   - 新規シートを追加 → **形式を選択して貼り付け** → **値のみ**

5. **不要行の削除**  
   - GID 列が空白の行をフィルタリング → 削除
   - 1行目ヘッダー行を削除（Quick Edit 貼り付け時は不要）

#### SharePoint への取り込み

6. **SharePoint「社員マスタ」リストを開く**

7. **グリッドビューで編集モードに切り替え**  
   右上「編集」→「**グリッドビューで編集**」

8. **1行目の空セルをクリックしてフォーカスを当てる**

9. **Excel データを貼り付け（Ctrl+V）**  
   > **⚠ 注意**: 一度に貼り付けられる行数に上限がある場合がある。  
   > **1,000行ずつ分割して貼り付け**ることを推奨。15,000件の場合は約15回に分けて実施する。

10. **「✓ 保存」をクリック**して確定

> **列の対応関係**  
> Excel の列順（GID / EmployeeName / Email / Office ... IsActive）が  
> SharePoint リストの列定義と一致している必要がある。  
> 列順が異なる場合は `docs/spec/lists.md` の「社員マスタ」列定義を参照して調整すること。

---

### 3-2. 改善分野マスタ（14件）— 手動入力

グリッドビューで編集 → 以下のデータを直接入力する。

| CategoryCode | CategoryName | Unit | SortOrder | ConversionRate | CategoryType |
|---|---|---|---|---|---|
| CAT-01 | 活人 | 人/月 | 1 | 760232 | 金額算出 |
| CAT-02 | 活工数 | h/月 | 2 | 4664 | 金額算出 |
| CAT-03 | 活スペース（ライン） | ㎡/月 | 3 | 6500 | 金額算出 |
| CAT-04 | 活スペース（事務所） | ㎡/月 | 4 | 1200 | 金額算出 |
| CAT-05 | 動線短縮 | m/月 | 5 | 1 | 金額算出 |
| CAT-06 | リードタイム短縮 | 分/月 | 6 | 0 | 金額算出 |
| CAT-07 | 労働生産性 | 円/月 | 7 | 0 | 直接入力 |
| CAT-08 | 設備生産性 | 円/月 | 8 | 0 | 直接入力 |
| CAT-09 | 経費削減 | 円/月 | 9 | 0 | 直接入力 |
| CAT-10 | 在庫削減 | 円/月 | 10 | 0 | 直接入力 |
| CAT-11 | その他 | 円/月 | 11 | 0 | 直接入力 |
| CAT-12 | 6S・ヒューマンエラー | （空白） | 12 | 0 | テキスト |
| CAT-13 | 環境 | （空白） | 13 | 0 | テキスト |
| CAT-14 | その他効果 | （空白） | 14 | 0 | テキスト |

---

### 3-3. 表彰区分マスタ（4件）— 手動入力

グリッドビューで編集 → 以下のデータを直接入力する。

| AwardCode | AwardName | RewardAmount | RequiresScoring | SortOrder | IsActive |
|---|---|---|---|---|---|
| KZ | 改善提案 | 0 | Yes | 1 | Yes |
| PL | 小集団 パール賞（3等） | 3000 | No | 2 | Yes |
| CU | 小集団 銅賞（2等） | 5000 | No | 3 | Yes |
| SV | 小集団 銀賞（1等） | 10000 | No | 4 | Yes |

---

## Step 4: ドキュメントライブラリ手動作成 `[UI]`

1. サイトコンテンツ → 「新規」→「ドキュメントライブラリ」
2. 名前: `添付ファイル`
3. 作成

**列の追加（`docs/spec/lists.md` の「添付ファイルライブラリ」を参照）**  
必要な列（FileCategory / リクエストID など）を手動で追加する。

---

## Step 5: 権限設定 `[UI]`

### 5-1. マスタリスト（3リスト）— メンバーグループを「閲覧」に降格

対象: **社員マスタ** / **改善分野マスタ** / **表彰区分マスタ**

各リストで以下を実施：

1. リスト設定（歯車アイコン → リストの設定）
2. 「このリストの権限」→「権限の継承を中止」→ OK
3. メンバーグループを選択 → 「ユーザー権限の編集」
4. 現在の権限（「編集」等）のチェックを外し、「閲覧」にチェック → OK

### 5-2. トランザクションリスト — 自分のアイテムのみ編集可

対象: **改善提案メイン** / **改善メンバー** / **改善分野実績** / **評価データ**

各リストで以下を実施：

1. リスト設定 → 「詳細設定」
2. 「このリストのアイテムの読み取りアクセス権」→「自分が作成したアイテムのみ」
3. 「このリストのアイテムの作成および編集アクセス権」→「自分のアイテムのみ」→ OK

### 5-3. ナビゲーション非表示

対象: **改善メンバー** / **改善分野実績** / **評価データ** / **回覧メンバー** / **添付ファイル**

各リストで以下を実施：

1. リスト設定 → 「リストの詳細設定」（または「全般設定」）
2. 「ナビゲーション」→「このリストをクイック起動に表示しますか？」→ **いいえ** → OK

---

## Step 9: Column Formatting 手動適用 `[UI]`

SharePoint リストの列にリンク書式（Column Formatting JSON）を適用する。

### 適用手順

1. `scripts/set-column-formatting.ps1` をテキストエディタで開く
2. スクリプト内の JSON 文字列部分を抽出する  
   （`$json = @'` ～ `'@` の間）
3. JSON 内の `{AppID}` プレースホルダーを実際の App ID（Step 8 で取得）に置換する
4. SharePoint リストを開く
5. 対象列（RequestID）のヘッダー「▼」をクリック →「列の書式設定」
6. 「詳細モード」→ テキストエリアに JSON を貼り付け → 「保存」

> **対象リスト・列**: `docs/spec/lists.md` の Column Formatting セクションを参照

---

## 参考: 各ファイルとステップの対応

| ファイル | Step | 備考 |
|---|---|---|
| `scripts/develop/employee-sharepoint-import-template.xlsx` | Step 3-1 | 本ガイドで説明 |
| `scripts/csv/test_employees.csv` | Step 3-1 | テスト環境用（本番は変換テンプレート使用） |
| `docs/spec/lists.md` | Step 2・3・4 | 列定義の参照先 |
| `docs/spec/security.md` | Step 5 | 権限設計の詳細仕様 |
