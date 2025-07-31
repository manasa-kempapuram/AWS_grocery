output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.grocery_alb_v2.dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.grocery_asg_v2.name
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.grocery_rds.endpoint
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.grocery_vpc.id
}
