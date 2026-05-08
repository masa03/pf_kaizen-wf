# ============================================================
# §8 社員マスタサジェスト検索UI — 既存環境差分パッチ
# ============================================================
# 対象: 既存テスト環境（リスト作成済み）に §8 用の EmployeeName インデックスを追加する
# 新規環境は create-lists.ps1 で対応済みのため不要
#
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./scripts/develop/patch-employee-name-index.ps1
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " §8 パッチ: EmployeeName インデックス追加" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 社員マスタ — EmployeeName インデックス追加
# ============================================================
Write-Host "[1/1] 社員マスタ — EmployeeName インデックス追加" -ForegroundColor Yellow

Set-PnPField -List "社員マスタ" -Identity "EmployeeName" -Values @{Indexed = $true}
Write-Host "  EmployeeName インデックス追加完了" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " §8 パッチ完了！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
