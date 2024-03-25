variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
  default = "1.29"
}

variable "vpc_id" {
  type = string
}

variable "ami_release_version" {
  description = "Default EKS AMI release version for node groups"
  type        = string
  default     = "1.29.0-20240129"
}