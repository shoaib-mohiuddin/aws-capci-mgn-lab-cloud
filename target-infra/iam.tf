################################################################################
#                  EC2 INSTANCE PROFILE/IAM ROLE                               #
################################################################################
resource "aws_iam_role" "ec2" {
  name               = "Instance_SSM_CW_Role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_role" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.ec2.name
  policy_arn = element(local.role_policy_arns, count.index)
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "webserver_instance_profile"
  role = aws_iam_role.ec2.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#######################################################################################
#               BUCKET POLICIES FOR VPC FLOW LOGS AND ALB ACCESS LOGS                 #
#######################################################################################
# data "aws_elb_service_account" "main" {}

# data "aws_iam_policy_document" "vpc_alb_logs" {
#   # Policy for vpc flow logs
#   statement {
#     principals {
#       type        = "AWS"
#       identifiers = [data.aws_elb_service_account.main.arn]
#     }
#     actions = [
#       "s3:PutObject"
#     ]
#     resources = [
#       "${module.logs_bucket.s3_bucket_arn}/*"
#     ]
#     condition {
#       test     = "StringEquals"
#       variable = "s3:x-amz-acl"
#       values = [
#         "bucket-owner-full-control"
#       ]
#     }
#   }
#   # Policy for alb access logs
#   statement {
#     #sid = "AWSLogDeliveryWrite"
#     principals {
#       type        = "Service"
#       identifiers = ["delivery.logs.amazonaws.com"]
#     }
#     actions = [
#       "s3:PutObject",
#     ]
#     resources = [
#       "${module.logs_bucket.s3_bucket_arn}/*"
#     ]
#     condition {
#       test     = "StringEquals"
#       variable = "s3:x-amz-acl"
#       values = [
#         "bucket-owner-full-control"
#       ]
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "aws:SourceAccount"
#       values = [
#         "${data.aws_caller_identity.current.account_id}"
#       ]
#     }
#     condition {
#       test     = "ArnLike"
#       variable = "aws:SourceArn"
#       values = [
#         "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
#       ]
#     }
#   }
#   statement {
#     sid = "AWSLogDeliveryCheck"
#     principals {
#       type        = "Service"
#       identifiers = ["delivery.logs.amazonaws.com"]
#     }
#     actions = [
#       "s3:GetBucketAcl",
#       "s3:ListBucket"
#     ]
#     resources = [
#       "${module.logs_bucket.s3_bucket_arn}/*"
#     ]
#     condition {
#       test     = "StringEquals"
#       variable = "aws:SourceAccount"
#       values = [
#         "${data.aws_caller_identity.current.account_id}"
#       ]
#     }
#     condition {
#       test     = "ArnLike"
#       variable = "aws:SourceArn"
#       values = [
#         "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
#       ]
#     }
#   }
# }

