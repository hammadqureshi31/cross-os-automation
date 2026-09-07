terraform {
  backend "s3" {
    bucket       = "hammad-cross-os-terraform-state"
    key          = "cross-os-automation/staging/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}