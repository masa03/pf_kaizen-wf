# ============================================================
# §13 承認リストのカスタムView承認遷移リンク — 既存環境差分パッチ
# ============================================================
# 対象: 既存テスト環境の RequestID 列 Column Formatting を §13 対応版に更新
# 新規環境は set-column-formatting.ps1 で対応済みのため不要
#
# 変更内容:
#   担当者（CurrentAssigneeEmail）が閲覧した場合、Status に応じて
#   EvalType/Mode パラメータを付与し、評価画面に直接遷移させる
#
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./scripts/develop/patch-v13-approval-view-link.ps1
#
# 前提:
#   - 改善提案メインリストが作成済み（create-lists.ps1 実行済み）
#   - Power Apps アプリが公開済み（AppID が確定していること）
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

# ============================================================
# ★ アプリ公開後に以下のAppIDを実際のGUIDに置換すること
# ============================================================
$AppID = "06249ec4-6b92-4c4b-a54c-daf52c177a83"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " §13 パッチ: RequestID 列 承認遷移リンク" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# RequestID 列 Column Formatting を更新
# ============================================================
# @me == [$CurrentAssigneeEmail.email] の場合、Status に応じて遷移パラメータを付与:
#   課長評価中 → &EvalType=課長  （評価画面・課長モード）
#   部長評価中 → &EvalType=部長  （評価画面・部長モード）
#   回覧中     → &Mode=Reviewer  （評価画面・回覧モード）
#   担当者でない場合 → パラメータなし（閲覧画面）
# ============================================================
Write-Host "[1/1] RequestID 列: Column Formatting 更新中..." -ForegroundColor Yellow

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

Write-Host "  → 適用完了" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " パッチ適用完了！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "【確認手順】" -ForegroundColor Yellow
Write-Host "  1. SharePoint > 改善提案メインリスト を開く"
Write-Host "  2. 「自分の承認待ち」ビュー: 課長評価中 → クリック → 評価画面（課長）に遷移"
Write-Host "  3. 「自分の承認待ち」ビュー: 部長評価中 → クリック → 評価画面（部長）に遷移"
Write-Host "  4. 「自分の申請」ビュー: クリック → 閲覧画面に遷移（パラメータなし）"
