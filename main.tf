module "helm" {
  source          = "github.com/terraform-helm/terraform-helm-velero"
  count           = var.install_helm ? 1 : 0
  release_version = var.release_version
  images          = var.images
  set_values = [
    {
      name  = "serviceAccount.server.name"
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
    region    = var.region,
    aws_image = var.images.aws,
    bucket    = var.bucket,
    }
  )]
}

resource "kubernetes_service_account_v1" "this" {
  metadata {
    name        = var.service_account_name
    namespace   = var.kubernetes_namespace
    annotations = { "eks.amazonaws.com/role-arn" : module.iam.arn }
  }

  dynamic "image_pull_secret" {
    for_each = var.kubernetes_svc_image_pull_secrets != null ? var.kubernetes_svc_image_pull_secrets : []
    content {
      name = image_pull_secret.value
    }
  }

  automount_service_account_token = true
}

