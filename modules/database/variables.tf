variable "namespace" {}
variable "environment" {}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "The name of the database"
}

variable "super_admin_user" {
  description = "Global postgres server admin username. STORE SECURELY. https://learn.hashicorp.com/tutorials/terraform/sensitive-variables"
  sensitive   = true
}

variable "users" {
  description = "List of users in the form of map {name, password}"
  sensitive   = true
  type = list(object({
    name     = string
    password = string
  }))
}

variable "schemas" {
  type = list(object({
    name        = string,
    read_users  = list(string)
    write_users = list(string)
    dba_users   = list(string)
  }))
}
