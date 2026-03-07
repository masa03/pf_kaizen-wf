# 改善提案システム 構築TODOリスト

**現在の環境**: テスト環境を構築中（Power Platformアカウント1つ: m.kato@...）
**基準設計書**: 改善提案システム_設計書v9
**方針**: コードベース最大化 / UI操作は最小限
**作成日**: 2026-02-20

---

## フェーズ1: 基盤構築（SharePoint Lists）

- [x] **1-1** SharePointサイト作成 `[UI]`
  - 改善提案システム用サイトコレクション作成
  - 手作業（1回限り、スクリプト化不要）
- [x] **1-2** 全リスト＋列定義の一括作成 `[PnP PowerShell]`
  - 改善提案メイン / 改善メンバー / 改善分野実績 / 評価データ（4リスト）
  - 社員マスタ / 改善分野マスタ / 表彰区分マスタ（3リスト）
  - ★ 承認履歴リスト（提案プラン、任意）
  - → `scripts/create-lists.ps1`
- [x] **1-3** インデックス作成 `[PnP PowerShell]`
  - 社員マスタ: GID, Email, IsActive
  - 改善提案メイン: Status, ApplicantEmail, ApproverManager, ApproverDirector
  - 評価データ: RequestID, EvaluatorType
  - 改善メンバー: RequestID
  - 改善分野実績: RequestID
  - → `scripts/create-lists.ps1`（リスト作成と同一スクリプト内）
- [x] **1-4** マスタデータ投入（社員マスタ） `[PnP PowerShell + CSV]`
  - 人事マスタ15,000件 → CSVマッピング → インポート
  - 人事部門との連携・データ受領
  - テスト環境: `scripts/test_employees.csv` のデータをSharePoint Lists（社員マスタ）に投入済み
  - → `scripts/import-employees.ps1` + `scripts/test_employees.csv`
- [x] **1-5** マスタデータ投入（改善分野・表彰区分） `[PnP PowerShell]`
  - 改善分野マスタ 14件
  - 表彰区分マスタ 4件（KZ/PL/CU/SV）
  - テスト環境: SharePoint Listsに投入済み
  - → `scripts/import-masters.ps1`
- [x] **1-6** ドキュメントライブラリ作成 `[PnP PowerShell]`
  - 添付ファイル用ライブラリ
  - テスト環境: 添付ファイルライブラリ作成済み（RequestID列+インデックス、説明列）
  - → `scripts/create-doclib.ps1`

---

## フェーズ2: Power Apps 開発

- [x] **2-0** キャンバスアプリ作成・データソース接続 `[UI]`
  - アプリ新規作成（タブレット形式）
  - 全リスト（8リスト）をデータソースとして接続済み
- [x] **2-1** 申請フォーム - 左カラム（基本情報） `[YAML / Code View]`
  - Email逆引きGID自動取得
  - 組織情報（TEC/部/課）自動入力
  - 表彰区分プルダウン（マスタ参照）
  - 改善テーマ / 問題点 / 改善内容 / 改善完了日 / 係
  - → `powerapps/screen-application-form.yaml`
- [x] **2-2** 申請フォーム - 右カラム（改善メンバー） `[YAML / Code View]`
  - メンバーGID入力ギャラリー
  - 社員マスタ検索→氏名自動表示
  - 追加/削除ボタン（最大10名）
  - 改善メンバーリストへの登録処理
  - → `powerapps/screen-application-form.yaml`（cntRightColumn部分）
  - → `powerapps/app-onstart.pfx`（colMembers初期化追加）
  - → `powerapps/submit-logic.pfx`（ForAll→改善メンバーPatch）
