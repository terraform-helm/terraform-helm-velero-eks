locals {
  eks_oidc_issuer_url   = var.oidc_provider != null ? var.oidc_provider : replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  eks_oidc_provider_arn = "arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"
}

data "aws_partition" "this" {}
data "aws_caller_identity" "this" {}

data "aws_eks_cluster" "this" {
  name = var.cluster_id
}

data "aws_iam_policy_document" "velero" {
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

module "helm" {
  source          = "github.com/terraform-helm/terraform-helm-velero"
  count           = var.install_helm ? 1 : 0
  release_version = var.release_version
  images          = var.images
  set_values = [
    {
      name  = "rbac.serviceAccount.name"
      value = var.service_account_name
    },
    {
      name  = "serviceAccount.server.create"
      value = "false"
    },
    {
      name  = "cleanUpCRDs"
      value = "true"
    },
  ]
  values = [templatefile("${path.module}/helm/velero.yaml", {
    aws_region = var.region,
    aws_image  = var.image.aws,
    bucket     = var.bucket,
    }
  )]
}

resource "kubernetes_service_account_v1" "this" {
  metadata {
    name        = var.service_account_name
    namespace   = var.kubernetes_namespace
    annotations = { "eks.amazonaws.com/role-arn" : aws_iam_role.this.arn }
  }

  dynamic "image_pull_secret" {
    for_each = var.kubernetes_svc_image_pull_secrets != null ? var.kubernetes_svc_image_pull_secrets : []
    content {
      name = image_pull_secret.value
    }
  }

  automount_service_account_token = true
}

resource "aws_iam_role" "this" {
  name                  = var.irsa_iam_role_name
  description           = "AWS IAM Role for the Kubernetes service account ${var.service_account_name}."
  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy.json
  path                  = var.irsa_iam_role_path
  force_detach_policies = true
  permissions_boundary  = var.irsa_iam_permissions_boundary
}

resource "aws_iam_policy" "this" {
  name        = var.irsa_iam_policy_name
  description = "Cluster Velero IAM policy"
  policy      = data.aws_iam_policy_document.velero.json
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}
