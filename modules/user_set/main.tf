#
# Creates a set of users
#

terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.15.0"
    }
  }
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
