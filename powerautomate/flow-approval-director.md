# Power Automate フロー設計書: 部長承認フロー

**タスク**: 3-3
**フロー名**: 改善提案_部長承認
**用途**: 部長が評価・承認/差戻した際のステータス遷移・メール通知・FinalRewardAmount上書き転記

---

## フロー概要

```
[SharePoint - 項目が作成または変更されたとき]
    │  リスト: 評価データ
    │
    ▼
[条件1: 評価者種別="部長" AND 判定≠空?]
    │
    ├── No → 終了（課長評価や未確定データはスキップ）
    │
    ▼ Yes
[SharePoint - 複数の項目の取得]
    │  リスト: 改善提案メイン
    │  Filter: RequestID eq 'トリガーのRequestID'
    │
    ▼
[条件2: 判定="承認"?]
    │
    ├── Yes（承認）
    │   │
    │   ▼
    │   [メインリスト ステータス更新 + FinalRewardAmount上書き転記]
    │   │  ステータス → "承認済"
    │   │  FinalRewardAmount → 部長のRewardAmount（上書き）
    │   │
    │   ▼
    │   [Office 365 - メール送信]
    │      宛先: 申請者（To）+ 部長（CC）
    │      テンプレート: 承認完了メール
    │
    └── No（差戻）
        │
        ▼
        [メインリスト ステータス更新]
        │  ステータス → "差戻"
        │
        ▼
        [Office 365 - メール送信]
           宛先: 申請者
           テンプレート: 差戻通知メール
```

> **3-2（課長承認）との違い**: 課長承認フローでは褒賞金額≥5,000円で部長へエスカレーションする分岐があったが、部長承認フローでは金額による分岐は不要。部長に到達する時点で必ず≥5,000円のため、承認時は常にFinalRewardAmountを上書き転記して承認完了となる。

---

## 構築手順

### Step 1: フロー作成

1. Power Automate → **マイフロー** → **新しいフロー** → **自動化したクラウドフロー**
2. フロー名: `改善提案_部長承認`
3. トリガー: **SharePoint - 項目が作成または変更されたとき** を選択

### Step 2: トリガー設定

| プロパティ | 値 |
|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` |
| リスト名 | `評価データ` |

> **「作成または変更」を使う理由**: 課長承認フローと同様。差戻→再提出→課長再承認→部長再評価のケースでは既存項目が更新される。

### Step 3: 条件1 — 評価者種別=部長 AND 判定≠空

1. **新しいステップ** → **条件**
2. 「AND」条件で2つを設定:

| # | 左辺 | 演算子 | 右辺 |
|---|---|---|---|
| 1 | `triggerOutputs()?['body/EvaluatorType/Value']` | 次の値に等しい | `部長` |
| 2 | `triggerOutputs()?['body/Decision/Value']` | 次の値に等しくない | `null` |

> **補足**: 判定（Decision）が空の場合は評価入力中（未確定）であるため処理しない。`null` チェックには「次の値に等しくない」演算子を使い、右辺に式 `null` を入力する。

**「いいえ」の場合**: 何もしない（終了）

### Step 4: メインリスト取得

「はい」の中に以下を追加:

1. **新しいステップ** → 「SharePoint」→ **複数の項目の取得**
2. 設定:

| プロパティ | 値 |
|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` |
| リスト名 | `改善提案メイン` |
| フィルター クエリ | `RequestID eq '@{triggerOutputs()?['body/RequestID']}'` |
| 上から順に取得 | `1` |

> **名前変更**: このアクションの名前を `メインリスト取得` に変更すること（後続ステップの式で参照するため）。

以降、メインリストの項目は以下の式でアクセスする:
```
first(body('メインリスト取得')?['value'])?['列名']
```

### Step 5: 条件2 — 判定=承認?

1. **新しいステップ** → **条件**
2. 設定:

| 左辺 | 演算子 | 右辺 |
|---|---|---|
| `triggerOutputs()?['body/Decision/Value']` | 次の値に等しい | `承認` |

### Step 6a: はい（承認）→ 承認完了

#### 6a-1. メインリスト ステータス更新 + FinalRewardAmount上書き転記

1. **新しいステップ** → 「SharePoint」→ **項目の更新**
2. 設定:

