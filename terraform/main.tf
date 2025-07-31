# Provider Configuration
provider "aws" {
  region = "eu-north-1"
}

##################
# Networking
##################

resource "aws_vpc" "grocery_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "grocery_subnet_1" {
  vpc_id            = aws_vpc.grocery_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1a"
}

resource "aws_subnet" "grocery_subnet_2" {
  vpc_id            = aws_vpc.grocery_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1b"
}

resource "aws_security_group" "grocery_sg" {
  name        = "grocery_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.grocery_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################
# Load Balancer & Target Group
##################

resource "aws_lb" "grocery_alb_v2" {
  name               = "grocery-alb-v2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.grocery_sg.id]
  subnets            = [aws_subnet.grocery_subnet_1.id, aws_subnet.grocery_subnet_2.id]
}

resource "aws_lb_target_group" "grocery_tg_v3" {
  name     = "grocery-tg-v3"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.grocery_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    unhealthy_threshold = 3
    healthy_threshold   = 2
  }
}

resource "aws_lb_listener" "grocery_listener" {
  load_balancer_arn = aws_lb.grocery_alb_v2.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grocery_tg_v3.arn
  }
}

##################
# Auto Scaling Group
##################

resource "aws_autoscaling_group" "grocery_asg_v2" {
  name                = "grocery-asg-v2"
  max_size            = 4
  min_size            = 2
  desired_capacity     = 2
  vpc_zone_identifier = [aws_subnet.grocery_subnet_1.id, aws_subnet.grocery_subnet_2.id]

  launch_template {
    id      = aws_launch_template.grocery_lt.id
    version = "$Latest"
  }

  target_group_arns         = [aws_lb_target_group.grocery_tg_v3.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "GroceryASGInstance"
    propagate_at_launch = true
  }
}



##################
# IAM Roles for CloudWatch
##################

resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_attach" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "ec2-cloudwatch-instance-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "monitoring.rds.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attach" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

##################
# Launch Template for ASG with CloudWatch Agent
##################

resource "aws_launch_template" "grocery_lt" {
  name_prefix   = "grocery-lt-"
  image_id      = "ami-00c8ac9147e19828e"
  instance_type = "t3.micro"
  key_name      = var.key_pair_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_cloudwatch_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum install -y amazon-cloudwatch-agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:AmazonCloudWatch-linux -s
  EOF
  )

  network_interfaces {
    security_groups             = [aws_security_group.grocery_sg.id]
    associate_public_ip_address = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


##################
# RDS Multi-AZ Setup with Enhanced Monitoring
##################

resource "aws_db_subnet_group" "grocery_db_subnet_group_v2" {
  name       = "grocery-db-subnet-group_v2"
  subnet_ids = [aws_subnet.grocery_subnet_1.id, aws_subnet.grocery_subnet_2.id]
}

resource "aws_db_instance" "grocery_rds" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
 
  username               = var.db_username
  password               = var.db_password
  multi_az               = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.grocery_db_subnet_group_v2.name
  vpc_security_group_ids = [aws_security_group.grocery_sg.id]
  skip_final_snapshot    = true

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
}

##################
# Internet Gateway and Route Tables
##################

resource "aws_internet_gateway" "grocery_igw" {
  vpc_id = aws_vpc.grocery_vpc.id
}

resource "aws_route_table" "grocery_public_rt" {
  vpc_id = aws_vpc.grocery_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.grocery_igw.id
  }
}

resource "aws_route_table_association" "grocery_subnet_1_assoc" {
  subnet_id      = aws_subnet.grocery_subnet_1.id
  route_table_id = aws_route_table.grocery_public_rt.id
}

resource "aws_route_table_association" "grocery_subnet_2_assoc" {
  subnet_id      = aws_subnet.grocery_subnet_2.id
  route_table_id = aws_route_table.grocery_public_rt.id
}

##################
# CloudWatch Alarm for High CPU on ASG Instances
##################

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "HighCPUAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when CPU usage is greater than 70% on EC2 instances in ASG"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.grocery_asg_v2.name
  }
}
>>>>>>> 8b89a54 (cloudwatch added)
