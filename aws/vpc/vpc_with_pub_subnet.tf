# Create an AWS Virtual Private Cloud (VPC) with a single public subnet
#
# This is a fairly rudimentary example, but possibly a good fit for development

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
variable "sg_cidr_range" {
  # No default has been specified; you must specify this for security reasons
  # Consider limiting this to your personal IP addr, i.e. 1.2.3.4/32
  description = "The range of IPv4 addresses allowed to pierce the security groups"
  type = string
}

variable "primary_region" {
    description = "The primary region for the VPC"
    type = string
    default = "us-east-2"
}

variable "primary_cidr_block" {
    description = "The CIDR block for the primary VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "primary_region_az1" {
    description = "The name of the first availability zone in the primary VPC"
    type = string
    default = "us-east-2a"
}

variable "subnet1_public_cidr_bloc" {
    description = "The CIDR block for the first public subnet in the primary VPC"
    type = string
    default = "10.0.1.0/24"
}

variable "primary_key_pair" {
    description = "The key pair to use in the primary VPC"
    type = string
}

# ----------------------------------------
provider "aws" {
  region  = var.primary_region
}


resource "aws_vpc" "dev_vpc" {
  cidr_block = var.primary_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name: "dev-vpc"
  }
}

# Create a public subnet
# Be sure to enable auto-assignment of IP V4 addresses
resource "aws_subnet" "dev_publicsubnet1" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = var.subnet1_public_cidr_bloc
  availability_zone = var.primary_region_az1
  map_public_ip_on_launch = true
  tags = {
    Name: "dev-publicsubnet1"
  }
}


# ------------------ Gateways and NAT ---------------------
# If public facing, this is required
resource "aws_internet_gateway" "dev_vpc_igw" {
  vpc_id = aws_vpc.dev_vpc.id
  
}

# ----------------- Public Routing ---------------------
resource "aws_route_table" "dev_public_rt" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_vpc_igw.id
  }
}

resource "aws_route_table_association" "dev_public_rta1" {
  subnet_id      = aws_subnet.dev_publicsubnet1.id
  route_table_id = aws_route_table.dev_public_rt.id
}

# --------- A key pair to be used with the various compute instances created
# If this doesn't already exist, uncomment the following block
# resource "aws_key_pair" "dev_keypair" {
#   key_name   = "dev-key"
#   public_key = var.primary_key_pair
# }

# --------------------- Security Groups -----------------------
resource "aws_security_group" "dev_sg" {
  name        = "dev-sg"
  description = "Allow SSH and Web Traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.sg_cidr_range]
  }

  ingress {
    description = "Web access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.sg_cidr_range]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name: "dev-sg"
  }
}

