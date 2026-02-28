# 改善提案システム（SharePoint + Power Platform）

## プロジェクト概要

業務改善提案の申請→評価→承認ワークフローを SharePoint Lists + Power Apps + Power Automate で構築するプロジェクト。利用規模15,000人。

## 必読ドキュメント

作業を始める前に必ず以下を読むこと。**進捗の把握は `docs/tasks.md` を確認すること。**

- `docs/design.md` — システム設計書v9（リスト設計・画面設計・フロー設計・評価ロジック・テストモード仕様）
- `docs/tasks.md` — 構築タスクリスト（進捗管理）。`[x]`=完了、`[ ]`=未着手。進捗はここが唯一の情報源

## ディレクトリ構成

- `docs/` — 設計書・タスクリスト
- `scripts/` — PnP PowerShellスクリプト（リスト作成・マスタ投入）。**クライアント環境の再構築に必要なファイルのみ配置**
- `scripts/develop/` — 開発時のみ使うスクリプト（パッチ・マイグレーション等）。クライアント納品対象外
- `powerapps/` — Power Fxコード・YAML定義（再現可能な手順書として保存）
- `refs/` — 参考資料（人事サンプルデータ・設計Excel）

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

### YAML記法ルール（Code Viewコピペ用）
- フォーマット: `- ControlName:` から始まる配列形式
- コントロール指定: `Control: Button@0.0.44` 形式
- プロパティ値: すべて `=` で始まるPower Fx式
- `#` や `:` を含む式: マルチライン（`|`）必須
- App ObjectはCode View不可（プロパティパネルで設定）
- **Galleryテンプレート内のレイアウト**: `X` プロパティはCode Viewペースト時に無視されるため、テンプレート直下にHorizontal AutoLayoutコンテナ（`GroupContainer@1.4.0`）を配置し、子コントロールを `FillPortions` / `Width` で並べること。X座標の固定値指定よりAutoLayoutコンテナを常に優先する
- モダンButton（Button@0.0.45）には `Size` プロパティがない（フォントサイズ指定不可）
- モダンTextInput（TextInput@0.0.54）には `Format` プロパティがない（数値フォーマット指定不可）。数値入力が必要な場合は `Value()` 関数で変換
- モダンTextInput（TextInput@0.0.54）には `Default` プロパティがない（Code View YAML非対応）。デフォルト値を設定するにはプロパティパネルで `Value` に数式を設定する
- Gallery はクラシックコントロール（Gallery@2.15.0）。モダンコントロールと混在OK

### Code View エクスポート時の注意（ラウンドトリップ差分）
手書きYAMLをCode Viewにペーストし、再度エクスポートすると以下の差分が発生する:
- **コメント消失**: `# ---` 等のYAMLコメントはCode Viewに保存されない（gitでの参照用としてのみ有効）
- **コントロール順序変更**: コンテナ内の子コントロールの表示順がCode View側で再配置される場合がある
- **プロパティ値のマルチライン化**: 単純な `Width: =400` が `Width: |` + `=400` 形式に変換される場合がある
- **デフォルト値プロパティの省略**: デフォルト値と一致するプロパティ（例: ButtonのHeight）はエクスポートに含まれない場合がある
- **運用ルール**: git管理ファイルはCode Viewエクスポート結果を正とする。手書きコメントはヘッダー部分のみ付与

### モダンコントロールのプロパティ名（クラシックとの違い）
- モダンTextInput（TextInput@0.0.54）: `.Value`（クラシックは `.Text`）
- モダンDropDown（DropDown@0.0.45）: `.Selected` + DropDownDataField子コントロール
- モダンDatePicker（DatePicker@0.0.46）: `.SelectedDate`
- モダンButton（Button@0.0.45）: `.OnSelect`, `.DisplayMode`
- モダンRadio（Radio@0.0.25）: Code Viewで `Default` / `Size` プロパティは非対応。デフォルト値はプロパティパネルで `Value` に数式を設定する
- モダンToggle（Toggle@1.1.5）: `.Checked`（true/false）。クラシックToggleの `.Value` とは異なるので注意。バージョンも 0.0.x 系ではなく 1.1.x 系

## コード同期ルール（重複ロジック）

以下のファイルは同一のロジックを含む。片方を変更したら必ずもう片方も同期すること。

| ロジック | ファイル1（参照用） | ファイル2（実動作） |
|---|---|---|
| 提出処理（メインPatch + メンバー + 分野実績） | `powerapps/submit-logic.pfx` | `powerapps/screen-application-form.yaml` の `btnSubmit.OnSelect` |

- `submit-logic.pfx` はgit管理・差分レビュー用の参照ファイル
- `screen-application-form.yaml` の `btnSubmit.OnSelect` が実際にPower Appsで動作するコード
- **列追加・Patch項目変更時は必ず両方を更新すること**

## 回答スタイル

- 技術的に問題がある場合は忖度せず率直に指摘すること
- 曖昧な表現を避け、問題点は明確に説明すること
- 「できません」「おすすめしません」が適切なら遠慮なく言うこと
