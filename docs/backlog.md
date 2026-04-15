# 改善提案システム — 要件バックログ

ミーティング等で決まった追加要件をここに蓄積する。
詳細仕様策定時に `changes/` へ変更提案（proposal）を作成し、開発中セクションへ移動する。
実装完了・spec/マージ後に完了セクションへ移動する。

**前提**: v1（spec/ v10.2）の機能が完成していること

---

## 検討中

ミーティングで決まった要件を詳細に記述するセクション。
「§Xの変更提案を作成して」で changes/ に proposal を作成 → 開発中セクションへ移動。

> **削除済み（2026-03-29）**
>
> - §7-2 管理者画面 → スコープ外（SPリスト直接編集で運用。エクスポートは§6でカバー）
> - §7-3 取下げ通知フロー → §4 申請取消機能のproposalにフローNo.4として包含済み
> - §7-5 承認履歴リスト → 今回スコープ外

---

## 開発中

changes/ に変更提案（proposal）を作成済み。実装進行中。

- **§6 集計・CSVダウンロード機能** — [proposal](changes/v2-csv-export/proposal.md)（DJ-3/4/5がTBD、実装ブロック中）

---

## 完了

spec/ にマージ済み。changes/archive/ に原本保存。

- **§2 評価者の変更機能** — 2026-04-02完了 → [proposal](changes/v2-evaluator-change/proposal.md)
- **§3 回覧者（事前確認者）** — 2026-04-06完了 → [proposal](changes/v2-reviewer/proposal.md)
- **§4 申請取消機能** — 2026-04-02完了 → [proposal](changes/v2-cancel/proposal.md)
- **§5 下書き保存機能** — 2026-04-05完了 → [proposal](changes/v2-draft-save/proposal.md)
- **§7 申請・承認状況の確認導線＋リマインダー** — 2026-04-14完了 → [proposal](changes/v2-status-view-reminder/proposal.md)
- **§8 社員マスタサジェスト検索UI** — 2026-04-08完了 → [proposal](changes/archive/v2-employee-suggest/proposal.md)
- **§1 添付資料の多ファイル形式対応・容量表記** — 2026-04-14完了 → [proposal](changes/v2-file-format/proposal.md)
- **§12 申請完了・承認完了後のサンクス画面** — 2026-04-15完了（proposal不要・YAML直接実装）
- **§13 承認リストのカスタムView承認遷移リンク** — 2026-04-14完了（proposal不要・スクリプト＋spec直接更新）
- **§9 評価画面: 取下げメッセージ表示** — 2026-04-15完了（proposal不要・YAML直接実装）

---

## 保留中

優先度が低い、または他の要件の具体化を待って判断する項目。

- **§10 改善提案メインに CreatedAt / SubmitAt 列追加** — リマインダーは `EvaluationStartDate` 基準で実装済みのため、現時点で緊急性なし。集計要件（§6）が具体化した際に再判断
- **§11 メール宛先氏名をAzure AD名から社員マスタ名に統一** — DisplayNameを社員マスタのEmployeeNameに統一する改善。優先度低のため保留
