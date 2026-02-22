# ============================================================
# 改善提案システム - SharePoint Lists 一括作成スクリプト
# 設計書: v9 準拠
# ============================================================
# 使い方:
#   pwsh
#   Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "your-client-id"
#   ./create-lists.ps1
# ============================================================

$SiteUrl = "https://xxxxx.sharepoint.com/sites/kaizen-wf"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 改善提案システム - リスト一括作成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 社員マスタ
# ============================================================
Write-Host "[1/8] 社員マスタ を作成中..." -ForegroundColor Yellow

New-PnPList -Title "社員マスタ" -Template GenericList -Url "Lists/EmployeeMaster" -ErrorAction Stop

# Title列を非表示（使わない）
$titleField = Get-PnPField -List "社員マスタ" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "社員マスタ" -DisplayName "GID" -InternalName "GID" -Type Text -Required -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "氏名" -InternalName "EmployeeName" -Type Text -Required -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "メールアドレス" -InternalName "Email" -Type Text -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "在籍事業所" -InternalName "Office" -Type Text -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "社員区分" -InternalName "EmployeeType" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "職位" -InternalName "Position" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "管理職フラグ" -InternalName "IsManagement" -Type Boolean
Add-PnPField -List "社員マスタ" -DisplayName "原価単位" -InternalName "CostUnit" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "TEC" -InternalName "Department" -Type Text -AddToDefaultView
Add-PnPField -List "社員マスタ" -DisplayName "部" -InternalName "Bu" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "課" -InternalName "Section" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部門長GID" -InternalName "DeptHeadGID" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部門長氏名" -InternalName "DeptHeadName" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部門長本人フラグ" -InternalName "IsDeptHead" -Type Boolean
Add-PnPField -List "社員マスタ" -DisplayName "部長GID" -InternalName "DirectorGID" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部長氏名" -InternalName "DirectorName" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "部長本人フラグ" -InternalName "IsDirector" -Type Boolean
Add-PnPField -List "社員マスタ" -DisplayName "課長GID" -InternalName "ManagerGID" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "課長氏名" -InternalName "ManagerName" -Type Text
Add-PnPField -List "社員マスタ" -DisplayName "課長本人フラグ" -InternalName "IsManager" -Type Boolean
Add-PnPField -List "社員マスタ" -DisplayName "有効フラグ" -InternalName "IsActive" -Type Boolean

Write-Host "  → 社員マスタ 完了" -ForegroundColor Green

# ============================================================
# 2. 改善分野マスタ
# ============================================================
Write-Host "[2/8] 改善分野マスタ を作成中..." -ForegroundColor Yellow

New-PnPList -Title "改善分野マスタ" -Template GenericList -Url "Lists/CategoryMaster" -ErrorAction Stop

$titleField = Get-PnPField -List "改善分野マスタ" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "改善分野マスタ" -DisplayName "分野コード" -InternalName "CategoryCode" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善分野マスタ" -DisplayName "分野名" -InternalName "CategoryName" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善分野マスタ" -DisplayName "単位" -InternalName "Unit" -Type Text -AddToDefaultView
Add-PnPField -List "改善分野マスタ" -DisplayName "並び順" -InternalName "SortOrder" -Type Number -AddToDefaultView
Add-PnPField -List "改善分野マスタ" -DisplayName "金額換算単価" -InternalName "ConversionRate" -Type Number
Add-PnPFieldFromXml -List "改善分野マスタ" -FieldXml '<Field Type="Choice" DisplayName="分野種別" Name="CategoryType" Required="TRUE" Format="Dropdown"><CHOICES><CHOICE>金額算出</CHOICE><CHOICE>直接入力</CHOICE><CHOICE>テキスト</CHOICE></CHOICES></Field>'

Write-Host "  → 改善分野マスタ 完了" -ForegroundColor Green

# ============================================================
# 3. 表彰区分マスタ
# ============================================================
Write-Host "[3/8] 表彰区分マスタ を作成中..." -ForegroundColor Yellow

New-PnPList -Title "表彰区分マスタ" -Template GenericList -Url "Lists/AwardMaster" -ErrorAction Stop

