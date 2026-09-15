# Cross-OS Infrastructure & Configuration Automation

![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-Configuration_Management-EE0000?logo=ansible&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud_Infrastructure-232F3E?logo=amazonaws&logoColor=white)
![Ubuntu](https://img.shields.io/badge/OS-Ubuntu-E95420?logo=ubuntu&logoColor=white)
![Amazon Linux](https://img.shields.io/badge/OS-Amazon_Linux-FF9900?logo=amazonec2&logoColor=white)

> **Reusable AWS infrastructure provisioning with Terraform, and cross-platform server configuration with Ansible.**

`cross-os-automation` is a production-oriented DevOps automation project that provisions, manages, and configures heterogeneous AWS infrastructure. It separates infrastructure provisioning from server configuration:

- **Terraform** provisions and manages AWS infrastructure.
- **Ansible** discovers Terraform-managed EC2 instances through AWS dynamic inventory and configures them according to their operating system.
- **Remote Terraform state** provides centralized, encrypted state management with locking.
- **Reusable Terraform modules** provide a foundation for multiple environments.
- **Ansible roles and group variables** provide reusable, idempotent configuration management.

The infrastructure currently targets two operating systems — **Ubuntu** and **Amazon Linux** — both configured through the same Ansible automation while using their native package-management systems (`apt` and `dnf` respectively).

## At a Glance

| | |
|---|---|
| **Problem** | Manually provisioning and configuring multi-OS cloud servers is repetitive, error-prone, and hard to reproduce consistently across environments. |
| **Solution** | Terraform provisions AWS infrastructure as code; Ansible automatically discovers that infrastructure and configures it per-OS, converging every host to a defined desired state. |
| **Cloud** | AWS (VPC, EC2, Security Groups, NAT Gateway, S3) |
| **IaC** | Terraform — modular, multi-environment, remote state in S3 |
| **Configuration** | Ansible — dynamic AWS inventory, reusable roles, idempotent playbooks |
| **OS Support** | Ubuntu (`apt`) and Amazon Linux (`dnf`), same role, OS-aware logic |
| **Key Concepts** | Infrastructure/configuration separation, dynamic inventory, state-safe refactoring (`moved` blocks), idempotency, failure/recovery testing |

---

## Overview

`cross-os-automation` demonstrates how to provision, manage, and configure heterogeneous AWS infrastructure using **Terraform** and **Ansible**, with a clear boundary between the two responsibilities: Terraform answers *"what infrastructure should exist?"* and Ansible answers *"how should those machines be configured?"*

The goals of the project are to show:

- Declarative, modular infrastructure provisioning with reusable Terraform modules across multiple environments.
- Centralized, encrypted, locked Terraform state suitable for collaborative and multi-environment work.
- Configuration management that automatically discovers infrastructure (no hand-maintained inventory) and converges hosts to a desired state regardless of their underlying OS.
- Real operational validation — not just a successful first deployment, but idempotency checks and failure/recovery testing.

---

## Architecture & Technology

### Architecture diagram

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

### What was built

**Infrastructure (Terraform-provisioned):**

- AWS VPC
- Public subnet
- Private subnet
- Internet Gateway
- Public and private route tables
- NAT Gateway
- Elastic IP
- Security Group
- Ubuntu EC2 instance
- Amazon Linux EC2 instance

### Technology stack

| Layer | Tooling |
|---|---|
| Infrastructure provisioning | Terraform, modular design, remote S3 backend |
| Cloud provider | AWS (VPC, EC2, Security Groups, NAT Gateway, EIP, S3) |
| Configuration management | Ansible, AWS EC2 dynamic inventory plugin |
| Operating systems | Ubuntu (`apt`), Amazon Linux (`dnf`) |
| Service configured | Nginx (via a reusable Ansible role) |

### Repository structure

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

## Implementation

### Infrastructure with Terraform

The Terraform configuration is organized around **reusable modules** and **environment-specific configurations**, separating reusable infrastructure components from per-environment settings.

**Terraform modules** avoid duplicating infrastructure definitions:

- **VPC module** — responsible for VPC creation, public subnet, private subnet, Internet Gateway, route tables, NAT Gateway, and Elastic IP.
- **Security Group module** — responsible for creating environment-specific security groups, SSH access restrictions, HTTP access, and outbound traffic rules.
- **EC2 module** — responsible for reusable EC2 provisioning. It accepts parameters such as AMI, instance type, subnet, security group, key pair, environment, and instance name, so the same module can provision different operating systems without duplicating resource definitions.

**Multi-environment design:** environments are separated at the Terraform root level (`terraform/environments/dev`, `terraform/environments/staging`). Each environment maintains its own configuration, variables, providers, outputs, and Terraform state — preventing environments from sharing state and providing a foundation for safely managing infrastructure across development, staging, and eventually production.

**Remote Terraform state:** state is stored remotely in Amazon S3:

```text
S3 Bucket
└── hammad-cross-os-terraform-state/
    ├── cross-os-automation/
    │   ├── dev/
    │   │   └── terraform.tfstate
    │   └── staging/
    │       └── terraform.tfstate
```

The backend uses S3, encryption at rest, S3 versioning, and Terraform's modern S3 lockfile mechanism. Environment-specific state keys prevent the development and staging environments from sharing state.

**State-safe refactoring:** the project also demonstrates infrastructure refactoring without unnecessarily recreating resources. When the EC2 configuration was refactored into separate Terraform module instances, a Terraform `moved` block was used to preserve the existing resource's state address — allowing the configuration to evolve without treating an existing infrastructure resource as a completely new one.

### Configuration with Ansible

Ansible is used as the configuration-management layer:

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

**Dynamic AWS inventory:** instead of manually maintaining EC2 IP addresses, Ansible uses the AWS EC2 dynamic inventory plugin. Instances are grouped automatically based on AWS tags (e.g. `tag_cross_os_ubuntu`, `tag_cross_os_amazon_linux`):

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

This means infrastructure changes such as replacing an instance or receiving a new public IP do not require manually rewriting the Ansible inventory.

**Ansible roles:** the Nginx configuration is implemented as a reusable role, keeping configuration logic separate from the playbook:

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

### Cross-OS automation

The same Ansible role configures both operating systems by detecting the OS family and selecting the appropriate package-management mechanism:

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

- **Ubuntu** uses `apt`.
- **Amazon Linux** uses `dnf`.

In both cases the service is then installed, started, and enabled at boot.

**SSH and OS-specific connection management:** different operating systems use different default SSH users. This is handled through Ansible inventory variables:

```yaml
# Ubuntu
ansible_user: ubuntu
```

```yaml
# Amazon Linux
ansible_user: ec2-user
```

This allows the same Ansible automation to operate across heterogeneous Linux systems.

### Idempotency

A key requirement of the Ansible implementation is **idempotency** — running the same playbook repeatedly should converge the server toward the desired state without producing unnecessary changes.

Example validation:

```text
First execution:
Amazon Linux → changed=2
Ubuntu       → changed=0

After the desired state was established:
Amazon Linux → changed=0
Ubuntu       → changed=0
```

This demonstrates that the configuration can be safely re-applied without continuously modifying the infrastructure.

### Terraform ↔ Ansible integration

The integration follows a clear separation of responsibilities:

| | Responsibility | Manages |
|---|---|---|
| **Terraform** | *"What infrastructure should exist?"* | VPC, networking, security groups, EC2 instances, infrastructure state, environment separation |
| **Ansible** | *"How should those machines be configured?"* | SSH connectivity, OS-specific package installation, Nginx installation, service state, server configuration |

Integration flow:

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

## How It Works

End-to-end infrastructure lifecycle:

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

In plain terms: Terraform provisions the VPC, subnets, security group, and both EC2 instances. Once the instances exist, Ansible's AWS dynamic inventory plugin automatically discovers them by tag — no IP addresses are ever hand-entered. Ansible then applies the Nginx role, which detects each host's OS family and runs the OS-appropriate installation path (`apt` for Ubuntu, `dnf` for Amazon Linux), converging both hosts to the same desired state. Terraform remains responsible for **infrastructure lifecycle management**, while Ansible handles **operating-system and application configuration**.

---

## Validation, Troubleshooting & Engineering Decisions

### Validation

Infrastructure and configuration were validated independently.

<details>
<summary><strong>Terraform validation</strong></summary>

```bash
terraform fmt
terraform validate
terraform plan
```
</details>

<details>
<summary><strong>Ansible inventory validation</strong></summary>

```bash
ansible-inventory --graph
ansible-inventory --host <host>
```
</details>

<details>
<summary><strong>Connectivity validation</strong></summary>

```bash
ansible all -m ping
```
</details>

<details>
<summary><strong>Configuration validation</strong></summary>

```bash
ansible-playbook playbooks/nginx.yml
```
</details>

<details>
<summary><strong>Idempotency validation</strong></summary>

The playbook was executed repeatedly and verified to converge to:

```text
changed=0
failed=0
unreachable=0
```
</details>

### Failure and recovery testing

The project is designed around an operational workflow rather than simply achieving a successful first deployment. The intended validation cycle is:

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

This approach validates that the automation is capable of **restoring** configuration rather than merely creating it once.

### Key engineering decisions

| Decision | Approach | Why |
|---|---|---|
| Terraform for infrastructure | Declarative provisioning with reusable modules and state-based lifecycle management | Predictable plans and repeatable infrastructure |
| Ansible for configuration | Configuration management layered on top of provisioned infrastructure | Better suited to OS configuration and service management than IaC tools |
| Dynamic inventory | AWS EC2 dynamic inventory plugin instead of a static host list | Removes the operational burden of manually maintaining changing EC2 addresses |
| Tag-driven grouping | AWS tags translated directly into Ansible host groups | Infrastructure metadata becomes usable automation metadata with no extra bookkeeping |
| Remote state | Centralized state in S3 with encryption, versioning, and locking | More appropriate foundation for collaborative, multi-environment work than local state |
| Modular Terraform | Separate VPC, security group, and EC2 modules | Components can be reused across environments and projects |
| Idempotent configuration | Ansible automation designed around desired state, not imperative commands | Playbooks can be safely re-run without unintended side effects |
| State-safe refactoring | `moved` blocks when restructuring EC2 resources into module instances | Evolves configuration without recreating existing infrastructure |

---

## Security, Cost & Production Considerations

### Security — Implemented

- SSH access restricted through the security group rather than exposed indiscriminately.
- Terraform state stored remotely with encryption enabled.
- S3 state versioning enabled.
- Terraform state locking enabled.
- Secrets are not intended to be committed to source control.
- `.terraform/` and Terraform state files are excluded through `.gitignore`.
- Environment state is isolated through separate backend keys.

### Security — Future / production recommendation

For a production deployment, additional controls would include private-only worker infrastructure, centralized secrets management, stronger network segmentation, IAM least privilege, logging/monitoring, and CI/CD security controls.

### Cost awareness

The project was designed with AWS cost control in mind:

- The infrastructure uses small EC2 instances suitable for development and learning workloads, while the architecture demonstrates patterns applicable to larger environments.
- The staging environment is represented in the Terraform structure without requiring it to remain continuously deployed.
- This allows the repository to demonstrate environment separation without unnecessarily running duplicate AWS infrastructure.

---

## Getting Started

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

> **Always review `terraform plan` before applying infrastructure changes.**

---

## Skills Demonstrated

**Infrastructure as Code:** Terraform, Terraform modules, variables and outputs, state management, remote S3 backend, state locking, environment separation, resource refactoring.

**AWS:** VPC, subnets, route tables, Internet Gateway, NAT Gateway, Elastic IP, EC2, Security Groups, AWS tagging.

**Configuration management:** Ansible, dynamic inventory, inventory groups, group variables, Ansible roles, OS detection, package management, service management, idempotency.

**DevOps engineering:** Infrastructure/configuration separation, reproducible infrastructure, cross-platform automation, desired-state management, failure/recovery workflows, cost-aware infrastructure design.

---

## Future Improvements & Conclusion

Potential next iterations include:

- CI/CD pipeline for Terraform and Ansible
- Terraform linting and automated validation
- Ansible linting
- Automated infrastructure testing
- Secrets management with AWS Secrets Manager or SSM Parameter Store
- Private EC2 architecture
- Bastion or SSM-based administration
- CloudWatch monitoring and logging
- Automated deployment of a real application
- Production-grade environment promotion workflow

**Project philosophy:** the objective of this project is not simply to provision EC2 instances or install Nginx. The core objective is to demonstrate the separation and integration of two fundamental DevOps responsibilities:

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
