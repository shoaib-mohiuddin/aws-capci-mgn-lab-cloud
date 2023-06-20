variable "region" {
  description = "AWS region to work with"
  type        = string
}

variable "public_domain_name" {
  description = "public domain name / route53 public hosted zone"
  type        = string
}

variable "private_domain_name" {
  description = "private domain name / route53 private hosted zone"
  type        = string
}

variable "subdomain_name" {
  description = "subdomain name / route53 subdomain"
  type        = string
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
}
