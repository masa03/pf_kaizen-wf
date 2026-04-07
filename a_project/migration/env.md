# 環境情報

## 環境一覧

| 環境 | テナント | App ID | .envファイル |
|---|---|---|---|
| 開発 (dev) | familiar | `37289bf7-75fd-48ce-833d-ad715131dbe3` | `.env.dev` |
| ステージング (stg) | Evolut | `06249ec4-6b92-4c4b-a54c-daf52c177a83` | `.env.stg` |
| 本番 (prod) | （未確定） | （未確定） | `.env.prod` |

---

## メールテンプレートの AppID 置換

`powerautomate/templates/` 配下の全HTMLファイルに `{AppID}` プレースホルダーが含まれている。
Power Automate にメール本文として貼り付ける前に、環境に合わせて置換すること。

### 方法A: スクリプトで一括置換（推奨）

```bash
# リポジトリルートで実行
./scripts/apply-env.sh dev    # 開発環境
./scripts/apply-env.sh stg    # ステージング環境
./scripts/apply-env.sh prod   # 本番環境
```

出力先: `powerautomate/templates-dist/{env}/`  
ソーステンプレートは変更されない。Power Automate に貼り付けるときは出力先のファイルを使用する。

### 方法B: 手動置換

テキストエディタで `{AppID}` を対応する App ID に一括置換する（エディタの「フォルダ内検索&置換」機能を使用）。

---

## 環境変数ファイルの管理

`.env.dev` / `.env.stg` / `.env.prod` は `a_project/migration/` 配下に配置。  
新しい環境変数を追加する場合はすべての `.env.*` ファイルに追記すること。

| 変数名 | 説明 |
|---|---|
| `APP_ID` | Power Apps アプリ ID（メールテンプレートの `{AppID}` に対応） |
