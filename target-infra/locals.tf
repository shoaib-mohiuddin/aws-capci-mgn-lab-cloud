# Target VPC
locals {

  availability_zones       = slice(data.aws_availability_zones.available.names, 0, var.number_of_azs)
  public_subnet_cidr       = cidrsubnet(var.target_vpc_cidr, 1, 0)
  private_subnet_cidr      = cidrsubnet(var.target_vpc_cidr, 1, 1)
  application_subnet_cidr  = cidrsubnet(local.private_subnet_cidr, 2, 0)
  database_subnet_cidr     = cidrsubnet(local.private_subnet_cidr, 2, 1)
  staging_area_subnet_cidr = cidrsubnet(local.private_subnet_cidr, 2, 2)
  db_uname                 = jsondecode(data.aws_secretsmanager_secret_version.mysql_creds_version.secret_string)["mysql_db_uname"]
  db_passwd                = jsondecode(data.aws_secretsmanager_secret_version.mysql_creds_version.secret_string)["mysql_db_passwd"]
  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
  ]
}
