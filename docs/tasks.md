# 改善提案システム 構築TODOリスト

**現在の環境**: テスト環境を構築中（Power Platformアカウント1つ: m.kato@...）
**基準設計書**: 改善提案システム\_設計書v9
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
  - → `powerautomate/flow-upload-attachment-build.html`（Power Automateフロー構築手順）
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
  - → `powerautomate/flow-notification-submit-build.html`（フロー構築手順）
  - → `powerautomate/templates/3-1_申請通知_承認依頼.html`（承認依頼メールテンプレート）
- [x] **3-2** 課長承認フロー `[UI + 式コード提供]`
  - トリガー: 評価データ作成/変更時（評価者種別=課長 AND 判定≠空）
  - メインリスト取得（RequestIDでFilter）→ 承認/差戻分岐
  - 承認: 褒賞金額 ≥ 5,000円 → ステータス「部長評価中」+ 部長通知 / < 5,000円 → ステータス「承認済」+ FinalRewardAmount転記 + 完了メール
  - 差戻: ステータス「差戻」+ NG通知メール
  - 表彰区分スキップ対応（RewardAmountの値のみで分岐、特別処理不要）
  - → `powerautomate/flow-approval-manager-build.html`（フロー構築手順）
  - → `powerautomate/templates/3-2_課長承認_差戻通知.html`（差戻通知メールテンプレート）
  - → `powerautomate/templates/3-2_課長承認_承認完了.html`（承認完了メールテンプレート）
  - → `powerautomate/templates/3-2_課長承認_部長へ承認依頼.html`（部長への承認依頼メールテンプレート）
- [x] **3-3** 部長承認フロー `[UI + 式コード提供]`
  - トリガー: 評価データ変更時（評価者種別=部長 AND 判定≠空）
  - 承認: FinalRewardAmount上書き転記 + 完了メール
  - 差戻: NG通知
  - → `powerautomate/flow-approval-director-build.html`（フロー構築手順）
  - → `powerautomate/templates/3-3_部長承認_承認完了.html`（承認完了メールテンプレート）
  - → `powerautomate/templates/3-3_部長承認_差戻通知.html`（差戻通知メールテンプレート）
- [x] **3-4** メールテンプレート作成 `[HTMLテンプレート提供]`
  - [x] 承認依頼メール → `powerautomate/templates/3-1_申請通知_承認依頼.html`
  - [x] NG通知（差戻）メール → `powerautomate/templates/3-2_課長承認_差戻通知.html`
  - [x] 承認完了メール（申請者+承認者宛） → `powerautomate/templates/3-2_課長承認_承認完了.html`
  - [x] 部長承認完了メール → `powerautomate/templates/3-3_部長承認_承認完了.html`
  - [x] 部長差戻通知メール → `powerautomate/templates/3-3_部長承認_差戻通知.html`
- [x] ★ **3-5** 取下げ通知フロー（§4） `[UI + 式コード提供]`
  - 取下げ時の承認者通知（Power Appsトリガー / PreviousStatusで通知先分岐）
  - → `powerautomate/flow-cancel-notify-build.html`（フロー構築手順）
  - → `powerautomate/templates/3-4_取下げ通知.html`（メールテンプレート）
- [ ] ★ **3-6** リマインダーフロー（提案プラン） `[UI + 式コード提供]`
  - 日次スケジュール
  - 承認期限5日超過チェック
  - 督促メール送信

---

## フェーズ4: テスト・調整

- [x] **4-1** テストデータ準備 `[スクリプト]`
  - テスト用社員マスタ投入（課長/部長/一般/管理職の各パターン）
  - テスト用改善分野データ
