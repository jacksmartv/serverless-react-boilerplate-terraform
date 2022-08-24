
resource "aws_api_gateway_rest_api" "apigw" {
  name = var.name

  endpoint_configuration {
    types = [var.endpoint_type]
  }
  tags = merge({ "Name" = "apigateway" }, var.default_tags)
}

resource "aws_api_gateway_account" "apigw_account" {
  cloudwatch_role_arn = var.cloudwatch_role_arn
}

resource "aws_api_gateway_resource" "health_resource" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = "health"
}

resource "aws_api_gateway_method" "health_resource_method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  resource_id   = aws_api_gateway_resource.health_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "method_integration" {
  rest_api_id             = aws_api_gateway_rest_api.apigw.id
  resource_id             = aws_api_gateway_resource.health_resource.id
  http_method             = "ANY"
  integration_http_method = "GET"
  type                    = "MOCK"
  depends_on              = [aws_api_gateway_method.health_resource_method]
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = "${var.stage}-ignore"
  depends_on  = [aws_api_gateway_integration.method_integration]
}

resource "aws_cloudwatch_log_group" "cloudwatchgroup" {
  name = "${var.identifier}_apigw/accesslogs"
  tags = merge({ "Name" = "cw-loggroup" }, var.default_tags)
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.stage
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.cloudwatchgroup.arn
    format          = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] $context.httpMethod $context.resourcePath $context.protocol $context.status $context.responseLength $context.requestId"
  }
  xray_tracing_enabled = true
  tags                 = merge({ "Name" = "apigw-stage" }, var.default_tags)
}

resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = var.stage
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
  depends_on = [aws_api_gateway_stage.stage]
}

