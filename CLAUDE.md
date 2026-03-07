# 改善提案システム（SharePoint + Power Platform）

## プロジェクト概要

業務改善提案の申請→評価→承認ワークフローを SharePoint Lists + Power Apps + Power Automate で構築するプロジェクト。利用規模15,000人。

## 必読ドキュメント

作業を始める前に必ず以下を読むこと。**進捗の把握は `docs/tasks.md` を確認すること。**

- `docs/design.md` — システム設計書v9（リスト設計・画面設計・フロー設計・評価ロジック・テストモード仕様）
- `docs/tasks.md` — 構築タスクリスト（進捗管理）。`[x]`=完了、`[ ]`=未着手。進捗はここが唯一の情報源

## 実践知見ファイル（タスク着手前に該当ファイルを必ず読むこと）

| ファイル | 内容 | 読むタイミング |
|---|---|---|
| `knowledge/powerapps.md` | YAML記法、コントロール、Code View制限、SP列名 | Power Apps画面タスク着手時 |
| `knowledge/automate.md` | フロー設計、Power Apps連携パターン | Power Automateフロー関連タスク着手時 |

**ルール**: 上記ファイルに該当するタスクに着手する際は、実装を始める前に該当ファイルをReadすること。知見を読まずに実装を開始してはならない。

## ディレクトリ構成

- `docs/` — 設計書・タスクリスト
- `knowledge/` — Power Platform実践知見（プロジェクト横断で再利用可能なナレッジ）
- `scripts/` — PnP PowerShellスクリプト（リスト作成・マスタ投入）。**クライアント環境の再構築に必要なファイルのみ配置**
- `scripts/develop/` — 開発時のみ使うスクリプト（パッチ・マイグレーション等）。クライアント納品対象外
- `powerapps/` — Power Fxコード・YAML定義（再現可能な手順書として保存）
- `powerautomate/` — Power Automateフロー設計書・メールHTMLテンプレート
- `docs/refs/` — 参考資料（人事サンプルデータ・設計Excel）
- `docs/pdf/` — 参考PDF資料

### scripts/ の配置ルール

- **`scripts/` 直下**: 新規環境を一から構築するためのスクリプト。常に最新の設計書仕様に準拠。これだけでクライアント環境を再現できる状態を維持する（例: `create-lists.ps1`, `import-masters.ps1`）
- **`scripts/develop/`**: 開発中の既存環境に差分を適用するパッチスクリプト。既存テーブルの削除+再作成を含む場合がある（例: `patch-update-category-01.ps1`, `patch-v92-evaluation-data.ps1`）

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

## コード同期ルール（重複ロジック）

以下のファイルは同一のロジックを含む。片方を変更したら必ずもう片方も同期すること。

| ロジック | ファイル1（参照用） | ファイル2（実動作） |
|---|---|---|
| 提出処理（メインPatch + メンバー + 分野実績） | `powerapps/submit-logic.pfx` | `powerapps/screen-application-form.yaml` の `btnSubmit.OnSelect` |

- `submit-logic.pfx` はgit管理・差分レビュー用の参照ファイル
- `screen-application-form.yaml` の `btnSubmit.OnSelect` が実際にPower Appsで動作するコード
- **列追加・Patch項目変更時は必ず両方を更新すること**

## 知見蓄積ルール（トライ&エラーの記録）

実装中に初期提案と最終解決策が異なった場合、**コミット時点で以下を必ず実施すること**:

1. **実装中**: 初期提案の内容と、トライ&エラーで発見した差分をメモリ（MEMORY.md）に記録
2. **コミット時**: 初期提案 → 最終解決策の差分を分析し、該当する知見ファイル（`knowledge/*.md`）に追記する
3. **対象**: Power Appsの挙動の違い、Power Automate連携のハマりどころ、YAML Code Viewの制限事項など、公式ドキュメントだけでは分からない実践的な知見
4. **目的**: 同じ失敗を繰り返さず、効率的に進めるためのナレッジベース構築

**ユーザーへの確認は不要** — 知見がある場合はコミット時に自動的に知見ファイル追記まで行うこと。

## YAML出力前セルフチェック（必須）

Power Apps YAMLを生成・編集したら、**ユーザーに提示する前に**以下を自己確認すること。1つでも該当したら修正してから提示する。

### 構造チェック
- [ ] プロパティ値はすべて `=` で始まっているか（`Width: =400` であり `Width: 400` ではない）
- [ ] `#` や `:` を含む式はマルチライン（`|`）にしているか
- [ ] インデントは2スペースの倍数か（タブ文字は禁止）
- [ ] `Control:`, `Properties:`, `Children:`, `Variant:` はYAML構造キーであり `=` 不要

### Gallery直下コンテナ（最頻出バグ）
- [ ] Gallery（`Gallery@2.15.0`）直下のコンテナに `Width: =Parent.TemplateWidth` を明示しているか
- [ ] `Width: =1` や `FillPortions: =1` になっていないか（Gallery直下では効かず1pxになる）
- [ ] `Height: =Parent.TemplateHeight` を明示しているか

### モダンコントロールのプロパティ制限
- [ ] `Button@0.0.45` に `Size` プロパティを使っていないか（フォントサイズ指定不可）
- [ ] `TextInput@0.0.54` に `Default` / `Format` を使っていないか（Code View非対応）
- [ ] `TextInput@0.0.54` のテキスト取得は `.Value` か（クラシックの `.Text` ではない）
- [ ] `Toggle@1.1.5` の値取得は `.Checked` か（クラシックの `.Value` ではない）
- [ ] `Radio@0.0.25` の `Layout` は `='RadioGroupCanvas.Layout'.Horizontal` か（`=Layout.Horizontal` は無視される）

### AutoLayoutコンテナ
- [ ] AutoLayoutコンテナ内の子で固定幅にしたい場合、`AlignInContainer: =AlignInContainer.Center` を設定しているか（デフォルトはStretchで引き伸ばされる）

### コード同期
- [ ] `btnSubmit.OnSelect` を変更した場合、`submit-logic.pfx` も同期したか

## 回答スタイル

- 技術的に問題がある場合は忖度せず率直に指摘すること
- 曖昧な表現を避け、問題点は明確に説明すること
- 「できません」「おすすめしません」が適切なら遠慮なく言うこと
