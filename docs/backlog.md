# 改善提案システム — 要件バックログ

ミーティング等で決まった追加要件をここに蓄積する。
詳細仕様策定時に `changes/` へ変更提案（proposal）を作成し、開発中セクションへ移動する。
実装完了・spec/マージ後に完了セクションへ移動する。

**前提**: v1（spec/ v10.2）の機能が完成していること

---

## 検討中

ミーティングで決まった要件を詳細に記述するセクション。
「§Xの変更提案を作成して」で changes/ に proposal を作成 → 開発中セクションへ移動。

### ~~§1 添付資料の多ファイル形式対応・容量表記~~ → 開発中セクションへ移動

### ~~§2 評価者の変更機能~~ → 開発中セクションへ移動

### ~~§3 回覧者（事前確認者）~~ → 開発中セクションへ移動

### ~~§4 申請取消機能~~ → 開発中セクションへ移動

### ~~§5 下書き保存機能~~ → 開発中セクションへ移動

### ~~§6 集計・CSVダウンロード機能~~ → 開発中セクションへ移動

### ~~§8 社員マスタサジェスト検索UI~~ → 開発中セクションへ移動

### ~~§7 提案プラン~~ → 開発中セクションへ移動

### §11 メール宛先氏名をAzure AD名から社員マスタ名に統一

Power Automateのメールテンプレートで `DisplayName`（Azure ADアカウント名）を使っている箇所を、社員マスタの `EmployeeName` に統一する。

**対象ファイル（`powerautomate/templates/`）:**

| ファイル | 問題箇所 | 変更内容 |
|---------|---------|---------|
| `3-1_申請通知_課長承認依頼.html` | 挨拶: `ApproverManager/DisplayName` | 社員マスタ取得 → `EmployeeName` |
| `3-1_申請通知_部長承認依頼.html` | 挨拶: `ApproverDirector/DisplayName` | 社員マスタ取得 → `EmployeeName` |
| `3-2_課長承認_部長へ承認依頼.html` | 挨拶: `ApproverDirector/DisplayName` | 社員マスタ取得 → `EmployeeName` |
| `3-2_課長承認_承認完了.html` | 承認者欄: `EvaluatorEmail/DisplayName` | 社員マスタ取得 → `EmployeeName` |
| `3-2_課長承認_差戻通知.html` | 差戻者欄: `EvaluatorEmail/DisplayName` | 社員マスタ取得 → `EmployeeName` |
| `3-3_部長承認_承認完了.html` | 承認者欄: `EvaluatorEmail/DisplayName` | 社員マスタ取得 → `EmployeeName` |
| `3-3_部長承認_差戻通知.html` | 差戻者欄: `EvaluatorEmail/DisplayName` | 社員マスタ取得 → `EmployeeName` |
| `3-5_回覧通知_課長承認依頼.html` | 挨拶: `ApproverManager/DisplayName` | 社員マスタ取得 → `EmployeeName` |
| `3-5_回覧通知_部長承認依頼.html` | 挨拶: `ApproverDirector/DisplayName` | 社員マスタ取得 → `EmployeeName` |

**実装方針:**
- 各フローでメール送信の直前に「社員マスタ」Get itemsアクションを追加し、メールアドレスでフィルタ（`Email eq '...'`、上限1件）
- テンプレートの `DisplayName` を `first(body('社員マスタ_XXX')?['value'])?['EmployeeName']` に置換
- アクション名はフロー内で一意になるよう `社員マスタ_課長` / `社員マスタ_部長` 等で区別
- 対応するフロー手順書（`flow-*-build.html`）も同時に更新すること

### §10 改善提案メインに CreatedAt / SubmitAt 列追加

改善提案メインリストに以下の2列を追加する。

| 列名 | 型 | 設定タイミング | 用途 |
|---|---|---|---|
| `CreatedAt` | 日時 | 初回保存時（下書き or 提出） | 申請作成日の記録 |
| `SubmitAt` | 日時 | 提出時（Status=申請中）のみ | 提出日の記録・集計・リマインダー判定 |

**背景:** SPリストのデフォルト `Created` 列は下書き保存時に設定される。提出日と作成日を区別したい場合に必要。`SubmitAt` はリマインダーフロー（§3-6）の承認期限計算にも活用できる。

**実装方針（未確定）:**
- `CreatedAt`: 初回Patch時に `Now()` をセット（下書き・提出共通）
- `SubmitAt`: 提出ボタン（btnSubmit）のPatchに `Now()` を追加、下書き保存ではセットしない
- PnPスクリプト（`scripts/create-lists.ps1`）に列追加
- Power Apps の submit-logic.pfx / screen-application-form.yaml を更新

### §9 評価画面: 本人確認メッセージ表示

評価画面を開いたユーザーが評価者本人でない場合、または申請ステータスが評価不可の場合に、状況に応じたメッセージを表示する。取下げ通知フロー（メール）の代替として機能させる。

**表示パターン:**

| 状況 | メッセージ |
|---|---|
| 自分が評価者 + 正しいステータス | 通常の評価フォームを表示（現状維持） |
| 他の人が評価中（自分は評価者でない） | 「現在 〇〇さん（課長/部長）が評価中です」 |
| ステータスが「取下げ」 | 「この申請は申請者により取り消されました」 |
| ステータスが「承認済」「差戻」 | 「この申請の評価は完了しています（〇〇）」 |

**実装方針:**
- OnVisible内で `varEvalIsAuthorized`（bool）と `varEvalStatusMessage`（テキスト）を計算
- 評価フォーム全体のコンテナに `Visible: =varEvalIsAuthorized` を追加
- 非認可時メッセージコンテナを新規追加（`varEvalStatusMessage` を表示）
- 変更ファイル: `screen-evaluation.yaml` / `app-onstart.pfx`

**背景:** 取下げ通知フロー（§4）のメール送信を省略した代替措置として検討。評価者がメールリンクから画面を開いた時点でステータスがわかれば運用上問題ない。

> **削除済み（2026-03-29）**
>
> - §7-2 管理者画面 → スコープ外（SPリスト直接編集で運用。エクスポートは§6でカバー）
> - §7-3 取下げ通知フロー → §4 申請取消機能のproposalにフローNo.4として包含済み
> - §7-5 承認履歴リスト → 今回スコープ外

---

## 開発中

changes/ に変更提案（proposal）を作成済み。実装進行中。

- **§1 添付資料の多ファイル形式対応・容量表記** — [proposal](changes/v2-file-format/proposal.md)（実装途中・仕様確認中）
- **§3 回覧者（事前確認者）** — [proposal](changes/v2-reviewer/proposal.md)
- **§6 集計・CSVダウンロード機能** — [proposal](changes/v2-csv-export/proposal.md)（DJ-3/4/5がTBD）
- **§7 申請・承認状況の確認導線＋リマインダー** — [proposal](changes/v2-status-view-reminder/proposal.md)

---

## 完了

spec/ にマージ済み。changes/archive/ に原本保存。

- **§2 評価者の変更機能** — 2026-04-02完了 → [proposal](changes/v2-evaluator-change/proposal.md)
- **§4 申請取消機能** — 2026-04-02完了 → [proposal](changes/v2-cancel/proposal.md)
- **§5 下書き保存機能** — 2026-04-05完了 → [proposal](changes/v2-draft-save/proposal.md)
- **§8 社員マスタサジェスト検索UI** — 2026-04-08完了 → [proposal](changes/archive/v2-employee-suggest/proposal.md)
