

/*===========================
          Root file
============================*/

# ------- Providers -------
provider "aws" {
  region             = var.aws_region

  # provider level tags - yet inconsistent when executing 
  # default_tags {
  #   tags = {
  #     Created_by = "Terraform"
  #     Project    = "AWS_demo_fullstack_devops"
  #   }
  # }
}
terraform {
  backend "s3" {
       bucket = "dsinfra"
       key    = "sample/terraform.tfstate"
       region = "ap-south-1"
  }
}

# # ------- Creating server ECR Repository to store Docker Images -------
module "ecr_server" {
  source = "../Modules/ECR"
  name   = "aig-repo-server"
}
