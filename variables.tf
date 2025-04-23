variable "project_id" {
  description = "The project ID to host the cluster in"
  default = "your-project-id"
}

variable "cluster_name" {
  description = "The name of the cluster"
  default     = "spark-gke-cluster"
}