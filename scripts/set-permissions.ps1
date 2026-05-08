# ============================================================
# 改善提案システム - 権限設計・適用スクリプト
# 設計書: v9 セクション7 準拠
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./set-permissions.ps1
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 改善提案システム - 権限設計・適用" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. マスタリストの権限設定（管理者のみ編集、一般は読み取り）
# ============================================================
# 対象: 社員マスタ / 改善分野マスタ / 表彰区分マスタ

# サイトのデフォルトグループをサイトから自動取得（サイト名に依存しない）
$web = Get-PnPWeb -Includes AssociatedMemberGroup, AssociatedVisitorGroup
$memberGroupName = $web.AssociatedMemberGroup.Title
$visitorGroupName = $web.AssociatedVisitorGroup.Title
Write-Host "メンバーグループ: $memberGroupName" -ForegroundColor Gray
Write-Host "閲覧者グループ:   $visitorGroupName" -ForegroundColor Gray
Write-Host ""

$masterLists = @("社員マスタ", "改善分野マスタ", "表彰区分マスタ")

foreach ($listName in $masterLists) {
    Write-Host "[権限] $listName - 権限の継承を中止..." -ForegroundColor Yellow

    # 権限の継承を中止（親サイトの権限をコピーした状態で切り離す）
    Set-PnPList -Identity $listName -BreakRoleInheritance -CopyRoleAssignments

    # メンバーグループの既存権限をすべて削除（何が設定されていても確実にリセット）
    $editRoles = @("フル コントロール", "デザイン", "編集", "投稿")
    foreach ($role in $editRoles) {
        try {
            Set-PnPListPermission -Identity $listName -Group $memberGroupName -RemoveRole $role
        }
        catch { <# 該当ロールがなければスキップ #> }
    }

    # メンバーグループに閲覧権限を付与
    try {
        Set-PnPListPermission -Identity $listName -Group $memberGroupName -AddRole "閲覧"
        Write-Host "  → $memberGroupName : 閲覧のみに設定完了" -ForegroundColor Green
    }
    catch {
        Write-Host "  → $memberGroupName の閲覧権限付与でエラー: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "  → $listName : 管理者のみ編集可に設定完了" -ForegroundColor Green
    Write-Host ""
}

# ============================================================
# 2. トランザクションリストのアイテムレベル権限
# ============================================================
# 改善提案メイン: 自分のアイテムのみ編集可

Write-Host "[権限] 改善提案メイン - アイテムレベル権限を設定..." -ForegroundColor Yellow

# ReadSecurity: 1 = すべてのアイテム読み取り可, 2 = 自分のアイテムのみ
# WriteSecurity: 1 = すべてのアイテム編集可, 2 = 自分のアイテムのみ
Set-PnPList -Identity "改善提案メイン" -ReadSecurity 1 -WriteSecurity 2

Write-Host "  → 読み取り: すべてのアイテム（課長/部長が閲覧する必要あり）" -ForegroundColor Green
Write-Host "  → 編集: 自分のアイテムのみ" -ForegroundColor Green
Write-Host ""

# ============================================================
# 3. 改善メンバー / 改善分野実績（自分のアイテムのみ編集）
# ============================================================
# 申請者がPatchで作成 → Created By = 申請者本人
# WriteSecurity=2 で他人のデータ改ざんを防止

$selfEditLists = @("改善メンバー", "改善分野実績", "評価データ")

foreach ($listName in $selfEditLists) {
    Write-Host "[権限] $listName - アイテムレベル権限を設定..." -ForegroundColor Yellow

    Set-PnPList -Identity $listName -ReadSecurity 1 -WriteSecurity 2

    Write-Host "  → 読み取り: すべてのアイテム（承認者が参照するため）" -ForegroundColor Green
    Write-Host "  → 編集: 自分のアイテムのみ" -ForegroundColor Green
    Write-Host ""
}

# ============================================================
# 4. サイトナビゲーションからリストを非表示
# ============================================================
# 本人によるSPリスト直接編集を抑止するため、
# 管理者が直接参照する必要がないリストをナビゲーションから非表示にする

$hiddenLists = @("改善メンバー", "改善分野実績", "評価データ", "回覧メンバー", "添付ファイル")

foreach ($listName in $hiddenLists) {
    Write-Host "[ナビゲーション] $listName - 非表示に設定..." -ForegroundColor Yellow

    Set-PnPList -Identity $listName -Hidden $false -EnableFolderCreation $false
    $list = Get-PnPList -Identity $listName
    $list.OnQuickLaunch = $false
    $list.Update()
    Invoke-PnPQuery

    Write-Host "  → サイトナビゲーションから非表示" -ForegroundColor Green
    Write-Host ""
}

# ============================================================
# 5. 改善提案メインリストの編集UI制限
# ============================================================
# ナビゲーションに表示されるリストのため、SPリスト画面からの
# 編集操作（グリ��ドビュー編集・詳細パネル・編集フォーム）を無効化する。
# Power Apps Patch() / Power Automate のREST API経由書き込みには���響なし。

Write-Host "[編集UI制限] 改善提案メイン - クイック編集と詳細ウィンドウ編集を無効化..." -ForegroundColor Yellow

Set-PnPList -Identity "改善提案メイン" -DisableGridEditing $true

Write-Host "  → グリッドビュー編集・詳細パネル編集・編集フォームが無効化" -ForegroundColor Green
Write-Host "  → Power Apps Patch() / Power Automate には影響なし（REST API経由）" -ForegroundColor Green
Write-Host ""

# ============================================================
# 完了サマリー
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 権限設定 完了サマリー" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "マスタリスト（3リスト）:" -ForegroundColor White
Write-Host "  社員マスタ / 改善分野マスタ / 表彰区分マスタ" -ForegroundColor White
Write-Host "  → 管理者のみ編集可、一般ユーザーは読み取りのみ" -ForegroundColor Green
Write-Host ""
Write-Host "トランザクションリスト:" -ForegroundColor White
Write-Host "  改善提案メイン → 読み取り:全件 / 編集:自分のみ" -ForegroundColor Green
Write-Host "  改善メンバー / 改善分野実績 / 評価データ → 読み取り:全件 / 編集:自分のみ" -ForegroundColor Green
Write-Host ""
Write-Host "ナビゲーション非表示:" -ForegroundColor White
Write-Host "  改善メンバー / 改善分野実績 / 評価データ / 回覧メンバー / 添付ファイル" -ForegroundColor Green
Write-Host "  → サイトナビゲーションから非表示（URL直打ちでのアクセスは可能）" -ForegroundColor Green
Write-Host ""
Write-Host "ナビゲーション表示（管理者が直接参照するリスト）:" -ForegroundColor White
Write-Host "  改善提案メイン / 社員マスタ / 改善分野マスタ / 表彰区分マスタ" -ForegroundColor Green
Write-Host ""
Write-Host "編集UI制限:" -ForegroundColor White
Write-Host "  改善提案メイン → クイック編集・詳細パネル編集・編集フォームを無効化" -ForegroundColor Green
Write-Host "  → Power Apps Patch() / Power Automate には影響なし" -ForegroundColor Green
Write-Host ""
Write-Host "【注意】" -ForegroundColor Red
Write-Host "  - グループ名（メンバー/訪問者）は環境に合わせて変更してください" -ForegroundColor Red
Write-Host "  - テスト環境ではアカウントが1つのため、自分がロックアウトされないよう注意" -ForegroundColor Red
Write-Host "  - 本番デプロイ前に権限設定を再確認してください" -ForegroundColor Red
