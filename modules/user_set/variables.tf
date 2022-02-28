variable "namespace" {}
variable "environment" {}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "users" {
  description = "List of users in the form of map {name, password}"
  sensitive   = true
  type = list(object({
    name     = string
    password = string
  }))
}
