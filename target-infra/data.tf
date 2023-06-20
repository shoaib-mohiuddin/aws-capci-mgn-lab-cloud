data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_acm_certificate" "acm_cert" {
  domain   = "capci-shoaib.aws.crlabs.cloud"
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "primary" {
  name         = "capci-shoaib.aws.crlabs.cloud"
  private_zone = false
}

data "aws_secretsmanager_secret" "mysql_creds" {
  name = "mysql_db_creds"
}

data "aws_secretsmanager_secret_version" "mysql_creds_version" {
  secret_id = data.aws_secretsmanager_secret.mysql_creds.id
}

# data "terraform_remote_state" "on_prem_instances" {
#   backend = "s3"
#   config = {
#     bucket         = "capci-mgn-lab-tfstates"
#     key            = "capci-mgn-lab/on-prem-vpc/terraform.tfstates"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-lock-capci-mgn-lab"
#   }
# }

data "aws_ami" "ami_webserver" {
  most_recent = true
  filter {
    name   = "tag:Name"
    values = ["phpmyadmin"]
  }
  owners = [data.aws_caller_identity.current.account_id]
}
