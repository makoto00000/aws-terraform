# AWS 勉強会 - トラブルシューティング環境構築手順書

## 概要

この勉強会では、Terraform と Ansible を使用して AWS 上に**意図的に問題のある Laravel 環境**を構築し、AWS コンソール上からトラブルシューティングを実施します。

### 構築される環境

- **AWS EC2** (Amazon Linux 2023)
- **VPC** (Virtual Private Cloud)
- **Application Load Balancer** (ALB)
- **Route53** (カスタムドメイン設定)
- **ACM** (SSL 証明書)
- **S3 バケット** (画像ストレージ)
- **セキュリティグループ** (SSH・HTTP/HTTPS アクセス許可)
- **Nginx** (Web サーバー)
- **PHP-FPM** (PHP 8.2)
- **Laravel** (最新版)
- **Composer** (依存関係管理)

### 学習目標

この環境では、AWS の各種サービスを使用した Web アプリケーションの構築と運用を学習します。

### 自動化の特徴

- **Terraform**: AWS インフラの自動構築
- **Ansible**: アプリケーション環境の自動構築

## 前提条件

- macOS、Linux
- AWS 認証情報の設定

## セットアップ手順

## 1. 必要なツールのインストール

### 1.1 Homebrew のインストール（すでに入っている方はスキップ）

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 1.2 AWS CLI のインストール

```bash
# macOS（Homebrew使用）
brew install awscli
```

### 1.3 Terraform のインストール

```bash
# macOS（Homebrew使用）
brew install terraform
```

### 1.4 Ansible のインストール

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

## 2. AWS アカウントの準備

### 2.0 Route53 ホストゾーンの確認

**重要**: この手順を実行する前に、使用するドメインのホストゾーンが Route53 に存在することを確認してください。

1. **AWS コンソール** → **Route53** サービスに移動
2. **ホストゾーン** を確認
3. 使用するドメイン（例: `horizon-infra-study01.click`）のホストゾーンが存在することを確認
4. 存在しない場合は、ホストゾーンを作成してください

### 2.1 AWS コンソールでの設定

1. **AWS コンソール**（https://aws.amazon.com/console/）にログイン
2. 右上のリージョンを**アジアパシフィック（東京）**に変更
3. **IAM**サービスに移動

### 2.2 IAM ユーザーの作成

1. **ユーザー** → **ユーザーを追加**
2. ユーザー名：`terraform-user`
3. **AWS マネジメントコンソールへのユーザーアクセスを提供する**のチェックは不要
4. **既存のポリシーを直接アタッチ**を選択
5. 以下のポリシーを検索・選択：
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
   - `AmazonRoute53FullAccess`
   - `AWSCertificateManagerFullAccess`
   - `AmazonS3FullAccess`
6. **ユーザーを作成**
7. **重要**: 以下の情報をメモしてください：
   - **アクセスキー ID**（例：`AKIA...`）
   - **シークレットアクセスキー**（例：`wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`）

## 3. プロジェクトのセットアップ

### 3.1 プロジェクトクローン

```bash
git clone https:// .....
cd aws-terraform
```

### 3.2 設定ファイルの準備

```bash
touch .env
```

### 3.3 AWS 認証情報の設定

```bash
vi .env
```

以下の内容に編集してください：

```
AWS_ACCESS_KEY_ID=AKIA...（アクセスキーID）
AWS_SECRET_ACCESS_KEY=...（シークレットキー）
AWS_DEFAULT_REGION=ap-northeast-1
DOMAIN_NAME=カスタムドメイン
```

### 3.4 SSH 鍵の生成

```bash
# プロジェクト内にキーディレクトリを作成
mkdir -p keys

# SSH鍵ペアを生成
ssh-keygen -t rsa -b 4096 -f keys/terraform-key -N "" -C "terraform-ec2-key"

# 権限設定
chmod 600 keys/terraform-key
chmod 644 keys/terraform-key.pub
```

## 4. AWS 接続のテスト

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

## 5. Terraform の実行

### 5.1 Terraform の初期化

```bash
# Terraformの初期化
terraform init
```

### 5.2 インフラの構築

```bash
# 環境変数を読み込み
set -a && source .env && set +a

# Terraformでインフラを構築
terraform apply -var="domain_name=$DOMAIN_NAME"

# 作成されるリソースが表示される
# 最後に yes を入力してEnter
```

## 6. Ansible で Laravel 環境の構築

### 6.1 Ansible インベントリの生成

```bash
# Ansibleディレクトリに移動
cd ansible

# インベントリファイルを生成
./generate-inventory.sh
```

### 6.2 Laravel 環境の構築

```bash
# AnsibleでLaravel環境を構築
ansible-playbook site.yml -v
```

このコマンドで以下が自動的に構築されます：

- **PHP-FPM** (PHP 8.2)
- **Nginx** (Web サーバー)
- **Laravel** (最新版)
- **Composer** (依存関係管理)
- **Apache の自動停止** (Nginx との競合を回避)
- **S3 画像の表示設定**

## 7. クリーンアップ

### 7.1 リソースの削除

```bash
# 環境変数を読み込み
set -a && source .env && set +a

# 全てのリソースを削除
terraform destroy -var="domain_name=$DOMAIN_NAME"

# 作成されるリソースが表示される
# 最後に yes を入力してEnter
```

---
