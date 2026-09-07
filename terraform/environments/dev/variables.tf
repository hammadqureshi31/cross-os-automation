variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the dev EC2 instance"
  type        = string
  default     = "ami-0aba19e56f3eaec05"
}

variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
  default     = "cross-os-automation"
}

variable "vpc_cidr" {
  description = "CIDR block for the dev VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the dev public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the dev private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "aws_region" {
  description = "AWS region for the environment"
  type        = string
  default     = "eu-north-1"
}