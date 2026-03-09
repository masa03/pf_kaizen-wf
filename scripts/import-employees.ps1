# =============================================
#  社員マスタ テストデータ投入スクリプト
#  対象: 社員マスタ（50名）
# =============================================
# 事前に接続済みであること:
#   Connect-PnPOnline -Url "https://familiar03.sharepoint.com/sites/kaizen-wf" -Interactive -ClientId "73cd559b-46af-4a0e-aaeb-3e720a3f017b"
#   $ctx = Get-PnPContext; $ctx.RequestTimeout = 300000

param(
    [string]$CsvPath = "./test_employees.csv"
)

$ListName = "社員マスタ"

# CSV読み込み
if (-not (Test-Path $CsvPath)) {
    Write-Error "CSVファイルが見つかりません: $CsvPath"
    exit 1
}

$records = Import-Csv -Path $CsvPath -Encoding UTF8
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 社員マスタ テストデータ投入" -ForegroundColor Cyan
Write-Host " 件数: $($records.Count) 名" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$count = 0
$errors = 0

foreach ($r in $records) {
    $count++
    Write-Host "[$count/$($records.Count)] $($r.GID) $($r.EmployeeName) ..." -NoNewline

    try {
        $values = @{
            "GID"           = $r.GID
            "EmployeeName"  = $r.EmployeeName
            "Email"         = $r.Email
            "Office"        = $r.Office
            "EmployeeType"  = $r.EmployeeType
            "Position"      = $r.Position
            "IsManagement"  = ($r.IsManagement -eq "True")
            "CostUnit"      = $r.CostUnit
            "Department"    = $r.Department
            "Division"      = $r.Division  # [v10] TECと部の間の組織階層
            "Bu"            = $r.Bu
            "Section"       = $r.Section
            "DeptHeadGID"   = $r.DeptHeadGID
            "DeptHeadName"  = $r.DeptHeadName
            "IsDeptHead"    = ($r.IsDeptHead -eq "True")
            "DirectorGID"   = $r.DirectorGID
            "DirectorName"  = $r.DirectorName
            "IsDirector"    = ($r.IsDirector -eq "True")
            "ManagerGID"    = $r.ManagerGID
            "ManagerName"   = $r.ManagerName
            "IsManager"     = ($r.IsManager -eq "True")
            "IsActive"      = ($r.IsActive -eq "True")
        }

        Add-PnPListItem -List $ListName -Values $values | Out-Null
        Write-Host " OK" -ForegroundColor Green
    }
    catch {
        Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 完了: $($count - $errors) 件成功 / $errors 件エラー" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
