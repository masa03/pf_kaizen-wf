# 改善提案システム（SharePoint + Power Platform）

## プロジェクト概要

業務改善提案の申請→評価→承認ワークフローを SharePoint Lists + Power Apps + Power Automate で構築するプロジェクト。利用規模15,000人。

## 必読ドキュメント

作業を始める前に必ず以下を読むこと。**進捗の把握は `docs/tasks.md` を確認すること。**

- `docs/design.md` — システム設計書v9（リスト設計・画面設計・フロー設計・評価ロジック・テストモード仕様）
- `docs/tasks.md` — 構築タスクリスト（進捗管理）。`[x]`=完了、`[ ]`=未着手。進捗はここが唯一の情報源

## ディレクトリ構成

- `docs/` — 設計書・タスクリスト
- `scripts/` — PnP PowerShellスクリプト（リスト作成・マスタ投入）
- `powerapps/` — Power Fxコード・YAML定義（再現可能な手順書として保存）
- `refs/` — 参考資料（人事サンプルデータ・設計Excel）

## 開発方針

- **コードベース最大化 / UI操作は最小限**: SharePointリスト作成やマスタ投入はPnP PowerShellスクリプトで実行
- **Power Apps YAML**: Code Viewフォーマットで `powerapps/` に保存、git管理。本番環境でも同じコードで再現可能
- **PnPスクリプト・メールHTMLテンプレート等**: 必要に応じてgit管理

## Power Apps 開発リファレンス

### YAML ソースコード
- pa.yaml 仕様: https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/power-apps-yaml
- Code View 機能: https://learn.microsoft.com/en-us/power-platform/release-plan/2024wave1/power-apps/save-canvas-applications-as-human-readable-yaml-files

### Power Fx（数式言語）
- 概要: https://learn.microsoft.com/en-us/power-platform/power-fx/overview
- 数式リファレンス: https://learn.microsoft.com/en-us/power-platform/power-fx/formula-reference-overview
- Canvas Apps 関数リファレンス: https://learn.microsoft.com/en-us/power-platform/power-fx/formula-reference-canvas-apps

### YAML記法ルール（Code Viewコピペ用）
- フォーマット: `- ControlName:` から始まる配列形式
- コントロール指定: `Control: Button@0.0.44` 形式
- プロパティ値: すべて `=` で始まるPower Fx式
- `#` や `:` を含む式: マルチライン（`|`）必須
- App ObjectはCode View不可（プロパティパネルで設定）

### モダンコントロールのプロパティ名（クラシックとの違い）
- モダンTextInput（TextInput@0.0.54）: `.Value`（クラシックは `.Text`）
- モダンDropDown（DropDown@0.0.45）: `.Selected` + DropDownDataField子コントロール
- モダンDatePicker（DatePicker@0.0.46）: `.SelectedDate`
- モダンButton（Button@0.0.45）: `.OnSelect`, `.DisplayMode`

## 回答スタイル

- 技術的に問題がある場合は忖度せず率直に指摘すること
- 曖昧な表現を避け、問題点は明確に説明すること
- 「できません」「おすすめしません」が適切なら遠慮なく言うこと
