#!/bin/bash
# メールテンプレートの環境変数を置換して templates-dist/{env}/ に出力するスクリプト
#
# 使い方:
#   ./scripts/apply-env.sh dev     # 開発環境 (familiar)
#   ./scripts/apply-env.sh stg     # ステージング環境 (Evolut)
#   ./scripts/apply-env.sh prod    # 本番環境
#
# 出力先: powerautomate/templates-dist/{env}/
# ソーステンプレート (powerautomate/templates/) は変更しない

set -e

ENV=${1:-}

# 引数チェック
if [ -z "$ENV" ]; then
  echo "使い方: $0 [dev|stg|prod]"
  exit 1
fi

# スクリプトの場所からリポジトリルートを特定
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/scripts/env/.env.${ENV}"
TEMPLATE_DIR="$REPO_ROOT/powerautomate/templates"
OUTPUT_DIR="$REPO_ROOT/powerautomate/templates-dist/${ENV}"

# .envファイルの存在確認
if [ ! -f "$ENV_FILE" ]; then
  echo "エラー: 環境ファイルが見つかりません: $ENV_FILE"
  echo "対応環境: dev / stg / prod"
  exit 1
fi

# .envを読み込む（コメント行・空行を除外）
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
  export "$key"="$value"
done < "$ENV_FILE"

# APP_IDの確認
if [ -z "$APP_ID" ] || [[ "$APP_ID" == *"未確定"* ]]; then
  echo "エラー: APP_ID が設定されていません: $ENV_FILE を確認してください"
  exit 1
fi

# 出力ディレクトリ作成
mkdir -p "$OUTPUT_DIR"

echo "環境: $ENV"
echo "APP_ID: $APP_ID"
echo "出力先: $OUTPUT_DIR"
echo ""

# テンプレートHTMLを置換して出力
count=0
for src in "$TEMPLATE_DIR"/*.html; do
  filename=$(basename "$src")
  dst="$OUTPUT_DIR/$filename"
  sed "s/{AppID}/$APP_ID/g" "$src" > "$dst"
  echo "  ✓ $filename"
  ((count++))
done

echo ""
echo "完了: ${count}件のテンプレートを出力しました"