- [x] **4-2** 結合テスト
  - [x] 通常申請→課長承認→完了（< 5,000円）
  - [x] 通常申請→課長承認→部長承認→完了（≥ 5,000円）
  - [x] 表彰区分 小集団 パール賞（3等）（スコアリングスキップ、3,000円固定）
  - [x] 表彰区分 小集団 銅賞（2等）（スコアリングスキップ、5,000円→部長承認）
  - [x] 表彰区分 小集団 銀賞（1等）（スコアリングスキップ、10,000円→部長承認）
  - [x] 課長=申請者（課長承認スキップ→部長が第1承認者）
  - [x] 差戻→修正→再提出（前回評価データ参考表示）
  - [x] FinalRewardAmount転記確認（課長のみ / 部長上書き）
  - [ ] 管理職の職能換算（×0.85）
  - [ ] メンバー10名登録
  - [x] 改善分野複数追加・効果金額合計
  - [x] 添付ファイル複数アップロード
  - [x] 回覧者あり申請 → 回覧承認 → 次の回覧者通知 → 全員承認 → 課長評価遷移
  - [x] 回覧差戻 → 差戻通知メール → 申請者が修正・再提出
- [x] **4-3** メール通知テスト
  - [x] 承認依頼メール（課長宛 / 部長宛）
  - [x] NG通知メール（差戻時）
  - [x] 承認完了メール（申請者+承認者宛）
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

## フェーズ5: v10 機能追加（設計書v10準拠）

### 5-A: 添付ファイル種別（FileCategory）追加

- [x] **5-A-1** ドキュメントライブラリにFileCategory列追加 `[PnP PowerShell]`
  - 選択肢: 改善前/改善後/その他
  - 既存環境: `scripts/develop/patch-v10-add-filecategory.ps1`
  - 新規環境: `scripts/create-doclib.ps1`（更新済み）
- [x] **5-A-2** Power Automateフロー更新: FileCategoryパラメータ追加 `[UI]`
  - → `powerautomate/flow-upload-attachment-build.html`（更新済み）
- [x] **5-A-3** 申請フォーム: ファイル種別選択UI追加 `[YAML / Code View]`
  - colAttachmentsにCategory列追加（デフォルト「その他」）
  - 添付ファイルボタン横にファイル種別ドロップダウン（改善前/改善後/その他）
  - 添付ファイルギャラリーに種別ラベル表示（色分け付き）
  - 閲覧画面・評価画面にもFileCategory表示追加
  - フロー呼び出しにCategory引数追加（submit-logic.pfx + btnSubmit.OnSelect同期）
  - → `powerapps/screen-application-form.yaml`
  - → `powerapps/screen-view.yaml`（FileCategory表示追加）
  - → `powerapps/screen-evaluation.yaml`（FileCategory表示追加）
  - → `powerapps/submit-logic.pfx`（Category引数追加）
  - → `powerapps/app-onstart.pfx`（colAttachments/colViewAttachmentsにCategory列追加）

### 5-B: レイアウト調整 + 評価データ可視化

- [x] **5-B-1** 閲覧画面: 改善前後画像2カラム埋め込み表示 `[YAML / Code View]`
  - FileCategory="改善前"/"改善後"の画像をImageコントロールで表示
  - 2カラムAutoLayout（改善前 / 改善後）、画像なし時はプレースホルダー
  - 「その他」添付ファイルは従来のリンク表示（セクション名変更）
  - → `powerapps/screen-view.yaml`（cntViewImages追加、cntViewAttachmentフィルタ変更）
  - → `powerapps/app-onstart.pfx`（varViewBeforeImageLink/varViewAfterImageLink追加）
- [x] **5-B-2** 閲覧画面: 評価結果セクション追加 `[YAML / Code View]`
  - 評価データリストからRequestIDで取得（課長/部長）
  - 2カラム: 課長評価 / 部長評価（判定・4軸スコア・素点・換算・等級・金額・コメント）
  - 表彰区分 ≠ 改善提案 の場合は4軸スコア非表示
  - 部長評価データなしの場合は部長カラム非表示
  - ステータスが承認済/差戻の場合のみ表示（Embedded時は非表示）
  - 最終褒賞金額バー表示
  - → `powerapps/screen-view.yaml`（cntViewEvalSection追加）
  - → `powerapps/app-onstart.pfx`（varViewManagerEval/varViewDirectorEval/varViewFinalReward追加）
