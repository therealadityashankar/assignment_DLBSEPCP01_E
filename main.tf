terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

####################
# S3 Bucket
####################
resource "aws_s3_bucket" "images_bucket" {
  bucket = "my-image-ranking-bucket-unique-name"
  acl    = "public-read"

  # Example: enabling website hosting if you want images served as a static site
  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  # Add lifecycle or versioning if you want
}

####################
# DynamoDB Table
####################
resource "aws_dynamodb_table" "image_rankings" {
  name           = "image_rankings"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "image_id"
  attribute {
    name = "image_id"
    type = "S"
  }
}

####################
# IAM Role for Lambda
####################
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role_image_ranking"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy_image_ranking"
  description = "Policy for Lambda to access S3 and DynamoDB"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.images_bucket.arn,
          "${aws_s3_bucket.images_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.image_rankings.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

####################
# Lambda Function
####################
resource "aws_lambda_function" "image_ranker" {
  function_name = "image_ranker"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.9"  # adjust if using another language
  
  # This assumes you have a lambda_function.zip file in the same directory
  filename = "lambda_function.zip"

  # If you want to force updates when code changes, you can use source_code_hash.
  # For example:
  # source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.image_rankings.name
      BUCKET_NAME    = aws_s3_bucket.images_bucket.bucket
    }
  }
}

####################
# API Gateway
####################
resource "aws_api_gateway_rest_api" "image_api" {
  name        = "ImageRankingAPI"
  description = "API for ranking images"
}

resource "aws_api_gateway_resource" "images_resource" {
  rest_api_id = aws_api_gateway_rest_api.image_api.id
  parent_id   = aws_api_gateway_rest_api.image_api.root_resource_id
  path_part   = "rank"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.image_api.id
  resource_id   = aws_api_gateway_resource.images_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.image_api.id
  resource_id             = aws_api_gateway_resource.images_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.image_ranker.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_ranker.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.image_api.id
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
  stage_name = "prod"
}

output "api_invoke_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}
