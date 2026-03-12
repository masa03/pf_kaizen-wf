# ============================================================
# 改善分野実績リストに「並び順」列を追加するパッチスクリプト
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive
#   ./patch-add-category-sortorder.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$listName = "改善分野実績"

Write-Host "[$listName] SortOrder列を追加中..." -ForegroundColor Yellow

Add-PnPField -List $listName -DisplayName "並び順" -InternalName "SortOrder" -Type Number -ErrorAction Stop

Write-Host "  → SortOrder列 追加完了" -ForegroundColor Green
