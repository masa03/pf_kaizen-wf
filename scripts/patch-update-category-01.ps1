# ============================================================
# [update_category_01] 改善分野実績リストを再作成（ConversionRate列追加）
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   # Step 1: 手動で削除
#   Remove-PnPList -Identity "改善分野実績" -Force
#   # Step 2: 再作成
#   ./patch-update-category-01.ps1
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "[update_category_01] 改善分野実績リストを作成中..." -ForegroundColor Yellow

New-PnPList -Title "改善分野実績" -Template GenericList -Url "Lists/KaizenCategoryResults"

$titleField = Get-PnPField -List "改善分野実績" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "改善分野実績" -DisplayName "リクエストID" -InternalName "RequestID" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善分野実績" -DisplayName "改善分野コード" -InternalName "CategoryCode" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善分野実績" -DisplayName "改善分野名" -InternalName "CategoryName" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善分野実績" -DisplayName "実績値" -InternalName "ActualValue" -Type Number -Required -AddToDefaultView
Add-PnPField -List "改善分野実績" -DisplayName "仕掛り金額" -InternalName "WIPAmount" -Type Number
Add-PnPField -List "改善分野実績" -DisplayName "金額換算単価" -InternalName "ConversionRate" -Type Number  # [update_category_01]
Add-PnPField -List "改善分野実績" -DisplayName "コメント" -InternalName "Comment" -Type Note
Add-PnPField -List "改善分野実績" -DisplayName "効果金額算出式" -InternalName "Formula" -Type Text -Required
Add-PnPField -List "改善分野実績" -DisplayName "効果金額" -InternalName "EffectAmount" -Type Number -Required -AddToDefaultView

# --- インデックス ---
Set-PnPField -List "改善分野実績" -Identity "RequestID" -Values @{Indexed = $true}

Write-Host "  → 改善分野実績リスト作成完了（ConversionRate列追加済み）" -ForegroundColor Green
