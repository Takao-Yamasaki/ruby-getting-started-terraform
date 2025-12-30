# # Bastion EC2インスタンスID
# output "bastion_instance_id" {
#   description = "Bastion EC2 instance ID for SSM connection"
#   value       = aws_instance.bastion.id
# }
#
# # RDSエンドポイント
# output "rds_endpoint" {
#   description = "RDS instance endpoint"
#   value       = aws_db_instance.main.endpoint
# }
#
# # RDSデータベース名
# output "rds_database_name" {
#   description = "RDS database name"
#   value       = aws_db_instance.main.db_name
# }
#
# # Secrets Manager ARN
# output "rds_password_secret_arn" {
#   description = "ARN of the secret containing RDS credentials"
#   value       = aws_secretsmanager_secret.rds_password.arn
# }
#
# # SSM経由でのRDS接続方法
# output "connection_instructions" {
#   description = "Instructions for connecting to RDS via SSM"
#   value       = <<-EOT
#     # 1. Connect to Bastion via SSM
#     aws ssm start-session --target ${aws_instance.bastion.id}
#
#     # 2. RDS connection information
#     Database: ${aws_db_instance.main.db_name}
#     Endpoint: ${aws_db_instance.main.address}
#     Port: 3306
#     Username: ${aws_db_instance.main.username}
#
#     # Retrieve password:
#     aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.rds_password.id} --query SecretString --output text | jq -r .password
#
#     # Note: MySQL client installation requires NAT Gateway or public subnet access since the bastion is in a private subnet.
#   EOT
# }
