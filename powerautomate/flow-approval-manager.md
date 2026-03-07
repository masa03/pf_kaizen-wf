# Power Automate フロー設計書: 課長承認フロー

**タスク**: 3-2
**フロー名**: 改善提案_課長承認
**用途**: 課長が評価・承認/差戻した際のステータス遷移・メール通知・FinalRewardAmount転記

---

## フロー概要

```
[SharePoint - 項目が作成または変更されたとき]
    │  リスト: 評価データ
    │
    ▼
[条件1: 評価者種別="課長" AND 判定≠空?]
    │
    ├── No → 終了（部長評価や未確定データはスキップ）
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
    │   [条件3: RewardAmount >= 5000?]
    │       │
    │       ├── Yes（≥5,000円 → 部長承認へ）
    │       │   │
    │       │   ▼
    │       │   [メインリスト ステータス更新]
    │       │   │  ステータス → "部長評価中"
    │       │   │  ※FinalRewardAmountはまだ書き込まない
    │       │   │
    │       │   ▼
    │       │   [Office 365 - メール送信]
    │       │      宛先: ApproverDirector/Email（メインリストから取得）
    │       │      テンプレート: 承認依頼メール
    │       │
    │       └── No（<5,000円 → 承認完了）
    │           │
    │           ▼
    │           [メインリスト ステータス更新 + FinalRewardAmount転記]
    │           │  ステータス → "承認済"
    │           │  FinalRewardAmount → 課長のRewardAmount
    │           │
    │           ▼
    │           [Office 365 - メール送信]
    │              宛先: 申請者 + 課長
    │              テンプレート: 承認完了メール
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

> **表彰区分スキップの扱い**: 小集団 パール賞（3等）=3,000円、銅賞（2等）=5,000円、銀賞（1等）=10,000円はPower Apps側で自動設定済み。フロー側はRewardAmountの値のみで分岐するため、表彰区分に関わらず同一ロジックで処理できる。

---

## 構築手順

### Step 1: フロー作成

1. Power Automate → **マイフロー** → **新しいフロー** → **自動化したクラウドフロー**
2. フロー名: `改善提案_課長承認`
3. トリガー: **SharePoint - 項目が作成または変更されたとき** を選択

### Step 2: トリガー設定

| プロパティ | 値 |
|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` |
| リスト名 | `評価データ` |

> **「作成または変更」を使う理由**: 初回評価時は項目が新規作成される。差戻→再提出後の再評価時は既存項目が更新される。両方のケースに対応するためこのトリガーを使用。

### Step 3: 条件1 — 評価者種別=課長 AND 判定≠空

1. **新しいステップ** → **条件**
2. 「AND」条件で2つを設定:

| # | 左辺 | 演算子 | 右辺 |
|---|---|---|---|
| 1 | `triggerOutputs()?['body/EvaluatorType/Value']` | 次の値に等しい | `課長` |
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

### Step 6a: はい（承認）→ 金額判定

#### 6a-1. 条件3 — RewardAmount >= 5000?

1. **新しいステップ** → **条件**
2. 設定:

| 左辺 | 演算子 | 右辺 |
|---|---|---|
| `triggerOutputs()?['body/RewardAmount']` | 次の値以上 | `5000` |

> **注意**: 左辺は式タブから入力。右辺の `5000` は整数として入力（文字列ではない）。

### Step 7a: はい（≥5,000円）→ 部長承認へ

#### 7a-1. メインリスト ステータス更新

1. **新しいステップ** → 「SharePoint」→ **項目の更新**
2. 設定:

