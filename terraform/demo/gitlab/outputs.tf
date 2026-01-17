output "gitlab_instance_id" {
  description = "ID of the GitLab EC2 instance"
  value       = module.gitlab.id
}

output "gitlab_instance_name" {
  description = "Name of the GitLab EC2 instance"
  value       = module.gitlab.tags_all["Name"]
}

output "gitlab_public_ip" {
  description = "Public IP of the GitLab instance"
  value       = module.gitlab.public_ip
}

output "gitlab_private_ip" {
  description = "Private IP of the GitLab instance"
  value       = module.gitlab.private_ip
}

output "gitlab_public_dns" {
  description = "Public DNS name of the GitLab instance"
  value       = module.gitlab.public_dns
}

output "gitlab_url" {
  description = "GitLab URL (HTTP)"
  value       = "http://${module.gitlab.public_ip}"
}

output "gitlab_url_https" {
  description = "GitLab URL (HTTPS)"
  value       = "https://${module.gitlab.public_ip}"
}

output "gitlab_security_group_id" {
  description = "ID of the GitLab security group"
  value       = aws_security_group.gitlab.id
}

output "gitlab_data_volume_id" {
  description = "ID of the GitLab data EBS volume"
  value       = aws_ebs_volume.gitlab_data.id
}

output "vpc_id" {
  description = "VPC ID where GitLab is deployed"
  value       = data.aws_vpc.main.id
}

output "subnet_id" {
  description = "Subnet ID where GitLab is deployed"
  value       = tolist(data.aws_subnets.public.ids)[0]
}

output "zzz_reminder_access_commands" {
  description = "⚠️  REMINDER: Access Commands"
  value = <<-EOT
    ⚠️  REMINDER: Access Commands
    
    # Access GitLab web UI
    open http://${module.gitlab.public_ip}
    # Or: open https://${module.gitlab.public_ip}
    
    # SSH to GitLab instance
    ssh -i ~/.ssh/${var.key_name != "" ? var.key_name : "your-key"} ec2-user@${module.gitlab.public_ip}
    
    # View instance details
    aws ec2 describe-instances --instance-ids ${module.gitlab.id} --region ${var.aws_region}
    
    # View security group
    aws ec2 describe-security-groups --group-ids ${aws_security_group.gitlab.id} --region ${var.aws_region}
  EOT
}

output "zzz_reminder_important_notes" {
  description = "⚠️  REMINDER: Important Notes"
  value = <<-EOT
    ⚠️  REMINDER: Important Notes
    
    Instance: ${var.instance_type} | Public IP: ${module.gitlab.public_ip} | Data Volume: ${var.gitlab_data_volume_size}GB ${var.gitlab_data_volume_type}
    Security: HTTP/HTTPS from ${join(", ", var.allowed_cidr_blocks)} | SSH from ${join(", ", var.allowed_ssh_cidr_blocks)}
    Cost: ~$${var.instance_type == "t3.medium" ? "30-35" : "60-80"}/month | Monitoring: ${var.enable_detailed_monitoring ? "enabled" : "disabled"}
    Next: Configure GitLab → Access web UI → Mount data volume (/dev/sdf) → Set up domain/DNS (optional)
  EOT
}

output "zzz_reminder_documentation" {
  description = "⚠️  REMINDER: Documentation Links"
  value = <<-EOT
    ⚠️  REMINDER: Documentation Links
    
    Module: https://github.com/hanyouqing/terraform-aws-modules/tree/main/ec2
    GitLab Install: https://about.gitlab.com/install/
    AWS EC2: https://docs.aws.amazon.com/ec2/
  EOT
}
