region                     = "us-west-2"
number_of_azs              = 2
target_vpc_name            = "main-vpc"
target_vpc_cidr            = "10.0.16.0/20"
database_subnet_group_name = "rds-subnet-group"
lb_name                    = "webserver-lb"
igw_name                   = "main-igw"
natgw_name                 = "main-natgw"
eip_name                   = "main-nat-eip"
instance_type              = "t3.small"
db_name                    = "customer_db"
db_identifier              = "mysqldb"
instance_class             = "db.t3.medium"

# tags = {
#   "Project"     = "capci-mgn-lab"
#   "Environment" = "Dev"
#   "Platform"    = "on-cloud"
# }
