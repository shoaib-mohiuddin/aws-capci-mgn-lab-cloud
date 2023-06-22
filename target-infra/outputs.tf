output "target_vpc_id" {
  value = module.target_vpc.vpc_id
}

output "staging_area_subnet_ids" {
  value = module.target_vpc.redshift_subnets
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "webserver_instance_id" {
  value = aws_instance.webserver.id
}

output "db_instance_address" {
  value = module.rds.db_instance_address
}

output "logs_bucket_id" {
  value = module.logs_bucket.s3_bucket_id
}
