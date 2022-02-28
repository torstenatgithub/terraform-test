# Create KMS Key for session data encryption (Session Manager)
resource "aws_kms_key" "ssm_key_session_data_encryption" {
  description             = "KMS Key for session data encryption (Session Manager)"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.ssm_key_session_data_encryption.json
}

resource "aws_kms_alias" "ssm_key_session_data_encryption" {
  name          = "alias/ssm-session-data-encryption"
  target_key_id = aws_kms_key.ssm_key_session_data_encryption.key_id
}

data "aws_iam_policy_document" "ssm_key_session_data_encryption" {
  statement {
    sid = "Allowed Principals"
    actions = [
      "kms:*",
    ]
    principals {
      type        = "AWS"
      identifiers = [ 
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        # "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/engineer"
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/admin"
      ]
    }
    resources = [
      "*",
    ]
  }
}

# Create KMS Key for session data logs encryption (CloudWatch Logs)
resource "aws_kms_key" "ssm_key_session_data_logs_encryption" {
  description             = "KMS Key for session data logs encryption (CloudWatch Logs)"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.ssm_key_session_data_logs_encryption.json
}

resource "aws_kms_alias" "ssm_key_session_data_logs_encryption" {
  name          = "alias/ssm-session-data-logs-encryption"
  target_key_id = aws_kms_key.ssm_key_session_data_logs_encryption.key_id
}

# Grant the CloudWatch service principal the permission to use the key
data "aws_iam_policy_document" "ssm_key_session_data_logs_encryption" {
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*",
    ]
    principals {
      type        = "AWS"
      identifiers = [ 
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        # "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/engineer"
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/admin"
      ]
    }
    resources = [
      "*",
    ]
  }

  statement {
    sid = "Enable CloudWatch Logs Permissions"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    principals {
      type        = "Service"
      identifiers = [ "logs.${data.aws_region.current.name}.amazonaws.com" ]
    }
    resources = [
      "*",
    ]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
      ]
    }
  }
}

# Create CloudWatch Log Group for session data logs (SSM Agent)
resource "aws_cloudwatch_log_group" "ssm_session_data_logs" {
  name = "ssm-session-data-logs"
  retention_in_days = 7
  kms_key_id = aws_kms_key.ssm_key_session_data_logs_encryption.arn
}

# Set AWS Systems Manager Session Manager Preferences
resource "aws_ssm_document" "ssm_session_manager_regional_settings" {
  name          = "SSM-SessionManagerRunShell"
  document_type = "Session"

  content = <<DOC
  {
      "schemaVersion": "1.0",
      "description": "Document to hold regional settings for Session Manager",
      "sessionType": "Standard_Stream",
      "inputs": {
          "kmsKeyId": "${aws_kms_key.ssm_key_session_data_encryption.key_id}",
          "idleSessionTimeout": "10",
          "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.ssm_session_data_logs.name}",
          "cloudWatchEncryptionEnabled": true,
          "cloudWatchStreamingEnabled": true
      }
  }
DOC
}