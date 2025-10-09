#!/bin/bash

# Terraformの出力からIPアドレスを取得
PUBLIC_IP=$(cd .. && terraform output -raw instance_public_ip)

# インベントリファイルを生成
cat > inventory << EOF
[web_servers]
web-server ansible_host=${PUBLIC_IP} ansible_user=ec2-user ansible_ssh_private_key_file=../keys/terraform-key ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[web_servers:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

echo "Generated inventory with IP: ${PUBLIC_IP}"
