################################################################################
#                  SSM PATCH MANAGER & MAINTENANCE WINDOW                      #
################################################################################

// Run the patch baseline every third thursday of the month at 23:30 UTC - "cron(30 23 ? * THU#3 *)"
// Run the patch baseline every day at 10:00 UTC - "cron(00 10 * * ? *)"

# resource "aws_ssm_patch_baseline" "production" {
#   name             = "patch-baseline"
#   operating_system = "UBUNTU"
# }

resource "aws_ssm_default_patch_baseline" "baseline" {
  baseline_id      = data.aws_ssm_patch_baseline.default_ubuntu.id
  operating_system = data.aws_ssm_patch_baseline.default_ubuntu.operating_system
}

resource "aws_ssm_patch_group" "patchgroup" {
  baseline_id = data.aws_ssm_patch_baseline.default_ubuntu.id // aws_ssm_default_patch_baseline.baseline.id
  patch_group = "capci"
}

resource "aws_ssm_maintenance_window" "web_mw" {
  name              = "maintenance-window-webserver"
  schedule          = "cron(30 23 ? * THU#3 *)" // "cron(10 11 * * ? *)"
  schedule_timezone = "Asia/Kolkata"
  duration          = 3
  cutoff            = 1
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
      #   output_s3_bucket     = aws_s3_bucket.example.id
      #   output_s3_key_prefix = "output"
      #   service_role_arn     = aws_iam_role.example.arn
      #   timeout_seconds      = 600

      #   notification_config {
      #     notification_arn    = aws_sns_topic.example.arn
      #     notification_events = ["All"]
      #     notification_type   = "Command"
      #   }

      parameter {
        name   = "Operation"
        values = ["Install"]
      }
    }
  }
}

################################################################################
#                               AWS BACKUP                                     #
################################################################################

resource "aws_backup_vault" "backup" {
  # checkov:skip=CKV_AWS_166: ADD REASON: kms cmk not required 
  name = "capci-mgn-vault"
  # kms_key_arn = aws_kms_key.example.arn
}

resource "aws_backup_plan" "plan" {
  name = "capci_mgn_backup_plan"

  rule {
    rule_name         = "capci_mgn_monthly_backup_rule"
    target_vault_name = aws_backup_vault.backup.name
    schedule          = "cron(30 23 ? * THU#3 *)" // "cron(25 06 * * ? *)"

    lifecycle {
      delete_after = 1
    }
  }
}

resource "aws_backup_selection" "resource_assignment" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "capci_mgn_backup_ec2"
  plan_id      = aws_backup_plan.plan.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Name"
    value = "webserver-phpmyadmin"
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
  name = "AWS-ConfigureAWSPackage"
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
  name = "AmazonCloudWatch-ManageAgent"

  targets {
    key    = "tag:Name"
    values = ["webserver-phpmyadmin"]
  }
  parameters = {
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

# ################################################################################
# #                           CLOUDWATCH      ALARMS                             #
# ################################################################################
# resource "aws_cloudwatch_metric_alarm" "cpu" {
#   alarm_name          = "cpu-usage-${data.terraform_remote_state.target_infra.outputs.webserver_instance_id}"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 90
#   actions_enabled     = true
#   alarm_description   = "This metric monitors ec2 cpu utilization"
#   alarm_actions       = [aws_sns_topic.capci_mgn_topic.arn]
#   datapoints_to_alarm = 1
# }

# resource "aws_cloudwatch_metric_alarm" "memory" {
#   alarm_name          = "mem-usage-${data.terraform_remote_state.target_infra.outputs.webserver_instance_id}"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 2
#   metric_name         = "mem_used_percent"
#   namespace           = "CapciMgnPhpmyAdmin"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 80
#   actions_enabled     = true
#   alarm_description   = "This metric monitors ec2 memory utilization"
#   alarm_actions       = [aws_sns_topic.capci_mgn_topic.arn]
#   datapoints_to_alarm = 1
# }

# resource "aws_cloudwatch_metric_alarm" "disk" {
#   alarm_name          = "disk-usage-${data.terraform_remote_state.target_infra.outputs.webserver_instance_id}"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 2
#   metric_name         = "disk_used_percent"
#   namespace           = "CapciMgnPhpmyAdmin"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 90
#   actions_enabled     = true
#   alarm_description   = "This metric monitors ec2 disk utilization"
#   alarm_actions       = [aws_sns_topic.capci_mgn_topic.arn]
#   datapoints_to_alarm = 1
# }

################################################################################
#                           SNS EMAIL NOTIFICATION                             #
################################################################################
resource "aws_sns_topic" "capci_mgn_topic" {
  # checkov:skip=CKV_AWS_26: ADD REASON: encryption not required
  name = "capci-mgn-lab"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.capci_mgn_topic.arn
  protocol  = "email"
  endpoint  = local.email_endpoint
}
