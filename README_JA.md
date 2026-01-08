# LocalSignTools

iOSアプリの署名を簡単に行うためのローカル実行版ツールです。統合Builderを使用して、単一のマシン上で完全に動作します。

## 概要

LocalSignToolsは、SignToolsの統合版のみを含むシンプルなローカル実行版です。外部ビルダーやCI/CDサービスは不要で、すべての処理がローカルで実行されます。

## 主な特徴

- **統合Builder**: 署名処理を内部で実行（別サーバー不要）
- **シンプルな構成**: 統合版のみで構成され、コードが簡潔
- **自動ポート管理**: デフォルトポートが使用中の場合は自動的にランダムポートを使用
- **自動クリーンアップ**: 古いアップロードファイルを自動削除
- **2FA対応**: Apple Developerアカウントの2段階認証に対応
- **Webインターフェース**: ブラウザから簡単に操作可能

## 必要な環境

- macOS（iOSアプリの署名にはmacOSが必要）
- Go 1.24.0以上（ビルド時）
- fastlane（署名処理に必要）
- Python 3（署名スクリプトに必要）
- Node.js（署名スクリプトに必要）

### 依存関係のインストール

```bash
# fastlaneのインストール
brew install fastlane
# または
gem install fastlane

# Python 3とNode.jsは通常macOSに含まれています
```

## セットアップ

### 1. プロジェクトのビルド

```bash
cd LocalSignTools

# 依存関係のダウンロード
go mod download

# ビルド
go build -o SignTools
```

### 2. 設定ファイルの準備

初回起動時に`signer-cfg.yml`が自動生成されます。必要に応じて編集してください：

```yaml
builder:
    integrated:
        enable: true
        sign_files_dir: ./builder
        entrypoint: sign.py
        job_timeout_mins: 15
server_url: http://localhost:8080
save_dir: data
cleanup_interval_mins: 5
sign_timeout_mins: 60
```

### 3. 署名プロファイルの設定

`data/profiles/`ディレクトリに署名プロファイルを作成します。

#### 開発者アカウントプロファイル

`data/profiles/developer_account/`ディレクトリに以下のファイルを配置：

- `cert.p12`: 証明書ファイル
- `cert_pass.txt`: 証明書のパスワード
- `account_name.txt`: Apple Developerアカウントのメールアドレス
- `account_pass.txt`: Apple Developerアカウントのパスワード
- `name.txt`: 開発者名（例: "Tatsuya Kawabata"）

#### カスタムプロビジョニングプロファイル

`data/profiles/custom_profile/`ディレクトリに以下のファイルを配置：

- `cert.p12`: 証明書ファイル
- `cert_pass.txt`: 証明書のパスワード
- `prov.mobileprovision`: プロビジョニングプロファイル
- `name.txt`: プロファイル名

### 4. 機密ファイルのパーミッション設定

機密情報を含むファイルのパーミッションを制限します：

```bash
chmod 600 data/profiles/*/cert.p12
chmod 600 data/profiles/*/cert_pass.txt
chmod 600 data/profiles/*/account_name.txt
chmod 600 data/profiles/*/account_pass.txt
```

## 使用方法

### サービスの起動

```bash
./SignTools
```

### Webインターフェースへのアクセス

ブラウザで以下のURLにアクセス：

```
http://localhost:8080
```

ポート8080が使用中の場合は、自動的にランダムポートが使用されます。起動時のログで実際のポート番号を確認してください。

## 2段階認証（2FA）

Apple Developerアカウントで2FAが有効な場合、署名時に2FAコードの入力が求められます。

### 2FAコードの入力

1. 署名ジョブを開始すると、Webインターフェースに2FA入力画面が表示されます
2. Appleから送信された2FAコードを入力
3. 署名処理が続行されます

### 2FAのトラブルシューティング

2FAコードが届かない場合：

```bash
# 2FA設定を確認
./check_2fa.sh

# fastlane認証を直接テスト
./debug_2fa.sh
```

確認事項：
- `account_name.txt`のメールアドレスが正しいか
- Apple Developerアカウントで2FAが有効か
- アカウントがロックされていないか

## ファイル管理

### 自動クリーンアップ

