#
# Core database which stores shared metadata e.g. SSO config
#

terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.15.0"
    }
  }
}

resource "postgresql_database" "core" {
  name = "core"
}

resource "postgresql_role" "users" {
  count = length(var.users)

  name     = var.users[count.index].name
  login    = true
  password = var.users[count.index].password

  lifecycle {
    ignore_changes = [
      roles
    ]
  }
}

resource "postgresql_grant" "connect" {
  count = length(postgresql_role.users)

  database    = postgresql_database.core.name
  role        = postgresql_role.users[count.index].name
  object_type = "database"
  privileges  = ["CONNECT"]

  depends_on = [
    postgresql_role.users
  ]
}

module "schemas" {
  count = length(var.schemas)

  source = "../schema"

  namespace   = var.namespace
  environment = var.environment

  super_admin_user = var.super_admin_user
  name             = var.schemas[count.index].name
  database         = postgresql_database.core.name

  read_users  = var.schemas[count.index].read_users
  write_users = var.schemas[count.index].write_users
  dba_users   = var.schemas[count.index].dba_users

  depends_on = [
    postgresql_grant.connect
  ]
}
