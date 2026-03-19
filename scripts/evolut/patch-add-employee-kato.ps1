# =============================================
#  社員マスタ 追加投入スクリプト（加藤雅人 1名）
#  対象: evolut8610 環境の社員マスタ（既存データ維持）
# =============================================
# 事前に接続済みであること:
#   Connect-PnPOnline -Url "https://evolut8610.sharepoint.com/sites/kaizen-wf" -Interactive -ClientId "YOUR-CLIENT-ID"
#   $ctx = Get-PnPContext; $ctx.RequestTimeout = 300000

$CsvPath = "$PSScriptRoot/add_employee_kato.csv"
$ListName = "社員マスタ"

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSVファイルが見つかりません: $CsvPath"
    exit 1
}

$records = Import-Csv -Path $CsvPath -Encoding UTF8
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 社員マスタ 追加投入（既存データ維持）" -ForegroundColor Cyan
Write-Host " 追加件数: $($records.Count) 名" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " 追加データ:" -ForegroundColor Yellow
Write-Host "   0000000051 加藤雅人  m.kato@familiar03.onmicrosoft.com (平社員)" -ForegroundColor Yellow
Write-Host "   課長: 0000000002 鈴木花子 (t.sato@evolut8610)" -ForegroundColor Yellow
Write-Host "   部長: 0000000001 佐藤太郎 (m.kato@evolut8610)" -ForegroundColor Yellow
Write-Host ""

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
            "Division"      = $r.Division
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
