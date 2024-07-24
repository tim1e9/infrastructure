# Create an AWS EC2 instance with a GPU.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# ----------------------------------------
variable "primary_region" {
    description = "The primary region for the VPC"
    type = string
    default = "us-east-2"
}

variable "key_pair_name" {
  description = "The name of the key to use with the ec2 instance"
  type = string
}

# ----------------------------------------
provider "aws" {
  region  = var.primary_region
}

data "aws_key_pair" "dev_keypair" {
  key_name           = var.key_pair_name
  include_public_key = true
}

data "aws_subnet" "dev_subnet" {
  filter {
    name   = "tag:Name"
    values = ["dev-publicsubnet1"]
  }
}

data "aws_security_group" "dev_sg" {
  filter {
    name   = "tag:Name"
    values = ["dev-sg"]
  }
}

resource "aws_instance" "gpu_ec2" {
  ami           = "ami-00db8dadb36c9815e" # "ami-0ee4f2271a4df2d7d"
  instance_type = "t2.micro" # "g5.2xlarge"
  subnet_id = data.aws_subnet.dev_subnet.id
  associate_public_ip_address = true
  security_groups = [data.aws_security_group.dev_sg.id]
  key_name = data.aws_key_pair.dev_keypair.key_name
  user_data = file("${path.module}/userdata.sh")
}

output "server_ip" {
  value = aws_instance.gpu_ec2.public_ip
}
