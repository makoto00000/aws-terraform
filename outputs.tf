# VPC情報
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# サブネット情報
output "subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

# インターネットゲートウェイ情報
output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.main.id
}

# ルートテーブル情報
output "route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

# EC2インスタンス情報
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web.public_dns
}

# セキュリティグループ情報
output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

# キーペア情報
output "key_pair_name" {
  description = "Name of the key pair"
  value       = var.create_key_pair ? aws_key_pair.main[0].key_name : var.key_name
}

# ALB情報
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.main.zone_id
}

# S3バケット情報
output "s3_bucket_name" {
  description = "Name of the S3 bucket for images"
  value       = aws_s3_bucket.images.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for images"
  value       = aws_s3_bucket.images.arn
}

# ドメイン情報
output "domain_name" {
  description = "Domain name used for the application"
  value       = var.domain_name
}

output "custom_domain_url" {
  description = "Custom domain URL for the application"
  value       = "https://${var.domain_name}"
}

# ACM証明書情報
output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.web.arn
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = aws_acm_certificate_validation.web.certificate_arn
}