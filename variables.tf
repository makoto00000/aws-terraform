# 基本設定
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "laravel-app"
}

# VPC設定
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# EC2設定
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name (既存のキーペアを使用する場合)"
  type        = string
  default     = ""
}

variable "create_key_pair" {
  description = "新しいキーペアを作成するかどうか"
  type        = bool
  default     = false
}

variable "public_key_path" {
  description = "ローカルの公開鍵ファイルのパス"
  type        = string
  default     = "keys/terraform-key.pub"
}

# ドメイン設定
variable "domain_name" {
  description = "既存のRoute53ホストゾーンのドメイン名"
  type        = string
}

# セキュリティ設定
variable "allowed_ips" {
  description = "ALBへのアクセスを許可するIPアドレス（CIDR形式）"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}