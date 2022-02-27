variable "namespace" {}
variable "environment" {}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "The name of the schema"
}

variable "database" {
  description = "The DATABASE in which where this schema will be created"
}

variable "super_admin_user" {
  description = "Global postgres server admin username. STORE SECURELY. https://learn.hashicorp.com/tutorials/terraform/sensitive-variables"
  sensitive   = true
}

variable "read_users" {
  description = "List of users to assign read-only access"
  type        = list(string)
  default     = []
}

variable "write_users" {
  description = "List of users to assign read-write access"
  type        = list(string)
  default     = []
}

variable "dba_users" {
  description = "List of users to assign DBA access (e.g. for migrations)"
  type        = list(string)
  default     = []
}
