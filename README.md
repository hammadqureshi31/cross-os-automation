# Cross-OS Infrastructure & Configuration Automation

> **Reusable AWS infrastructure provisioning with Terraform and cross-platform server configuration with Ansible.**

## Overview

`cross-os-automation` is a production-oriented DevOps automation project that demonstrates how to provision, manage, and configure heterogeneous AWS infrastructure using **Terraform** and **Ansible**.

The project separates infrastructure provisioning from server configuration:

* **Terraform** provisions and manages AWS infrastructure.
* **Ansible** discovers Terraform-managed EC2 instances through AWS dynamic inventory and configures them according to their operating system.
* **Remote Terraform state** provides centralized, encrypted state management with locking.
* **Reusable Terraform modules** provide a foundation for multiple environments.
* **Ansible roles and group variables** provide reusable, idempotent configuration management.

The infrastructure currently targets two operating systems:

* Ubuntu
* Amazon Linux

Both are configured through the same Ansible automation while using their native package management systems.

---

## Architecture

```text
                         ┌──────────────────────┐
                         │      Developer       │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │      Terraform       │
                         │  Infrastructure IaC  │
                         └──────────┬───────────┘
                                    │
                ┌───────────────────┼───────────────────┐
                │                   │                   │
                ▼                   ▼                   ▼
          ┌───────────┐       ┌───────────┐       ┌────────────┐
          │    VPC    │       │    EC2    │       │    SG      │
          │ Networking│       │ Instances │       │  Security  │
          └───────────┘       └─────┬─────┘       └────────────┘
                                    │
                                    │ AWS metadata / tags
                                    ▼
                         ┌──────────────────────┐
                         │ Ansible Dynamic      │
                         │ Inventory (AWS EC2)  │
                         └──────────┬───────────┘
                                    │
                         ┌──────────┴───────────┐
                         │                      │
                         ▼                      ▼
                  ┌─────────────┐       ┌─────────────┐
                  │   Ubuntu    │       │ Amazon Linux│
                  │    host     │       │    host     │
                  └──────┬──────┘       └──────┬──────┘
                         │                     │
                         ▼                     ▼
                    apt + nginx           dnf + nginx
                         │                     │
                         └──────────┬──────────┘
                                    ▼
                            Desired State
                             Configuration
```

---

# What Was Built

### Infrastructure

Terraform provisions:

* AWS VPC
* Public subnet
* Private subnet
* Internet Gateway
* Public and private route tables
* NAT Gateway
* Elastic IP
* Security Group
* Ubuntu EC2 instance
* Amazon Linux EC2 instance

### Infrastructure architecture

The Terraform configuration is organized around reusable modules and environment-specific configurations.

```text
terraform/
├── environments/
│   ├── dev/
│   └── staging/
│
└── modules/
    ├── ec2/
    ├── security_group/
    └── vpc/
```

This separates **reusable infrastructure components** from **environment-specific configuration**.

---

# Terraform

## Modular Infrastructure

Terraform modules are used to avoid duplicating infrastructure definitions.

### VPC module

Responsible for:

* VPC creation
* Public subnet
* Private subnet
* Internet Gateway
* Route tables
* NAT Gateway
* Elastic IP

### Security Group module

Responsible for:

* Creating environment-specific security groups
* SSH access restrictions
* HTTP access
* Outbound traffic

### EC2 module

Responsible for reusable EC2 provisioning.

The module accepts parameters such as:

* AMI
* Instance type
* Subnet
* Security group
* Key pair
* Environment
* Instance name

This allows the same module to provision different operating systems without duplicating resource definitions.

---

# Multi-Environment Design

The project separates environments at the Terraform root level:

```text
terraform/
└── environments/
    ├── dev/
    └── staging/
```

Each environment maintains its own configuration, variables, providers, outputs, and Terraform state.

This prevents environments from sharing the same state and provides a foundation for safely managing infrastructure across development, staging, and eventually production.

---

# Remote Terraform State

Terraform state is stored remotely in Amazon S3.

```text
S3 Bucket
└── hammad-cross-os-terraform-state/
    ├── cross-os-automation/
    │   ├── dev/
    │   │   └── terraform.tfstate
    │   └── staging/
    │       └── terraform.tfstate
```

The backend uses:

* S3
* Encryption at rest
* S3 versioning
* Terraform's modern S3 lockfile mechanism

Environment-specific state keys prevent the development and staging environments from sharing state.

---

# Infrastructure Lifecycle

The intended workflow is:

```text
Terraform Configuration
        │
        ▼
terraform plan
        │
        ▼
Review Infrastructure Changes
        │
        ▼
terraform apply
        │
        ▼
AWS Infrastructure
        │
        ▼
Ansible Dynamic Inventory
        │
        ▼
Server Configuration
```

Terraform remains responsible for **infrastructure lifecycle management**, while Ansible handles **operating-system and application configuration**.

