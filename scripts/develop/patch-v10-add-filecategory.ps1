# ============================================================
# [v10] 添付ファイルライブラリに FileCategory 列追加パッチ
# ============================================================
# 既存環境に FileCategory（ファイル種別）列を追加する
# 新規環境は create-doclib.ps1 で一括作成されるため不要
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " [v10] FileCategory列追加パッチ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ファイル種別列を追加（改善前/改善後/その他）
$fileCategoryXml = '<Field Type="Choice" DisplayName="ファイル種別" Name="FileCategory" Required="TRUE"><Default>その他</Default><CHOICES><CHOICE>改善前</CHOICE><CHOICE>改善後</CHOICE><CHOICE>その他</CHOICE></CHOICES></Field>'
Add-PnPFieldFromXml -List "添付ファイル" -FieldXml $fileCategoryXml

Write-Host "  → FileCategory列追加完了" -ForegroundColor Green
Write-Host ""
Write-Host "【注意】既存の添付ファイルは FileCategory='その他' がデフォルト設定されます" -ForegroundColor Yellow