| プロパティ | 値 | 入力方法 |
|---|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` | |
| リスト名 | `改善提案メイン` | |
| ID | `first(body('メインリスト取得')?['value'])?['ID']` | 式タブ |
| ステータス Value | `承認済` | テキスト |
| 最終褒賞金額 | `triggerOutputs()?['body/RewardAmount']` | 式タブ |
| 申請者GID | `first(body('メインリスト取得')?['value'])?['ApplicantGID']` | 式タブ（必須列） |
| 申請者氏名 | `first(body('メインリスト取得')?['value'])?['ApplicantName']` | 式タブ（必須列） |
| TEC | `first(body('メインリスト取得')?['value'])?['Department']` | 式タブ（必須列） |
| 改善テーマ | `first(body('メインリスト取得')?['value'])?['Theme']` | 式タブ（必須列） |
| 問題点 | `first(body('メインリスト取得')?['value'])?['Problem']` | 式タブ（必須列） |
| 改善内容 | `first(body('メインリスト取得')?['value'])?['Improvement']` | 式タブ（必須列） |
| 改善完了日 | `first(body('メインリスト取得')?['value'])?['CompletionDate']` | 式タブ（必須列） |

> **FinalRewardAmount上書き転記**: 部長のRewardAmountをメインリストのFinalRewardAmountに書き込む。課長承認時に書き込まれていた値は上書きされる（部長の評価が最終値）。

#### 6a-2. 申請者+部長へ承認完了メール送信

1. **新しいステップ** → 「Office 365 Outlook」→ **メールの送信 (V2)**
2. 設定:

| プロパティ | 値 | 入力方法 |
|---|---|---|
| 宛先 | `first(body('メインリスト取得')?['value'])?['ApplicantEmail']?['Email']` | 式タブ |
| CC | `concat(triggerOutputs()?['body/EvaluatorEmail/Email'], ';', first(body('メインリスト取得')?['value'])?['ApproverManager']?['Email'])` | 式タブ（部長+課長） |
| 件名 | `【改善提案】承認完了: @{first(body('メインリスト取得')?['value'])?['Theme']}` | テキスト+式 |
| 本文 | HTMLテンプレート（後述） | |
| 重要度 | 標準 | |

### Step 6b: いいえ（差戻）

#### 6b-1. メインリスト ステータス更新

1. **新しいステップ** → 「SharePoint」→ **項目の更新**
2. 設定:

| プロパティ | 値 | 入力方法 |
|---|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` | |
| リスト名 | `改善提案メイン` | |
| ID | `first(body('メインリスト取得')?['value'])?['ID']` | 式タブ |
| ステータス Value | `差戻` | テキスト |
| 申請者GID | `first(body('メインリスト取得')?['value'])?['ApplicantGID']` | 式タブ（必須列） |
| 申請者氏名 | `first(body('メインリスト取得')?['value'])?['ApplicantName']` | 式タブ（必須列） |
| TEC | `first(body('メインリスト取得')?['value'])?['Department']` | 式タブ（必須列） |
| 改善テーマ | `first(body('メインリスト取得')?['value'])?['Theme']` | 式タブ（必須列） |
| 問題点 | `first(body('メインリスト取得')?['value'])?['Problem']` | 式タブ（必須列） |
| 改善内容 | `first(body('メインリスト取得')?['value'])?['Improvement']` | 式タブ（必須列） |
| 改善完了日 | `first(body('メインリスト取得')?['value'])?['CompletionDate']` | 式タブ（必須列） |

#### 6b-2. 申請者へ差戻通知メール送信

1. **新しいステップ** → 「Office 365 Outlook」→ **メールの送信 (V2)**
2. 設定:

| プロパティ | 値 | 入力方法 |
|---|---|---|
| 宛先 | `first(body('メインリスト取得')?['value'])?['ApplicantEmail']?['Email']` | 式タブ |
| 件名 | `【改善提案】差戻通知: @{first(body('メインリスト取得')?['value'])?['Theme']}` | テキスト+式 |
| 本文 | HTMLテンプレート（後述） | |
| 重要度 | 高 | |

---

## メール本文（HTML）

### 1. 承認完了メール

テンプレート: `powerautomate/templates/3-3_部長承認_承認完了.html`

| プレースホルダー | 式 |
|---|---|
| 申請者名 | `first(body('メインリスト取得')?['value'])?['ApplicantName']` |
| リクエストID | `first(body('メインリスト取得')?['value'])?['RequestID']` |
| 改善テーマ | `first(body('メインリスト取得')?['value'])?['Theme']` |
| 表彰区分 | `first(body('メインリスト取得')?['value'])?['AwardCategory']?['Value']` |
| TEC/部門/部/課 | `first(body('メインリスト取得')?['value'])?['Department']` / `Division` / `Bu` / `Section` |
| 等級 | `triggerOutputs()?['body/Grade']` |
| 褒賞金額 | `formatNumber(triggerOutputs()?['body/RewardAmount'], '#,##0')` |
| 評価コメント | `triggerOutputs()?['body/EvalComment']` |
| 承認者名 | `triggerOutputs()?['body/EvaluatorEmail']?['DisplayName']` |

### 2. 差戻通知メール

テンプレート: `powerautomate/templates/3-3_部長承認_差戻通知.html`