- [x] **5-B-3** 全画面レイアウト調整 `[YAML / Code View]`
  - PDF改善提案シートを参考にした配置最適化
  - 情報ヘッダーのレイアウト変更
  - → `docs/layout-design.md`（レイアウト仕様）

### 5-C: 部門（Division）列追加

- [x] **5-C-1** SharePointリストにDivision列追加 `[PnP PowerShell]`
  - 社員マスタ + 改善提案メイン
  - 既存環境: `scripts/develop/patch-v10-add-division.ps1`
  - 新規環境: `scripts/create-lists.ps1`（更新済み）
- [x] **5-C-2** 社員マスタCSVにDivision列追加・インポート `[CSV / PnP PowerShell]`
  - `scripts/import-employees.ps1` 更新（Division列マッピング追加）
  - テスト用CSVにDivision列追加（TEC-A:技術開発部門, TEC-B:製造部門, TEC-D:営業部門 / TEC-C,TEC-E:空）
- [x] **5-C-3** Power Apps全画面にDivision対応 `[YAML / Code View]`
  - 申請フォーム: TEC→部門→部→課→係の5階層表示（部門が空の場合は非表示）
  - 閲覧画面: 部門表示追加（空の場合は非表示）
  - 評価画面: 閲覧部分に部門追加（空の場合は非表示）
  - → `powerapps/screen-application-form.yaml`（cntDivision追加、OnVisible/Preview/Patch更新）
  - → `powerapps/screen-view.yaml`（cntViewDivision追加、OnVisible更新）
  - → `powerapps/screen-evaluation.yaml`（cntEvalViewDivision追加、OnVisible更新）
  - → `powerapps/submit-logic.pfx`（Division: gCurrentDivision追加）
  - → `powerapps/app-onstart.pfx`（gCurrentDivision/varViewDivision追加）
- [x] **5-C-4** メールテンプレート更新 `[HTML]`
  - TEC/部門/部/課の表示追加（全6テンプレート更新）
  - → `powerautomate/templates/*.html`
- [x] **5-C-5** Power Automateフロー更新 `[UI]`
  - メインリスト更新時のDivision列対応（Division列はRequired=falseのため項目の更新に追加不要）
  - フロー設計書のメール本文プレースホルダー更新
  - → `powerautomate/flow-approval-director-build.html`（TEC/部門/部/課に更新）

### 5-D: 申請状況確認導線（SharePointビュー＋Param遷移）

- [x] **5-D-1** App.OnStart: URLパラメータ（Param）受け取り処理追加 `[Power Fx]`
  - `Param("RequestID")` で閲覧画面に直接遷移
  - `Param("EvalType")` で評価画面に直接遷移（承認依頼メール用）
  - `Param("Mode")` = "Edit" で申請フォームに直接遷移（差戻再提出用）
  - → `powerapps/app-onstart.pfx`
- [x] **5-D-2** SharePointリスト カスタムビュー作成 `[UI / PnP PowerShell]`
  - 改善提案メインリストに「自分の申請」ビュー作成（ApplicantEmail = [Me]）
  - 表示列: RequestID / Theme / Status / CompletionDate / FinalRewardAmount
  - 並び替え: ID 降順
- [x] **5-D-3** Column Formatting（列の書式設定）適用 `[UI]`
  - RequestID列にJSON書式設定を適用
  - クリックでPower Apps閲覧画面へ遷移するリンク表示
  - AppID はアプリ公開後に確定→設定

### 5-E: メールリンクURL設定

- [x] **5-E-1** メールテンプレートのプレースホルダーURL更新 `[HTML / Power Automate]`
  - 全6テンプレートの `https://apps.powerapps.com/play/e/XXXXXXXX` をアプリGUID＋パラメータに置換
  - 承認依頼メール（2件）: `?RequestID={RequestID}&EvalType=課長or部長` → 評価画面
  - 承認完了メール（2件）: `?RequestID={RequestID}` → 閲覧画面
  - 差戻通知メール（2件）: `?RequestID={RequestID}&Mode=Edit` → 申請フォーム
  - Power Automateフロー内のメール本文でRequestIDを動的コンテンツとして差し込み
  - → `powerautomate/templates/*.html`（全6ファイル）
  - → フロー設計書（`powerautomate/flow-*.md`）更新
  - **前提**: 5-D-1（Param受け取り処理）が完了していること
  - **前提**: AppID はアプリ公開後に確定するため、テスト環境のAppIDで先行設定

