# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
resource "aws_iam_role" "eks_node_group_role" {
  name = "ECPEKSNodeGroupRole-${local.cluster_name}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_role_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_role_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_role_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_role_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_role_kms_decrypt_policy" {
  policy_arn = aws_iam_policy.kms_decrypt_policy.arn
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_role_ecp_ssm_session_logs" {
  policy_arn = aws_iam_policy.ecp_ssm_session_logs.arn
  role       = aws_iam_role.eks_node_group_role.name
}

# Policy for SSM Agent to decrypt KMS keys (session data and session data logging)
data "aws_iam_policy_document" "kms_decrypt_policy" {
  statement {
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      "${aws_kms_key.ssm_key_session_data_encryption.arn}",
      "${aws_kms_key.ssm_key_session_data_logs_encryption.arn}",
    ]
  }
}

resource "aws_iam_policy" "kms_decrypt_policy" {
  name        = "ECPKMSDecryptKeysForSSM-${local.cluster_name}"
  policy = data.aws_iam_policy_document.kms_decrypt_policy.json
}

# Policy for sending session data logs (commands, output) as an encrypted stream from SSM Agent to CloudWatch
data "aws_iam_policy_document" "ecp_ssm_session_logs" {
  statement {
    sid = "SSMSessionLogsToCloudWatch"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ssm:UpdateInstanceInformation",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecp_ssm_session_logs" {
  name        = "ECPSSMSessionLogs-${local.cluster_name}"
  policy = data.aws_iam_policy_document.ecp_ssm_session_logs.json
}