$titleField = Get-PnPField -List "表彰区分マスタ" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "表彰区分マスタ" -DisplayName "区分コード" -InternalName "AwardCode" -Type Text -Required -AddToDefaultView
Add-PnPField -List "表彰区分マスタ" -DisplayName "区分名" -InternalName "AwardName" -Type Text -Required -AddToDefaultView
Add-PnPField -List "表彰区分マスタ" -DisplayName "褒賞金額" -InternalName "RewardAmount" -Type Number -AddToDefaultView
Add-PnPField -List "表彰区分マスタ" -DisplayName "評価スコアリング要否" -InternalName "RequiresScoring" -Type Boolean -AddToDefaultView
Add-PnPField -List "表彰区分マスタ" -DisplayName "並び順" -InternalName "SortOrder" -Type Number
Add-PnPField -List "表彰区分マスタ" -DisplayName "有効フラグ" -InternalName "IsActive" -Type Boolean

Write-Host "  → 表彰区分マスタ 完了" -ForegroundColor Green

# ============================================================
# 4. 改善提案メイン
# ============================================================
Write-Host "[4/8] 改善提案メイン を作成中..." -ForegroundColor Yellow

New-PnPList -Title "改善提案メイン" -Template GenericList -Url "Lists/KaizenMain" -ErrorAction Stop

$titleField = Get-PnPField -List "改善提案メイン" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "改善提案メイン" -DisplayName "リクエストID" -InternalName "RequestID" -Type Text -AddToDefaultView
Add-PnPField -List "改善提案メイン" -DisplayName "申請者メール" -InternalName "ApplicantEmail" -Type User -Required -AddToDefaultView
Add-PnPField -List "改善提案メイン" -DisplayName "申請者GID" -InternalName "ApplicantGID" -Type Text -Required
Add-PnPField -List "改善提案メイン" -DisplayName "申請者氏名" -InternalName "ApplicantName" -Type Text -Required -AddToDefaultView
Add-PnPFieldFromXml -List "改善提案メイン" -FieldXml '<Field Type="Choice" DisplayName="表彰区分" Name="AwardCategory" Required="TRUE" Format="Dropdown"><CHOICES><CHOICE>改善提案</CHOICE><CHOICE>パール賞</CHOICE><CHOICE>銅賞</CHOICE><CHOICE>銀賞</CHOICE></CHOICES></Field>'
Add-PnPField -List "改善提案メイン" -DisplayName "TEC" -InternalName "Department" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善提案メイン" -DisplayName "部" -InternalName "Bu" -Type Text
Add-PnPField -List "改善提案メイン" -DisplayName "課" -InternalName "Section" -Type Text
Add-PnPField -List "改善提案メイン" -DisplayName "係" -InternalName "Unit" -Type Text
Add-PnPField -List "改善提案メイン" -DisplayName "改善テーマ" -InternalName "Theme" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善提案メイン" -DisplayName "問題点" -InternalName "Problem" -Type Note -Required
Add-PnPField -List "改善提案メイン" -DisplayName "改善内容" -InternalName "Improvement" -Type Note -Required
Add-PnPField -List "改善提案メイン" -DisplayName "改善完了日" -InternalName "CompletionDate" -Type DateTime -Required
Add-PnPField -List "改善提案メイン" -DisplayName "効果金額合計" -InternalName "TotalEffectAmount" -Type Number -AddToDefaultView
Add-PnPFieldFromXml -List "改善提案メイン" -FieldXml '<Field Type="Choice" DisplayName="ステータス" Name="Status" Required="TRUE" Format="Dropdown"><Default>下書き</Default><CHOICES><CHOICE>下書き</CHOICE><CHOICE>申請中</CHOICE><CHOICE>課長評価中</CHOICE><CHOICE>部長評価中</CHOICE><CHOICE>承認済</CHOICE><CHOICE>差戻</CHOICE><CHOICE>取下げ</CHOICE></CHOICES></Field>'
Add-PnPField -List "改善提案メイン" -DisplayName "最終褒賞金額" -InternalName "FinalRewardAmount" -Type Number
Add-PnPField -List "改善提案メイン" -DisplayName "承認者（課長）" -InternalName "ApproverManager" -Type User -Required
Add-PnPField -List "改善提案メイン" -DisplayName "承認者（部長）" -InternalName "ApproverDirector" -Type User