- [x] **2-3** 改善分野実績テーブル `[YAML / Code View]`
  - 分野追加プルダウン（マスタ参照、追加済み除外フィルタ、テキスト型含む全分野統一UI）
  - 分野種別に応じた入力フォーム（金額算出型/直接入力型/テキスト型）
  - 効果金額自動算出（リアルタイムプレビュー、リードタイム短縮の仕掛り金額対応）
  - 合計の自動計算
  - テキスト型3分野（6S・ヒューマンエラー/環境/その他効果）もプルダウンから選択→テキスト入力
  - メインPatch統合（改善提案メイン + 改善メンバー + 改善分野実績の一括登録）
  - → `powerapps/screen-application-form.yaml`（cntCategorySection部分）
  - → `powerapps/app-onstart.pfx`（colCategories初期化追加）
  - → `powerapps/submit-logic.pfx`（メインPatch統合 + ForAll→改善分野実績Patch）
- [x] **`[update_category_01]`** 改善分野実績に換算単価（ConversionRate）列を追加
  - 改善分野実績リストに ConversionRate 列を追加（`scripts/create-lists.ps1`）
  - submit-logic.pfx の ForAll Patch に `ConversionRate: ThisRecord.ConversionRate` を追加
  - 金額算出型: マスタの換算単価を申請時スナップショットとして保存
  - EffectAmountは従来通り保存（集計・フロー参照用に併存）
- [x] **2-4** 申請内容閲覧画面 `[YAML / Code View]`
  - 読取専用表示（プレビュー / 登録後閲覧 / 承認時確認の3用途）
  - 改善分野実績一覧・メンバー一覧のデータテーブル
  - 添付ファイルリンク表示（2-7実装後に対応予定、プレースホルダー配置済）
  - ステータスバッジ（色分け対応）
  - → `powerapps/screen-view.yaml`
  - → `powerapps/app-onstart.pfx`（colViewCategories/colViewMembers初期化追加）
  - → `powerapps/screen-application-form.yaml`（btnPreview.OnSelect追加）
- [x] **`[v9.3]`** 申請者在籍事業所・原価単位のスナップショット保存 + 閲覧画面委任警告修正
  - 改善提案メインに ApplicantOffice / ApplicantCostUnit 列追加（`scripts/create-lists.ps1`）
  - submit-logic.pfx / screen-application-form.yaml の Patch に `gCurrentEmployee.Office` / `.CostUnit` を追加
  - 閲覧画面から在籍事業所・原価単位の表示を削除（社員マスタ LookUp 不要に）
  - 閲覧画面の ForAll(Filter(...)) を ClearCollect + ForAll に分離（委任警告解消）
  - → `scripts/develop/patch-add-applicant-office.ps1`（既存環境パッチ）
- [x] **2-5** 評価画面（課長/部長共通） `[YAML / Code View]`
  - 閲覧画面を上部に組込
  - 4軸ラジオボタン（8択×4軸）
  - ①効果: 金額算定スイッチ + 金額目安表示
  - スコアリング自動計算（素点→職能換算→等級→褒賞金額）
  - 表彰区分スキップ（パール/銅/銀時はスコアリング非表示）
  - 部長評価時: 課長データをデフォルト値表示
  - 承認/差戻ボタン
  - おすすめ情報トグル（IsRecommended）
  - テストモードヘッダー（RequestID入力 + 評価者種別切替）
  - → `powerapps/screen-evaluation.yaml`
  - → `powerapps/app-onstart.pfx`（評価画面用変数初期化追加）
- [x] **2-6** 確認ポップアップ `[YAML / Code View]`
  - 提出 / 承認 / 差戻 の確認ダイアログ
  - フラグ変数（varConfirmed）+ Select()再トリガーパターンで実装
  - 半透明オーバーレイ + 白背景ダイアログ（Screen直下に配置、z-orderで前面表示）
  - → `powerapps/screen-application-form.yaml`（cntConfirmOverlay + btnSubmit Ifラップ）
  - → `powerapps/screen-evaluation.yaml`（cntEvalConfirmOverlay + btnEvalApprove/btnEvalReject Ifラップ）
  - → `powerapps/submit-logic.pfx`（同期ルールに従いIfラップ適用）
  - → `powerapps/app-onstart.pfx`（varShowConfirmPopup/varConfirmAction/varConfirmed初期化）
