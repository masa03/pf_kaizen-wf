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

$masterLists = @("社員マスタ", "改善分野マスタ", "表彰区分マスタ")

foreach ($listName in $masterLists) {
    Write-Host "[権限] $listName - 権限の継承を中止..." -ForegroundColor Yellow

    # 権限の継承を中止（親サイトの権限をコピーした状態で切り離す）
    Set-PnPList -Identity $listName -BreakRoleInheritance -CopyRoleAssignments

    # サイトメンバー（編集グループ）の権限を「読み取り」に変更
    # ※ グループ名はサイト作成時のデフォルト名。環境に合わせて変更してください
    $memberGroupName = "kaizen-wf メンバー"  # ← サイトのメンバーグループ名に要変更
    $visitorGroupName = "kaizen-wf 訪問者"    # ← サイトの訪問者グループ名に要変更

    # メンバーグループの編集権限を削除し、読み取りに変更
    try {
        Set-PnPListPermission -Identity $listName -Group $memberGroupName -RemoveRole "編集"
        Set-PnPListPermission -Identity $listName -Group $memberGroupName -AddRole "読み取り"
        Write-Host "  → $memberGroupName : 編集→読み取りに変更" -ForegroundColor Green
    }
    catch {
        Write-Host "  → $memberGroupName の権限変更でエラー: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  → グループ名が異なる可能性があります。手動確認してください" -ForegroundColor Red
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
# 3. 評価データ / 改善メンバー / 改善分野実績
# ============================================================
# Power Apps経由でのみ操作。アイテムレベル権限は既定のまま
# ※ 必要に応じて WriteSecurity を設定

$txnLists = @("評価データ", "改善メンバー", "改善分野実績")

foreach ($listName in $txnLists) {
    Write-Host "[権限] $listName - アイテムレベル権限を確認..." -ForegroundColor Yellow

    # 読み取り: すべて可（承認者が参照するため）
    # 編集: Power Apps経由で制御するため既定のまま
    Set-PnPList -Identity $listName -ReadSecurity 1

    Write-Host "  → 読み取り: すべてのアイテム（既定）" -ForegroundColor Green
    Write-Host "  → 編集: Power Apps側でフィルタリング制御" -ForegroundColor Green
    Write-Host ""
}

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
Write-Host "  評価データ / 改善メンバー / 改善分野実績 → Power Apps側で制御" -ForegroundColor Green
Write-Host ""
Write-Host "【注意】" -ForegroundColor Red
Write-Host "  - グループ名（メンバー/訪問者）は環境に合わせて変更してください" -ForegroundColor Red
Write-Host "  - テスト環境ではアカウントが1つのため、自分がロックアウトされないよう注意" -ForegroundColor Red
Write-Host "  - 本番デプロイ前に権限設定を再確認してください" -ForegroundColor Red
