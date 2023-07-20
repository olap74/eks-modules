variable "aws_region" {
  description = "AWS region"
  type = string
}

variable "name_suffix" {
  description = "Name suffix (environment name, etc.)"
  type = string
  default = ""
}

variable "firehose_name" {
  description = "Map of firehose names. Looks like {s3_prefix = firehose_name}"
  type = map(string)
  default = {}
}

variable "bucket_name" {
  description = "Firehose bucket name"
  type = string
  default = ""
}

variable "replica_bucket_name" {
  description = "Replica bucket name"
  type = string
  default = ""
}

variable "expire_days" {
  description = "Delete objects after x days"
  default = 300
}

variable "expire_days_replica" {
  description = "Delete replicated objects after x days"
  default = 300
}

variable "kinesis_firehose_buffer" {
  description = "Kinesis Firehose buffer"
  default = 10
}

variable "kinesis_firehose_buffer_interval" {
  description = "Kinesis Firehose buffer interval"
  default = 300
}

variable "s3_compression_format" {
  description = "S3 Compression format"
  default = "UNCOMPRESSED"
}

variable "cloudwatch_log_retention" {
  description = "Cloudwatch log retention period"
  default = 7
}
