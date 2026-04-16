# メールテンプレートの環境変数を置換して templates-dist/ に出力するスクリプト
#
# 使い方:
#   ./scripts/apply-env.ps1 dev     # 開発環境 (familiar)
#   ./scripts/apply-env.ps1 stg     # ステージング環境 (Evolut)
#   ./scripts/apply-env.ps1 prod    # 本番環境
#   ./scripts/apply-env.ps1 clear   # templates-dist/ を全削除
#
# 出力先: powerautomate/templates-dist/
# ソーステンプレート (powerautomate/templates/) は変更しない

param(
    [Parameter(Position = 0)]
    [string]$Env_Name
)

if (-not $Env_Name) {
    Write-Host "使い方: ./scripts/apply-env.ps1 [dev|stg|prod|clear]"
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$OutputDir = Join-Path $RepoRoot "powerautomate/templates-dist"

# clearコマンド
if ($Env_Name -eq "clear") {
    if (Test-Path $OutputDir) {
        Remove-Item -Recurse -Force $OutputDir
        Write-Host "削除しました: $OutputDir"
    } else {
        Write-Host "既に空です: $OutputDir"
    }
    exit 0
}

$EnvFile = Join-Path $RepoRoot "scripts/env/.env.$Env_Name"
$TemplateDir = Join-Path $RepoRoot "powerautomate/templates"

# .envファイルの存在確認
if (-not (Test-Path $EnvFile)) {
    Write-Host "エラー: 環境ファイルが見つかりません: $EnvFile"
    Write-Host "対応環境: dev / stg / prod"
    exit 1
}

# .envを読み込む（コメント行・空行を除外）
$AppId = $null
Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts[0] -eq "APP_ID") {
            $AppId = $parts[1]
        }
    }
}

# APP_IDの確認
if (-not $AppId -or $AppId -match "未確定") {
    Write-Host "エラー: APP_ID が設定されていません: $EnvFile を確認してください"
    exit 1
}

# 出力ディレクトリ作成
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Host "環境: $Env_Name"
Write-Host "APP_ID: $AppId"
Write-Host "出力先: $OutputDir"
Write-Host ""

# テンプレートHTMLを置換して出力
$count = 0
Get-ChildItem -Path $TemplateDir -Filter "*.html" | ForEach-Object {
    $filename = $_.Name
    $dst = Join-Path $OutputDir "${Env_Name}_${filename}"
    $content = Get-Content $_.FullName -Raw -Encoding UTF8
    $content = $content -replace "\{AppID\}", $AppId
    Set-Content -Path $dst -Value $content -Encoding UTF8 -NoNewline
    Write-Host "  ✓ ${Env_Name}_${filename}"
    $count++
}

Write-Host ""
Write-Host "完了: ${count}件のテンプレートを出力しました"
