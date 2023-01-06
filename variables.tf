variable "images" {
  description = "Map of images"
  type = object({
    main    = optional(string)
    kubectl = optional(string)
    aws     = optional(string)
  })
  default = {
    main    = null
    kubectl = null
    aws     = null
  }
}

variable "install_helm" {
  description = "Do you want to install helm chart?"
  type        = bool
  default     = true
}

variable "release_version" {
  description = "version of helm release"
  type        = string
  default     = null
}

variable "service_account_name" {
  description = "Name of the service account to have right to send to S3 bucket"
  type        = string
  default     = "velero"
}

variable "kubernetes_namespace" {
  description = "Namespace to install autoscaler pod"
  type        = string
  default     = "velero"
}

variable "irsa_iam_role_name" {
  type        = string
  description = "IAM role name for IRSA"
  default     = "eks-velero"
}

variable "irsa_iam_role_additional_inline_policies" {
  type        = map(string)
  description = "Additional inline policies for IRSA IAM role"
  default     = {}
}

variable "irsa_iam_role_use_default_inline_policy" {
  type        = bool
  description = "Use of default inline policy for IRSA IAM role"
  default     = true
}

variable "cluster_id" {
  description = "EKS cluster name"
  type        = string
}

variable "bucket" {
  description = "bucket name"
  type        = string
}

variable "region" {
  description = "Region of you eks cluster"
  type        = string
}

variable "values" {
  description = "Values"
  type        = list(any)
  default     = []
}
