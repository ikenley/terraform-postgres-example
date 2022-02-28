#
# Creates the databases, roles, and users for a sample PostgreSQL server
# The server will have: 
#   A shared "core" database for client configuration
#   Multiple single-tenant "tenant" databases
#   An "analytics" database for ad-hoc reporting
#

locals {
  namespace     = "ikenley"
  environment   = "dev"
  tenants       = ["tenant_x", "tenant_y"]
  analyst_users = ["analyst_x", "analyst_y"]
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

module "user_set" {
  source = "../modules/user_set"

  namespace   = local.namespace
  environment = local.environment

  users = var.users
}

module "core_database" {
  source = "../modules/database"

  namespace   = local.namespace
  environment = local.environment

  name             = "core"
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

  depends_on = [
    module.user_set
  ]
}

module "tenant_databases" {
  count = length(local.tenants)

  source = "../modules/database"

  namespace   = local.namespace
  environment = local.environment

  name             = local.tenants[count.index]
  super_admin_user = var.super_admin_user
  users            = var.users

  # ETL schemas modeled after DBT
  # https://discourse.getdbt.com/t/how-we-structure-our-dbt-projects/355
  schemas = concat(
    [
      # raw data
      {
        name        = "source"
        read_users  = local.analyst_users
        write_users = []
        dba_users   = ["etl_dba"]
      },
      # research and transformations
      {
        name        = "staging"
        read_users  = []
        write_users = []
        dba_users   = concat(["etl_dba"], local.analyst_users)
      },
      # data mart, ready to publish
      {
        name        = "mart"
        read_users  = []
        write_users = []
        dba_users   = concat(["etl_dba"], local.analyst_users)
      },
      {
        name        = "app_x"
        read_users  = local.analyst_users
        write_users = ["app_x_user"]
        dba_users   = ["app_x_dba"]
      }
    ],
    # Create a "sandbox schema" for each analyst
    [for analyst in local.analyst_users : {
      name        = "${analyst}_sandbox"
      read_users  = []
      write_users = []
      dba_users   = [analyst]
    }]
  )

  depends_on = [
    module.user_set
  ]
}

module "analytics_database" {
  source = "../modules/database"

  namespace   = local.namespace
  environment = local.environment

  name             = "analytics"
  super_admin_user = var.super_admin_user
  users            = var.users

  schemas = [
    {
      name        = "main"
      read_users  = ["example_core_reader"]
      write_users = ["app_x_user", "example_core_writer"]
      dba_users   = local.analyst_users
    }
  ]

  depends_on = [
    module.user_set
  ]
}
