# data "aws_vpc" "target_vpc" {
#   filter {
#     name   = "tag:Name"
#     values = ["main-vpc"]
#   }
# }

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "capci-mgn-lab-tfstates"
    key            = "aws-capci-mgn-lab-cloud/target-infra/terraform.tfstates"
    region         = "us-west-2"
    dynamodb_table = "terraform-lock-capci-mgn-lab"
  }
}

data "aws_vpc" "target_vpc" {
  id = data.terraform_remote_state.vpc.outputs.target_vpc_id
}
