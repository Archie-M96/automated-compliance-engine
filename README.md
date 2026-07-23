# Automated Cloud Compliance Monitor

## Why I Built This
Manual security audits don't scale, and in financial services a single misconfigured S3 bucket 
isn't just a bug, it's a regulatory incident. Frameworks like POPIA demand continuous, auditable 
proof that controls stay enforced, not just that they were correct at deployment time. 
Configuration drift is one of the most common real-world causes of cloud data breaches, so I 
built a scheduled, serverless audit that catches it and alerts a human the moment it happens.

## What I Built

### 1. Trigger Layer (Scheduled Automation)
- Amazon EventBridge, cron-based rule firing daily at 08:00. This decouples the audit schedule 
  from the audit logic, so I can change timing without touching the Lambda.

### 2. Compute Layer (Audit Logic)
- Python 3.12, using `boto3`, enumerates every S3 bucket in the account and checks its 
  `PublicAccessBlock` configuration. Anything missing full enforcement gets flagged non-compliant.

### 3. Alerting Layer (Human-in-the-Loop)
- Non-compliant findings publish as a structured payload to a dedicated SNS topic, delivering an 
  email alert the same operational day drift occurs, not at the next scheduled review.

### 4. Identity & Access Layer (IAM)
- The Lambda's role has exactly two capabilities: read-only `s3:GetBucket*` checks and publish 
  rights to one specific SNS topic ARN. It cannot modify a bucket, read object data, or publish 
  anywhere else.

## Current Scope & Next Steps
This is a detection-first v1. It identifies drift and alerts, it doesn't auto-remediate yet. 
I deliberately kept it to one control (`PublicAccessBlock`) as the highest-impact starting point, 
and kept a human in the loop rather than letting an automated process alter production resources 
unsupervised.

**Planned v2:** an optional auto-remediation path (Lambda re-applies the block on detection) 
gated behind manual approval, plus expanding the ruleset to cover encryption-at-rest and bucket 
policy checks. I'm also looking at moving from scheduled Lambda scans to native AWS Config plus 
CloudTrail event-driven detection for real-time alerting instead of a daily cron.

## CI/CD & Security Prevention (DevSecOps)
This repo is protected by a GitHub Actions pipeline:
- **GitLeaks** scans every push and PR for hardcoded secrets.
- **Checkov** scans the Terraform for infrastructure misconfigurations before deployment.

*Proof of execution: I tested this by intentionally committing a dummy AWS credential. 
[See the blocked run here](https://github.com/Archie-M96/automated-compliance-engine/commit/64c2d29ceb4c52659beb2172e820ca9048c22806). 
It's worth noting the block itself doesn't remove the secret from git history. The real 
incident response step is revoking and rotating the credential immediately, not just fixing 
the file.*
