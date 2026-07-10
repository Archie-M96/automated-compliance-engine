# 1. Package the Python script
data "archive_file" "auditor_zip" {
  type        = "zip"
  source_file = "auditor.py"
  output_path = "auditor.zip"
}

# 2. IAM Role for the Auditor Lambda
resource "aws_iam_role" "auditor_role" {
  name = "fintech_compliance_auditor_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 3. IAM Policy granting S3 read and SNS publish permissions
resource "aws_iam_policy" "auditor_policy" {
  name = "fintech_auditor_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketPublicAccessBlock"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        # Restrict publishing ONLY to our specific alarm bell
        Resource = aws_sns_topic.compliance_alerts.arn 
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

resource "aws_iam_role_policy_attachment" "auditor_attach" {
  role       = aws_iam_role.auditor_role.name
  policy_arn = aws_iam_policy.auditor_policy.arn
}

# 4. The Lambda Function itself
resource "aws_lambda_function" "compliance_auditor" {
  filename         = data.archive_file.auditor_zip.output_path
  function_name    = "S3ComplianceAuditor"
  role             = aws_iam_role.auditor_role.arn
  handler          = "auditor.lambda_handler"
  source_code_hash = data.archive_file.auditor_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 15

  # Pass the SNS Topic ARN to the Python script as an environment variable
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.compliance_alerts.arn
    }
  }
}

# 5. Connect EventBridge (Alarm Clock) to Lambda (Auditor)
resource "aws_cloudwatch_event_target" "trigger_auditor" {
  rule      = aws_cloudwatch_event_rule.daily_audit.name
  target_id = "TriggerComplianceAuditor"
  arn       = aws_lambda_function.compliance_auditor.arn
}

# 6. Give EventBridge permission to "push the button" on Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.compliance_auditor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_audit.arn
}