| プレースホルダー | 式 |
|---|---|
| 申請者名 | `first(body('メインリスト取得')?['value'])?['ApplicantName']` |
| リクエストID | `first(body('メインリスト取得')?['value'])?['RequestID']` |
| 改善テーマ | `first(body('メインリスト取得')?['value'])?['Theme']` |
| 表彰区分 | `first(body('メインリスト取得')?['value'])?['AwardCategory']?['Value']` |
| TEC/部門/部/課 | `first(body('メインリスト取得')?['value'])?['Department']` / `Division` / `Bu` / `Section` |
| 差戻者名 | `triggerOutputs()?['body/EvaluatorEmail']?['DisplayName']` |
| 差戻コメント | `triggerOutputs()?['body/EvalComment']` |

---

## 設計上の注意点

### トリガーの条件フィルタリング

評価データリストは課長・部長の両方のデータが格納される。Step 3の条件で `EvaluatorType/Value == "部長"` をチェックし、課長の評価データ変更時にはこのフローが発火しないようにする。課長評価は別フロー（3-2）で処理する。

### メインリスト取得が0件の場合

通常運用では評価データのRequestIDに対応するメインリスト項目が必ず存在する。万が一0件の場合は `first()` が `null` を返し、後続の「項目の更新」アクションがIDなしでエラーになる。この場合はフロー実行履歴で原因を調査する。

### FinalRewardAmountの上書きルール

部長承認フローでは、部長のRewardAmountをFinalRewardAmountに転記する。課長承認フロー（3-2）の≥5,000円ルートではFinalRewardAmountを書き込んでいないため、この時点が初回書き込みとなる。ただし将来的にフローの実行順序がずれる可能性を考慮し、設計上は「上書き」として扱う。

### 承認完了メールの宛先

設計書§5.5に基づき、完了メールは**申請者（To）+ 部長（CC）** に送信する。部長自身が承認操作を行っているため、CCで通知するだけで十分。

### 差戻→再提出時の動作

部長が差戻した場合、Power Apps側でステータスが「差戻」に更新される。申請者が修正・再提出すると、ステータスが「申請中」に戻り、申請通知フロー（3-1）→課長承認フロー（3-2）を経て再度部長承認フロー（3-3）に到達する。

---

## 式リファレンス（コピペ用）

### トリガー出力（評価データ）
```
triggerOutputs()?['body/RequestID']
triggerOutputs()?['body/EvaluatorType/Value']
triggerOutputs()?['body/Decision/Value']
triggerOutputs()?['body/RewardAmount']
triggerOutputs()?['body/Grade']
triggerOutputs()?['body/EvalComment']
triggerOutputs()?['body/EvaluatorEmail/Email']
triggerOutputs()?['body/EvaluatorEmail/DisplayName']
triggerOutputs()?['body/AwardCategory/Value']
```

### メインリスト取得結果
```
first(body('メインリスト取得')?['value'])?['ID']
first(body('メインリスト取得')?['value'])?['RequestID']
first(body('メインリスト取得')?['value'])?['ApplicantName']
first(body('メインリスト取得')?['value'])?['ApplicantEmail']?['Email']
first(body('メインリスト取得')?['value'])?['Theme']
first(body('メインリスト取得')?['value'])?['Department']
first(body('メインリスト取得')?['value'])?['Bu']
first(body('メインリスト取得')?['value'])?['Section']
first(body('メインリスト取得')?['value'])?['TotalEffectAmount']
first(body('メインリスト取得')?['value'])?['AwardCategory']?['Value']
first(body('メインリスト取得')?['value'])?['ApproverManager']?['Email']
first(body('メインリスト取得')?['value'])?['ApproverManager']?['DisplayName']
first(body('メインリスト取得')?['value'])?['ApproverDirector']?['Email']
first(body('メインリスト取得')?['value'])?['ApproverDirector']?['DisplayName']
```

### 書式設定
```
formatNumber(triggerOutputs()?['body/RewardAmount'], '#,##0')
formatNumber(first(body('メインリスト取得')?['value'])?['TotalEffectAmount'], '#,##0')
```

---

## 関連ファイル

| ファイル | 内容 |
|---|---|
| `powerautomate/templates/3-3_部長承認_承認完了.html` | 承認完了メールHTMLテンプレート |
| `powerautomate/templates/3-3_部長承認_差戻通知.html` | 差戻通知メールHTMLテンプレート |
| `powerapps/screen-evaluation.yaml` | 評価画面（評価データをPatchする側） |
| `scripts/create-lists.ps1` | 評価データリスト・改善提案メインリスト定義 |
| `docs/design.md` §5.4 | 部長承認フロー詳細設計 |
| `powerautomate/flow-approval-manager.md` | 課長承認フロー設計書（3-2、参考） |
