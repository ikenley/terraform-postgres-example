#
# Creates the databases, roles, and users for a sample PostgreSQL server
# The server will have: 
#   Multiple single-tenant "tenant" databases
#   A shared "core" database for client configuration
#   An "analytics" database for ad-hoc reporting
#

locals {
  namespace   = "ikenley"
  environment = "dev"
}

terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.15.0"
    }
  }
}

provider "postgresql" {
  host     = "localhost"
  port     = 5432
  database = "postgres"
  username = "postgres"
  password = var.super_admin_password
  sslmode  = "disable" # localhost only. Do not disable in real env
}

module "core_db" {
  source = "../modules/core_db"

  namespace   = local.namespace
  environment = local.environment

  super_admin_user = var.super_admin_user
  users            = var.users

  schemas = [
    {
      name        = "foo"
      read_users  = ["example_core_reader"]
      write_users = ["app_x_user", "example_core_writer"]
      dba_users   = ["app_x_dba", "example_core_dba"]
    },
    {
      name        = "bar"
      read_users  = ["example_core_reader"]
      write_users = ["example_core_writer"]
      dba_users   = ["example_core_dba"]
    }
  ]
}
