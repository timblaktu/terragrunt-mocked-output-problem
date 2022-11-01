data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
  description = "AWS Account ID of the executing IAM principal"
}

