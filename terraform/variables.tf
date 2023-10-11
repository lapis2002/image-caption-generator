// Variables to use accross the project
// which can be accessed by var.project_id
variable "project_id" {
  description = "The project ID to host the cluster in"
  default     = "mle-course-399400"
}

variable "region" {
  description = "The region the cluster in"
  default     = "us-east1"
}

variable "bucket" {
  description = "GCS bucket for MLE course"
  default     = "mle-course"
}