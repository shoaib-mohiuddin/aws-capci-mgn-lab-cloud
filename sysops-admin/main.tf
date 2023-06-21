################################################################################
#                  SSM PATCH MANAGER & MAINTENANCE WINDOW                      #
################################################################################

// Run the patch baseline every third thursday of the month at 23:30 UTC - "cron(30 23 ? * THU#3 *)"
// Run the patch baseline every day at 10:00 UTC - "cron(00 10 * * ? *)"

resource "aws_ssm_patch_baseline" "ubuntu" {
  name             = "patch-baseline-ubuntu"
  description      = "Patch baseline to be used for Ubuntu machines"
  operating_system = "UBUNTU"
  approval_rule {
    approve_after_days = "7"
    compliance_level   = "HIGH"

    patch_filter {
      key    = "PRODUCT"
      values = ["*"]
    }

    patch_filter {
      key    = "SECTION"
      values = ["*"]
    }

    patch_filter {
      key    = "PRIORITY"
      values = ["Required", "Important"]
    }
  }
}

resource "aws_ssm_patch_group" "patchgroup" {
  baseline_id = aws_ssm_patch_baseline.ubuntu.id
  patch_group = "capci"
}

resource "aws_ssm_maintenance_window" "web_mw" {
  name     = "maintenance-window-webserver"
  schedule = "cron(30 23 ? * THU#3 *)" // "cron(10 11 * * ? *)"
  # schedule_timezone = "Asia/Kolkata"
  duration = 3
  cutoff   = 1
}

resource "aws_ssm_maintenance_window_target" "web_mw_target" {
  window_id     = aws_ssm_maintenance_window.web_mw.id
  name          = "maintenance-window-webserver-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    # key    = "tag:Name"
    # values = ["webserver-phpmyadmin"]
    key    = "tag:PatchGroup"
    values = ["capci"]
  }
}

resource "aws_ssm_maintenance_window_task" "web_mw_task" {
  name            = "maintenance-window-webserver-task"
  max_concurrency = 2
  max_errors      = 1
  priority        = 1
  task_arn        = "AWS-RunPatchBaseline"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.web_mw.id

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.web_mw_target.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}

################################################################################
#                               AWS BACKUP                                     #
################################################################################

resource "aws_backup_vault" "backup" {
  name        = "capci-mgn-vault"
  kms_key_arn = data.aws_kms_alias.backup.target_key_arn
}

resource "aws_backup_plan" "plan" {
  name = "capci_mgn_backup_plan"

  rule {
    rule_name         = "capci_mgn_daily_backup_rule"
    target_vault_name = aws_backup_vault.backup.name
    schedule          = "cron(30 23 * * ? *)" // "cron(25 06 * * ? *)"

    lifecycle {
      delete_after = 1
    }
  }
}

resource "aws_backup_selection" "resource_assignment" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "capci_mgn_backup_ec2"
  plan_id      = aws_backup_plan.plan.id
  resources = [
    "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*",
    "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
  ]

  # selection_tag {
  #   type  = "STRINGEQUALS"
  #   key   = "Name"
  #   value = "webserver-phpmyadmin"
  # }
  condition {
    string_equals {
      key   = "aws:ResourceTag/Backup"
      value = "true"
    }
  }
}

################################################################################
#                   Collect metrics with CloudWatch Agent                      #
################################################################################
// Install the CloudWatch Agent with a custom configuration via Systems Manager
resource "aws_ssm_parameter" "cwagent_config_param" {
  name        = "CloudwatchAgentConfiguration"
  description = "The configuration json for cloudwatch agent"
  type        = "String"
  value       = file("${path.module}/files/cw_agent_config.json")
}

resource "aws_ssm_association" "install_cwagent" {
  name             = "AWS-ConfigureAWSPackage"
  association_name = "download-install-cwagent"
  targets {
    key    = "tag:Name"
    values = ["webserver-phpmyadmin"]
  }
  parameters = {
    action = "Install"
    name   = "AmazonCloudWatchAgent"
  }
}
resource "aws_ssm_association" "configure_cwagent" {
  name             = "AmazonCloudWatch-ManageAgent"
  association_name = "configure-start-cwagent"
  targets {
    key    = "tag:Name"
    values = ["webserver-phpmyadmin"]
  }
  parameters = {
    action                        = "configure"
    optionalConfigurationLocation = aws_ssm_parameter.cwagent_config_param.name
  }
  depends_on = [
    aws_ssm_association.install_cwagent
  ]
}

################################################################################
#                           CLOUDWATCH  DASHBOARD                              #
################################################################################
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "CAPCI-MIGRATION-LAB"

  dashboard_body = jsonencode({
    widgets : [
      {
        "type" : "explorer",
        "width" : 24,
        "height" : 15,
        "x" : 0,
        "y" : 0,
        "properties" : {
          "metrics" : [
            {
              "metricName" : "CPUUtilization",
              "resourceType" : "AWS::EC2::Instance",
              "stat" : "Average"
            },
            {
              "metricName" : "disk_used_percent",
              "resourceType" : "AWS::EC2::Instance",
              "stat" : "Average"
            },
            {
              "metricName" : "mem_used_percent",
              "resourceType" : "AWS::EC2::Instance",
              "stat" : "Average"
            }
          ],
          "aggregateBy" : {
            "key" : "InstanceId",
            "func" : "AVG"
          },
          "labels" : [
            {
              "key" : "Name",
              "value" : "webserver-phpmyadmin"
            }
          ],
          "widgetOptions" : {
            "legend" : {
              "position" : "bottom"
            },
            "view" : "timeSeries",
            "rowsPerPage" : 8,
            "widgetsPerRow" : 2
          },
          "period" : 300,
          "splitBy" : "InstanceId",
          "title" : "EC2 METRICS CAPCI-MIGRATION-LAB"
        }
      }
    ]
  })
}

