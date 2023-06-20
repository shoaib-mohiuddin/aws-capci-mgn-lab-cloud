output "target_vpc_id" {
  value = module.target_vpc.vpc_id
}

output "webserver_instance_id" {
  value = aws_instance.webserver.id
}
