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

# read-only access
resource "postgresql_role" "reader" {
  name = "${var.name}_reader"

  lifecycle {
    ignore_changes = [
      roles
    ]
  }
}

# read-write access
resource "postgresql_role" "writer" {
  name = "${var.name}_writer"

  lifecycle {
    ignore_changes = [
      roles
    ]
  }
}

# DBA (DataBase Admin) access. Schema edits but not role changes
resource "postgresql_role" "dba" {
  name = "${var.name}_dba"

  lifecycle {
    ignore_changes = [
      roles
    ]
  }
}

# Make grants transitive. e.g. dba inherits writer which inherits reader
# resource "postgresql_grant_role" "writer_inherits_reader" {
#   role       = postgresql_role.writer.name
#   grant_role = postgresql_role.reader.name
# }

# resource "postgresql_grant_role" "dba_inherits_writer" {
#   role       = postgresql_role.dba.name
#   grant_role = postgresql_role.writer.name
# }

#
# reader permissions
#

# Grant reader role to users
resource "postgresql_grant_role" "reader" {
  count = length(var.read_users)

  role       = var.read_users[count.index]
  grant_role = postgresql_role.reader.name
}

resource "postgresql_grant" "reader_schema_usage" {
  database    = var.database
  role        = postgresql_role.reader.name
  schema      = var.name
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "reader_schema_permissions" {
  database    = var.database
  role        = postgresql_role.reader.name
  schema      = var.name
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_default_privileges" "reader_superadmin" {
  role     = postgresql_role.reader.name
  database = var.database
  schema   = var.name

  owner       = var.super_admin_user
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_default_privileges" "reader_dba" {
  role     = postgresql_role.reader.name
  database = var.database
  schema   = var.name

  owner       = postgresql_role.dba.name
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
  grant_role = postgresql_role.writer.name
}

resource "postgresql_grant" "writer_schema_usage" {
  database    = var.database
  role        = postgresql_role.writer.name
  schema      = var.name
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "writer_schema_permissions" {
  database    = var.database
  role        = postgresql_role.writer.name
  schema      = var.name
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "UPDATE", "DELETE"]
}

resource "postgresql_default_privileges" "writer_super_admin" {
  role     = postgresql_role.writer.name
  database = var.database
  schema   = var.name

  owner       = var.super_admin_user
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "UPDATE", "DELETE"]
}

resource "postgresql_default_privileges" "writer_dba" {
  role     = postgresql_role.writer.name
  database = var.database
  schema   = var.name

  owner       = postgresql_role.dba.name
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
  grant_role = postgresql_role.dba.name
}

resource "postgresql_grant" "dba_schema_permissions" {
  database    = var.database
  role        = postgresql_role.dba.name
  schema      = var.name
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "dba_table_permissions" {
  database    = var.database
  role        = postgresql_role.dba.name
  schema      = var.name
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "UPDATE", "DELETE", "TRUNCATE"]
}

resource "postgresql_default_privileges" "dba_table" {
  role     = postgresql_role.dba.name
  database = var.database
  schema   = var.name

  owner       = var.super_admin_user
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "UPDATE", "DELETE", "TRUNCATE"]
}

resource "postgresql_grant" "dba_sequence_permissions" {
  database    = var.database
  role        = postgresql_role.dba.name
  schema      = var.name
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]
}

resource "postgresql_default_privileges" "dba_sequence" {
  role     = postgresql_role.dba.name
  database = var.database
  schema   = var.name

  owner       = var.super_admin_user
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]
}
