# Target VPC module
module "target_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = var.target_vpc_name
  cidr = var.target_vpc_cidr
  azs  = slice(data.aws_availability_zones.available.names, 0, var.number_of_azs)

  public_subnets   = [for i, v in local.availability_zones : cidrsubnet(local.public_subnet_cidr, 3, i)]
  private_subnets  = [for i, v in local.availability_zones : cidrsubnet(local.application_subnet_cidr, 2, i)]
  database_subnets = [for i, v in local.availability_zones : cidrsubnet(local.database_subnet_cidr, 2, i)]
  redshift_subnets = [for i, v in local.availability_zones : cidrsubnet(local.staging_area_subnet_cidr, 2, i)]

  public_subnet_names   = [for i, v in local.availability_zones : "public-subnet-${data.aws_availability_zones.available.names[i]}"]
  private_subnet_names  = [for i, v in local.availability_zones : "app-subnet-${data.aws_availability_zones.available.names[i]}"]
  database_subnet_names = [for i, v in local.availability_zones : "database-subnet-${data.aws_availability_zones.available.names[i]}"]
  redshift_subnet_names = [for i, v in local.availability_zones : "staging-area-subnet-${data.aws_availability_zones.available.names[i]}"]

  create_database_subnet_group = var.create_database_subnet_group
  create_redshift_subnet_group = var.create_redshift_subnet_group
  database_subnet_group_name   = var.database_subnet_group_name

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  enable_flow_log                   = var.enable_flow_log
  flow_log_destination_type         = var.flow_log_destination_type
  flow_log_destination_arn          = module.logs_bucket.s3_bucket_arn
  flow_log_traffic_type             = var.flow_log_traffic_type
  flow_log_file_format              = var.flow_log_file_format
  flow_log_max_aggregation_interval = var.flow_log_max_aggregation_interval
  flow_log_per_hour_partition       = var.flow_log_per_hour_partition

  igw_tags = {
    "Name" = var.igw_name
  }
  nat_eip_tags = {
    "Name" = var.eip_name
  }
  nat_gateway_tags = {
    "Name" = var.natgw_name
  }
  # tags = var.tags

}

module "logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = format("%s-%s-%s", var.log_bucket_prefix, data.aws_caller_identity.current.account_id, data.aws_region.current.name)
  # acl                            = "log-delivery-write"
  # object_ownership               = "ObjectWriter"
  # control_object_ownership       = true
  force_destroy                  = true # Allow deletion of non-empty bucket
  block_public_acls              = true
  block_public_policy            = true
  ignore_public_acls             = true
  restrict_public_buckets        = true
  attach_elb_log_delivery_policy = true # Required for ALB logs
  attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs
  # attach_policy                  = true
  # policy                         = data.aws_iam_policy_document.vpc_alb_logs.json
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning = {
    status = true
  }
  lifecycle_rule = [
    {
      id      = "flow-logs-retention"
      enabled = true
      filter  = {}
      transition = [
        {
          days          = 30
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 90
      }
    }
  ]
  # tags = var.tags
}
