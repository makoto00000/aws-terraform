# AWS勉強会 - Laravel環境構築手順書

## 概要
この勉強会では、TerraformとAnsibleを使用してAWS上にLaravelアプリケーションを自動構築します。

### 構築される環境
- **AWS EC2** (Amazon Linux 2023)
- **VPC** (Virtual Private Cloud)
- **セキュリティグループ** (SSH・HTTPアクセス許可)
- **Nginx** (Webサーバー)
- **PHP-FPM** (PHP 8.4)
- **Laravel** (最新版)
- **Composer** (依存関係管理)

### 自動化の特徴
- **Terraform**: AWSインフラの自動構築
- **Ansible**: アプリケーション環境の自動構築
- **完全自動化**: Apacheの停止からNginxの起動まで自動実行

## 前提条件
- macOS、Linux
- AWS認証情報の設定

## セットアップ手順

## 1. 必要なツールのインストール

### 1.1 Homebrewのインストール（すでに入っている方はスキップ）
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 1.2 AWS CLIのインストール
```bash
# macOS（Homebrew使用）
brew install awscli
```

### 1.3 Terraformのインストール
```bash
# macOS（Homebrew使用）
brew install terraform
```

### 1.4 Ansibleのインストール
```bash
# macOS（Homebrew使用）
brew install ansible
```

### 1.5 インストール確認
```bash
aws --version
terraform --version
ansible --version
```

## 2. AWSアカウントの準備

### 2.1 AWSコンソールでの設定
1. **AWSコンソール**（https://aws.amazon.com/console/）にログイン
2. 右上のリージョンを**アジアパシフィック（東京）**に変更
3. **IAM**サービスに移動

### 2.2 IAMユーザーの作成
1. **ユーザー** → **ユーザーを追加**
2. ユーザー名：`terraform-user`
3. **プログラムによるアクセス**を選択
4. **既存のポリシーを直接アタッチ**を選択
5. 以下のポリシーを検索・選択：
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
6. **ユーザーを作成**
7. **重要**: 以下の情報をメモしてください：
   - **アクセスキーID**（例：`AKIA...`）
   - **シークレットアクセスキー**（例：`wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`）

## 3. プロジェクトのセットアップ

### 3.1 プロジェクトクローン
```bash
git clone https:// .....
```

### 3.2 設定ファイルの準備
```bash
# 認証情報ファイルの作成
cp .env.example .env
```

### 3.3 AWS認証情報の設定
```bash
# 認証情報ファイルを編集
vim .env
```

以下の内容に編集してください：
```
AWS_ACCESS_KEY_ID=AKIA...（アクセスキーID）
AWS_SECRET_ACCESS_KEY=...（シークレットキー）
AWS_DEFAULT_REGION=ap-northeast-1
```

### 3.4 SSH鍵の生成
```bash
# プロジェクト内にキーディレクトリを作成
mkdir -p keys

# SSH鍵ペアを生成
ssh-keygen -t rsa -b 4096 -f keys/terraform-key -N "" -C "terraform-ec2-key"

# 権限設定
chmod 600 keys/terraform-key
chmod 644 keys/terraform-key.pub
```

## 4. AWS接続のテスト

### 4.1 接続テスト
```bash
# 環境変数を読み込み
set -a && source .env && set +a

# AWS接続をテスト
aws sts get-caller-identity
```

成功すると以下のような出力が表示されます：
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/terraform-user"
}
```

## 5. Terraformの実行

### 5.1 Terraformの初期化
```bash
# Terraformの初期化
terraform init
```

### 5.2 インフラの構築
```bash
# 環境変数を読み込み
set -a && source .env && set +a

# Terraformでインフラを構築
terraform apply

# 作成されるリソースが表示される
# 最後に yes を入力してEnter
```

## 6. AnsibleでLaravel環境の構築

### 6.1 Ansibleインベントリの生成
```bash
# Ansibleディレクトリに移動
cd ansible

# インベントリファイルを生成
./generate-inventory.sh
```

### 6.2 Laravel環境の構築
```bash
# AnsibleでLaravel環境を構築
ansible-playbook site.yml -v
```

このコマンドで以下が自動的に構築されます：
- **PHP-FPM** (PHP 8.4)
- **Nginx** (Webサーバー)
- **Laravel** (最新版)
- **Composer** (依存関係管理)
- **Apacheの自動停止** (Nginxとの競合を回避)

### 6.3 構築内容の確認
```bash
# パブリックIPを確認
cd ..
terraform output instance_public_ip

# ブラウザでアクセス
# http://<パブリックIP>
```

## 7. アプリケーションの確認

### 7.1 Webアプリケーションの確認

```bash
sh show-instance-info.sh
```
以下のように表示されるので、ブラウザで確認とSSH接続

=== アクセス方法 ===
HTTPアクセス: http://<パブリックIP>

SSHアクセス（作成した秘密鍵を使用）:
ssh -i keys/terraform-key ec2-user@<パブリックIP>

### 7.2 Laravelアプリケーションの確認
ブラウザで `http://<パブリックIP>` にアクセスすると、カスタマイズされたLaravelのウェルカムページが表示されます。

## 8. クリーンアップ

### 8.1 リソースの削除
```bash
# 環境変数を読み込み
set -a && source .env && set +a

# 全てのリソースを削除
terraform destroy

# 作成されるリソースが表示される
# 最後に yes を入力してEnter
```

---
