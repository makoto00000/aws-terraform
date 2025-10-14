# AWS Provider設定
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# データソース
data "aws_availability_zones" "available" {
  state = "available"
}

# Route53 ホストゾーンの参照
data "aws_route53_zone" "main" {
  name = var.domain_name
}

# ローカルSSH鍵の読み込み
data "local_file" "public_key" {
  count    = var.create_key_pair ? 1 : 0
  filename = var.public_key_path
}

# キーペアの作成
resource "aws_key_pair" "main" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = data.local_file.public_key[0].content

  tags = {
    Name = "${var.project_name}-key"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# パブリックサブネット
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone        = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# ルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# ルートテーブル関連付け
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# セキュリティグループ
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = aws_vpc.main.id

  # SSH アクセス (ポート 22) - 全IP許可
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP アクセス (ポート 80) - ALBからのみ許可
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # アウトバウンドトラフィック
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# ALB用セキュリティグループ
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = aws_vpc.main.id

  # HTTP アクセス (ポート 80) - IP制限
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # HTTPS アクセス (ポート 443) - IP制限
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # アウトバウンドトラフィック
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# データソース: Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# EC2インスタンス
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.create_key_pair ? aws_key_pair.main[0].key_name : (var.key_name != "" ? var.key_name : null)

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from Amazon Linux 2023!</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.project_name}-web-server"
  }
}

# S3バケット（画像用）
resource "aws_s3_bucket" "images" {
  bucket = "${var.project_name}-images-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-images"
  }
}

# S3バケットのランダムサフィックス
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3バケットのパブリックアクセスブロック
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3バケットのバージョニング
resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3バケットのサーバーサイド暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# horizon.webp画像のアップロード
resource "aws_s3_object" "horizon_image" {
  bucket = aws_s3_bucket.images.id
  key    = "horizon.webp"
  source = "horizon.webp"
  etag   = filemd5("horizon.webp")
  
  content_type = "image/webp"
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ALB ターゲットグループ
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# ALB ターゲットグループアタッチメント
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}

# ALB リスナー（削除 - HTTPSリダイレクトに置き換え）
# resource "aws_lb_listener" "web" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "80"
#   protocol          = "HTTP"
#
#   # デフォルトアクション: EC2に転送
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web.arn
#   }
# }

# ALB リスナールール（削除 - HTTPSリスナーに移行）
# resource "aws_lb_listener_rule" "root_redirect" {
#   listener_arn = aws_lb_listener.web.arn
#   priority     = 1
#
#   action {
#     type = "redirect"
#
#     redirect {
#       port        = "80"
#       protocol    = "HTTP"
#       status_code = "HTTP_302"
#       host        = "aws.amazon.com"
#       path        = "/jp/?nc2=h_home"
#     }
#   }
#
#   condition {
#     path_pattern {
#       values = ["/"]
#     }
#   }
# }
#
# resource "aws_lb_listener_rule" "root_forward" {
#   listener_arn = aws_lb_listener.web.arn
#   priority     = 2
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web.arn
#   }
#
#   condition {
#     path_pattern {
#       values = ["/"]
#     }
#   }
# }

# ACM証明書のリクエスト
resource "aws_acm_certificate" "web" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cert"
  }
}

# DNS検証用のRoute53レコード
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.web.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# ACM証明書の検証
resource "aws_acm_certificate_validation" "web" {
  certificate_arn         = aws_acm_certificate.web.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route53 レコード（ALB用）
resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# HTTPSリスナーの追加
resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.web.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# HTTPSリスナールール1: "/"へのアクセスでAWSサイトにリダイレクト（優先度1 - 最優先）
resource "aws_lb_listener_rule" "https_root_redirect" {
  listener_arn = aws_lb_listener.web_https.arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302"
      host        = "aws.amazon.com"
      path        = "/jp/"
      query       = "nc2=h_home"
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# HTTPSリスナールール2: "/"へのアクセスでEC2に転送（優先度2 - 次点）
resource "aws_lb_listener_rule" "https_root_forward" {
  listener_arn = aws_lb_listener.web_https.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# HTTPからHTTPSへのリダイレクト（ALB経由）
resource "aws_lb_listener" "web_http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = var.domain_name
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}