- [x] **2-7** 添付ファイルコントロール `[YAML / UI / Power Automate]`
  - 方式: ドキュメントライブラリ + Power Automateフロー
  - 申請フォーム添付ファイルセクション（galAttachments + cntAttachmentButtonArea）
  - 提出ロジック Step 3.5: ForAllでPower Automateフロー呼び出し
  - 閲覧画面・評価画面: ドキュメントライブラリからRequestIDでFilter → リンク一覧表示
  - → `powerapps/screen-application-form.yaml`（cntAttachmentSection + btnSubmit更新）
  - → `powerapps/submit-logic.pfx`（Step 3.5追加 + 同期）
  - → `powerapps/app-onstart.pfx`（colAttachments/colViewAttachments初期化）
  - → `powerapps/screen-view.yaml`（cntViewAttachment実装）
  - → `powerapps/screen-evaluation.yaml`（cntEvalViewAttachment実装）
  - → `powerautomate/flow-upload-attachment.md`（Power Automateフロー設計書）
  - → `docs/ui-manual-2-7.md`（UI手作業手順書）
  - **UI手作業**: AddMediaButton配置 + Power Automateフロー構築 + データソース接続（手順書参照）
- [x] **2-8** グローバルロジック設定 `[Power Fx]`
  - App.OnStart: テストモード切替 + ログインユーザー情報取得
  - 社員マスタLookUp（Email→GID→組織情報）
  - グローバル変数定義（gTestMode, gCurrentEmployee, gCurrentGID 等）
  - → `powerapps/app-onstart.pfx`
- [ ] ★ **2-9** ホーム画面（提案プラン） `[YAML / Code View]`
  - 自分の申請一覧ギャラリー
  - 承認待ち一覧ギャラリー
  - ステータスフィルタ / 期間フィルタ
- [ ] ★ **2-10** 管理者画面（提案プラン） `[YAML / Code View]`
  - マスタCRUD
  - 全件閲覧・エクスポート

---

## フェーズ3: Power Automate 開発

- [x] **3-1** 申請通知フロー `[UI + 式コード提供]`
  - トリガー: Lists項目作成時（ステータス=申請中）
  - 課長=申請者の場合は部長へ送信の分岐（ApplicantEmail == ApproverManager/Email で判定）
  - 課長へ承認依頼メール送信
  - → `powerautomate/flow-notification-submit.md`（フロー設計書）
  - → `powerautomate/templates/3-1_申請通知_承認依頼.html`（承認依頼メールテンプレート）
- [x] **3-2** 課長承認フロー `[UI + 式コード提供]`
  - トリガー: 評価データ作成/変更時（評価者種別=課長 AND 判定≠空）
  - メインリスト取得（RequestIDでFilter）→ 承認/差戻分岐
  - 承認: 褒賞金額 ≥ 5,000円 → ステータス「部長評価中」+ 部長通知 / < 5,000円 → ステータス「承認済」+ FinalRewardAmount転記 + 完了メール
  - 差戻: ステータス「差戻」+ NG通知メール
  - 表彰区分スキップ対応（RewardAmountの値のみで分岐、特別処理不要）
  - → `powerautomate/flow-approval-manager.md`（フロー設計書）
  - → `powerautomate/templates/3-2_課長承認_差戻通知.html`（差戻通知メールテンプレート）
  - → `powerautomate/templates/3-2_課長承認_承認完了.html`（承認完了メールテンプレート）
  - → `powerautomate/templates/3-2_課長承認_部長へ承認依頼.html`（部長への承認依頼メールテンプレート）
- [x] **3-3** 部長承認フロー `[UI + 式コード提供]`
  - トリガー: 評価データ変更時（評価者種別=部長 AND 判定≠空）
  - 承認: FinalRewardAmount上書き転記 + 完了メール
  - 差戻: NG通知
  - → `powerautomate/flow-approval-director.md`（フロー設計書）
  - → `powerautomate/templates/3-3_部長承認_承認完了.html`（承認完了メールテンプレート）
  - → `powerautomate/templates/3-3_部長承認_差戻通知.html`（差戻通知メールテンプレート）
