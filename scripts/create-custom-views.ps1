# ============================================================
# 改善提案システム - カスタムビュー作成スクリプト（§7）
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./create-custom-views.ps1
#
# 前提:
#   - 改善提案メインリストが作成済み（create-lists.ps1 実行済み）
#
# 作成されるビュー:
#   - すべてのアイテム（既存ビューの列・並び順を更新）
#   - 自分の申請（ApplicantEmail = [Me]）
#   - 自分の承認待ち（CurrentAssigneeEmail = [Me]）
# ============================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " カスタムビュー作成（§7）" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ビュー1: すべてのアイテム（既存ビューを更新）
Write-Host "  改善提案メイン: すべてのアイテム ビューを更新中..." -ForegroundColor Yellow
Set-PnPView -List "改善提案メイン" -Identity "すべてのアイテム" `
    -Fields @("RequestID", "Theme", "Status", "ApplicantName", "Created") `
    -Values @{
        ViewQuery = "<OrderBy><FieldRef Name='ID' Ascending='FALSE' /></OrderBy>"
    }

# ビュー2: 自分の申請（新規作成）
# ApplicantEmail = [Me] フィルタ（CAMLのUserID = 現在ログインユーザー）
Write-Host "  改善提案メイン: 自分の申請 ビューを作成中..." -ForegroundColor Yellow
Add-PnPView -List "改善提案メイン" -Title "自分の申請" `
    -Fields @("RequestID", "Theme", "Status", "CompletionDate", "FinalRewardAmount") `
    -Query "<Where><Eq><FieldRef Name='ApplicantEmail' /><Value Type='Integer'><UserID /></Value></Eq></Where><OrderBy><FieldRef Name='ID' Ascending='FALSE' /></OrderBy>"

# ビュー3: 自分の承認待ち（新規作成）
# CurrentAssigneeEmail = [Me] フィルタ（Person型列）
Write-Host "  改善提案メイン: 自分の承認待ち ビューを作成中..." -ForegroundColor Yellow
Add-PnPView -List "改善提案メイン" -Title "自分の承認待ち" `
    -Fields @("RequestID", "Theme", "Status", "ApplicantName", "Created") `
    -Query "<Where><Eq><FieldRef Name='CurrentAssigneeEmail' /><Value Type='Integer'><UserID /></Value></Eq></Where><OrderBy><FieldRef Name='ID' Ascending='FALSE' /></OrderBy>"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " カスタムビュー作成完了" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "作成されたビュー（改善提案メイン）:" -ForegroundColor White
Write-Host "  すべてのアイテム（更新） / 自分の申請 / 自分の承認待ち" -ForegroundColor White
Write-Host ""
Write-Host "※ Column Formatting（§13 承認リンク含む）は set-column-formatting.ps1 で適用" -ForegroundColor Cyan
