variable "project" {
  description = "The project in which to hold the components"
  type        = string
  default     = "mmp5-dev"
}

variable "region" {
  description = "The region in which to create the VPC network"
  type        = string
  default     = "southamerica-east1"
}

variable "zone" {
  description = "The zone in which to create the Kubernetes cluster. Must match the region"
  type        = string
  default     = "southamerica-east1-a"
}

variable "cluster_name" {
  description = "The name to give the new Kubernetes cluster."
  type        = string
  default     = "mmp5-private-cluster"
}

variable "node_pool_name" {
  description = "The name of the new node pool."
  type        = string
  default     = "mmp5-private-nodepool"
}

variable "bastion_tags" {
  description = "A list of tags applied to your bastion instance."
  type        = list
  default     = ["bastion"]
}

variable "node_machine_type" {
  description = "The machine type that will be used by the node"
  type        = string
  default     = "n1-highmem-2"
}

variable "k8s_namespace" {
  description = "The namespace to use for the deployment and workload identity binding"
  type        = string
  default     = "default"
}

variable "k8s_sa_name" {
  description = "The k8s service account name to use for the deployment and workload identity binding"
  type        = string
  default     = "postgres"
}

variable "db_username" {
  description = "The name for the DB connection"
  type        = string
  default     = "postgres"
}

variable "service_account_iam_roles" {
  type = list

  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
  description = <<-EOF
  List of the default IAM roles to attach to the service account on the
  GKE Nodes.
  EOF
}

variable "service_account_custom_iam_roles" {
  type = list
  default = []

  description = <<-EOF
  List of arbitrary additional IAM roles to attach to the service account on
  the GKE nodes.
  EOF
}

variable "project_services" {
  type = list

  default = [
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "sqladmin.googleapis.com",
    "securetoken.googleapis.com",
  ]
  description = <<-EOF
  The GCP APIs that should be enabled in this project.
  EOF
}
