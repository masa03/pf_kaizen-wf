# ============================================================
# 改善提案システム - ドキュメントライブラリ作成スクリプト
# 設計書: v9 準拠
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./create-doclib.ps1
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 改善提案システム - ドキュメントライブラリ作成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 添付ファイル用ドキュメントライブラリ作成
# ============================================================
Write-Host "[1/1] 添付ファイルライブラリ を作成中..." -ForegroundColor Yellow

New-PnPList -Title "添付ファイル" -Template DocumentLibrary -Url "AttachmentFiles" -ErrorAction Stop

# リクエストID列を追加（提案との紐付け用）
Add-PnPField -List "添付ファイル" -DisplayName "リクエストID" -InternalName "RequestID" -Type Text -Required -AddToDefaultView

# 説明列を追加（ファイルの補足情報用）
Add-PnPField -List "添付ファイル" -DisplayName "説明" -InternalName "FileDescription" -Type Note -AddToDefaultView

# リクエストIDにインデックスを作成（検索高速化）
$field = Get-PnPField -List "添付ファイル" -Identity "RequestID"
$field.Indexed = $true
$field.Update()
Invoke-PnPQuery

Write-Host "  → ライブラリ作成完了" -ForegroundColor Green
Write-Host "  → RequestID列追加（インデックス付き）" -ForegroundColor Green
Write-Host "  → 説明列追加" -ForegroundColor Green
Write-Host ""

# ============================================================
# 完了サマリー
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " ドキュメントライブラリ作成 完了" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "作成したライブラリ:" -ForegroundColor White
Write-Host "  添付ファイル (AttachmentFiles)" -ForegroundColor Green
Write-Host "    - RequestID列（インデックス付き）: 提案との紐付け" -ForegroundColor Green
Write-Host "    - 説明列: ファイルの補足情報" -ForegroundColor Green
Write-Host ""
Write-Host "【次のステップ】" -ForegroundColor Yellow
Write-Host "  Power Apps の添付ファイルコントロール（タスク2-7）で" -ForegroundColor Yellow
Write-Host "  このライブラリをデータソースとして接続してください" -ForegroundColor Yellow
