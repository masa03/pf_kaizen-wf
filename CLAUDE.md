# 改善提案システム（SharePoint + Power Platform）

## プロジェクト概要

業務改善提案の申請→評価→承認ワークフローを SharePoint Lists + Power Apps + Power Automate で構築するプロジェクト。利用規模15,000人。

## 新規セッション開始時の確認手順

新しい会話を始めたら、以下の順でプロジェクト状況を把握すること。

1. **CLAUDE.md**（本ファイル）— 自動読み込み。プロジェクト構成・ルールの把握
2. **MEMORY.md** — 直近の作業状況・引き継ぎ事項・注意点の確認
3. **`docs/tasks.md`** — 実装タスクの進捗（`[x]`=完了、`[ ]`=未着手）
4. **`docs/backlog.md`** — 要件のステータス（検討中/開発中/完了）
5. **`docs/changes/`** — 開発中の変更提案があれば、該当する proposal.md を確認

ユーザーが「続きをやりたい」「次のタスクは？」と言った場合は、上記2〜5を確認してから回答すること。

## ドキュメント体系

OpenSpecの概念に基づき、**確定仕様（spec/）** と **変更提案（changes/）** を分離管理している。

### ワークフロー

```
1. ミーティングで要件決定 → backlog.md【検討中】に詳細を記述
2. 「§Xの変更提案を作成して」→ changes/v2-xxx/ にproposal.md作成
   backlog.md では【開発中】にタイトル+リンクだけ残す
3. 実装完了 → proposal.md の内容を spec/ の各ファイルに分配マージ
   changes/archive/ に原本保存、backlog.md では【完了】に移動
```

### 確定仕様（実装済み機能）

仕様書は `docs/spec/` 配下にセクション分割されている。**全文を一括で読まず、タスクに関連するファイルだけを読むこと。**

| ファイル | 内容 | 読むタイミング |
|---|---|---|
| `docs/spec/index.md` | **目次（インデックス）** | 分割ファイルの一覧確認 |
| `docs/spec/overview.md` | 変更履歴、システム概要、業務フロー、表彰区分、アーキテクチャ | 全体像・業務ルールの確認時 |
| `docs/spec/lists.md` | SharePoint Lists設計（全リスト列定義、マスタ設計、インデックス） | リスト・列・Patch式の実装時 |
| `docs/spec/screens.md` | Power Apps画面設計（申請フォーム、閲覧画面、評価画面、申請状況確認導線） | 画面YAML実装時 |
| `docs/spec/flows.md` | Power Automateフロー設計（3フロー詳細、メールテンプレート、URL設定） | フロー実装時 |
| `docs/spec/evaluation.md` | 評価ロジック・自動計算（スコアリング、等級判定、条件分岐） | 評価・褒賞金額ロジック実装時 |
| `docs/spec/security.md` | セキュリティ・権限設計、テストモード仕様 | 権限・テストモード関連時 |
| `docs/spec/workplan.md` | タスクリスト・工数サマリー | 工数見積・計画確認時 |

### 要件バックログ・変更提案

| ファイル/ディレクトリ | 内容 | 役割 |
|---|---|---|
| `docs/backlog.md` | 要件バックログ（検討中/開発中/完了の3セクション） | 追加要件のインテーク・ステータス管理 |
| `docs/changes/` | 変更提案（機能単位のフォルダ） | 各機能のproposal.md + tasks.md |
| `docs/changes/archive/` | 完了した変更提案の原本 | 経緯の記録 |

### 変更提案（proposal.md）の構成

proposal.md は1ファイルに要件+詳細設計を全部書く。マージ時にspec/の各ファイルに分配する。

```markdown
# 機能名

## 概要
## リスト設計          ← → spec/lists.md
## 画面設計            ← → spec/screens.md
## フロー設計          ← → spec/flows.md
## 評価ロジック        ← → spec/evaluation.md（該当する場合）
```

### その他の必読ドキュメント