################################################################################
#                           CLOUDWATCH      ALARMS                             #
################################################################################
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "high-cpu-usage-${data.terraform_remote_state.target_infra.outputs.webserver_instance_id}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  actions_enabled     = true
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.capci_mgn_topic.arn]
  datapoints_to_alarm = 1
  dimensions = {
    InstanceId = data.terraform_remote_state.target_infra.outputs.webserver_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  alarm_name          = "high-mem-usage-${data.terraform_remote_state.target_infra.outputs.webserver_instance_id}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  actions_enabled     = true
  alarm_description   = "This metric monitors ec2 memory utilization"
  alarm_actions       = [aws_sns_topic.capci_mgn_topic.arn]
  datapoints_to_alarm = 1
  dimensions = {
    InstanceId = data.terraform_remote_state.target_infra.outputs.webserver_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "disk" {
  alarm_name          = "high-disk-usage-${data.terraform_remote_state.target_infra.outputs.webserver_instance_id}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  actions_enabled     = true
  alarm_description   = "This metric monitors ec2 disk utilization"
  alarm_actions       = [aws_sns_topic.capci_mgn_topic.arn]
  datapoints_to_alarm = 1
  dimensions = {
    InstanceId = data.terraform_remote_state.target_infra.outputs.webserver_instance_id
  }
}

################################################################################
#                           SNS EMAIL NOTIFICATION                             #
################################################################################
resource "aws_sns_topic" "capci_mgn_topic" {
  # checkov:skip=CKV_AWS_26: ADD REASON: encryption not required
  name = "capci-mgn-lab-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.capci_mgn_topic.arn
  protocol  = "email"
  endpoint  = local.email_endpoint
  // If need to send to multiple email ids, use this
  # count = length(var.subscription_mails)
  # endpoint  = var.subscription_mails[count.index]
}

################################################################################
#                       Setup ATHENA to query Logs in S3                       #
################################################################################
resource "aws_athena_database" "vpc_flow_logs_db" {
  # checkov:skip=CKV_AWS_77: ADD REASON: encryption not required
  name          = "vpc_flow_logs_db"
  bucket        = "${data.terraform_remote_state.target_infra.outputs.logs_bucket_id}/aws-athena-query-results"
  force_destroy = true //(Default: false) All tables should be deleted from the db so that the db can be destroyed without error.
}

resource "aws_athena_named_query" "create_table" {
  name     = "create-vpc-flow-logs-table"
  database = aws_athena_database.vpc_flow_logs_db.name
  query    = <<-EOF
  CREATE EXTERNAL TABLE IF NOT EXISTS `vpc_flow_logs` (
    `version` int, 
    `account_id` string, 
    `interface_id` string, 
    `srcaddr` string, 
    `dstaddr` string, 
    `srcport` int, 
    `dstport` int, 
    `protocol` bigint, 
    `packets` bigint, 
    `bytes` bigint, 
    `start` bigint, 
    `end` bigint, 
    `action` string, 
    `log_status` string, 
    `vpc_id` string, 
    `subnet_id` string, 
    `instance_id` string, 
    `tcp_flags` int, 
    `type` string, 
    `pkt_srcaddr` string, 
    `pkt_dstaddr` string, 
    `region` string, 
    `az_id` string, 
    `sublocation_type` string, 
    `sublocation_id` string, 
    `pkt_src_aws_service` string, 
    `pkt_dst_aws_service` string, 
    `flow_direction` string, 
    `traffic_path` int
  )
  PARTITIONED BY (`date` date)
  ROW FORMAT DELIMITED
  FIELDS TERMINATED BY ' '
  LOCATION "s3://${data.terraform_remote_state.target_infra.outputs.logs_bucket_id}/AWSLogs/${data.aws_caller_identity.current.account_id}/vpcflowlogs/${data.aws_region.current.name}/"
  TBLPROPERTIES ("skip.header.line.count"="1");
  EOF
}

resource "aws_athena_named_query" "partition" {
  name     = "add-partition"
  database = aws_athena_database.vpc_flow_logs_db.name
  query    = <<EOF
  ALTER TABLE vpc_flow_logs 
  ADD PARTITION (`date`='2023') LOCATION "s3://${data.terraform_remote_state.target_infra.outputs.logs_bucket_id}/AWSLogs/${data.aws_caller_identity.current.account_id}/vpcflowlogs/${data.aws_region.current.name}/2023"
EOF
}

resource "aws_athena_named_query" "get_logs" {
  name     = "get-vpc-flow-logs"
  database = aws_athena_database.vpc_flow_logs_db.name
  query    = "SELECT * FROM vpc_flow_logs;"
}

resource "aws_athena_named_query" "select_vpc_cidr" {
  name     = "select-vpc-cidr"
  database = aws_athena_database.vpc_flow_logs_db.name
  query    = "SELECT dstaddr,srcaddr,srcport,dstport,vpc_id,subnet_id,instance_id FROM vpc_flow_logs WHERE dstaddr BETWEEN '192.168.0.1' AND '192.168.15.24';"
}
