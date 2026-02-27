# =============================================
#  マスタデータ投入スクリプト
#  対象: 改善分野マスタ（14件）＋ 表彰区分マスタ（4件）
# =============================================
# 事前に接続済みであること:
#   Connect-PnPOnline -Url "https://familiar03.sharepoint.com/sites/kaizen-wf" -Interactive -ClientId "73cd559b-46af-4a0e-aaeb-3e720a3f017b"
#   $ctx = Get-PnPContext; $ctx.RequestTimeout = 300000

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " マスタデータ投入" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# --------------------------------------------------
# 改善分野マスタ（14件）
# --------------------------------------------------
Write-Host ""
Write-Host "[改善分野マスタ] 投入中..." -ForegroundColor Yellow

$categories = @(
    @{ CategoryCode="CAT-01"; CategoryName="活人";                  Unit="人/月"; SortOrder=1;  ConversionRate=760232; CategoryType="金額算出" }
    @{ CategoryCode="CAT-02"; CategoryName="活工数";                Unit="h/月";  SortOrder=2;  ConversionRate=4664;   CategoryType="金額算出" }
    @{ CategoryCode="CAT-03"; CategoryName="活スペース（ライン）";  Unit="㎡/月"; SortOrder=3;  ConversionRate=6500;   CategoryType="金額算出" }
    @{ CategoryCode="CAT-04"; CategoryName="活スペース（事務所）";  Unit="㎡/月"; SortOrder=4;  ConversionRate=1200;   CategoryType="金額算出" }
    @{ CategoryCode="CAT-05"; CategoryName="動線短縮";              Unit="m/月";  SortOrder=5;  ConversionRate=1;      CategoryType="金額算出" }
    @{ CategoryCode="CAT-06"; CategoryName="リードタイム短縮";      Unit="分/月"; SortOrder=6;  ConversionRate=0;      CategoryType="金額算出" }
    @{ CategoryCode="CAT-07"; CategoryName="労働生産性";            Unit="円/月"; SortOrder=7;  ConversionRate=0;      CategoryType="直接入力" }
    @{ CategoryCode="CAT-08"; CategoryName="設備生産性";            Unit="円/月"; SortOrder=8;  ConversionRate=0;      CategoryType="直接入力" }
    @{ CategoryCode="CAT-09"; CategoryName="経費削減";              Unit="円/月"; SortOrder=9;  ConversionRate=0;      CategoryType="直接入力" }
    @{ CategoryCode="CAT-10"; CategoryName="在庫削減";              Unit="円/月"; SortOrder=10; ConversionRate=0;      CategoryType="直接入力" }
    @{ CategoryCode="CAT-11"; CategoryName="その他";                Unit="円/月"; SortOrder=11; ConversionRate=0;      CategoryType="直接入力" }
    @{ CategoryCode="CAT-12"; CategoryName="6S・ヒューマンエラー";  Unit="";      SortOrder=12; ConversionRate=0;      CategoryType="テキスト" }
    @{ CategoryCode="CAT-13"; CategoryName="環境";                  Unit="";      SortOrder=13; ConversionRate=0;      CategoryType="テキスト" }
    @{ CategoryCode="CAT-14"; CategoryName="その他効果";            Unit="";      SortOrder=14; ConversionRate=0;      CategoryType="テキスト" }
)

$catCount = 0
foreach ($c in $categories) {
    $catCount++
    Write-Host "  [$catCount/14] $($c.CategoryCode) $($c.CategoryName) ..." -NoNewline
    try {
        Add-PnPListItem -List "改善分野マスタ" -Values $c | Out-Null
        Write-Host " OK" -ForegroundColor Green
    }
    catch {
        Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --------------------------------------------------
# 表彰区分マスタ（4件）
# --------------------------------------------------
Write-Host ""
Write-Host "[表彰区分マスタ] 投入中..." -ForegroundColor Yellow

$awards = @(
    @{ AwardCode="KZ"; AwardName="改善提案";  RewardAmount=0;     RequiresScoring=$true;  SortOrder=1; IsActive=$true }
    @{ AwardCode="PL"; AwardName="小集団 パール賞（3等）"; RewardAmount=3000;  RequiresScoring=$false; SortOrder=2; IsActive=$true }
    @{ AwardCode="CU"; AwardName="小集団 銅賞（2等）";   RewardAmount=5000;  RequiresScoring=$false; SortOrder=3; IsActive=$true }
    @{ AwardCode="SV"; AwardName="小集団 銀賞（1等）";   RewardAmount=10000; RequiresScoring=$false; SortOrder=4; IsActive=$true }
)

$awdCount = 0
foreach ($a in $awards) {
    $awdCount++
    Write-Host "  [$awdCount/4] $($a.AwardCode) $($a.AwardName) ..." -NoNewline
    try {
        Add-PnPListItem -List "表彰区分マスタ" -Values $a | Out-Null
        Write-Host " OK" -ForegroundColor Green
    }
    catch {
        Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " マスタデータ投入 完了" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
