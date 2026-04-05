# 設計方針ガイドライン

このプロジェクトで**意図的に選択した設計方針**を記録する。失敗対策（knowledge/automate.md 等）ではなく、設計の一貫性を保つための方針集。

設計前・実装前に必ず読むこと。新たな設計判断をした際は、ここに追記すること。

---

## Power Automate フロー設計

### 変数は最小限に絞る

変数化するのは「トリガー出力から直接取れない値」で、後続アクションで繰り返し参照するものだけ（RequestID、ReviewOrder 等）。
Get items の結果は `first(body('アクション名')?['value'])?['列名']` で直接参照し、Apply to each + 変数セットは使わない。

```
// ✅ 変数不要: Get items 結果は直接参照
first(body('メインリスト取得')?['value'])?['ApplicantName']

// ✅ 変数が必要な例: トリガーから取れない値
変数: varRequestID ← triggerBody()['text'] (Power Apps V2 トリガー経由)
```

### トリガー条件とフロー内条件を二重チェックする

トリガーの「トリガー条件」設定でフロー起動を事前フィルタリングし、さらにフロー内の条件アクションでも同じ条件を再チェックする（多層防御）。
トリガー条件は誤設定でもフローが起動してしまうため、フロー内での確認が安全網として機能する。

### 分岐は「種別」ではなく「値（金額）」で設計する

表彰区分（パール賞・銅賞等）そのもので分岐させない。褒賞金額（RewardAmount）の数値で分岐させる。
これにより、マスタの表彰区分が変わってもフローを変更する必要がない。

```
// ✅ 金額で判定（マスタ変更に強い）
条件: RewardAmount >= 5000 → 部長承認へ / < 5000 → 承認完了

// ❌ 表彰区分で判定（マスタ変更で即影響）
条件: AwardCategory == "銀賞" → 部長承認へ
```

---

## Power Apps 設計

### 変数のスコープルール（g / var / col）

| プレフィックス | 種別 | 用途 |
|---|---|---|
| `g` | グローバル変数 | OnStart で初期化。ログイン者の属性（GID・氏名・上司情報）、テストモードフラグ等、アプリ全体で長生きするデータ |
| `var` | ローカル変数 | 画面内のUI状態（ポップアップ表示フラグ、確認済みフラグ、一時入力値）に限定 |
| `col` | コレクション | 子リスト（メンバー・分野実績・回覧者）の一時保持。`_temp` プレフィックスで中間データを分離 |

### コントロール命名規則

| プレフィックス | 種別 |
|---|---|
| `btn` | Button |
| `txt` | TextInput |
| `lbl` | Label |
| `dd` | Dropdown |
| `gal` | Gallery |
| `cnt` | Container |
| `dp` | DatePicker |
| `img` | Image |

機能名は PascalCase で続ける（例: `btnSubmit`, `txtTheme`, `galMembers`）。

### LookUp のタイミング：OnVisible / OnStart で一括、入力都度はNG

社員マスタ LookUp は OnVisible（画面遷移時）または OnStart（アプリ起動時）で一括実行し、変数に展開する。
入力フィールドの OnChange 都度 LookUp は行わない（パフォーマンス劣化・競合状態の原因）。
GID 入力 → 確定ボタンのタップ時に LookUp する方式に統一する。

```
// ✅ OnVisible で一括 LookUp
With(
    {req: LookUp(改善提案メイン, RequestID = varTargetRequestID)},
    Set(varApplicantName, req.ApplicantName);
    Set(varApplicantGID, req.ApplicantGID);
    ...
)

// ❌ OnChange 都度 LookUp（避ける）
Set(varMemberName, LookUp(社員マスタ, GID = txtGIDInput.Value).EmployeeName)
```

### Patch は新規/編集を1本のコードで統一する

Patch の第2引数を If で切り替えることで、新規作成と編集を同一コードで処理する。

```
// ✅ 新規/編集統一パターン
Patch(
    改善提案メイン,
    If(!IsBlank(varEditRequestID),
        LookUp(改善提案メイン, RequestID = varEditRequestID),
        Defaults(改善提案メイン)
    ),
    { 列名: 値, ... }
)
```