# 添付ファイルはSharePointリストのデフォルト機能で有効（追加設定不要）

Write-Host "  → 改善提案メイン 完了" -ForegroundColor Green

# ============================================================
# 5. 改善メンバー
# ============================================================
Write-Host "[5/8] 改善メンバー を作成中..." -ForegroundColor Yellow

New-PnPList -Title "改善メンバー" -Template GenericList -Url "Lists/KaizenMembers" -ErrorAction Stop

$titleField = Get-PnPField -List "改善メンバー" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "改善メンバー" -DisplayName "リクエストID" -InternalName "RequestID" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善メンバー" -DisplayName "メンバーGID" -InternalName "MemberGID" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善メンバー" -DisplayName "メンバー氏名" -InternalName "MemberName" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善メンバー" -DisplayName "所属会社" -InternalName "MemberOffice" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善メンバー" -DisplayName "原価単位" -InternalName "MemberCostUnit" -Type Text -Required
Add-PnPField -List "改善メンバー" -DisplayName "並び順" -InternalName "SortOrder" -Type Number

Write-Host "  → 改善メンバー 完了" -ForegroundColor Green

# ============================================================
# 6. 改善分野実績
# ============================================================
Write-Host "[6/8] 改善分野実績 を作成中..." -ForegroundColor Yellow

New-PnPList -Title "改善分野実績" -Template GenericList -Url "Lists/KaizenCategoryResults" -ErrorAction Stop

$titleField = Get-PnPField -List "改善分野実績" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "改善分野実績" -DisplayName "リクエストID" -InternalName "RequestID" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善分野実績" -DisplayName "改善分野コード" -InternalName "CategoryCode" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善分野実績" -DisplayName "改善分野名" -InternalName "CategoryName" -Type Text -Required -AddToDefaultView
Add-PnPField -List "改善分野実績" -DisplayName "実績値" -InternalName "ActualValue" -Type Number -Required -AddToDefaultView
Add-PnPField -List "改善分野実績" -DisplayName "仕掛り金額" -InternalName "WIPAmount" -Type Number
Add-PnPField -List "改善分野実績" -DisplayName "コメント" -InternalName "Comment" -Type Note
Add-PnPField -List "改善分野実績" -DisplayName "効果金額算出式" -InternalName "Formula" -Type Text -Required
Add-PnPField -List "改善分野実績" -DisplayName "効果金額" -InternalName "EffectAmount" -Type Number -Required -AddToDefaultView

Write-Host "  → 改善分野実績 完了" -ForegroundColor Green

# ============================================================
# 7. 評価データ
# ============================================================
Write-Host "[7/8] 評価データ を作成中..." -ForegroundColor Yellow

New-PnPList -Title "評価データ" -Template GenericList -Url "Lists/EvaluationData" -ErrorAction Stop

$titleField = Get-PnPField -List "評価データ" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "評価データ" -DisplayName "リクエストID" -InternalName "RequestID" -Type Text -Required -AddToDefaultView
Add-PnPFieldFromXml -List "評価データ" -FieldXml '<Field Type="Choice" DisplayName="評価者種別" Name="EvaluatorType" Required="TRUE" Format="Dropdown"><CHOICES><CHOICE>課長</CHOICE><CHOICE>部長</CHOICE></CHOICES></Field>'
Add-PnPField -List "評価データ" -DisplayName "評価者メール" -InternalName "EvaluatorEmail" -Type User -Required -AddToDefaultView
Add-PnPFieldFromXml -List "評価データ" -FieldXml '<Field Type="Choice" DisplayName="表彰区分" Name="AwardCategory" Format="Dropdown"><CHOICES><CHOICE>改善提案</CHOICE><CHOICE>パール賞</CHOICE><CHOICE>銅賞</CHOICE><CHOICE>銀賞</CHOICE></CHOICES></Field>'
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

Write-Host "  → 評価データ 完了" -ForegroundColor Green

