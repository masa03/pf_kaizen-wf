# 環境情報

## Power Apps App ID

| 環境 | テナント/環境名 | App ID |
|---|---|---|
| 開発 | familiar | `37289bf7-75fd-48ce-833d-ad715131dbe3` |
| Staging | Evolut | `06249ec4-6b92-4c4b-a54c-daf52c177a83` |

## メールテンプレートの AppID 置換

`powerautomate/templates/` 配下の全HTMLファイルに `{AppID}` プレースホルダーが含まれている。
Power Automate に貼り付ける前に、上記の対応する環境の App ID に置換すること。
