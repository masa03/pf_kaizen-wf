# ============================================================
# §3 回覧者機能 - 既存環境パッチスクリプト
# 対象: 既存テスト環境への差分適用
# 適用内容:
#   1. 改善提案メイン: Status列に「回覧中」選択肢を追加
#   2. 回覧者リスト（Lists/Reviewers）を新規作成
#   3. 回覧者リストの RequestID インデックス作成
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./patch-v3-reviewer.ps1
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " §3 回覧者機能 パッチ適用" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 改善提案メイン: Status列に「回覧中」を追加
# ============================================================
Write-Host "[1/2] 改善提案メイン: Status列に「回覧中」を追加中..." -ForegroundColor Yellow

$statusField = Get-PnPField -List "改善提案メイン" -Identity "Status"
$xml = $statusField.SchemaXml

# 「申請中」の後に「回覧中」が未追加の場合のみ追加
if ($xml -notmatch "回覧中") {
    $xml = $xml -replace '<CHOICE>課長評価中</CHOICE>', '<CHOICE>回覧中</CHOICE><CHOICE>課長評価中</CHOICE>'
    Set-PnPField -List "改善提案メイン" -Identity "Status" -Values @{SchemaXml = $xml}
    Write-Host "  → Status列に「回覧中」を追加しました" -ForegroundColor Green
} else {
    Write-Host "  → 「回覧中」は既に存在します。スキップ" -ForegroundColor Gray
}

# ============================================================
# 2. 回覧者リスト作成
# ============================================================
Write-Host "[2/2] 回覧者リスト を作成中..." -ForegroundColor Yellow

# 既存チェック
$existingList = Get-PnPList -Identity "Lists/Reviewers" -ErrorAction SilentlyContinue
if ($existingList) {
    Write-Host "  → 回覧者リストは既に存在します。スキップ" -ForegroundColor Gray
} else {
    New-PnPList -Title "回覧者" -Template GenericList -Url "Lists/Reviewers" -ErrorAction Stop

    $titleField = Get-PnPField -List "回覧者" -Identity "Title"
    $titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

    Add-PnPField -List "回覧者" -DisplayName "リクエストID" -InternalName "RequestID" -Type Text -Required -AddToDefaultView
    Add-PnPField -List "回覧者" -DisplayName "回覧者GID" -InternalName "ReviewerGID" -Type Text -Required -AddToDefaultView
    Add-PnPField -List "回覧者" -DisplayName "回覧者氏名" -InternalName "ReviewerName" -Type Text -Required -AddToDefaultView
    Add-PnPField -List "回覧者" -DisplayName "回覧者メール" -InternalName "ReviewerEmail" -Type Text -Required -AddToDefaultView
    Add-PnPField -List "回覧者" -DisplayName "回覧順" -InternalName "ReviewOrder" -Type Number -Required -AddToDefaultView
    Add-PnPFieldFromXml -List "回覧者" -FieldXml '<Field Type="Choice" DisplayName="ステータス" Name="ReviewStatus" Required="TRUE" Format="Dropdown"><Default>未回覧</Default><CHOICES><CHOICE>未回覧</CHOICE><CHOICE>承認</CHOICE><CHOICE>差戻</CHOICE></CHOICES></Field>'
    Add-PnPField -List "回覧者" -DisplayName "回覧日時" -InternalName "ReviewDateTime" -Type DateTime

    # インデックス作成
    Set-PnPField -List "回覧者" -Identity "RequestID" -Values @{Indexed = $true}

    Write-Host "  → 回覧者リスト作成完了" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " §3 パッチ適用完了！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "次のステップ: Power Apps データソースに「回覧者」リストを接続する" -ForegroundColor Cyan
