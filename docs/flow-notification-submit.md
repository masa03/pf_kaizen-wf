# Power Automate フロー設計書: 申請通知フロー

**タスク**: 3-1
**フロー名**: 改善提案_申請通知
**用途**: 新規申請が提出されたときに承認者（課長 or 部長）へ承認依頼メールを送信

---

## フロー概要

```
[SharePoint - 項目が作成されたとき]
    │  リスト: 改善提案メイン
    │
    ▼
[条件: ステータス = "申請中"?]
    │
    ├── No → 終了（下書き等はスキップ）
    │
    ▼ Yes
[条件: ApplicantEmail == ApproverManager?]
    │  （課長=申請者なら一致する）
    │
    ├── Yes（課長=申請者）
    │   │
    │   ▼
    │   [メインリスト ステータス更新]
    │   │  ステータス → "部長評価中"
    │   │
    │   ▼
    │   [Office 365 - メール送信]
    │      宛先: ApproverDirector/Email（トリガーから取得）
    │      テンプレート: 承認依頼メール
    │
    └── No（通常ケース）
        │
        ▼
        [メインリスト ステータス更新]
        │  ステータス → "課長評価中"
        │
        ▼
        [Office 365 - メール送信]
           宛先: ApproverManager/Email（トリガーから取得）
           テンプレート: 承認依頼メール
```

> **簡略化ポイント**: 課長・部長のメールアドレスは改善提案メインのユーザー型列（ApproverManager / ApproverDirector）に既に保存されているため、社員マスタへのLookUpは不要。課長=申請者の判定も `ApplicantEmail == ApproverManager` の比較で完結する。

---

## 構築手順

### Step 1: フロー作成

1. Power Automate → **マイフロー** → **新しいフロー** → **自動化したクラウドフロー**
2. フロー名: `改善提案_申請通知`
3. トリガー: **SharePoint - 項目が作成されたとき** を選択

### Step 2: トリガー設定

| プロパティ | 値 |
|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` |
| リスト名 | `改善提案メイン` |

### Step 3: 条件 — ステータス確認

1. **新しいステップ** → **条件**
2. 設定:

| 左辺 | 演算子 | 右辺 |
|---|---|---|
| `triggerOutputs()?['body/Status/Value']` | 次の値に等しい | `申請中` |

> **補足**: 選択肢列の値は `Status/Value` で取得。Power Appsから「下書き」保存で項目が作成される場合もあるため、このチェックが必要。

**「いいえ」の場合**: 何もしない（終了）

### Step 4: 条件 — 課長=申請者?

1. **新しいステップ** → **条件**
2. 設定:

| 左辺 | 演算子 | 右辺 |
|---|---|---|
| `triggerOutputs()?['body/ApplicantEmail/Email']` | 次の値に等しい | `triggerOutputs()?['body/ApproverManager/Email']` |

> **判定ロジック**: 課長が自分で申請した場合、社員マスタの ManagerGID が本人を指すため、ApproverManager に自分自身が登録される。よって ApplicantEmail と ApproverManager の Email が一致すれば「課長=申請者」と判断できる。社員マスタへのアクセスは不要。

### Step 5a: はい（課長=申請者）→ 部長へ通知

#### 5a-1. メインリスト ステータス更新

1. **新しいステップ** → 「SharePoint」→ **項目の更新**
2. 設定:

| プロパティ | 値 |
|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` |
| リスト名 | `改善提案メイン` |
| ID | `triggerOutputs()?['body/ID']` |
| ステータス Value | `部長評価中` |

> **理由**: 課長=申請者の場合、課長評価をスキップして部長評価に直接進む。

#### 5a-2. 部長へメール送信

1. **新しいステップ** → 「Office 365 Outlook」→ **メールの送信 (V2)**
2. 設定:

| プロパティ | 値 |
|---|---|
| 宛先 | `triggerOutputs()?['body/ApproverDirector/Email']` |
| 件名 | `【改善提案】承認依頼: @{triggerOutputs()?['body/Theme']}` |
| 本文 | HTMLテンプレート（後述） |
| 重要度 | 標準 |

