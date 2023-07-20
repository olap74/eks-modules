resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose" {
  for_each    = local.firehose_name
  name        = each.value
  destination = "extended_s3"
  depends_on  = [aws_iam_role.kinesis_firehose]
  extended_s3_configuration {
    role_arn           = aws_iam_role.kinesis_firehose.arn
    prefix             = format("%s/", each.key)
    bucket_arn         = aws_s3_bucket.main.arn
    buffer_size        = var.kinesis_firehose_buffer
    buffer_interval    = var.kinesis_firehose_buffer_interval
    compression_format = var.s3_compression_format
  }
  tags = local.tags
}

# Cloudwatch logging group for Kinesis Firehose
resource "aws_cloudwatch_log_group" "kinesis_logs" {
  for_each          = local.firehose_name
  depends_on        = [aws_kinesis_firehose_delivery_stream.kinesis_firehose]
  name              = "/aws/kinesisfirehose/${each.value}-firehose-logs"
  retention_in_days = var.cloudwatch_log_retention

  tags = local.tags
}

# Create the stream
resource "aws_cloudwatch_log_stream" "kinesis_logs" {
  for_each       = local.firehose_name
  depends_on     = [aws_kinesis_firehose_delivery_stream.kinesis_firehose]
  name           = local.log_stream_name
  log_group_name = aws_cloudwatch_log_group.kinesis_logs[each.key].name
}

# Role for Kinesis Firehose
resource "aws_iam_role" "kinesis_firehose" {
  name        = local.kinesis_firehose_role_name
  description = "IAM Role for Kenisis Firehose"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Effect": "Allow"
    }
  ]
}
POLICY

  tags = local.tags
}

data "aws_iam_policy_document" "kinesis_firehose_policy_document" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [ aws_s3_bucket.main.arn, format("%s/*", maws_s3_bucket.main.arn ) ]    

    effect = "Allow"
  }

  statement {
    actions = [
      "firehose:PutRecordBatch",
    ]

    resources = [
        for stream in local.firehose_name :  "arn:${data.aws_partition.current.partition}:firehose:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deliverystream/${stream}"
    ]

    effect = "Allow"
  }

  statement {
    actions = [
      "logs:PutLogEvents",
    ]

    resources = concat(
      [
        for log in aws_cloudwatch_log_group.kinesis_logs : "${log.arn}:*"
      ],
      [
        for logstream in aws_cloudwatch_log_stream.kinesis_logs : logstream.arn
      ])

    effect = "Allow"
  }
}

resource "aws_iam_policy" "kinesis_firehose_iam_policy" {
  depends_on = [aws_kinesis_firehose_delivery_stream.kinesis_firehose]
  name       = local.kinesis_firehose_iam_policy_name
  policy     = data.aws_iam_policy_document.kinesis_firehose_policy_document.json
}

resource "aws_iam_role_policy_attachment" "kinesis_fh_role_attachment" {
  depends_on = [aws_kinesis_firehose_delivery_stream.kinesis_firehose]
  role       = aws_iam_role.kinesis_firehose.name
  policy_arn = aws_iam_policy.kinesis_firehose_iam_policy.arn
}
