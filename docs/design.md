# 改善提案システム — システム設計書 v10.2

本設計書は以下のファイルに分割されています。タスクに関連するファイルのみを読んでください。

| ファイル | 内容 | 読むタイミング |
|---|---|---|
| [design/overview.md](design/overview.md) | 変更履歴、システム概要、業務フロー、表彰区分、アーキテクチャ | 全体像・業務ルールの確認時 |
| [design/lists.md](design/lists.md) | SharePoint Lists設計（全リスト列定義、マスタ設計、インデックス） | リスト・列・Patch式の実装時 |
| [design/screens.md](design/screens.md) | Power Apps画面設計（申請フォーム、閲覧画面、評価画面、申請状況確認導線） | 画面YAML実装時 |
| [design/flows.md](design/flows.md) | Power Automateフロー設計（3フロー詳細、メールテンプレート、URL設定） | フロー実装時 |
| [design/evaluation.md](design/evaluation.md) | 評価ロジック・自動計算（スコアリング、等級判定、条件分岐） | 評価・褒賞金額ロジック実装時 |
| [design/security.md](design/security.md) | セキュリティ・権限設計、テストモード仕様 | 権限・テストモード関連時 |
| [design/workplan.md](design/workplan.md) | タスクリスト・工数サマリー | 工数見積・計画確認時 |
