output "jump_instance_id" {
  description = "ID of the jump host EC2 instance"
  value       = module.jump.id
}

output "jump_instance_name" {
  description = "Name of the jump host EC2 instance"
  value       = module.jump.tags_all["Name"]
}

output "jump_public_ip" {
  description = "Public IP of the jump host"
  value       = module.jump.public_ip
}

output "jump_private_ip" {
  description = "Private IP of the jump host"
  value       = module.jump.private_ip
}

output "jump_public_dns" {
  description = "Public DNS name of the jump host"
  value       = module.jump.public_dns
}

output "jump_security_group_id" {
  description = "ID of the jump host security group"
  value       = aws_security_group.jump.id
}

output "vpc_id" {
  description = "VPC ID where jump host is deployed"
  value       = data.aws_vpc.main.id
}

output "subnet_id" {
  description = "Subnet ID where jump host is deployed"
  value       = tolist(data.aws_subnets.public.ids)[0]
}

output "zzz_reminder_access_commands" {
  description = "⚠️  REMINDER: Access Commands"
  value = <<-EOT
    ⚠️  REMINDER: Access Commands
    
    # SSH to jump host
    ssh -i ~/.ssh/${var.key_name != "" ? var.key_name : "your-key"} ec2-user@${module.jump.public_ip}
    
    # View instance details
    aws ec2 describe-instances --instance-ids ${module.jump.id} --region ${var.aws_region}
    
    # View security group
    aws ec2 describe-security-groups --group-ids ${aws_security_group.jump.id} --region ${var.aws_region}
  EOT
}

output "zzz_reminder_important_notes" {
  description = "⚠️  REMINDER: Important Notes"
  value = <<-EOT
    ⚠️  REMINDER: Important Notes
    
    Instance: ${var.instance_type} | Public IP: ${module.jump.public_ip} | Private IP: ${module.jump.private_ip}
    Security: SSH allowed from ${join(", ", var.allowed_cidr_blocks)} | Key: ${var.key_name != "" ? var.key_name : "Not configured"}
    Cost: ~$${var.instance_type == "t3.micro" ? "7-10" : "15-20"}/month | Monitoring: ${var.enable_detailed_monitoring ? "enabled" : "disabled"}
    Next: Configure SSH key → SSH to jump host → Use as bastion to access private resources
  EOT
}

output "zzz_reminder_documentation" {
  description = "⚠️  REMINDER: Documentation Links"
  value = <<-EOT
    ⚠️  REMINDER: Documentation Links
    
    Module: https://github.com/hanyouqing/terraform-aws-modules/tree/main/ec2
    AWS EC2: https://docs.aws.amazon.com/ec2/
    SSH Config: Add to ~/.ssh/config for easy access
  EOT
}
