#
# Creates the schema and standard roles
#

terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.15.0"
    }
  }
}

resource "postgresql_schema" "this" {
  name     = var.name
  database = var.database

  drop_cascade = true
}

#
# Create standard roles reader, writer, and dba
#

locals {
  has_readers = length(var.read_users) == 0 ? 0 : 1
  has_writers = length(var.write_users) == 0 ? 0 : 1
  has_dbas    = length(var.dba_users) == 0 ? 0 : 1
}

# read-only access
resource "postgresql_role" "reader" {
  count = local.has_readers

  name = "${var.database}_${var.name}_reader"

  lifecycle {
    ignore_changes = [
      roles
    ]
  }
}

# read-write access
resource "postgresql_role" "writer" {
  count = local.has_writers

  name = "${var.database}_${var.name}_writer"

  lifecycle {
    ignore_changes = [
      roles
    ]
  }
}

# DBA (DataBase Admin) access. Schema edits but not role changes
resource "postgresql_role" "dba" {
  count = local.has_dbas

  name = "${var.database}_${var.name}_dba"

  lifecycle {
    ignore_changes = [
      roles
    ]
  }
}

#
# reader permissions
#

# Grant reader role to users
resource "postgresql_grant_role" "reader" {
  count = length(var.read_users)

  role       = var.read_users[count.index]
  grant_role = postgresql_role.reader[0].name
}

resource "postgresql_grant" "reader_schema_usage" {
  count = local.has_readers

  database    = var.database
  role        = postgresql_role.reader[0].name
  schema      = var.name
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "reader_schema_permissions" {
  count = local.has_readers

  database    = var.database
  role        = postgresql_role.reader[0].name
  schema      = var.name
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_default_privileges" "reader_superadmin" {
  count = local.has_readers

  role     = postgresql_role.reader[0].name
  database = var.database
  schema   = var.name

  owner       = var.super_admin_user
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_default_privileges" "reader_dba" {
  count = local.has_readers

  role     = postgresql_role.reader[0].name
  database = var.database
  schema   = var.name

  owner       = postgresql_role.dba[0].name
  object_type = "table"
  privileges  = ["SELECT"]
}

#
# writer permissions
#

# Grant writer role to users
resource "postgresql_grant_role" "writer" {
  count = length(var.write_users)

  role       = var.write_users[count.index]
  grant_role = postgresql_role.writer[0].name
}

resource "postgresql_grant" "writer_schema_usage" {
  count = local.has_writers

  database    = var.database
  role        = postgresql_role.writer[0].name
  schema      = var.name
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "writer_schema_permissions" {
  count = local.has_writers

  database    = var.database
  role        = postgresql_role.writer[0].name
  schema      = var.name
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "UPDATE", "DELETE"]
}

resource "postgresql_default_privileges" "writer_super_admin" {
  count = local.has_writers

  role     = postgresql_role.writer[0].name
  database = var.database
  schema   = var.name

  owner       = var.super_admin_user
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "UPDATE", "DELETE"]
}

resource "postgresql_default_privileges" "writer_dba" {
  count = local.has_writers

  role     = postgresql_role.writer[0].name
  database = var.database
  schema   = var.name

  owner       = postgresql_role.dba[0].name
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "UPDATE", "DELETE"]
}

#
# dba permissions
#

# Grant dba role to users
resource "postgresql_grant_role" "dba" {
  count = length(var.dba_users)

  role       = var.dba_users[count.index]
  grant_role = postgresql_role.dba[0].name
}

resource "postgresql_grant" "dba_schema_permissions" {
  count = local.has_dbas

  database    = var.database
  role        = postgresql_role.dba[0].name
  schema      = var.name
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "dba_table_permissions" {
  count = local.has_dbas

  database    = var.database
  role        = postgresql_role.dba[0].name
  schema      = var.name
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "UPDATE", "DELETE", "TRUNCATE"]
}

resource "postgresql_default_privileges" "dba_table" {
  count = local.has_dbas

  role     = postgresql_role.dba[0].name
  database = var.database
  schema   = var.name

  owner       = var.super_admin_user
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "UPDATE", "DELETE", "TRUNCATE"]
}

resource "postgresql_grant" "dba_sequence_permissions" {
  count = local.has_dbas

  database    = var.database
  role        = postgresql_role.dba[0].name
  schema      = var.name
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]
}

resource "postgresql_default_privileges" "dba_sequence" {
  count = local.has_dbas

  role     = postgresql_role.dba[0].name
  database = var.database
  schema   = var.name

  owner       = var.super_admin_user
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]
}