### 5-F: v10.2 追加仕様

- [x] **5-F-1** 閲覧画面: 評価結果セクションを申請者本人のみに表示 `[YAML / Code View]`
  - 現在の条件: `(varViewStatus = "承認済" || varViewStatus = "差戻") && varViewMode <> "Embedded"`
  - 追加条件: `User().Email = ApplicantEmail`（申請者本人のみ）
  - テストモード時: `gCurrentEmail = ApplicantEmail` で判定
  - OnVisibleで申請者のメールアドレスを変数に保存する処理を追加
  - → `powerapps/screen-view.yaml`（cntViewEvalSection の Visible条件変更）
  - → `powerapps/app-onstart.pfx`（varViewApplicantEmail追加）
- [x] **5-F-2** 申請フォーム: 添付ファイルを必須から任意に変更 `[YAML / Code View]`
  - 提出時バリデーションから添付ファイル必須チェックを削除
  - 改善前/改善後画像がない状態でも提出可能にする
  - 閲覧画面の「画像なし」プレースホルダーは既に実装済み
  - → `powerapps/screen-application-form.yaml`（btnSubmit バリデーション変更）
  - → `powerapps/submit-logic.pfx`（同期不要 — バリデーションはDisplayModeのみ）

---

## フェーズ6: 環境移行テスト

- [x] **6-1** 環境移行テスト `[PnP PowerShell / UI]` **期限: 2026-03-19（木）**
  - テスト環境から本番環境（または別テスト環境）への移行手順検証
  - `docs/deployment-guide.md` の手順に従い、スクリプトによる環境再現を確認
  - リスト作成・マスタ投入・Power Appsインポート・Power Automateフロー構築の一連を検証

---

## フェーズ7: v2 機能（提案プラン + 追加要件）

> 詳細仕様は `docs/backlog.md` を参照。以下はタスク管理用。

- [x] ★ **§3** 回覧者（事前確認者）機能 `[YAML / Power Automate / PnP PowerShell]`
  - 回覧者リスト作成（SharePoint）: RequestID / ReviewerGID / ReviewerName / ReviewerEmail / ReviewOrder / ReviewStatus
  - 申請フォーム 右カラムに回覧者入力セクション追加（最大5名、上下並べ替えボタン）
  - 評価画面 Reviewerモード追加（`Mode=Reviewer`パラメータ / スコアリング非表示 / 承認+差戻ボタン）
  - App.StartScreen に `Mode=Reviewer` 分岐追加
  - App.OnStart: EvaluationScreen 再ロードブロック追加（OnVisible→OnStart順序問題の対応）
  - 回覧通知フロー（listトリガー / ReviewStatus=承認 / 次の回覧者通知 or 課長通知）
  - 回覧差戻フロー（PAトリガー / 差戻通知メール送信）
  - 申請通知フロー更新（Step 3.5: 回覧者有無分岐追加）
  - → `powerapps/screen-application-form.yaml`（cntReviewerSection追加）
  - → `powerapps/screen-evaluation.yaml`（Reviewerモード追加）
  - → `powerapps/app-onstart.pfx`（回覧者変数・EvaluationScreen再ロード追加）
  - → `powerapps/app-startscreen.pfx`（Mode=Reviewer分岐追加）
  - → `powerautomate/flow-reviewer-notify-build.html`（フロー構築手順）
  - → `powerautomate/flow-reviewer-dismiss-build.html`（フロー構築手順）
  - → `powerautomate/flow-notification-submit-build.html`（Step 3.5追加）
  - → `powerautomate/templates/3-5_回覧通知_回覧依頼.html`
  - → `powerautomate/templates/3-5_回覧通知_差戻通知.html`
  - テスト完了: 2026-04-06
