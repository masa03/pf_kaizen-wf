# クライアントPC セットアップ手順（Windows）

移植作業用PCが空の状態から、必要なツールをインストールする手順書。

---

## 必要ツール一覧

| ツール | 用途 | 必須 |
|--------|------|------|
| **PowerShell 7 (pwsh)** | 全スクリプト（.ps1）の実行環境 | 必須 |
| **PnP.PowerShell モジュール** | SharePoint操作（リスト作成・マスタ投入・権限設定等） | 必須 |
| **VS Code** | スクリプト内の変数編集 | 推奨（メモ帳でも可） |
| **Webブラウザ（Edge）** | Power Apps / Power Automate / SharePoint管理センター操作 | 標準搭載 |

> **プロジェクトファイルの引き渡し**: Google Drive等でzip共有するため、Gitのインストールは不要。

---

## 1. PowerShell 7 (pwsh)

PnP PowerShellの実行に必要。Windows標準のWindows PowerShell 5.1とは別物。

### インストール

```powershell
# 方法A: winget（推奨）
winget install Microsoft.PowerShell

# 方法B: MSIインストーラー
# https://github.com/PowerShell/PowerShell/releases から最新の .msi をダウンロードして実行
```

### 確認

```
pwsh --version
```

`PowerShell 7.x.x` と表示されればOK。

---

## 2. PnP PowerShell モジュール

SharePointリスト作成・マスタ投入・権限設定など、スクリプト系のStep全てで使用（Step 2, 3, 4, 5, 9）。

### インストール

```powershell
pwsh
Install-Module PnP.PowerShell -Scope CurrentUser
```

> 「信頼されていないリポジトリからモジュールをインストールしますか？」と表示されたら `Y` を入力して続行。

### 確認

```powershell
Get-Module PnP.PowerShell -ListAvailable
```

バージョン番号が表示されればOK。

---

## 3. VS Code（推奨）

スクリプト内の `$SiteUrl`・`$ClientId` 等の変数書き換え作業に便利。

### インストール

```powershell
winget install Microsoft.VisualStudioCode
```

> メモ帳でも作業可能だが、PowerShellスクリプト（.ps1）の編集にはVS Codeが見やすい。

---

## 4. Webブラウザ

Power Apps Studio、Power Automate、SharePoint管理センターの操作に使用（Step 1, 6, 7, 8, 10）。

Windows標準搭載の **Microsoft Edge** をそのまま使用すればOK。追加インストール不要。

---

## 5. スクリプト実行ポリシーの変更

Windowsはデフォルトでスクリプト実行が無効化（`Restricted`）されている。初回実行時にエラーが出た場合は以下を実行する。

```powershell
# pwsh 内で実行（現在のユーザーのみに適用）
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

| エラー内容 | 対策 |
|-----------|------|
| `このシステムではスクリプトの実行が無効になっているため、ファイル ○○.ps1 を読み込むことができません。` | 上記コマンドを実行する |

---

## 6. Python（Step 3: Excel → CSV 変換時のみ）

社員マスタを Excel から CSV に変換する場合のみ必要（`convert-employee-xlsx.py`）。Python が使えない場合は Excel テンプレート方式で代替可能（deployment-guide.md Step 3 参照）。

macOS では `python3` / `pip3` だが、Windows では `python` / `pip` の場合がある。

```powershell
# インストール確認
python --version   # または python3 --version

# ライブラリインストール
pip install openpyxl   # または pip3 install openpyxl
```

> Microsoft Store版Pythonがインストールされている場合は `python3` でも動作する。

---

## 注意事項

### 事前にテナント管理者へ依頼しておくこと

以下はPCのツールではなく、テナント側の事前準備（deployment-guide.md Step 0 参照）:

- Azure AD（Entra ID）アプリ登録 → `{ClientId}` の取得
- SharePointサイト作成権限の付与
- Power Platform環境へのアクセス権付与
- ライセンス確認（Power Apps / Power Automate）

### ネットワーク制限がある場合

クライアントPCにプロキシやファイアウォール制限がある場合、`winget` や `Install-Module` が動作しない可能性がある。

**対策**: 事前に以下のオフラインインストーラーをUSBに入れて持ち込む。

| ツール | オフラインインストーラーの入手先 |
|--------|-------------------------------|
| PowerShell 7 | GitHub Releases (`https://github.com/PowerShell/PowerShell/releases`) から `.msi` をダウンロードしてUSBに保存。移植先PCでダブルクリックして実行 |
| PnP.PowerShell | 下記「PnP.PowerShell のオフライン準備手順」参照 |
| VS Code | `https://code.visualstudio.com/download` から `.exe` をダウンロードしてUSBに保存 |

> **事前確認推奨**: クライアントのネットワーク環境でインターネット接続・ソフトウェアインストールが可能かどうか、訪問前に確認しておくこと。

#### PnP.PowerShell のオフライン準備手順

**① 手元のPC（インターネット接続可能な環境）で実行**

```powershell
# pwsh を起動して実行
mkdir ./pnp-module
Save-Module PnP.PowerShell -Path ./pnp-module
```

生成された `pnp-module/` フォルダをUSBにコピーする。

**② 移植先PC（クライアントPC）で実行**

```powershell
# USBの pnp-module フォルダを Documents\PowerShell\Modules\ にコピー
# （E:\ はUSBのドライブレター。環境に合わせて変更）
Copy-Item -Path "E:\pnp-module\PnP.PowerShell" `
          -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PnP.PowerShell" `
          -Recurse

# インストール確認
Get-Module PnP.PowerShell -ListAvailable
```

`Documents\PowerShell\Modules\` に配置すれば、そのユーザーアカウントのpwshからどこでも `PnP.PowerShell` が使えるようになる。
