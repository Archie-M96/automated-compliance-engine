# Automated Cloud Compliance Monitor

## Business Case

Manual security audits don't scale, and in financial services, a single 
misconfigured S3 bucket exposing customer or transaction data isn't just a 
technical bug — it's a regulatory incident. Frameworks like POPIA (South 
Africa) and international equivalents demand continuous, auditable proof 
that data-at-rest controls remain enforced, not just that they were correct 
at deployment time. Configuration drift — a bucket policy changed manually, 
a public access block accidentally removed — is one of the most common 
causes of real-world cloud data breaches.

This project automates the first line of defense: a scheduled, serverless 
audit that checks every S3 bucket in the account against a required security 
control, and alerts a human the moment drift is detected — closing the gap 
between "secure at deployment" and "secure right now."

## Architecture

### 1. Trigger Layer (Scheduled Automation)
- **Service:** Amazon EventBridge
- **Pattern:** Cron-based rule firing daily at 08:00, decoupling the audit 
  schedule from the audit logic itself — the schedule can change without 
  touching the Lambda.

### 2. Compute Layer (Audit Logic)
- **Runtime:** Python 3.12, using `boto3`
- **Function:** Enumerates every S3 bucket in the account and checks the 
  `PublicAccessBlock` configuration on each. Buckets missing full public 
  access block enforcement are flagged as non-compliant.

### 3. Alerting Layer (Human-in-the-Loop Notification)
- **Service:** Amazon SNS
- **Flow:** Non-compliant findings are published as a structured payload to 
  a dedicated SNS topic, which delivers an email alert — ensuring drift is 
  surfaced to a human within the same operational day it occurs, not 
  discovered during the next scheduled audit or manual review.

### 4. Identity & Access Layer (IAM)
- **Framework:** Principle of Least Privilege (PoLP)
- **Implementation:** A dedicated IAM role restricts the Lambda to exactly 
  two capabilities — read-only S3 configuration checks (`s3:GetBucket*`) 
  and publish rights to the single, specific SNS topic ARN. The function 
  cannot modify any bucket, read any object data, or publish to any other 
  destination.

## Current Scope & Next Steps

This is a **detection-first v1** — it identifies drift and alerts a human; 
it does not auto-remediate. Deliberate scope decisions for this version:

- Checks one control (`PublicAccessBlock`) rather than a full compliance 
  ruleset — chosen as the highest-impact, most common misconfiguration to 
  start with.
- Alerts rather than auto-fixes, keeping a human in the loop for this 
  version rather than allowing an automated process to alter production 
  resources unsupervised.

**Planned v2:** an optional auto-remediation path (Lambda re-applies the 
public access block on detection) gated behind a manual approval step, plus 
expanding the ruleset to cover encryption-at-rest and bucket policy checks.
- Transitioning from custom scheduled Lambda scans to native event-driven detection using AWS Config and CloudTrail for real-time drift alerting.