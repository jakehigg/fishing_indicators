provider "aws" {
  alias  = "root"
  region = "us-east-1"
}

provider "aws" {
  alias  = "target"
  region = "us-east-1"
  assume_role {
    role_arn = local.target_account_role_arn
  }
}

terraform {
  backend "s3" {
    bucket         = "autrui-tfstate"
    key            = "fish/find-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "app-state"
    encrypt        = true
  }
}