- `docs/layout-design.md` — 画面レイアウト設計書（各画面のセクション配置・画像表示・評価結果表示仕様）
- `docs/tasks.md` — 構築タスクリスト（進捗管理）。`[x]`=完了、`[ ]`=未着手。進捗はここが唯一の情報源

### 環境移行手順

- `a_project/migration/deployment-guide.md` — 新環境への移植・デプロイ手順書
- `a_project/migration/ui-manual-2-7.md` — Power Apps Studio手作業手順書

**ルール**: 新機能の実装で移行手順に影響がある場合（特にPower Automateフローの手作業手順）、`a_project/migration/` 配下の該当ファイルに追記すること。

## 専門エージェント（.claude/agents/）

品質向上のために、以下の専門エージェントを使い分ける。

| エージェント | ファイル | 用途 | 起動タイミング |
|---|---|---|---|
| **proposal-writer** | `.claude/agents/proposal-writer.md` | backlog → 変更提案作成（整合性確認・曖昧点質問・mermaid図） | 「§Xの変更提案を作成して」 |
| **spec-reviewer** | `.claude/agents/spec-reviewer.md` | 提案/成果物 vs 既存仕様の整合性レビュー | 提案完成後 or 成果物完成後 |
| **client-report** | `.claude/agents/client-report.md` | 顧客向けドキュメント生成（進捗・設計概要・mermaid中心） | 「進捗レポートを作成して」「○○の概要資料を作って」 |

### 開発ワークフローでのエージェント活用

```
1. backlog検討項目の決定
   ↓
2. 「§Xの変更提案を作成して」
   → proposal-writer (pass=analyze): 整合性分析 + 質問リスト返却
   ↓
3. メインエージェントがユーザーに質問を提示 → ユーザーが回答
   ↓
4. proposal-writer (pass=create): 回答を反映して proposal.md 作成
   ↓
5. proposal完成 → spec-reviewer (mode=proposal) で整合性レビュー
   ↓
6. レビュー指摘の修正 → 実装開始
   ↓
7. 成果物完成 → spec-reviewer (mode=deliverable) で成果物レビュー
   ↓
8. レビュー通過 → コミット（知見蓄積は既存ルールでメインエージェントが対応）
   ↓
9. 必要に応じて client-report で顧客向け資料生成
```

### proposal-writer の2パス方式

proposal-writerは**analyzeパス（分析）→ ユーザー回答 → createパス（作成）**の2段階で動作する。
メインエージェントは以下の手順で起動すること:

1. `pass=analyze` でサブエージェントを起動。質問リストが返る
2. 質問リストをユーザーに提示し、回答を受け取る
3. `pass=create` でサブエージェントを起動。ユーザーの回答をプロンプトに含める
4. 作成された proposal.md の結果をユーザーに報告

**重要**: analyzeパスで質問が0件（曖昧点なし）の場合でも、その旨をユーザーに報告してからcreateパスに進むこと。

### 起動方法

メインエージェントが上記タイミングを検知して自動的にサブエージェントを起動する。
ユーザーが明示的に指示する場合の例:

- 「§2の変更提案を作成して」→ proposal-writer (pass=analyze → create) 起動
- 「このproposalをレビューして」→ spec-reviewer (mode=proposal) 起動
- 「YAMLの整合性チェックして」→ spec-reviewer (mode=deliverable) 起動
- 「進捗レポートを作って」→ client-report (type=progress) 起動
- 「回覧者機能の概要資料を作って」→ client-report (type=feature) 起動
- 「システム全体の概要資料を作って」→ client-report (type=overview) 起動

## 実践知見ファイル（タスク着手前に該当ファイルを必ず読むこと）

| ファイル | 内容 | 読むタイミング |
|---|---|---|
| `knowledge/powerapps.md` | YAML記法、コントロール、Code View制限、SP列名 | Power Apps画面タスク着手時 |
| `knowledge/automate.md` | フロー設計、Power Apps連携パターン | Power Automateフロー関連タスク着手時 |

**ルール**: 上記ファイルに該当するタスクに着手する際は、実装を始める前に該当ファイルをReadすること。知見を読まずに実装を開始してはならない。

