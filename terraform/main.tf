terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  description = "1 vCPU / 1 GB RAM"
  default     = "t2.micro"
}

variable "public_key_path" {
  description = "Public key used for SSH (generate with: ssh-keygen -t rsa -b 4096 -f nest-key)"
  default     = "nest-key.pub"
}

# Latest official Ubuntu 24.04 LTS AMI (Canonical)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "nest-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "app" {
  name        = "nest-app-sg"
  description = "SSH + Nest.js API"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Nest.js API"
    from_port   = 3000
    to_port     = 3000
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

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.app.id]

  # Bootstrap: Node.js, swap, /opt/nest-app layout, systemd unit
  user_data = file("${path.module}/../deploy/scripts/server-setup.sh")

  tags = {
    Name = "nest-app-server"
  }
}

output "public_ip" {
  value = aws_instance.app.public_ip
}

output "ssh_command" {
  value = "ssh -i nest-key ubuntu@${aws_instance.app.public_ip}"
}
