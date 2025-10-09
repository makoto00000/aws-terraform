# AWS設定
aws_region = "ap-northeast-1"

# プロジェクト設定
project_name = "laravel-app"

# VPC設定
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# EC2設定
# instance_type = "t3.micro"

# キーペア設定（どちらか一方を選択）
# 方法1: 新しいキーペアをTerraformで作成
create_key_pair = true
public_key_path = "keys/terraform-key.pub"

# 方法2: 既存のキーペアを使用
# create_key_pair = false
# key_name = "your-existing-key-pair-name"
