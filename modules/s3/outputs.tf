output "arn" {
  value = aws_s3_bucket.main.arn
}

output "log_bucket_arn" {
  value = var.enable_logging ? aws_s3_bucket.log_bucket[0].arn : null
}

output "name" {
  value = aws_s3_bucket.main.id
}

output "log_bucket_name" {
  value = var.enable_logging ? aws_s3_bucket.log_bucket[0].id : null
}
