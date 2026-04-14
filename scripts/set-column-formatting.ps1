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
#   - [§13] 担当者（CurrentAssigneeEmail）が閲覧した場合、Status に応じて EvalType/Mode パラメータを付与
#           → 「自分の承認待ち」ビューでは承認画面に直接遷移
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
# [§13] @me == [$CurrentAssigneeEmail.email] の場合、Status に応じた遷移パラメータを付与
#   → 「自分の承認待ち」ビュー: 自分が担当者なので EvalType/Mode が付く → 評価画面へ
#   → 「自分の申請」ビュー: 自分は申請者（担当者でない）なので付かない → 閲覧画面へ
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
    "href": "='https://apps.powerapps.com/play/__APPID__?RequestID=' + @currentField + if(@me == [$CurrentAssigneeEmail.email], if([$Status] == '課長評価中', '&EvalType=課長', if([$Status] == '部長評価中', '&EvalType=部長', if([$Status] == '回覧中', '&Mode=Reviewer', ''))), '')",
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
Write-Host "  2. 「自分の申請」ビュー: RequestID が青色リンク → 閲覧画面に遷移（担当者でないためパラメータなし）" -ForegroundColor Yellow
Write-Host "  3. 「自分の承認待ち」ビュー: RequestID リンク → 承認画面に直接遷移（担当者のため自動判定）" -ForegroundColor Yellow
Write-Host "     課長評価中 → EvalType=課長 / 部長評価中 → EvalType=部長 / 回覧中 → Mode=Reviewer" -ForegroundColor Yellow
Write-Host ""
Write-Host "【注意】" -ForegroundColor Yellow
Write-Host "  AppID が {AppID} のままの場合、リンク先が正しくありません。"
Write-Host "  スクリプト内の `$AppID 変数を実際のアプリGUIDに置換してから実行してください。"
