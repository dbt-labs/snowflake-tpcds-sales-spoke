# Local dbt Stubs

This directory contains fixtures that allow dbt-core to run locally against this project, which uses [dbt Cloud Mesh](https://docs.getdbt.com/docs/collaborate/govern/project-dependencies) cross-project refs that only resolve in dbt Cloud.

## Why this exists

Models like `transactions.sql` use cross-project refs:

```sql
select * from {{ ref('snowflake_tpcds_core', 'customers') }}
select * from {{ ref('snowflake_tpcds_core', 'stores') }}
```

These refs are declared in `dependencies.yml` as a project dependency. dbt Cloud resolves them via Mesh. dbt-core cannot -- it fails with "depends on a node named 'customers' in package or project 'snowflake_tpcds_core' which was not found."

The stubs provide minimal stand-in models so these refs resolve locally.

## What's here

```
stubs/
  profiles.yml                       # Dummy Snowflake profile (no real connection)
  snowflake_tpcds_core/              # Stub dbt project
    dbt_project.yml
    models/
      customers.sql                  # Provides ref('snowflake_tpcds_core', 'customers')
      stores.sql                     # Provides ref('snowflake_tpcds_core', 'stores')
```

- **`profiles.yml`** -- A Snowflake profile with dummy credentials. Sufficient for `dbt parse`, `dbt compile`, and `dbt ls`, which don't open a warehouse connection.
- **`snowflake_tpcds_core/`** -- A minimal dbt project whose models satisfy the two cross-project refs. The models return single-row stubs with the correct column names.

## How to use

Use the wrapper script to run any dbt command locally:

```bash
scripts/with-local-dbt.sh parse
scripts/with-local-dbt.sh compile --select fct_daily_sales
scripts/with-local-dbt.sh ls --resource-type model
```

The wrapper handles all the plumbing: sidelining `dependencies.yml`, injecting the stub package into `packages.yml`, pointing `DBT_PROFILES_DIR` at the dummy profile, and restoring everything when done.

## Adding a new stub

When a new cross-project ref is introduced (e.g., `ref('snowflake_tpcds_core', 'new_model')`):

1. Create `stubs/snowflake_tpcds_core/models/new_model.sql` with a `select` returning the column names the downstream model expects.
2. That's it. The wrapper script picks it up automatically on the next run.

If the project adds a dependency on a different upstream project (e.g., `snowflake_tpcds_other`):

1. Create `stubs/snowflake_tpcds_other/` with its own `dbt_project.yml` and stub models.
2. Update `scripts/with-local-dbt.sh` to also append `- local: stubs/snowflake_tpcds_other` to `packages.yml`, and add `dbt_packages/snowflake_tpcds_other` to the cleanup step.

## How the wrapper works

`scripts/with-local-dbt.sh` does this on every invocation:

1. Backs up `dependencies.yml`, `packages.yml`, and `package-lock.yml`
2. Removes `dependencies.yml` (the `projects:` key is Cloud-only)
3. Appends `- local: stubs/snowflake_tpcds_core` to `packages.yml`
4. Sets `DBT_PROFILES_DIR` to this `stubs/` directory
5. Runs `dbt deps` (installs packages including the stub) then the requested dbt command
6. Restores all backed-up files and removes `dbt_packages/snowflake_tpcds_core/`

Cleanup runs via `trap EXIT`, so files are restored even if the dbt command fails.