### Step 5b: いいえ（通常ケース）→ 課長へ通知

#### 5b-1. メインリスト ステータス更新

1. **新しいステップ** → 「SharePoint」→ **項目の更新**
2. 設定:

| プロパティ | 値 |
|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` |
| リスト名 | `改善提案メイン` |
| ID | `triggerOutputs()?['body/ID']` |
| ステータス Value | `課長評価中` |

#### 5b-2. 課長へメール送信

1. **新しいステップ** → 「Office 365 Outlook」→ **メールの送信 (V2)**
2. 設定:

| プロパティ | 値 |
|---|---|
| 宛先 | `triggerOutputs()?['body/ApproverManager/Email']` |
| 件名 | `【改善提案】承認依頼: @{triggerOutputs()?['body/Theme']}` |
| 本文 | HTMLテンプレート（後述） |
| 重要度 | 標準 |

---

## メール本文（HTML）

メールテンプレートは `templates/email-approval-request.html` を参照。

動的コンテンツの差し込み:

| プレースホルダー | 動的コンテンツ / 式 |
|---|---|
| `{{ApproverName}}` | 5a: `triggerOutputs()?['body/ApproverDirector/DisplayName']` / 5b: `triggerOutputs()?['body/ApproverManager/DisplayName']` |
| `{{ApplicantName}}` | `triggerOutputs()?['body/ApplicantName']` |
| `{{Theme}}` | `triggerOutputs()?['body/Theme']` |
| `{{TotalEffectAmount}}` | `formatNumber(triggerOutputs()?['body/TotalEffectAmount'], '#,##0')` |
| `{{AwardCategory}}` | `triggerOutputs()?['body/AwardCategory/Value']` |
| `{{Department}}` | `triggerOutputs()?['body/Department']` |
| `{{Bu}}` | `triggerOutputs()?['body/Bu']` |
| `{{Section}}` | `triggerOutputs()?['body/Section']` |
| `{{AppUrl}}` | Power Apps の評価画面URL（環境に合わせて設定） |
| `{{RequestID}}` | `triggerOutputs()?['body/RequestID']` |

---

## 設計上の注意点

### ステータス更新のタイミング

Power Appsの提出処理（btnSubmit.OnSelect）では `Status: {Value: "申請中"}` でPatchしている。このフローのトリガーは「項目が作成されたとき」なので、新規申請のみ発火する。

**差戻→再提出の場合**: 既存アイテムの更新（Status→申請中に戻す）であり「項目の作成」にはならない。再提出時の通知は別途検討が必要（3-2フローのステータス監視で対応、または別フローで対応）。

### 課長=申請者時のステータス遷移

通常: 申請中 → **課長評価中** → （課長承認後に3-2フローで判定）
課長本人: 申請中 → **部長評価中**（課長評価スキップ）

この分岐はフロー内でステータス更新することで実現。Power Apps側のPatchでは常に `"申請中"` で統一。

### 社員マスタ不要の理由

改善提案メインリストに ApproverManager / ApproverDirector をユーザー型で保存しているため、承認者のメールアドレスはトリガー出力から直接取得できる。課長=申請者の判定も ApplicantEmail と ApproverManager の比較で完結する。社員マスタへのアクセスを省くことで、フローのステップ数を削減し、実行速度を向上させている。

---

## 関連ファイル

| ファイル | 内容 |
|---|---|
| `templates/3-1_申請通知_承認依頼.html` | 承認依頼メールHTMLテンプレート |
| `powerapps/submit-logic.pfx` | 提出処理（Status="申請中"でPatch） |
| `powerapps/screen-application-form.yaml` | btnSubmit.OnSelect |
| `scripts/create-lists.ps1` | 改善提案メインリスト定義 |
| `docs/design.md` §5.2 | 申請通知フロー詳細設計 |
