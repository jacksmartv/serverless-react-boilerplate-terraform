output "id" {
  value = "${aws_api_gateway_rest_api.apigw.id}"
}

output "arn" {
  value = "${aws_api_gateway_rest_api.apigw.arn}"
}

output "root_resource_id" {
  value = "${aws_api_gateway_rest_api.apigw.root_resource_id}"
}