# ============================================================
# 8. ★ 承認履歴（提案プラン・任意）
# ============================================================
Write-Host "[8/8] ★ 承認履歴 を作成中..." -ForegroundColor Yellow

New-PnPList -Title "承認履歴" -Template GenericList -Url "Lists/ApprovalHistory" -ErrorAction Stop

$titleField = Get-PnPField -List "承認履歴" -Identity "Title"
$titleField | Set-PnPField -Values @{Required = $false; Hidden = $true}

Add-PnPField -List "承認履歴" -DisplayName "リクエストID" -InternalName "RequestID" -Type Text -Required -AddToDefaultView
Add-PnPFieldFromXml -List "承認履歴" -FieldXml '<Field Type="Choice" DisplayName="アクション" Name="Action" Required="TRUE" Format="Dropdown"><CHOICES><CHOICE>申請</CHOICE><CHOICE>承認</CHOICE><CHOICE>差戻</CHOICE><CHOICE>取下げ</CHOICE><CHOICE>再提出</CHOICE></CHOICES></Field>'
Add-PnPField -List "承認履歴" -DisplayName "実行者" -InternalName "Actor" -Type User -Required -AddToDefaultView
Add-PnPField -List "承認履歴" -DisplayName "コメント" -InternalName "HistoryComment" -Type Note
Add-PnPField -List "承認履歴" -DisplayName "実行日時" -InternalName "ActionDateTime" -Type DateTime -Required -AddToDefaultView
Add-PnPField -List "承認履歴" -DisplayName "ステータス変更前" -InternalName "StatusBefore" -Type Text
Add-PnPField -List "承認履歴" -DisplayName "ステータス変更後" -InternalName "StatusAfter" -Type Text

Write-Host "  → 承認履歴 完了" -ForegroundColor Green

# ============================================================
# インデックス作成（1-3）
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " インデックス作成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 社員マスタ
Write-Host "  社員マスタ: GID, Email, IsActive" -ForegroundColor Yellow
Set-PnPField -List "社員マスタ" -Identity "GID" -Values @{Indexed = $true}
Set-PnPField -List "社員マスタ" -Identity "Email" -Values @{Indexed = $true}
Set-PnPField -List "社員マスタ" -Identity "IsActive" -Values @{Indexed = $true}

# 改善提案メイン
Write-Host "  改善提案メイン: Status, ApplicantEmail, ApproverManager, ApproverDirector" -ForegroundColor Yellow
Set-PnPField -List "改善提案メイン" -Identity "Status" -Values @{Indexed = $true}
Set-PnPField -List "改善提案メイン" -Identity "ApplicantEmail" -Values @{Indexed = $true}
Set-PnPField -List "改善提案メイン" -Identity "ApproverManager" -Values @{Indexed = $true}
Set-PnPField -List "改善提案メイン" -Identity "ApproverDirector" -Values @{Indexed = $true}

# 評価データ
Write-Host "  評価データ: RequestID, EvaluatorType" -ForegroundColor Yellow
Set-PnPField -List "評価データ" -Identity "RequestID" -Values @{Indexed = $true}
Set-PnPField -List "評価データ" -Identity "EvaluatorType" -Values @{Indexed = $true}

# 改善メンバー
Write-Host "  改善メンバー: RequestID" -ForegroundColor Yellow
Set-PnPField -List "改善メンバー" -Identity "RequestID" -Values @{Indexed = $true}

# 改善分野実績
Write-Host "  改善分野実績: RequestID" -ForegroundColor Yellow
Set-PnPField -List "改善分野実績" -Identity "RequestID" -Values @{Indexed = $true}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " 全リスト・インデックス作成完了！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "作成されたリスト:" -ForegroundColor White
Write-Host "  [マスタ] 社員マスタ / 改善分野マスタ / 表彰区分マスタ" -ForegroundColor White
Write-Host "  [トランザクション] 改善提案メイン / 改善メンバー / 改善分野実績 / 評価データ" -ForegroundColor White
Write-Host "  [★提案プラン] 承認履歴" -ForegroundColor White
Write-Host ""
Write-Host "次のステップ: マスタデータ投入（1-4, 1-5）" -ForegroundColor Cyan
