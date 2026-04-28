# Author: Rob Satnarain
# Created: 2026-04-27
# Description: This file configures the Terraform backend to use Amazon S3 for storing the state.
#. 
# Updated By     Update Date   Version   Description
# -----------------------------------------------------------------------------------------------
# Rob.           2026-04-27.    1.0.     Initial Create

terraform {
  backend "s3" {
    bucket = "my-terraform-state-rs13"
    key = "global/dev/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}