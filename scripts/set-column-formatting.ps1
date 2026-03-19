# ============================================================
# 改善提案システム - Column Formatting 適用スクリプト
# タスク: 5-D-3
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./set-column-formatting.ps1
#
# 前提:
#   - 改善提案メインリストが作成済み（create-lists.ps1 実行済み）
#   - Power Apps アプリが公開済み（AppID が確定していること）
#
# 設定内容:
#   - 改善提案メインリストの RequestID 列にリンク書式を適用
#   - クリックで Power Apps 閲覧画面に遷移（?RequestID=xxx）
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

# ============================================================
# ★ アプリ公開後に以下のAppIDを実際のGUIDに置換すること
# Power Apps > アプリ詳細 > アプリID で確認可能
# ============================================================
$AppID = "06249ec4-6b92-4c4b-a54c-daf52c177a83"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 改善提案システム - Column Formatting 適用" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# RequestID 列に Column Formatting を適用
# ============================================================
Write-Host "[1/1] 改善提案メインリスト: RequestID 列にリンク書式を適用中..." -ForegroundColor Yellow

# シングルクォート here-string（@'...'@）で変数展開を防止
# ※ @currentField はSharePoint Column Formattingのトークン。
#    ダブルクォート here-string だとPowerShellが@を変数として解釈し破壊される。
$columnFormatting = @'
{
  "$schema": "https://columnformatting.sharepointpnp.com/columnFormattingSchema.json",
  "elmType": "a",
  "txtContent": "@currentField",
  "style": {
    "color": "#0078d4",
    "text-decoration": "underline",
    "cursor": "pointer"
  },
  "attributes": {
    "href": "='https://apps.powerapps.com/play/__APPID__?RequestID=' + @currentField",
    "target": "_blank"
  }
}
'@
$columnFormatting = $columnFormatting.Replace("__APPID__", $AppID)

Set-PnPField -List "改善提案メイン" -Identity "RequestID" -Values @{
    CustomFormatter = $columnFormatting
}

Write-Host "  → RequestID 列にリンク書式を適用完了" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Column Formatting 適用完了" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "【確認手順】" -ForegroundColor Yellow
Write-Host "  1. SharePoint > 改善提案メインリスト を開く"
Write-Host "  2. RequestID 列の値が青色リンクになっていることを確認"
Write-Host "  3. リンクをクリック → Power Apps 閲覧画面に遷移することを確認"
Write-Host ""
Write-Host "【注意】" -ForegroundColor Yellow
Write-Host "  AppID が {AppID} のままの場合、リンク先が正しくありません。"
Write-Host "  スクリプト内の `$AppID 変数を実際のアプリGUIDに置換してから実行してください。"
