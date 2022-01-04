// LAMBDA CHALLENGE 2 // 
// Creating a new policy to allow permission on Cloudwatch Logs // 

resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "cloudwatch_policy"
  path        = "/"
  description = "My Cloudwatch Logs policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [                                   // This Policy allows permissions on CloudWatch Logs 
      {                                                 // Policy has been created on Cloudwatch Logs. 
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "mia-log-group" {
  name = "cwlog-group-mia"

  tags = {
    Environment = "production"
    Application = "serviceA"
  }
}


//Create Role for lambda function with an assume Role & Create Function//

resource "aws_iam_role" "iamLambda_role" { 
  name = "lambda_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "lambda_file" {
  type        = "zip"
  source_file = "../lambda/lambda.py"
  output_path = "../lambda/lambda.zip"
}

// Lambda Function 

resource "aws_lambda_function" "lambda_function_mia" {
  filename      = data.archive_file.lambda_file.output_path
  function_name = "mia_lambda_s3_function"
  role          = aws_iam_role.iamLambda_role.arn
  handler       = "lambda.lambda_handler"
  runtime = "python3.8"
  environment {
    variables = {
      foo = "bar"
    }
  }
}

// Create new bucket // 
resource "aws_s3_bucket" "my_s3_bucket" {
  bucket = "talent-academy-s3-bucket"

  versioning {
    enabled = true                                // Creating New Bucket called: talent-academy-s3-bucket // 
  }                                                    // Bucket Created 

  tags = {
    Name        = "talent-academy-tfstates"
    Environment = "Test"
  }
}

// Setting S3 permissions policy //
resource "aws_iam_policy" "s3permissionspolicy" {
  name        = "s3Permissions_policy"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a                // This policy allows read, write and create permissions for S3 
  # Terraform expression result to valid JSON syntax.               // Policy created, not yet attached to anything 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
        "s3:CreateBucket",
        "s3:GetObject",
        "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}                 

resource "aws_iam_policy_attachment" "attach_s3toLambda" {
  name       = "attach_s3toLambda"
  roles      = [aws_iam_role.iamLambda_role.name]             // Attaching above S3 Permissions to Lambda Role 
  policy_arn = aws_iam_policy.s3permissionspolicy.arn               // S3 Policy above now attached to Lambda Role/Function. 
}                                                                       // Lambda Function can now read/write/create in S3.


resource "aws_cloudwatch_event_rule" "s3event" {
  name        = "s3-upload-trigger-lambda"
  description = "each S3 upload to trigger Lambda Function"

  event_pattern = <<EOF
{
    "source": [
        "aws.s3"
    ],
    "detail-type": [
        "AWS s3 trigger"
    ],
    "detail": {
        "eventSource": [
            "s3.amazonaws.com"
        ],
        "eventName": [
            "PutObject"
        ],
        "requestParameters": {
            "bucketName": [
                "talent-academy-s3-bucket"
            ],
            "key": [
                "*"
            ]
        }
    }
}
EOF
}

resource "aws_cloudwatch_event_target" "LambdaTrigger" {
  arn  = aws_lambda_function.lambda_function_mia.arn
  rule = aws_cloudwatch_event_rule.s3event.id
}