---

# Terraform State-Safe Refactoring

The project also demonstrates infrastructure refactoring without unnecessarily recreating resources.

When the EC2 configuration was refactored into separate Terraform module instances, a Terraform `moved` block was used to preserve the existing resource's state address.

This allowed the configuration to evolve without treating an existing infrastructure resource as a completely new resource.

---

# Ansible

Ansible is used as the configuration-management layer.

```text
ansible/
├── ansible.cfg
├── inventory/
│   ├── hosts.ini
│   ├── aws_ec2.yml
│   └── group_vars/
├── playbooks/
│   └── nginx.yml
└── roles/
    └── nginx/
```

---

# Dynamic AWS Inventory

Instead of manually maintaining EC2 IP addresses, Ansible uses the AWS EC2 dynamic inventory plugin.

```text
AWS
 │
 ├── EC2 instance
 │      └── Name: cross-os-ubuntu
 │
 └── EC2 instance
        └── Name: cross-os-amazon-linux
              │
              ▼
        Ansible Dynamic Inventory
              │
              ▼
       Automatically generated
          Ansible groups
```

Instances are grouped based on AWS tags.

For example:

```text
tag_cross_os_ubuntu
tag_cross_os_amazon_linux
```

This means infrastructure changes such as replacing an instance or receiving a new public IP do not require manually rewriting the Ansible inventory.

---

# Cross-Operating-System Automation

The same Ansible role configures both operating systems.

```text
                    nginx role
                       │
             ┌─────────┴─────────┐
             │                   │
             ▼                   ▼
        Debian family       RedHat family
             │                   │
             ▼                   ▼
            apt                 dnf
             │                   │
             └─────────┬─────────┘
                       ▼
                 Nginx running
```

The role detects the operating-system family and selects the appropriate package-management mechanism.

### Ubuntu

Uses:

```text
apt
```

### Amazon Linux

Uses:

```text
dnf
```

The service is then:

* Installed
* Started
* Enabled at boot

---

# Ansible Roles

The Nginx configuration is implemented as a reusable role:

```text
roles/
└── nginx/
    ├── defaults/
    │   └── main.yml
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    ├── templates/
    ├── vars/
    ├── meta/
    └── tests/
```

This keeps configuration logic separate from the playbook and makes the automation reusable across multiple hosts.

---

# Idempotency

A key requirement of the Ansible implementation is **idempotency**.

Running the same playbook repeatedly should converge the server toward the desired state without producing unnecessary changes.

Example validation:

```text
First execution:

Amazon Linux → changed=2
Ubuntu       → changed=0
```

After the desired state was established:

```text
Amazon Linux → changed=0
Ubuntu       → changed=0
```

This demonstrates that the configuration can be safely re-applied without continuously modifying the infrastructure.

---

# Terraform ↔ Ansible Integration

The integration follows a clear separation of responsibilities:

### Terraform

> **"What infrastructure should exist?"**

Terraform manages:

* VPC
* Networking
* Security groups
* EC2 instances
* Infrastructure state
* Environment separation

### Ansible

> **"How should those machines be configured?"**

Ansible manages:

* SSH connectivity
* OS-specific package installation
* Nginx installation
* Service state
* Server configuration

### Integration flow

```text
Terraform
    │
    ▼
AWS EC2
    │
    ├── Tags
    ├── Public IP
    └── OS metadata
    │
    ▼
AWS Dynamic Inventory
    │
    ▼
Ansible Groups
    │
    ▼
Ansible Variables
    │
    ▼
Ansible Roles
    │
    ▼
Configured Servers
```

---

# SSH and OS-Specific Connection Management

Different operating systems use different default SSH users.

The project handles this through Ansible inventory variables:

```yaml
# Ubuntu
ansible_user: ubuntu
```

```yaml
# Amazon Linux
ansible_user: ec2-user
```

This allows the same Ansible automation to operate across heterogeneous Linux systems.

---

# Validation

Infrastructure and configuration were validated independently.

### Terraform validation

```bash
terraform fmt
terraform validate
terraform plan
```

### Ansible inventory validation

```bash
ansible-inventory --graph
ansible-inventory --host <host>
```

### Connectivity validation

```bash
ansible all -m ping
```

### Configuration validation

```bash
ansible-playbook playbooks/nginx.yml
```

### Idempotency validation

The playbook was executed repeatedly and verified to converge to:

```text
changed=0
failed=0
unreachable=0
```

---

# Failure and Recovery Testing

The project is designed around an operational workflow rather than simply achieving a successful first deployment.

The intended validation cycle is:

```text
Deploy
  ↓
Verify
  ↓
Intentionally break
  ↓
Detect
  ↓
Diagnose
  ↓
Run automation
  ↓
Recover
  ↓
Verify desired state
```

This approach validates that the automation is capable of restoring configuration rather than merely creating it once.

---

# Repository Structure