- [x] **3-4** メールテンプレート作成 `[HTMLテンプレート提供]`
  - [x] 承認依頼メール → `powerautomate/templates/3-1_申請通知_承認依頼.html`
  - [x] NG通知（差戻）メール → `powerautomate/templates/3-2_課長承認_差戻通知.html`
  - [x] 承認完了メール（申請者+承認者宛） → `powerautomate/templates/3-2_課長承認_承認完了.html`
  - [x] 部長承認完了メール → `powerautomate/templates/3-3_部長承認_承認完了.html`
  - [x] 部長差戻通知メール → `powerautomate/templates/3-3_部長承認_差戻通知.html`
- [ ] ★ **3-5** 取下げ通知フロー（提案プラン） `[UI + 式コード提供]`
  - 取下げ時の承認者通知
- [ ] ★ **3-6** リマインダーフロー（提案プラン） `[UI + 式コード提供]`
  - 日次スケジュール
  - 承認期限5日超過チェック
  - 督促メール送信

---

## フェーズ4: テスト・調整

- [ ] **4-1** テストデータ準備 `[スクリプト]`
  - テスト用社員マスタ投入（課長/部長/一般/管理職の各パターン）
  - テスト用改善分野データ
- [ ] **4-2** 結合テスト
  - [ ] 通常申請→課長承認→完了（< 5,000円）
  - [ ] 通常申請→課長承認→部長承認→完了（≥ 5,000円）
  - [ ] 表彰区分 小集団 パール賞（3等）（スコアリングスキップ、3,000円固定）
  - [ ] 表彰区分 小集団 銅賞（2等）（スコアリングスキップ、5,000円→部長承認）
  - [ ] 表彰区分 小集団 銀賞（1等）（スコアリングスキップ、10,000円→部長承認）
  - [ ] 課長=申請者（課長承認スキップ→部長が第1承認者）
  - [ ] 差戻→修正→再提出（前回評価データ参考表示）
  - [ ] FinalRewardAmount転記確認（課長のみ / 部長上書き）
  - [ ] 管理職の職能換算（×0.85）
  - [ ] メンバー10名登録
  - [ ] 改善分野複数追加・効果金額合計
  - [ ] 添付ファイル複数アップロード
- [ ] **4-3** メール通知テスト
  - [ ] 承認依頼メール（課長宛 / 部長宛）
  - [ ] NG通知メール（差戻時）
  - [ ] 承認完了メール（申請者+承認者宛）
- [ ] **4-4** 権限設計・適用 `[PnP PowerShell]`
  - サイト権限設定
  - リスト権限設定（マスタ: 管理者のみ編集、他は読取）
  - アイテムレベル権限の確認
  - テスト用追加アカウント準備（一般ユーザー権限）
  - スクリプト: `scripts/set-permissions.ps1`
- [ ] **4-5** ユーザーテスト
  - 実ユーザーによる操作確認
- [ ] **4-6** 修正・調整
  - テストで発見した不具合修正
- [ ] ★ **4-7** 追加画面・フローテスト（提案プラン）
  - ホーム画面 / 管理者画面
  - 取下げフロー / リマインダーフロー

---

## コード管理メモ

- **PnPスクリプト**: `scripts/` に保存、git管理
- **Power Apps YAML / Power Fx**: `powerapps/` に `.yaml` / `.pfx` ファイルとして保存、git管理
- **メールHTMLテンプレート**: 必要に応じてgit管理
- 各タスクの完了時に使用したスクリプト/コードへのリンクを `→` で記載
- 本番環境構築時は同じファイルを参照して再現可能

---

## 工数目安（v9設計書準拠）

| プラン | 工数 | 期間 |
|---|---|---|
| シンプルプラン | 11.75日 | 約2.5週間 |
| シンプル＋提案プラン | 15.75日 | 約3週間 |

> ※ 1名作業想定。マスタデータ準備状況により変動あり。
