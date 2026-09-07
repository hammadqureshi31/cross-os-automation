terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

provider "aws" {
    region = "eu-north-1"
}


# Upload our public SSH key to AWS
resource "aws_key_pair" "cross_os" {
    key_name = "cross-os-automation"
    public_key = file("~/.ssh/cross-os-automation.pub")
}


# Security Group Allow SSH
resource "aws_security_group" "cross_os" {
    name = "cross-os-automation-sg"

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}


# Ec2 Instance - Ubuntu image
resource "aws_instance" "my_instance" {
    ami = "ami-0aba19e56f3eaec05"
    instance_type = "t3.micro"

    key_name = aws_key_pair.cross_os.key_name
    vpc_security_group_ids = [aws_security_group.cross_os.id]

    tags = {
        Name = "cross-os-automation"
    }
}

# 2nd Ec2 Instance - RedHat Image 
resource "aws_instance" "amazon_linux" {
    ami = "ami-0b79f6b294a030f24"
    instance_type = "t3.micro"

    key_name = aws_key_pair.cross_os.key_name
    vpc_security_group_ids = [aws_security_group.cross_os.id]

    tags = {
        Name = "cross_os_amazon_linux"
    }
}