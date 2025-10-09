#!/bin/bash
echo "=== アクセス方法 ==="
echo "HTTPアクセス: http://$(terraform output -raw instance_public_ip)"
echo ""
echo "SSHアクセス（作成した秘密鍵を使用）:"
echo "ssh -i keys/terraform-key ec2-user@$(terraform output -raw instance_public_ip)"
echo ""
