variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the dev EC2 instance"
  type        = string
}

variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the dev VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the dev public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the dev private subnet"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the environment"
  type        = string
}