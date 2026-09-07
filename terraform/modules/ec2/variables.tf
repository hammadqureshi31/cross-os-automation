variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet where the instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "Security Groups attached to the instance"
  type        = list(string)
}

variable "key_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}