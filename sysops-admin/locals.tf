locals {
  email_endpoint = jsondecode(data.aws_secretsmanager_secret_version.email.secret_string)["email"]
}