- [x] ★ **7-1** 添付資料の多ファイル形式対応（PDF/PPT等） `[YAML / Power Automate]`
  - ContentBase64廃止・統合表示・バリデーション強化
  - その他添付ファイル複数対応（最大7件）・フローfirst()最適化
  - テスト完了: 2026-04-14
- [x] ★ **7-2** 課長不在時の直接部長承認フロー `[Power Automate / Power Fx]`
  - 社員マスタの承認課長（ManagerGID）が空欄のケースに対応
  - 申請通知フロー: 課長GID空 → 部長に直接承認依頼
  - 課長承認フローのトリガー条件調整
  - 申請フォーム・閲覧画面での承認者表示対応
- [x] ★ **7-3** 申請画面での承認者表示・変更機能 `[YAML / Code View]`
  - 申請フォームに承認者（課長・部長）の表示欄追加
  - 社員マスタから自動取得した承認者を表示
  - 承認者を変更する機能（社員マスタ検索＋選択UI）
  - 変更時のバリデーション（課長/部長ロール確認）
- [ ] ★ **7-4** CSVエクスポート機能 `[Power Automate]`
  - Power Automate手動トリガーフローで実現（Bプラン）
  - 入力パラメータ: 開始日・終了日（期間指定）
  - フロー内でメイン+メンバー+分野実績+評価データを結合し、フラット化CSVを生成
  - 生成CSVをSharePointドキュメントライブラリに保存 → DLリンクをメール通知
  - 出力項目: 申請基本情報（26列）+ メンバー横展開 + 分野実績横展開 + 課長/部長評価
  - サンプルCSV: `a_project/refs/csv-export-sample.csv`
  - 将来的にv2管理者画面（2-10）のUIに組み込み可
- [ ] ★ **2-9** ホーム画面（提案プラン） `[YAML / Code View]`
  - 自分の申請一覧ギャラリー
  - 承認待ち一覧ギャラリー
  - ステータスフィルタ / 期間フィルタ
- [ ] ★ **2-10** 管理者画面（提案プラン） `[YAML / Code View]`
  - マスタCRUD
  - 全件閲覧・エクスポート
- [x] ★ **3-5** 取下げ通知フロー（§4） `[UI + 式コード提供]`
  - 取下げ時の承認者通知（Power Appsトリガー / PreviousStatusで通知先分岐）
  - → `powerautomate/flow-cancel-notify-build.html`（フロー構築手順）
  - → `powerautomate/templates/3-4_取下げ通知.html`（メールテンプレート）
- [ ] ★ **3-6** リマインダーフロー（提案プラン） `[UI + 式コード提供]`
  - 日次スケジュール
  - 承認期限5日超過チェック
  - 督促メール送信
- [ ] ★ **7-5** 改善メンバー入力補助: 名前サジェスション `[YAML / Code View]`
  - メンバー追加時に名前で社員マスタを検索・サジェスト表示
  - 現在のGID入力に加えて、名前からの検索・選択UIを追加
- [ ] ★ **4-7** v2 テスト `[テスト]`
  - v2追加機能の結合テスト
  - ホーム画面 / 管理者画面 / 追加フローのテスト

---

## コード管理メモ

- **PnPスクリプト**: `scripts/` に保存、git管理
- **Power Apps YAML / Power Fx**: `powerapps/` に `.yaml` / `.pfx` ファイルとして保存、git管理
- **メールHTMLテンプレート**: 必要に応じてgit管理
- 各タスクの完了時に使用したスクリプト/コードへのリンクを `→` で記載
- 本番環境構築時は同じファイルを参照して再現可能

---

## 工数目安（v10.1設計書準拠）

| プラン               | 工数    | 期間      |
| -------------------- | ------- | --------- |
| シンプルプラン       | 12.25日 | 約2.5週間 |
| シンプル＋提案プラン | 16.25日 | 約3週間   |

> ※ v10.1追加分: 申請状況確認導線（5-D: 0.25日）＋ メールリンクURL設定（5-E: 0.25日）= +0.5日

> ※ 1名作業想定。マスタデータ準備状況により変動あり。
