# ============================================================
# [v9.2] 評価データリストを再作成
#   - 表彰区分名変更（小集団 パール賞（3等）/ 銅賞（2等）/ 銀賞（1等））
#   - おすすめ情報（IsRecommended）カラム追加
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./patch-v92-evaluation-data.ps1
#
# ⚠ 注意: 既存の評価データリストを削除して再作成します。
#          既存データがある場合は事前にバックアップしてください。
# ============================================================

$ErrorActionPreference = "Stop"

# --- Step 1: 既存リスト削除 ---
Write-Host "[v9.2] 評価データリストを削除中..." -ForegroundColor Yellow
try {
    Remove-PnPList -Identity "評価データ" -Force
    Write-Host "  → 既存リスト削除完了" -ForegroundColor Green
}
catch {
    Write-Host "  → リストが存在しないためスキップ" -ForegroundColor Gray
}

# --- Step 2: リスト再作成 ---
Write-Host "[v9.2] 評価データリストを作成中..." -ForegroundColor Yellow

New-PnPList -Title "評価データ" -Template GenericList -Url "Lists/EvaluationData"

$titleField = Get-PnPField -List "評価データ" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "評価データ" -DisplayName "リクエストID" -InternalName "RequestID" -Type Text -Required -AddToDefaultView
Add-PnPFieldFromXml -List "評価データ" -FieldXml '<Field Type="Choice" DisplayName="評価者種別" Name="EvaluatorType" Required="TRUE" Format="Dropdown"><CHOICES><CHOICE>課長</CHOICE><CHOICE>部長</CHOICE></CHOICES></Field>'
Add-PnPField -List "評価データ" -DisplayName "評価者メール" -InternalName "EvaluatorEmail" -Type User -Required -AddToDefaultView
Add-PnPFieldFromXml -List "評価データ" -FieldXml '<Field Type="Choice" DisplayName="表彰区分" Name="AwardCategory" Format="Dropdown"><CHOICES><CHOICE>改善提案</CHOICE><CHOICE>小集団 パール賞（3等）</CHOICE><CHOICE>小集団 銅賞（2等）</CHOICE><CHOICE>小集団 銀賞（1等）</CHOICE></CHOICES></Field>'
Add-PnPField -List "評価データ" -DisplayName "金額算定フラグ" -InternalName "EffectCalcFlag" -Type Boolean
Add-PnPField -List "評価データ" -DisplayName "①効果_点数" -InternalName "EffectScore" -Type Number
Add-PnPField -List "評価データ" -DisplayName "②独創性" -InternalName "CreativityScore" -Type Number
Add-PnPField -List "評価データ" -DisplayName "③努力工夫" -InternalName "EffortScore" -Type Number
Add-PnPField -List "評価データ" -DisplayName "④応用範囲" -InternalName "ScopeScore" -Type Number
Add-PnPField -List "評価データ" -DisplayName "素点合計" -InternalName "RawTotal" -Type Number
Add-PnPField -List "評価データ" -DisplayName "職能換算" -InternalName "AdjustedScore" -Type Number
Add-PnPField -List "評価データ" -DisplayName "等級" -InternalName "Grade" -Type Text -AddToDefaultView
Add-PnPField -List "評価データ" -DisplayName "褒賞金額" -InternalName "RewardAmount" -Type Number -AddToDefaultView
Add-PnPField -List "評価データ" -DisplayName "コメント" -InternalName "EvalComment" -Type Note
Add-PnPFieldFromXml -List "評価データ" -FieldXml '<Field Type="Choice" DisplayName="判定" Name="Decision" Format="Dropdown"><CHOICES><CHOICE>承認</CHOICE><CHOICE>差戻</CHOICE></CHOICES></Field>'
Add-PnPField -List "評価データ" -DisplayName "評価日時" -InternalName "EvalDateTime" -Type DateTime
Add-PnPField -List "評価データ" -DisplayName "おすすめ情報" -InternalName "IsRecommended" -Type Boolean  # [v9.2] 追加

# --- Step 3: インデックス ---
Write-Host "  インデックス作成中..." -ForegroundColor Yellow
Set-PnPField -List "評価データ" -Identity "RequestID" -Values @{Indexed = $true}
Set-PnPField -List "評価データ" -Identity "EvaluatorType" -Values @{Indexed = $true}

Write-Host "  → 評価データリスト作成完了（v9.2: 表彰区分名変更 + IsRecommended追加）" -ForegroundColor Green
