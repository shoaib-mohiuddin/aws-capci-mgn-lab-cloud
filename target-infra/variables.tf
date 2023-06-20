variable "region" {
  description = "AWS region to work with"
  type        = string
}

variable "number_of_azs" {
  description = "Required number of Availibility Zones"
  type        = number
}

variable "target_vpc_name" {
  description = "Name of the Target VPC"
  type        = string
}

variable "target_vpc_cidr" {
  description = "VPC cidr for the Target VPC"
  type        = string
}

variable "database_subnet_group_name" {
  description = "Name of the database subnet group"
  type        = string
}

variable "lb_name" {
  description = "Application load balancer name"
  type        = string
}

variable "igw_name" {
  description = "Internet gateway tag name"
  type        = string
}

variable "natgw_name" {
  description = "NAT gateway tag name"
  type        = string
}

variable "eip_name" {
  description = "Elastic IP address tag name"
  type        = string
}

# variable "tags" {
#   description = "Tags for the resources"
#   type        = map(string)
# }

variable "create_database_subnet_group" {
  type    = bool
  default = true
}

variable "create_redshift_subnet_group" {
  type    = bool
  default = false
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "one_nat_gateway_per_az" {
  type    = bool
  default = false
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "instance_type" {
  description = "Instance type to use for the instance"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the instance"
  type        = string
  default     = "webserver-phpmyadmin"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_identifier" {
  description = "RDS database identifier"
  type        = string
}

variable "db_engine" {
  description = "RDS database engine"
  type        = string
  default     = "mysql"
}

# variable "db_port" {
#   description = "RDS database engine port"
#   type        = number
#   default     = 3306
# }
variable "storage_type" {
  description = "Storage type for the rds"
  type        = string
  default     = "gp3"
}

variable "db_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "instance_class" {
  description = "Instance type to use"
  type        = string
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance"
  type        = number
  default     = 10
}

variable "db_maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'"
  type        = string
  default     = "SUN:10:00-SUN:22:00"
}

# variable "repl_subnet_group_name" {
#   description = "DMS subnet group name"
#   type        = string
# }

# variable "repl_subnet_group_description" {
#   description = "A description for the DMS subnet group"
#   type        = string
#   default     = "DMS Subnet group"
# }

# variable "repl_instance_class" {
#   description = "Instance class/type for the DMS replication instance"
#   type        = string
# }

# variable "repl_instance_identifier" {
#   description = "DMS replication instance identifier"
#   type        = string
# }

variable "log_bucket_prefix" {
  description = "Prefix for the log bucket name"
  type        = string
  default     = "aws-logs"
}

variable "enable_flow_log" {
  description = "Whether or not to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination. Can be s3 or cloud-watch-logs"
  type        = string
  default     = "s3"
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL"
  type        = string
  default     = "ALL"
}

variable "flow_log_file_format" {
  description = "The format for the flow log. Valid values: plain-text, parquet"
  type        = string
  default     = "plain-text"
}

variable "flow_log_max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: 60 seconds or 600 seconds"
  type        = number
  default     = 60
}

variable "flow_log_per_hour_partition" {
  description = "Indicates whether to partition the flow log per hour. This reduces the cost and response time for queries"
  type        = bool
  default     = true
}


# variable "foo" {
#   type = string
# }
