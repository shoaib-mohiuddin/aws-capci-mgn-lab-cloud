resource "aws_instance" "webserver" {
  # checkov:skip=CKV_AWS_79: ADD REASON: Instance metadata options - not required
  ami                    = data.aws_ami.ami_webserver.id
  instance_type          = var.instance_type
  subnet_id              = module.target_vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.target_web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/scripts/web_userdata.sh.tpl", {
    rds_endpoint        = module.rds.db_instance_address
    mysql_root_password = local.db_passwd
  })
  monitoring    = true
  ebs_optimized = true
  root_block_device {
    volume_size           = "8"
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  # volume_tags = merge(provider.aws.default_tags, var.instance_name)
  tags = {
    "Name"       = var.instance_name
    "PatchGroup" = "capci"
  }
}

# resource "aws_launch_template" "web_lt" {
#   # checkov:skip=CKV_AWS_79: ADD REASON: Instance metadata options - Not required
#   name                   = "${var.instance_tags}-launch-template"
#   image_id               = data.aws_ami.ami_webserver.id
#   instance_type          = var.instance_type
#   vpc_security_group_ids = [aws_security_group.target_web_sg.id]
#   ebs_optimized          = true
#   iam_instance_profile {
#     name = aws_iam_instance_profile.ec2_profile.name
#   }
#   # metadata_options {
#   #   http_endpoint               = "enabled"
#   #   http_tokens                 = "required"
#   #   http_put_response_hop_limit = 1
#   #   instance_metadata_tags      = "enabled"
#   # }
#   monitoring {
#     enabled = true
#   }
#   user_data = filebase64(templatefile("${path.module}/scripts/web_userdata.sh.tpl", {
#     rds_endpoint        = module.rds.db_instance_address
#     mysql_root_password = local.db_passwd
#   }))
#   tag_specifications {
#     resource_type = "volume"
#     tags = {
#       Name = "vol-${var.instance_tags}"
#     }
#   }
#   tags = {
#     Name = var.instance_name
#   }

# }

resource "aws_security_group" "target_web_sg" {
  # checkov:skip=CKV_AWS_260: ADD REASON: open ports to internet
  name        = "target-web-sg"
  description = "Security group for database server"
  vpc_id      = module.target_vpc.vpc_id

  ingress {
    description     = "Allow HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
    # cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
    # cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   description = "For MGN"
  #   from_port   = 1500
  #   to_port     = 1500
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    description = "Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #   egress {
  #     description = "For MGN"
  #     from_port   = 1500
  #     to_port     = 1500
  #     protocol    = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }

  tags = {
    "Name" : "target-web-sg"
  }

}
