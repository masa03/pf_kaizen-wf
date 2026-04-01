# ============================================================
# 添付ファイルステージングリスト 作成スクリプト（§1 差分パッチ）
# 対象: 既存環境への差分適用（新規環境は create-lists.ps1 に統合予定）
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./patch-staging-list.ps1
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 添付ファイルステージングリスト 作成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 添付ファイルステージング（新規）
# ============================================================
Write-Host "[1/1] 添付ファイルステージング を作成中..." -ForegroundColor Yellow

# 既存チェック
$existingList = Get-PnPList -Identity "添付ファイルステージング" -ErrorAction SilentlyContinue
if ($existingList) {
    Write-Host "  -> 既に存在します。スキップします。" -ForegroundColor DarkYellow
} else {
    New-PnPList -Title "添付ファイルステージング" -Template GenericList -Url "Lists/AttachmentStaging" -ErrorAction Stop
    Write-Host "  -> リスト作成完了" -ForegroundColor Green

    # FileCategory 列追加
    Add-PnPField -List "添付ファイルステージング" -DisplayName "ファイルカテゴリ" -InternalName "FileCategory" -Type Text -AddToDefaultView
    Write-Host "  -> FileCategory 列追加完了" -ForegroundColor Green

    # 添付ファイルを有効化（SP リストはデフォルトで有効だが明示的に確認）
    Set-PnPList -Identity "添付ファイルステージング" -EnableAttachments $true
    Write-Host "  -> Attachments 有効化確認完了" -ForegroundColor Green

    # Title列を非表示（UIには不要）
    $titleField = Get-PnPField -List "添付ファイルステージング" -Identity "Title"
    $titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}
    Write-Host "  -> Title列 非表示設定完了" -ForegroundColor Green

    # インデックス追加（Power Apps のフィルタ高速化）
    Set-PnPField -List "添付ファイルステージング" -Identity "FileCategory" -Values @{Indexed = $true}
    Write-Host "  -> FileCategory インデックス追加完了" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 完了" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "次の手順:" -ForegroundColor Yellow
Write-Host "  1. Power Apps Studio で「添付ファイルステージング」をデータソースに追加"
Write-Host "  2. a_project/migration/ui-manual-2-7.md の §1 対応手順を実施"
