variable "super_admin_user" {
  description = "Global postgres server admin username. STORE SECURELY. https://learn.hashicorp.com/tutorials/terraform/sensitive-variables"
  sensitive   = true
}

variable "super_admin_password" {
  description = "Global postgres server admin password. STORE SECURELY. https://learn.hashicorp.com/tutorials/terraform/sensitive-variables"
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
