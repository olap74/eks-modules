data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
    name_suffix                      = var.name_suffix
    firehose_name                    = var.firehose_name
    kinesis_firehose_role_name       = format("%s-firehose", local.name_suffix)
    log_stream_name                  = format("%s-firehose-log-stream", local.name_suffix)
    kinesis_firehose_iam_policy_name = format("%s-firehose-policy", local.name_suffix)

    bucket_name = format("%s-%s", var.bucket_name, local.name_suffix)
    replica_bucket_name = format("%s-%s-replica", var.replica_bucket_name, local.name_suffix)
}
