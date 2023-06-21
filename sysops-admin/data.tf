# data "aws_caller_identity" "current" {}

# data "aws_region" "current" {}

data "terraform_remote_state" "target_infra" {
  backend = "s3"
  config = {
    bucket         = "capci-mgn-lab-tfstates"
    key            = "aws-capci-mgn-lab-cloud/target-infra/terraform.tfstates"
    region         = "us-west-2"
    dynamodb_table = "terraform-lock-capci-mgn-lab"
  }
}

data "aws_ssm_patch_baseline" "default_ubuntu" {
  owner            = "AWS"
  operating_system = "UBUNTU"
}

data "aws_secretsmanager_secret" "sns_email" {
  name = "sns_email_endpoint"
}

data "aws_secretsmanager_secret_version" "email" {
  secret_id = data.aws_secretsmanager_secret.sns_email.id
}