```text
cross-os-automation/
│
├── terraform/
│   │
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── backend.tf
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── providers.tf
│   │   │   ├── variables.tf
│   │   │   └── dev.auto.tfvars
│   │   │
│   │   └── staging/
│   │       ├── backend.tf
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       ├── providers.tf
│   │       ├── variables.tf
│   │       └── staging.auto.tfvars
│   │
│   └── modules/
│       ├── ec2/
│       ├── security_group/
│       └── vpc/
│
├── ansible/
│   ├── ansible.cfg
│   │
│   ├── inventory/
│   │   ├── hosts.ini
│   │   ├── aws_ec2.yml
│   │   └── group_vars/
│   │
│   ├── playbooks/
│   │   └── nginx.yml
│   │
│   └── roles/
│       └── nginx/
│
├── .gitignore
└── README.md
```

---

# Key Engineering Decisions

### Terraform for infrastructure

Terraform provides declarative infrastructure management, predictable plans, reusable modules, and state-based lifecycle management.

### Ansible for configuration

Ansible is better suited for operating-system configuration and service management after infrastructure has been provisioned.

### Dynamic inventory

AWS dynamic inventory removes the operational burden of manually maintaining changing EC2 addresses.

### Tag-driven grouping

AWS tags provide infrastructure metadata that can be translated directly into Ansible host groups.

### Remote state

Centralized S3 state provides a more appropriate foundation for collaborative and multi-environment infrastructure management than local state.

### Modular Terraform

Separating VPC, security group, and EC2 resources into modules allows infrastructure components to be reused across environments and projects.

### Idempotent configuration

Ansible automation is designed around desired state rather than imperative "run this command" workflows.

---

# Deployment Workflow

A typical deployment follows:

```bash
# 1. Provision infrastructure
cd terraform/environments/dev

terraform init
terraform plan
terraform apply

# 2. Move to Ansible
cd ../../../ansible

# 3. Verify AWS inventory
ansible-inventory --graph

# 4. Test SSH connectivity
ansible all -m ping

# 5. Configure servers
ansible-playbook playbooks/nginx.yml

# 6. Re-run to verify idempotency
ansible-playbook playbooks/nginx.yml
```

> Always review `terraform plan` before applying infrastructure changes.

---

# Security Considerations

The project incorporates several basic infrastructure security practices:

* SSH access restricted through the security group rather than exposed indiscriminately.
* Terraform state stored remotely with encryption enabled.
* S3 state versioning enabled.
* Terraform state locking enabled.
* Secrets are not intended to be committed to source control.
* `.terraform/` and Terraform state files are excluded through `.gitignore`.
* Environment state is isolated through separate backend keys.

For a production deployment, additional controls would include private-only worker infrastructure, centralized secrets management, stronger network segmentation, IAM least privilege, logging/monitoring, and CI/CD security controls.

---

# Cost Awareness

The project was designed with AWS cost control in mind.

The infrastructure uses small EC2 instances suitable for development and learning workloads, while the architecture demonstrates patterns applicable to larger environments.

The staging environment is represented in the Terraform structure without requiring it to remain continuously deployed.

This allows the repository to demonstrate environment separation without unnecessarily running duplicate AWS infrastructure.

---

# Skills Demonstrated

This project demonstrates practical experience with:

**Infrastructure as Code**

* Terraform
* Terraform modules
* Variables and outputs
* State management
* Remote S3 backend
* State locking
* Environment separation
* Resource refactoring

**AWS**

* VPC
* Subnets
* Route tables
* Internet Gateway
* NAT Gateway
* Elastic IP
* EC2
* Security Groups
* AWS tagging

**Configuration Management**

* Ansible
* Dynamic inventory
* Inventory groups
* Group variables
* Ansible roles
* OS detection
* Package management
* Service management
* Idempotency

**DevOps Engineering**

* Infrastructure/configuration separation
* Reproducible infrastructure
* Cross-platform automation
* Desired-state management
* Failure/recovery workflows
* Cost-aware infrastructure design

---

# Future Improvements

Potential next iterations include:

* CI/CD pipeline for Terraform and Ansible
* Terraform linting and automated validation
* Ansible linting
* Automated infrastructure testing
* Secrets management with AWS Secrets Manager or SSM Parameter Store
* Private EC2 architecture
* Bastion or SSM-based administration
* CloudWatch monitoring and logging
* Automated deployment of a real application
* Production-grade environment promotion workflow

---

## Project Philosophy

The objective of this project is not simply to provision EC2 instances or install Nginx.

The core objective is to demonstrate the separation and integration of two fundamental DevOps responsibilities:

```text
Terraform
Infrastructure Lifecycle
        +
Ansible
Configuration Lifecycle
        =
Reproducible Infrastructure Automation
```

The resulting workflow allows infrastructure to be **provisioned consistently, discovered automatically, configured predictably, and repeatedly converged toward the desired state**.
