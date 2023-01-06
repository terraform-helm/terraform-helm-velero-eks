locals {
  kms_inline_policy = var.bucket_kms_arn != null ? { kms = data.aws_iam_policy_document.kms.json } : {}
  ec2_inline_policy = var.stateful ? { ec2 = data.aws_iam_policy_document.ec2.json } : {}
  s3_inline_policy  = var.irsa_iam_role_use_default_inline_policy ? { s3 = data.aws_iam_policy_document.s3.json } : {}
  inline_policies = merge(
    local.kms_inline_policy,
    local.ec2_inline_policy,
    local.s3_inline_policy,
    var.irsa_iam_role_additional_inline_policies,
  )
}

data "aws_partition" "this" {}

data "aws_iam_policy_document" "s3" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = ["arn:${data.aws_partition.this.partition}:s3:::${var.bucket}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:${data.aws_partition.this.partition}:s3:::${var.bucket}"]
  }
}

data "aws_iam_policy_document" "ec2" {
  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DescribeSnapshots",
      "ec2:DescribeVolumes",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "kms" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [var.bucket_kms_arn]
  }
}

module "role_sa" {
  source          = "github.com/littlejo/terraform-aws-role-eks.git?ref=v0.2"
  name            = var.irsa_iam_role_name
  inline_policies = local.inline_policies
  cluster_id      = var.cluster_id
  create_sa       = true
  service_accounts = {
    main = {
      name      = var.service_account_name
      namespace = var.kubernetes_namespace
    }
  }
}
