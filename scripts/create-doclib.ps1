# ============================================================
# 改善提案システム - ドキュメントライブラリ作成スクリプト
# 設計書: v10 準拠
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

# ファイル種別列を追加（改善前/改善後/その他）[v10]
$fileCategoryXml = '<Field Type="Choice" DisplayName="ファイル種別" Name="FileCategory" Required="TRUE"><Default>その他</Default><CHOICES><CHOICE>改善前</CHOICE><CHOICE>改善後</CHOICE><CHOICE>その他</CHOICE></CHOICES></Field>'
Add-PnPFieldFromXml -List "添付ファイル" -FieldXml $fileCategoryXml

# 説明列を追加（ファイルの補足情報用）
Add-PnPField -List "添付ファイル" -DisplayName "説明" -InternalName "FileDescription" -Type Note

# デフォルトビューを設定（全列作成後）
Add-PnPView -List "添付ファイル" -Title "すべてのドキュメント" -Fields "DocIcon", "LinkFilename", "RequestID", "FileCategory", "FileDescription" -SetAsDefault

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
Write-Host "    - FileCategory列（選択肢）: 改善前/改善後/その他" -ForegroundColor Green
Write-Host "    - 説明列: ファイルの補足情報" -ForegroundColor Green
Write-Host ""
Write-Host "【次のステップ】" -ForegroundColor Yellow
Write-Host "  Power Apps の添付ファイルコントロール（タスク2-7）で" -ForegroundColor Yellow
Write-Host "  このライブラリをデータソースとして接続してください" -ForegroundColor Yellow