- **アップロードファイル**: 60分以上経過したファイルは自動削除
- **ジョブ**: タイムアウト後に自動削除
- 起動時と定期的（5分間隔）にクリーンアップを実行

### 手動クリーンアップ

```bash
# uploadsディレクトリの古いファイルを削除
find data/uploads -type f -mtime +1 -delete
```

## トラブルシューティング

### ポートが既に使用中

デフォルトポート（8080）が使用中の場合、自動的にランダムポートが使用されます。起動ログで実際のポート番号を確認してください。

### 署名に失敗する

1. fastlaneが正しくインストールされているか確認
2. 証明書とプロファイルが正しく設定されているか確認
3. ログを確認（`-log-level 0`で詳細ログを表示）

```bash
./SignTools -log-level 0
```

### 2FAコードが届かない

1. `account_name.txt`のメールアドレスを確認
2. `debug_2fa.sh`でfastlane認証をテスト
3. Apple Developerアカウントの設定を確認

## ディレクトリ構造

```
LocalSignTools/
├── SignTools                 # メイン実行ファイル
├── signer-cfg.yml           # 設定ファイル
├── data/                    # データディレクトリ
│   ├── apps/               # アップロードされたアプリ
│   ├── profiles/           # 署名プロファイル
│   └── uploads/            # 一時アップロードファイル
├── builder/                # 署名スクリプト
└── src/                     # ソースコード
```

## 設定ファイルの詳細

### 主要な設定項目

- `cleanup_interval_mins`: クリーンアップ実行間隔（分）
- `sign_timeout_mins`: 署名タイムアウト（分）
- `server_url`: サーバーURL
- `save_dir`: データ保存ディレクトリ

### Builder設定

- `integrated.enable`: 統合Builderの有効/無効（常にtrue）
- `integrated.sign_files_dir`: 署名スクリプトのディレクトリ
- `integrated.entrypoint`: エントリーポイントスクリプト
- `integrated.job_timeout_mins`: ジョブタイムアウト（分）

## セキュリティ

- 機密ファイル（証明書、パスワード）のパーミッションを`600`に設定
- ローカル環境での使用を想定
- 必要に応じてBasic認証を有効化

```yaml
basic_auth:
    enable: true
    username: admin
    password: YOUR_PASSWORD
```

## 元のSignToolsとの違い

LocalSignToolsは、元のSignToolsから以下の機能を削除したシンプル版です：

- GitHub Actions Builder
- Semaphore CI Builder
- Self-hosted Builder（外部サーバー）

統合Builderのみをサポートし、ローカル環境での使用に最適化されています。

## ライセンス

このプロジェクトは**GNU Affero General Public License v3.0 (AGPL-3.0)**の下でライセンスされています。

完全なライセンス文書は`LICENSE`ファイルを参照してください。

### ライセンス概要

- ✅ **商用利用**: 可能
- ✅ **改変**: 可能
- ✅ **配布**: 可能
- ✅ **私的利用**: 可能
- ✅ **特許利用**: 可能
- ❌ **サブライセンス**: 不可
- ❌ **保証**: なし
- ⚠️ **コピーレフト**: 改変版も同じライセンスで公開する必要があります
- ⚠️ **ネットワーク利用**: サーバー上で改変版を実行する場合、ユーザーにソースコードを提供する必要があります

このプロジェクトは[SignTools](https://github.com/SignTools/SignTools)をベースにしており、同様にAGPL-3.0でライセンスされています。

## 謝辞

このプロジェクトは、オープンソースのiOSアプリ署名ツールである[SignTools](https://github.com/SignTools/SignTools)をベースにしています。LocalSignToolsは、元のプロジェクトの署名インフラストラクチャとの互換性を維持しながら、ローカル開発での使いやすさに焦点を当てた、シンプルなローカル専用版です。

優れたiOSアプリ署名ワークフローの基盤を作成してくださった、元のSignToolsプロジェクトとその貢献者の皆様に感謝の意を表します。

## 貢献

これはシンプルさに焦点を当てたローカル専用版です。メインのSignToolsプロジェクトへの貢献については、[元のリポジトリ](https://github.com/SignTools/SignTools)を参照してください。
