provider "aws" {
  region = "eu-north-1"
}

resource "aws_vpc" "grocery_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "grocery_subnet" {
  vpc_id            = aws_vpc.grocery_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
}

resource "aws_security_group" "grocery_sg" {
  name        = "grocery_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.grocery_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Caution: Open to the world
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "grocery_app" {
  ami                    = "ami-00c8ac9147e19828e"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.grocery_subnet.id
  vpc_security_group_ids = [aws_security_group.grocery_sg.id]
  associate_public_ip_address = true
  key_name               = var.key_pair_name

  tags = {
    Name = "GroceryAppInstance"
  }
}
