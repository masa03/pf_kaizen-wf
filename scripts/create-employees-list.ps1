# ============================================================
# 改善提案システム - SharePoint Lists 一括作成スクリプト
# 設計書: v9 準拠
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./create-lists.ps1
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 改善提案システム - リスト一括作成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 社員マスタ
# ============================================================
Write-Host "[1/8] 社員マスタ を作成中..." -ForegroundColor Yellow

New-PnPList -Title "社員マスタ" -Template GenericList -Url "Lists/EmployeeMaster" -ErrorAction Stop

# Title列を非表示（使わない）
$titleField = Get-PnPField -List "社員マスタ" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}
$view = Get-PnPView -List "社員マスタ" -Identity "すべてのアイテム" -ErrorAction SilentlyContinue
if (-not $view) { $view = Get-PnPView -List "社員マスタ" -Identity "All Items" -ErrorAction SilentlyContinue }
if ($view -and ($view.ViewFields -contains "LinkTitle")) {
    $view.ViewFields.Remove("LinkTitle"); $view.Update(); Invoke-PnPQuery
}

Add-PnPField -List "社員マスタ" -DisplayName "GID" -InternalName "GID" -Type Text -Required -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "氏名" -InternalName "EmployeeName" -Type Text -Required -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "メールアドレス" -InternalName "Email" -Type Text -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "在籍事業所" -InternalName "Office" -Type Text -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "社員区分" -InternalName "EmployeeType" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "職位" -InternalName "Position" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "管理職フラグ" -InternalName "IsManagement" -Type Boolean
Add-PnPField -List "社員マスタ" -DisplayName "原価単位" -InternalName "CostUnit" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "TEC" -InternalName "Department" -Type Text -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "部門" -InternalName "Division" -Type Text  # [v10] TECと部の間の組織階層
Add-PnPField -List "社員マスタ" -DisplayName "部" -InternalName "Bu" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "課" -InternalName "Section" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部門長GID" -InternalName "DeptHeadGID" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部門長氏名" -InternalName "DeptHeadName" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部門長本人フラグ" -InternalName "IsDeptHead" -Type Boolean
Add-PnPField -List "社員マスタ" -DisplayName "部長GID" -InternalName "DirectorGID" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部長氏名" -InternalName "DirectorName" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部長本人フラグ" -InternalName "IsDirector" -Type Boolean
Add-PnPField -List "社員マスタ" -DisplayName "課長GID" -InternalName "ManagerGID" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "課長氏名" -InternalName "ManagerName" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "課長本人フラグ" -InternalName "IsManager" -Type Boolean
Add-PnPField -List "社員マスタ" -DisplayName "有効フラグ" -InternalName "IsActive" -Type Boolean

Write-Host "  → 社員マスタ 完了" -ForegroundColor Green