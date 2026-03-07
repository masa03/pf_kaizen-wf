# ============================================================
# [v10] 部門(Division)列追加パッチ
# ============================================================
# 社員マスタ・改善提案メインに Division 列を追加する
# 新規環境は create-lists.ps1 で一括作成されるため不要
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " [v10] Division列追加パッチ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 社員マスタに部門列追加
Add-PnPField -List "社員マスタ" -DisplayName "部門" -InternalName "Division" -Type Text
Write-Host "  → 社員マスタ: Division列追加完了" -ForegroundColor Green

# 改善提案メインに部門列追加
Add-PnPField -List "改善提案メイン" -DisplayName "部門" -InternalName "Division" -Type Text
Write-Host "  → 改善提案メイン: Division列追加完了" -ForegroundColor Green

Write-Host ""
Write-Host "【次のステップ】" -ForegroundColor Yellow
Write-Host "  1. 社員マスタCSVに部門列を追加してインポート" -ForegroundColor Yellow
Write-Host "  2. Power Appsの申請フォーム・閲覧画面・評価画面を更新" -ForegroundColor Yellow
Write-Host "  3. submit-logic.pfx / app-onstart.pfx にDivision追加" -ForegroundColor Yellow
