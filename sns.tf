# 1. AWS Provider Setup
provider "aws" {
  region = "us-east-1"
}

# 2. Create the SNS Topic (The Megaphone)
resource "aws_sns_topic" "compliance_alerts" {
  name = "fintech-compliance-alerts"
}

# 3. Subscribe your email to the Topic
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.compliance_alerts.arn
  protocol  = "email"
  endpoint  = "acmagoro@protonmail.com" # 
}