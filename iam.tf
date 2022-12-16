data "aws_partition" "this" {}

data "aws_iam_policy_document" "this" {
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

module "role_sa" {
  source        = "github.com/littlejo/terraform-aws-role-eks.git?ref=v0.1"
  name          = var.irsa_iam_role_name
  inline_policy = data.aws_iam_policy_document.this.json
  cluster_id    = var.cluster_id
  create_sa     = true
  service_accounts = {
    main = {
      name      = var.service_account_name
      namespace = var.kubernetes_namespace
    }
  }
}
