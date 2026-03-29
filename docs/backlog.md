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

> **削除済み（2026-03-29）**
> - §7-2 管理者画面 → スコープ外（SPリスト直接編集で運用。エクスポートは§6でカバー）
> - §7-3 取下げ通知フロー → §4 申請取消機能のproposalにフローNo.4として包含済み
> - §7-5 承認履歴リスト → 今回スコープ外

---

## 開発中

changes/ に変更提案（proposal）を作成済み。実装進行中。

- **§1 添付資料の多ファイル形式対応・容量表記** — [proposal](changes/v2-file-format/proposal.md)
- **§3 回覧者（事前確認者）** — [proposal](changes/v2-reviewer/proposal.md)
- **§2 評価者の変更機能** — [proposal](changes/v2-evaluator-change/proposal.md)
- **§5 下書き保存機能** — [proposal](changes/v2-draft-save/proposal.md)
- **§4 申請取消機能** — [proposal](changes/v2-cancel/proposal.md)
- **§6 集計・CSVダウンロード機能** — [proposal](changes/v2-csv-export/proposal.md)（DJ-3/4/5がTBD）
- **§7 申請・承認状況の確認導線＋リマインダー** — [proposal](changes/v2-status-view-reminder/proposal.md)
- **§8 社員マスタサジェスト検索UI** — [proposal](changes/v2-employee-suggest/proposal.md)

---

## 完了

spec/ にマージ済み。changes/archive/ に原本保存。

<!-- 例:
- §3 回覧者 — 2026-xx-xx完了 → [archive](changes/archive/2026-xx-xx-v2-reviewer/)
-->

（現在なし）