| プロパティ | 値 | 入力方法 |
|---|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` | |
| リスト名 | `改善提案メイン` | |
| ID | `first(body('メインリスト取得')?['value'])?['ID']` | 式タブ |
| ステータス Value | `部長評価中` | テキスト |
| 申請者GID | `first(body('メインリスト取得')?['value'])?['ApplicantGID']` | 式タブ（必須列） |
| 申請者氏名 | `first(body('メインリスト取得')?['value'])?['ApplicantName']` | 式タブ（必須列） |
| 表彰区分 Value | `first(body('メインリスト取得')?['value'])?['AwardCategory']?['Value']` | 式タブ（必須列） |
| TEC | `first(body('メインリスト取得')?['value'])?['Department']` | 式タブ（必須列） |
| 改善テーマ | `first(body('メインリスト取得')?['value'])?['Theme']` | 式タブ（必須列） |
| 問題点 | `first(body('メインリスト取得')?['value'])?['Problem']` | 式タブ（必須列） |
| 改善内容 | `first(body('メインリスト取得')?['value'])?['Improvement']` | 式タブ（必須列） |
| 改善完了日 | `first(body('メインリスト取得')?['value'])?['CompletionDate']` | 式タブ（必須列） |
| 効果金額合計 | `first(body('メインリスト取得')?['value'])?['TotalEffectAmount']` | 式タブ（必須列） |

> **必須列の補足**: 「項目の更新」アクションはリストの必須列すべてに値が必要（PUT相当のバリデーション）。変更しない列はメインリスト取得の値をそのまま渡す（knowledge/automate.md参照）。

#### 7a-2. 部長へ承認依頼メール送信

1. **新しいステップ** → 「Office 365 Outlook」→ **メールの送信 (V2)**
2. 設定:

| プロパティ | 値 | 入力方法 |
|---|---|---|
| 宛先 | `first(body('メインリスト取得')?['value'])?['ApproverDirector']?['Email']` | 式タブ |
| 件名 | `【改善提案】承認依頼: @{first(body('メインリスト取得')?['value'])?['Theme']}` | テキスト+式 |
| 本文 | HTMLテンプレート（後述） | |
| 重要度 | 標準 | |

> **テンプレート**: `powerautomate/templates/email-approval-request.html` を再利用。動的コンテンツの差し込み元がメインリスト取得の結果になる点のみ異なる。

### Step 7b: いいえ（<5,000円）→ 承認完了

#### 7b-1. メインリスト ステータス更新 + FinalRewardAmount転記

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
| 表彰区分 Value | `first(body('メインリスト取得')?['value'])?['AwardCategory']?['Value']` | 式タブ（必須列） |
| TEC | `first(body('メインリスト取得')?['value'])?['Department']` | 式タブ（必須列） |
| 改善テーマ | `first(body('メインリスト取得')?['value'])?['Theme']` | 式タブ（必須列） |
| 問題点 | `first(body('メインリスト取得')?['value'])?['Problem']` | 式タブ（必須列） |
| 改善内容 | `first(body('メインリスト取得')?['value'])?['Improvement']` | 式タブ（必須列） |
| 改善完了日 | `first(body('メインリスト取得')?['value'])?['CompletionDate']` | 式タブ（必須列） |
| 効果金額合計 | `first(body('メインリスト取得')?['value'])?['TotalEffectAmount']` | 式タブ（必須列） |

> **FinalRewardAmount転記**: 課長のRewardAmountをメインリストのFinalRewardAmountに書き込む。これが最終確定金額となる。

#### 7b-2. 申請者+課長へ承認完了メール送信

1. **新しいステップ** → 「Office 365 Outlook」→ **メールの送信 (V2)**
2. 設定:

| プロパティ | 値 | 入力方法 |
|---|---|---|
| 宛先 | `first(body('メインリスト取得')?['value'])?['ApplicantEmail']?['Email']` | 式タブ |
| CC | `triggerOutputs()?['body/EvaluatorEmail/Email']` | 式タブ（課長本人） |
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
| 表彰区分 Value | `first(body('メインリスト取得')?['value'])?['AwardCategory']?['Value']` | 式タブ（必須列） |
| TEC | `first(body('メインリスト取得')?['value'])?['Department']` | 式タブ（必須列） |
| 改善テーマ | `first(body('メインリスト取得')?['value'])?['Theme']` | 式タブ（必須列） |
| 問題点 | `first(body('メインリスト取得')?['value'])?['Problem']` | 式タブ（必須列） |
| 改善内容 | `first(body('メインリスト取得')?['value'])?['Improvement']` | 式タブ（必須列） |
| 改善完了日 | `first(body('メインリスト取得')?['value'])?['CompletionDate']` | 式タブ（必須列） |
| 効果金額合計 | `first(body('メインリスト取得')?['value'])?['TotalEffectAmount']` | 式タブ（必須列） |

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

### 1. 部長への承認依頼メール

テンプレートは `powerautomate/templates/email-approval-request.html` を再利用。

動的コンテンツの差し込み（3-1フローとの違い: メインリスト取得結果から参照）:

| プレースホルダー | 式 |
|---|---|
| `{{ApproverName}}` | `first(body('メインリスト取得')?['value'])?['ApproverDirector']?['DisplayName']` |
| `{{ApplicantName}}` | `first(body('メインリスト取得')?['value'])?['ApplicantName']` |
| `{{Theme}}` | `first(body('メインリスト取得')?['value'])?['Theme']` |
| `{{TotalEffectAmount}}` | `formatNumber(first(body('メインリスト取得')?['value'])?['TotalEffectAmount'], '#,##0')` |
| `{{AwardCategory}}` | `first(body('メインリスト取得')?['value'])?['AwardCategory']?['Value']` |
| `{{Department}}` | `first(body('メインリスト取得')?['value'])?['Department']` |
| `{{Bu}}` | `first(body('メインリスト取得')?['value'])?['Bu']` |
| `{{Section}}` | `first(body('メインリスト取得')?['value'])?['Section']` |
| `{{AppUrl}}` | Power Apps の評価画面URL（環境に合わせて設定） |
| `{{RequestID}}` | `first(body('メインリスト取得')?['value'])?['RequestID']` |

### 2. 承認完了メール

テンプレート: `powerautomate/templates/email-approval-complete.html`

| プレースホルダー | 式 |
|---|---|
| `{{ApplicantName}}` | `first(body('メインリスト取得')?['value'])?['ApplicantName']` |
| `{{RequestID}}` | `first(body('メインリスト取得')?['value'])?['RequestID']` |
| `{{Theme}}` | `first(body('メインリスト取得')?['value'])?['Theme']` |
| `{{AwardCategory}}` | `first(body('メインリスト取得')?['value'])?['AwardCategory']?['Value']` |
| `{{Department}}` | `first(body('メインリスト取得')?['value'])?['Department']` |
| `{{Bu}}` | `first(body('メインリスト取得')?['value'])?['Bu']` |
| `{{Section}}` | `first(body('メインリスト取得')?['value'])?['Section']` |
| `{{Grade}}` | `triggerOutputs()?['body/Grade']` |
| `{{RewardAmount}}` | `formatNumber(triggerOutputs()?['body/RewardAmount'], '#,##0')` |
| `{{EvalComment}}` | `triggerOutputs()?['body/EvalComment']` |
| `{{ApproverName}}` | `triggerOutputs()?['body/EvaluatorEmail']?['DisplayName']` |
| `{{AppUrl}}` | Power Apps の閲覧画面URL（環境に合わせて設定） |

### 3. 差戻通知メール

テンプレート: `powerautomate/templates/email-rejection-notice.html`

| プレースホルダー | 式 |
|---|---|
| `{{ApplicantName}}` | `first(body('メインリスト取得')?['value'])?['ApplicantName']` |
| `{{RequestID}}` | `first(body('メインリスト取得')?['value'])?['RequestID']` |
| `{{Theme}}` | `first(body('メインリスト取得')?['value'])?['Theme']` |
| `{{AwardCategory}}` | `first(body('メインリスト取得')?['value'])?['AwardCategory']?['Value']` |
| `{{Department}}` | `first(body('メインリスト取得')?['value'])?['Department']` |
| `{{Bu}}` | `first(body('メインリスト取得')?['value'])?['Bu']` |
| `{{Section}}` | `first(body('メインリスト取得')?['value'])?['Section']` |
| `{{RejecterName}}` | `triggerOutputs()?['body/EvaluatorEmail']?['DisplayName']` |
| `{{EvalComment}}` | `triggerOutputs()?['body/EvalComment']` |
| `{{AppUrl}}` | Power Apps の申請フォームURL（修正・再提出用） |

---

## 設計上の注意点

### トリガーの条件フィルタリング

評価データリストは課長・部長の両方のデータが格納される。Step 3の条件で `EvaluatorType/Value == "課長"` をチェックし、部長の評価データ変更時にはこのフローが発火しないようにする。部長評価は別フロー（3-3）で処理する。

### メインリスト取得が0件の場合

通常運用では評価データのRequestIDに対応するメインリスト項目が必ず存在する。万が一0件の場合は `first()` が `null` を返し、後続の「項目の更新」アクションがIDなしでエラーになる。この場合はフロー実行履歴で原因を調査する。

### FinalRewardAmountの転記タイミング

- **≥5,000円の場合**: この時点ではFinalRewardAmountを書き込まない。部長承認フロー（3-3）で部長のRewardAmountが最終値として転記される。
- **<5,000円の場合**: 課長のRewardAmountをFinalRewardAmountに転記する。これが最終確定金額。

### 差戻→再提出時の動作

申請者が差戻後に修正・再提出すると、Power Apps側でステータスが「申請中」に戻り、申請通知フロー（3-1）が再度トリガーされる（※再提出は既存アイテムの更新なので、3-1のトリガーが「作成時」のみの場合は別途対応が必要）。課長が再評価すると評価データが更新され、このフロー（3-2）が再度発火する。

### 承認完了メールの宛先

設計書§5.5に基づき、完了メールは**申請者（To）+ 課長（CC）** に送信する。課長自身が承認操作を行っているため、CCで通知するだけで十分。

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
| `powerautomate/templates/3-2_課長承認_部長へ承認依頼.html` | 部長への承認依頼メールHTMLテンプレート |
| `powerautomate/templates/3-2_課長承認_承認完了.html` | 承認完了メールHTMLテンプレート |
| `powerautomate/templates/3-2_課長承認_差戻通知.html` | 差戻通知メールHTMLテンプレート |
| `powerapps/screen-evaluation.yaml` | 評価画面（評価データをPatchする側） |
| `scripts/create-lists.ps1` | 評価データリスト・改善提案メインリスト定義 |
| `docs/design.md` §5.3 | 課長承認フロー詳細設計 |
| `powerautomate/flow-notification-submit.md` | 申請通知フロー設計書（3-1、参考） |
