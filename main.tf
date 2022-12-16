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
  values = concat([templatefile("${path.module}/helm/velero.yaml", {
    region    = var.region,
    aws_image = var.images.aws,
    bucket    = var.bucket,
    }
  )], var.values)
}
