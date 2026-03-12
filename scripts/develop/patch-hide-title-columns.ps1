# ============================================================
# パッチ: 全リストの Title 列を非表示にする
# 既存環境で Title 列が表示されている場合に適用
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./develop/patch-hide-title-columns.ps1
#
# 注意:
#   Hidden = $true だけではデフォルトビューから消えない。
#   ビューからも明示的に列を削除する必要がある。
# ============================================================

$lists = @(
    "社員マスタ",
    "改善分野マスタ",
    "表彰区分マスタ",
    "改善提案メイン",
    "改善メンバー",
    "改善分野実績",
    "評価データ",
    "承認履歴"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Title列 非表示パッチ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($listName in $lists) {
    try {
        # 1. 列のプロパティを非表示に設定
        $titleField = Get-PnPField -List $listName -Identity "Title" -ErrorAction Stop
        $titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

        # 2. デフォルトビューから Title 列を削除
        $view = Get-PnPView -List $listName -Identity "すべてのアイテム" -ErrorAction SilentlyContinue
        if (-not $view) {
            $view = Get-PnPView -List $listName -Identity "All Items" -ErrorAction SilentlyContinue
        }
        if ($view -and ($view.ViewFields -contains "LinkTitle")) {
            $view.ViewFields.Remove("LinkTitle")
            $view.Update()
            Invoke-PnPQuery
            Write-Host "  [OK] $listName (列非表示 + ビューから削除)" -ForegroundColor Green
        } else {
            Write-Host "  [OK] $listName (列非表示設定済み)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  [SKIP] $listName ($_)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "完了" -ForegroundColor Green
