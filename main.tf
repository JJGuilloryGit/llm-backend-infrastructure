terraform {
  backend "s3" {
    bucket         = "awsaibucket1"
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

data "aws_s3_bucket" "logs" {
  bucket = "awsaibucket1"  # Your existing bucket name
}

provider "aws" {
  region = "us-east-1"
}


# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# IAM policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "LambdaBedrockPolicy"
  description = "Allows Lambda to invoke Amazon Bedrock and access required resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock-runtime:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:us-east-1:*:foundation-model/amazon.titan-embed-text-v2"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.feedback.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${data.aws_s3_bucket.logs.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function
# Lambda function
resource "aws_lambda_function" "backend" {
  filename      = "lambda_code.zip"
  function_name = "LLMBackend"
  role         = aws_iam_role.lambda_role.arn
  runtime      = "python3.9"
  handler      = "llm_handler.lambda_handler"
  timeout      = 30
  memory_size  = 256

  environment {
    variables = {
      FEEDBACK_TABLE = aws_dynamodb_table.feedback.name
      LOGS_BUCKET   = data.aws_s3_bucket.logs.id  # Changed to use data source
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/LLMBackend"
  retention_in_days = 14
}

# DynamoDB table for feedback
resource "aws_dynamodb_table" "feedback" {
  name           = "feedback-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "feedback_id"

  attribute {
    name = "feedback_id"
    type = "S"
  }

  tags = {
    Environment = "production"
    Application = "LLM-Backend"
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "llm_api" {
  name        = "llm-api"
  description = "API Gateway for LLM Backend"
}

# API Gateway resource
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.llm_api.id
  parent_id   = aws_api_gateway_rest_api.llm_api.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway method
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.llm_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway integration with Lambda
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.llm_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.backend.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.llm_api.execution_arn}/*/*"
}

# API Gateway method response
resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.llm_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# API Gateway integration response
resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.llm_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.lambda
  ]
}

# OPTIONS method for CORS
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.llm_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# OPTIONS method response
resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.llm_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# OPTIONS integration
resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.llm_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# OPTIONS integration response
resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.llm_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.options
  ]
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.llm_api.id

  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.options,
    aws_api_gateway_method.proxy,
    aws_api_gateway_method.options
  ]
}

# API Gateway stage
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.llm_api.id
  stage_name    = "prod"
}

# Output the API Gateway URL
output "api_gateway_url" {
  value = "${aws_api_gateway_stage.stage.invoke_url}/backend"
}
