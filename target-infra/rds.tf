module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.9.0"

  db_name                             = var.db_name
  identifier                          = var.db_identifier
  storage_type                        = var.storage_type
  allocated_storage                   = var.db_storage
  max_allocated_storage               = var.db_storage
  engine                              = var.db_engine
  engine_version                      = "8.0"
  instance_class                      = var.instance_class
  username                            = local.db_uname
  password                            = local.db_passwd
  db_subnet_group_name                = module.target_vpc.database_subnet_group
  vpc_security_group_ids              = [aws_security_group.rds_sg.id]
  multi_az                            = false // give true for production environments
  skip_final_snapshot                 = true
  copy_tags_to_snapshot               = true
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  storage_encrypted                   = true
  create_db_subnet_group              = false
  create_db_parameter_group           = false
  create_db_option_group              = false
  create_random_password              = false
  create_monitoring_role              = true
  monitoring_interval                 = var.monitoring_interval
  monitoring_role_name                = "${var.db_identifier}-enhanced-monitoring"
  backup_retention_period             = var.backup_retention_period
  enabled_cloudwatch_logs_exports     = ["audit", "general", "error", "slowquery"]
  maintenance_window                  = var.db_maintenance_window

  # tags = var.tags

}

resource "aws_security_group" "rds_sg" {
  # checkov:skip=CKV_AWS_260: ADD REASON: open ports to internet
  name        = "rds-sg"
  description = "Security group for database server"
  vpc_id      = module.target_vpc.vpc_id

  # ingress {
  #   description = "For DMS"
  #   from_port   = 3306
  #   to_port     = 3306
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    description     = "Allow db connection from webserver"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.target_web_sg.id]
  }

  egress {
    description = "Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" : "rds-sg"
  }

}
