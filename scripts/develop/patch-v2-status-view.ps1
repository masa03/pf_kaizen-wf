# ============================================================
# §7 申請・承認状況の確認導線 — 既存環境差分パッチ
# ============================================================
# 対象: 既存テスト環境（リスト作成済み）に §7 の列・インデックス・ビューを追加する
# 新規環境は create-lists.ps1 で対応済みのため不要
#
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./scripts/develop/patch-v2-status-view.ps1
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " §7 パッチ: 列・インデックス・ビュー追加" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 改善提案メインリスト — 列追加
# ============================================================
Write-Host "[1/3] 改善提案メイン — 列追加" -ForegroundColor Yellow

Add-PnPField -List "改善提案メイン" -DisplayName "現在の担当者" -InternalName "CurrentAssigneeEmail" -Type User `
    -ErrorAction SilentlyContinue
Write-Host "  CurrentAssigneeEmail（Person型）追加" -ForegroundColor Green

Add-PnPField -List "改善提案メイン" -DisplayName "評価開始日時" -InternalName "EvaluationStartDate" -Type DateTime `
    -ErrorAction SilentlyContinue
Write-Host "  EvaluationStartDate（日時型）追加" -ForegroundColor Green

# ============================================================
# 2. インデックス追加
# ============================================================
Write-Host ""
Write-Host "[2/3] 改善提案メイン — インデックス追加" -ForegroundColor Yellow

Set-PnPField -List "改善提案メイン" -Identity "CurrentAssigneeEmail" -Values @{Indexed = $true}
Write-Host "  CurrentAssigneeEmail インデックス追加" -ForegroundColor Green

# ============================================================
# 3. カスタムビュー作成
# ============================================================
Write-Host ""
Write-Host "[3/3] 改善提案メイン — カスタムビュー作成" -ForegroundColor Yellow

# ビュー1: すべてのアイテム（既存ビューの列・並び替えを更新）
Write-Host "  すべてのアイテム ビューを更新中..." -ForegroundColor Yellow
Set-PnPView -List "改善提案メイン" -Identity "すべてのアイテム" `
    -Fields @("RequestID", "Theme", "Status", "ApplicantName", "Created") `
    -Values @{
        ViewQuery = "<OrderBy><FieldRef Name='ID' Ascending='FALSE' /></OrderBy>"
    }
Write-Host "  すべてのアイテム 更新完了" -ForegroundColor Green

# ビュー2: 自分の申請（新規）
# 既存ビューが存在する場合は削除して再作成
Write-Host "  自分の申請 ビューを作成中..." -ForegroundColor Yellow
$existingView = Get-PnPView -List "改善提案メイン" -Identity "自分の申請" -ErrorAction SilentlyContinue
if ($existingView) {
    Remove-PnPView -List "改善提案メイン" -Identity "自分の申請" -Force
    Write-Host "    既存ビュー削除済み" -ForegroundColor Gray
}
Add-PnPView -List "改善提案メイン" -Title "自分の申請" `
    -Fields @("RequestID", "Theme", "Status", "CompletionDate", "FinalRewardAmount") `
    -Query "<Where><Eq><FieldRef Name='ApplicantEmail' /><Value Type='Integer'><UserID /></Value></Eq></Where><OrderBy><FieldRef Name='ID' Ascending='FALSE' /></OrderBy>"
Write-Host "  自分の申請 作成完了" -ForegroundColor Green

# ビュー3: 自分の承認待ち（新規）
Write-Host "  自分の承認待ち ビューを作成中..." -ForegroundColor Yellow
$existingView2 = Get-PnPView -List "改善提案メイン" -Identity "自分の承認待ち" -ErrorAction SilentlyContinue
if ($existingView2) {
    Remove-PnPView -List "改善提案メイン" -Identity "自分の承認待ち" -Force
    Write-Host "    既存ビュー削除済み" -ForegroundColor Gray
}
Add-PnPView -List "改善提案メイン" -Title "自分の承認待ち" `
    -Fields @("RequestID", "Theme", "Status", "ApplicantName", "Created") `
    -Query "<Where><Eq><FieldRef Name='CurrentAssigneeEmail' /><Value Type='Integer'><UserID /></Value></Eq></Where><OrderBy><FieldRef Name='ID' Ascending='FALSE' /></OrderBy>"
Write-Host "  自分の承認待ち 作成完了" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " パッチ適用完了！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "追加内容:" -ForegroundColor White
Write-Host "  列: CurrentAssigneeEmail（Person型）/ EvaluationStartDate（日時型）" -ForegroundColor White
Write-Host "  インデックス: CurrentAssigneeEmail" -ForegroundColor White
Write-Host "  ビュー: すべてのアイテム（更新）/ 自分の申請 / 自分の承認待ち" -ForegroundColor White
Write-Host ""
Write-Host "次のステップ:" -ForegroundColor Cyan
Write-Host "  - Power Apps の btnSubmit.OnSelect に CurrentAssigneeEmail/EvaluationStartDate の Patch を追加" -ForegroundColor Cyan
Write-Host "  - Power Apps の btnCancel.OnSelect に CurrentAssigneeEmail: Blank() を追加" -ForegroundColor Cyan
Write-Host "  - 既存フロー（No.1〜3, 回覧通知）の「項目の更新」に CurrentAssigneeEmail/EvaluationStartDate を追加" -ForegroundColor Cyan
Write-Host "  - リマインダーフロー（No.5）を新規構築" -ForegroundColor Cyan
