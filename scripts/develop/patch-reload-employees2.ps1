# =============================================
#  社員マスタ テストデータ入替スクリプト（test_employees2用）
#  既存データを全削除 → test_employees2.csv を投入
# =============================================
# 事前に接続済みであること:
#   Connect-PnPOnline -Url "https://familiar03.sharepoint.com/sites/kaizen-wf" -Interactive -ClientId "73cd559b-46af-4a0e-aaeb-3e720a3f017b"
#   $ctx = Get-PnPContext; $ctx.RequestTimeout = 300000

param(
    [string]$CsvPath = (Join-Path $PSScriptRoot ".." "test_employees2.csv")
)

$ListName = "社員マスタ"

# -----------------------------------------------
# Step 1: 既存データ全削除
# -----------------------------------------------
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 社員マスタ データ入替（test_employees2）" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[Step 1] 既存データ削除中..." -ForegroundColor Yellow

$existingItems = Get-PnPListItem -List $ListName -PageSize 500
$delCount = 0
foreach ($item in $existingItems) {
    $delCount++
    Write-Host "  削除 [$delCount] ID=$($item.Id) $($item["EmployeeName"]) ..." -NoNewline
    try {
        Remove-PnPListItem -List $ListName -Identity $item.Id -Force | Out-Null
        Write-Host " OK" -ForegroundColor Green
    }
    catch {
        Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host "  → $delCount 件削除完了" -ForegroundColor Green

# -----------------------------------------------
# Step 2: test_employees2.csv 投入
# -----------------------------------------------
Write-Host ""
Write-Host "[Step 2] test_employees2.csv 投入中..." -ForegroundColor Yellow

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSVファイルが見つかりません: $CsvPath"
    exit 1
}

$records = Import-Csv -Path $CsvPath -Encoding UTF8
Write-Host "  件数: $($records.Count) 名" -ForegroundColor Cyan

$count = 0
$errors = 0

foreach ($r in $records) {
    $count++
    Write-Host "  [$count/$($records.Count)] $($r.GID) $($r.EmployeeName) ($($r.Email)) ..." -NoNewline

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

# -----------------------------------------------
# 結果サマリ
# -----------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 完了: $($count - $errors) 件成功 / $errors 件エラー" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " メールアドレス割当:" -ForegroundColor Yellow
Write-Host "  申請者（ログインユーザー）: m.kato@familiar03.onmicrosoft.com → 佐藤陽子(0000000004)" -ForegroundColor White
Write-Host "  部長（全部門）:             m.kato@familiar.fun" -ForegroundColor White
Write-Host "  課長（全部門）:             contact@familiar.fun" -ForegroundColor White
Write-Host "  その他一般社員:             m.kato@evolut.jp" -ForegroundColor White
