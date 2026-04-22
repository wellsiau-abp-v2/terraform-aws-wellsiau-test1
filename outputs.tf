# Define your output values here.
# Example:
# output "id" {
#   description = "The ID of the resource"
#   value       = aws_resource.example.id
# }
output "bucket" {
   description = "bucket name"
   value = aws_s3_bucket.example.id
}
