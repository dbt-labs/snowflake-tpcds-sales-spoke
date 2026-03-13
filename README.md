# snowflake_tpcds_sales_spoke

A dbt project built on TPC-DS data in Snowflake. This is a downstream "spoke" project that depends on `snowflake_tpcds_core` via dbt Cloud Mesh.

## Local Development

This project uses dbt Cloud Mesh cross-project refs, which don't resolve in dbt-core. A wrapper script handles this so you can run dbt commands locally.

### Prerequisites

Install `dbt-snowflake` in your Python environment:

```bash
pip install dbt-snowflake
```

### Running dbt locally

Use the wrapper script instead of calling `dbt` directly:

```bash
scripts/with-local-dbt.sh parse
scripts/with-local-dbt.sh compile --select fct_daily_sales
scripts/with-local-dbt.sh ls --resource-type model
scripts/with-local-dbt.sh test --select stg_tpcds_core__date_dim
```

The wrapper temporarily injects stub models for the upstream `snowflake_tpcds_core` project and uses a dummy Snowflake profile. It restores all files when done.

Commands that need a live warehouse connection (`dbt run`, `dbt test` on the full project) require real Snowflake credentials in `~/.dbt/profiles.yml` and won't work with the dummy profile.

See [`stubs/README.md`](stubs/README.md) for how the stubs work and how to extend them.

### Validating the manifest

To validate project fixture completeness (materialization types, resource types, etc.):

```bash
# Generate a manifest if you don't have one
scripts/with-local-dbt.sh parse

# Validate
python scripts/verify_manifest.py
python scripts/verify_manifest.py --manifest path/to/other/manifest.json
```

## Resources

- [dbt documentation](https://docs.getdbt.com/docs/introduction)
- [dbt Community](https://community.getdbt.com/)
- [dbt Events](https://events.getdbt.com)
- [dbt Blog](https://blog.getdbt.com/)
