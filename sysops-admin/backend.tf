terraform {
  backend "s3" {
    bucket         = "capci-mgn-lab-tfstates"
    key            = "aws-capci-mgn-lab-cloud/sysops-admin/terraform.tfstates"
    region         = "us-west-2"
    dynamodb_table = "terraform-lock-capci-mgn-lab"
  }
}
