# ============================================================
# 改善提案メインに申請者在籍事業所・原価単位列を追加
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./patch-add-applicant-office.ps1
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "改善提案メインに ApplicantOffice / ApplicantCostUnit 列を追加中..." -ForegroundColor Yellow

Add-PnPField -List "改善提案メイン" -DisplayName "申請者在籍事業所" -InternalName "ApplicantOffice" -Type Text
Add-PnPField -List "改善提案メイン" -DisplayName "申請者原価単位" -InternalName "ApplicantCostUnit" -Type Text

Write-Host "  → 完了" -ForegroundColor Green
