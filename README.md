# AWS 勉強会 - トラブルシューティング環境構築手順書

## 概要

この勉強会では、Terraform と Ansible を使用して AWS 上に**意図的に問題のある Laravel 環境**を構築し、AWS コンソール上からトラブルシューティングを実施します。

### 構築される環境

- **AWS EC2** (Amazon Linux 2023)
- **VPC** (Virtual Private Cloud)
- **Application Load Balancer** (ALB)
- **S3 バケット** (画像ストレージ)
- **セキュリティグループ** (SSH・HTTP アクセス許可)
- **Nginx** (Web サーバー)
- **PHP-FPM** (PHP 8.2)
- **Laravel** (最新版)
- **Composer** (依存関係管理)

### 学習目標

この環境では、AWS の各種サービスを使用した Web アプリケーションの構築と運用を学習します。

### 自動化の特徴

- **Terraform**: AWS インフラの自動構築
- **Ansible**: アプリケーション環境の自動構築
- **完全自動化**: Apache の停止から Nginx の起動まで自動実行

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

### 2.1 AWS コンソールでの設定

1. **AWS コンソール**（https://aws.amazon.com/console/）にログイン
2. 右上のリージョンを**アジアパシフィック（東京）**に変更
3. **IAM**サービスに移動

### 2.2 IAM ユーザーの作成

1. **ユーザー** → **ユーザーを追加**
2. ユーザー名：`terraform-user`
3. **プログラムによるアクセス**を選択
4. **既存のポリシーを直接アタッチ**を選択
5. 以下のポリシーを検索・選択：
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
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
# 認証情報ファイルの作成（.envファイルが存在しない場合）
touch .env
```

### 3.3 AWS 認証情報の設定

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
terraform apply

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

### 6.3 構築内容の確認

```bash
# プロジェクトルートに戻る
cd ..

# 環境情報を表示
sh show-instance-info.sh
```

## 7. アプリケーションの確認

### 7.1 環境情報の確認

```bash
sh show-instance-info.sh
```

以下のように表示されます：

=== アクセス方法 ===
ALB 経由アクセス: http://<ALB の DNS 名>
EC2 直接アクセス: http://<パブリック IP>

=== SSH アクセス（作成した秘密鍵を使用）===
ssh -i keys/terraform-key ec2-user@<パブリック IP>

=== S3 バケット情報 ===
バケット名: <S3 バケット名>
バケット ARN: <S3 バケット ARN>

### 7.2 アプリケーションの動作確認

1. **ALB 経由アクセス**: `http://<ALBのDNS名>` にアクセスして Laravel アプリケーションを確認
2. **EC2 直接アクセス**: `http://<パブリックIP>` にアクセスしてアプリケーションの動作を確認
3. **S3 画像**: Laravel ページで画像の表示を確認

## 8. 運用とトラブルシューティング

### 8.1 アプリケーションの運用

構築された環境を使用して、以下の運用タスクを実施してください：

1. **Web アプリケーションの動作確認**
2. **AWS サービスの設定確認**
3. **問題発生時の対応手順の確認**

AWS コンソールを使用して、必要に応じて設定の調整や問題の解決を行ってください。

## 9. クリーンアップ

### 9.1 リソースの削除

```bash
# 環境変数を読み込み
set -a && source .env && set +a

# 全てのリソースを削除
terraform destroy

# 作成されるリソースが表示される
# 最後に yes を入力してEnter
```

---