### 条件判定の Blank チェックは必ず両分岐を明示する

`If(IsBlank(...), ...)` の Else ブランチを省略しない。省略すると未定義状態が生まれ、後続処理でデバッグが困難になる。

```
// ✅ 両分岐を明示
If(
    IsBlank(req.ApproverManager.Email),
    Set(varEval1IsNone, true); Set(varEval1GID, ""); ...,
    With({eval1: LookUp(社員マスタ, GID = req.ManagerGID)},
        Set(varEval1IsNone, false); Set(varEval1GID, eval1.GID); ...)
)

// ❌ Else を省略（避ける）
If(IsBlank(req.ApproverManager.Email), Set(varEval1IsNone, true))
```

### コレクション設計：子リストは1コレクション1種別、中間データは `_temp` 分離

子リスト（メンバー・分野実績・回覧者）は各々独立したコレクションで管理する。
編集モードで SP から読み込んだ既存レコードは `_temp` プレフィックスのコレクションに一時退避してから展開する（同一データソースの Read + Remove 制約を回避）。

```
// ✅ 差戻・再提出モードでのパターン
ClearCollect(_tempEditMembers, Filter(改善メンバー, RequestID = varTargetRequestID));
Clear(colMembers);
ForAll(_tempEditMembers As rec, Collect(colMembers, { MemberGID: rec.MemberGID, ... }))
```

---

## リスト設計

### 承認者は Person 型、メンバー・回覧者はテキスト型 GID で管理する

| 対象 | 列型 | 理由 |
|---|---|---|
| ApproverManager（課長） | ユーザー型（Person） | フロー側で Email を直接取得可能。社員マスタへの追加 LookUp が不要 |
| ApproverDirector（部長） | ユーザー型（Person） | 同上 |
| MemberGID（改善メンバー） | 1行テキスト | ユーザーが検索・選択する対象。異動・退職時も GID は不変 |
| ReviewerGID（回覧者） | 1行テキスト | 同上 |
| ReviewerEmail（回覧者） | 1行テキスト | 申請時点のメールをスナップショット保存（異動で Email が変わっても通知履歴が残る） |

承認権限（フローが自動的に次の評価者を決定する）は Person 型。ユーザーが手動で選択する対象はテキスト型 GID。

### スナップショット保存：申請時点の情報を別列に複製する

後でマスタが更新されても過去の申請内容・金額計算が変わらないよう、申請時点のマスタ値を別列にコピーして保存する。

- `ApplicantOffice`（在籍事業所）、`ApplicantCostUnit`（原価単位）— 社員マスタからスナップショット
- `ConversionRate`（換算単価）— 改善分野マスタからスナップショット
- `ReviewerEmail`（回覧者Email）— 申請時点のメールをテキストで保存

金額・権限に関わる情報は原則スナップショット保存とする。

### ステータス管理は Status 1列で完結させる

複数のフラグ列でフロー制御をせず、`Status` 選択肢型 1列で全ステータスを管理する。
副ステータス列（フラグ列）を増やすと、フローの条件分岐が複雑になり整合性が崩れる。

```
Status の遷移:
下書き → 申請中 → 回覧中（§3 回覧者あり時） → 課長評価中 → 部長評価中 → 承認済
                                                                          └→ 差戻
         └→ 取下げ（申請中以降、承認済・差戻前）
```

---

## 全般

### 環境依存値は Power Apps 変数経由で参照する

SharePoint サイト URL・AppID・リスト名等の環境依存値を YAML にハードコードしない。
`gSharePointSiteUrl` 等のグローバル変数経由で参照し、環境移行時に YAML を書き換えなくてよい状態を維持する。

Power Automate フローの接続先（サイトアドレス・リスト名）は UI 上で選択するため、環境間移行時は再接続で対応する。

### テストモードは gTestMode フラグで制御する

`gTestMode = true` の場合、`User().Email` での自動取得を行わず、UI 上の GID 手入力欄を使用する。
フロー呼び出し時のメールアドレスも `If(gTestMode, gCurrentEmail, User().Email)` で切り替える。
本番移行時は `gTestMode = false` に変更するだけで全ロジックが本番動作に切り替わる。