## ディレクトリ構成

- `docs/spec/` — 確定仕様書（実装済み機能、セクション分割）
- `docs/backlog.md` — 要件バックログ（検討中/開発中/完了）
- `docs/changes/` — 変更提案（開発中の機能単位フォルダ）
- `docs/changes/archive/` — 完了した変更提案の原本保存
- `knowledge/` — Power Platform実践知見（プロジェクト横断で再利用可能なナレッジ）
- `scripts/` — PnP PowerShellスクリプト（リスト作成・マスタ投入）。**クライアント環境の再構築に必要なファイルのみ配置**
- `scripts/develop/` — 開発時のみ使うスクリプト（パッチ・マイグレーション等）。クライアント納品対象外
- `powerapps/` — Power Fxコード・YAML定義（再現可能な手順書として保存）
- `powerautomate/` — Power Automateフロー設計書・メールHTMLテンプレート
- `a_project/` — プロジェクト管理（TODO・参考資料）
- `a_project/migration/` — 環境移行手順書（デプロイガイド・UI手作業手順）
- `docs/refs/` — 参考資料（人事サンプルデータ・設計Excel）
- `docs/pdf/` — 参考PDF資料

### scripts/ の配置ルール

- **`scripts/` 直下**: 新規環境を一から構築するためのスクリプト。常に最新の設計書仕様に準拠。これだけでクライアント環境を再現できる状態を維持する（例: `create-lists.ps1`, `import-masters.ps1`）
- **`scripts/develop/`**: 開発中の既存環境に差分を適用するパッチスクリプト。既存テーブルの削除+再作成を含む場合がある（例: `patch-update-category-01.ps1`, `patch-v92-evaluation-data.ps1`）

## 開発方針

- **コードベース最大化 / UI操作は最小限**: SharePointリスト作成やマスタ投入はPnP PowerShellスクリプトで実行
- **Power Apps YAML**: Code Viewフォーマットで `powerapps/` に保存、git管理。本番環境でも同じコードで再現可能
- **Power Apps YAMLに環境依存値を書かない**: URL・AppID・サイトアドレス等はハードコードせず、`gSharePointSiteUrl` 等の変数経由で参照すること。YAMLファイルは環境移行時に書き換え不要な状態を維持する
- **PnPスクリプト・メールHTMLテンプレート等**: 必要に応じてgit管理

## Power Automateフロー構築手順書のルール

フロー構築手順書は `powerautomate/flow-{name}-build.html` のHTMLファイルで作成する。mdファイルは設計書（仕様・設計意図の記述）、htmlファイルは構築手順書（実際の操作手順・コピペ用式）として分離する。

### HTMLファイルの規則

- 既存の `flow-upload-attachment-build.html` のスタイル・構造を踏襲する
- 式（関数）は **`@{expression}` 形式** で記述し、コピーボタンを配置する
  - 例: `@{triggerBody()['StagingBeforeID']}`
  - コピーボタンで改行なしにクリップボードへコピーできるようにする
- ドロップダウン選択など式でない項目はコピーボタン不要（`.plain` テキストで記述）
- アクション名（日本語）は日本語表記を先に書き、英語名をカッコで添える
  - 例: 「添付ファイルの取得（Get attachments V2）」
- 1フロー = 1HTMLファイル。ファイル名: `flow-{kebab-case-name}-build.html`

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

## 標準パーツ用語

ユーザーが以下の用語で指示した場合、`knowledge/powerapps.md` の該当テンプレートを参照して適用すること。

| 用語 | 内容 | 知見ファイルのセクション |
|---|---|---|
| **プレビューラベル値パーツ** | 読み取り専用の「項目名＋値」行。ラベル＋値コンテナ（値テキスト＋下線）の構造 | `プレビューラベル値パーツ（読み取り専用の項目名＋値パーツ）` |
| **アンダーラインパーツ** | Gallery行用のシャドウなし＋アンダーライン付きコンテナ。コンテンツ行＋下線コンテナの構造 | `アンダーラインパーツ（Gallery行の標準パーツ）` |

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
