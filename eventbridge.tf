# 1. Create the EventBridge Rule (The Alarm Clock)
resource "aws_cloudwatch_event_rule" "daily_audit" {
  name                = "daily-compliance-audit"
  description         = "Wakes up the compliance auditor every morning at 8 AM UTC"
  schedule_expression = "cron(0 8 * * ? *)" 
}

# Note: We will add the "Target" (the Lambda function) to this rule 
# in the next step once we write the Python script!