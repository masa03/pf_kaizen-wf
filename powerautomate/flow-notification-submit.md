# Power Automate フロー設計書: 申請通知フロー

**タスク**: 3-1
**フロー名**: 改善提案_申請通知
**用途**: 新規申請・差戻再提出時に承認者（課長 or 部長）へ承認依頼メールを送信

---

## フロー概要

```
[SharePoint - 項目が作成または変更されたとき]
    │  リスト: 改善提案メイン
    │  トリガー条件: @equals(triggerOutputs()?['body/Status/Value'], '申請中')
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
3. トリガー: **SharePoint - 項目が作成または変更されたとき** を選択

### Step 2: トリガー設定

| プロパティ | 値 |
|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` |
| リスト名 | `改善提案メイン` |

#### トリガー条件の設定

トリガーの **設定** → **トリガー条件** に以下を追加（不要な発火を防止）:

```
@equals(triggerOutputs()?['body/Status/Value'], '申請中')
```

> **なぜトリガー条件が必要か**: 「作成または変更」トリガーは、ステータス更新（課長評価中・部長評価中への変更等）を含むあらゆる変更で発火する。トリガー条件で `Status == "申請中"` のときのみフローを実行することで、無駄な実行を抑制する。Step 3の条件分岐と同じチェックだが、トリガー条件に入れることでフロー実行自体を抑制でき、実行回数課金を削減できる。

### Step 3: 条件 — ステータス確認

1. **新しいステップ** → **条件**
2. 設定:

| 左辺 | 演算子 | 右辺 |
|---|---|---|
| `triggerOutputs()?['body/Status/Value']` | 次の値に等しい | `申請中` |

> **補足**: 選択肢列の値は `Status/Value` で取得。Power Appsから「下書き」保存で項目が作成される場合や、他のフローによるステータス更新でもトリガーが発火するため、このチェックが必要。トリガー条件でも同じフィルタを設定しているが、安全のためフロー内でも二重チェックする。

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

| プロパティ | 値 | 入力方法 |
|---|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` | |
| リスト名 | `改善提案メイン` | |
| ID | `triggerOutputs()?['body/ID']` | 式タブ |
| ステータス Value | `部長評価中` | テキスト |
| 申請者メール Claims | `triggerOutputs()?['body/ApplicantEmail/Claims']` | 式タブ（必須列） |
| 申請者GID | `triggerOutputs()?['body/ApplicantGID']` | 式タブ（必須列） |
| 申請者氏名 | `triggerOutputs()?['body/ApplicantName']` | 式タブ（必須列） |
| 表彰区分 Value | `triggerOutputs()?['body/AwardCategory/Value']` | 式タブ（必須列） |
| TEC | `triggerOutputs()?['body/Department']` | 式タブ（必須列） |
| 改善テーマ | `triggerOutputs()?['body/Theme']` | 式タブ（必須列） |
| 問題点 | `triggerOutputs()?['body/Problem']` | 式タブ（必須列） |
| 改善内容 | `triggerOutputs()?['body/Improvement']` | 式タブ（必須列） |
| 改善完了日 | `triggerOutputs()?['body/CompletionDate']` | 式タブ（必須列） |
| 承認者（課長） Claims | `triggerOutputs()?['body/ApproverManager/Claims']` | 式タブ（必須列） |

> **理由**: 課長=申請者の場合、課長評価をスキップして部長評価に直接進む。
>
> **必須列の補足**: 「項目の更新」アクションはリストの必須列すべてに値が必要（PUT相当のバリデーション）。変更しない列はトリガー出力の値をそのまま渡す。

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

| プロパティ | 値 | 入力方法 |
|---|---|---|
| サイトのアドレス | `https://xxxxx.sharepoint.com/sites/kaizen-wf` | |
| リスト名 | `改善提案メイン` | |
| ID | `triggerOutputs()?['body/ID']` | 式タブ |
| ステータス Value | `課長評価中` | テキスト |
| 申請者メール Claims | `triggerOutputs()?['body/ApplicantEmail/Claims']` | 式タブ（必須列） |
| 申請者GID | `triggerOutputs()?['body/ApplicantGID']` | 式タブ（必須列） |
| 申請者氏名 | `triggerOutputs()?['body/ApplicantName']` | 式タブ（必須列） |
| 表彰区分 Value | `triggerOutputs()?['body/AwardCategory/Value']` | 式タブ（必須列） |
| TEC | `triggerOutputs()?['body/Department']` | 式タブ（必須列） |
| 改善テーマ | `triggerOutputs()?['body/Theme']` | 式タブ（必須列） |
| 問題点 | `triggerOutputs()?['body/Problem']` | 式タブ（必須列） |
| 改善内容 | `triggerOutputs()?['body/Improvement']` | 式タブ（必須列） |
| 改善完了日 | `triggerOutputs()?['body/CompletionDate']` | 式タブ（必須列） |
| 承認者（課長） Claims | `triggerOutputs()?['body/ApproverManager/Claims']` | 式タブ（必須列） |

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

メールテンプレートは `powerautomate/templates/3-1_申請通知_承認依頼.html` を参照。

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

Power Appsの提出処理（btnSubmit.OnSelect）では `Status: {Value: "申請中"}` でPatchしている。このフローのトリガーは「項目が作成または変更されたとき」なので、新規申請・差戻再提出の両方で発火する。

**新規申請**: 項目が作成される → トリガー発火 → ステータス="申請中" → フロー実行
**差戻→再提出**: 既存アイテムのStatus="差戻"→"申請中"に更新 → トリガー発火 → ステータス="申請中" → フロー実行

> **無限ループ防止**: このフロー内でステータスを「課長評価中」「部長評価中」に更新するが、トリガー条件で `Status == "申請中"` のみに限定しているため、フロー自身の更新で再トリガーされることはない。

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
| `powerautomate/templates/3-1_申請通知_承認依頼.html` | 承認依頼メールHTMLテンプレート |
| `powerapps/submit-logic.pfx` | 提出処理（Status="申請中"でPatch） |
| `powerapps/screen-application-form.yaml` | btnSubmit.OnSelect |
| `scripts/create-lists.ps1` | 改善提案メインリスト定義 |
| `docs/design.md` §5.2 | 申請通知フロー詳細設計 |
