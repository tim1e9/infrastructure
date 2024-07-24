# Create an AWS filesystem which can be attached to Linux instances via NFS

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
# ----------------------------------------

provider "aws" {
  region  = var.primary_region
}

data "aws_subnet" "dev_subnet" {
  filter {
    name   = "tag:Name"
    values = ["dev-publicsubnet1"]
  }
}


resource "aws_efs_file_system" "dev_efs" {
  creation_token = "my-efs-for-dev"
  encrypted = true
  tags = {
    Name = "dev-efs"
  }
}

resource "aws_efs_mount_target" "dev_mount_target" {
  file_system_id = aws_efs_file_system.dev_efs.id
  subnet_id      = data.aws_subnet.dev_subnet.id
}