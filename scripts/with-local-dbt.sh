#!/usr/bin/env bash
#
# Run any dbt command locally against this dbt Cloud Mesh project.
#
# This wrapper temporarily swaps in a local stub package for
# snowflake_tpcds_core (resolving cross-project refs that only
# work in dbt Cloud) and points at a dummy Snowflake profile.
#
# Usage:
#   scripts/with-local-dbt.sh parse
#   scripts/with-local-dbt.sh compile --select fct_daily_sales
#   scripts/with-local-dbt.sh ls --resource-type model
#   scripts/with-local-dbt.sh test --select stg_tpcds_core__date_dim
#
# Prerequisites: dbt-snowflake must be installed in the active Python environment.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <dbt-command> [args...]" >&2
    echo "Example: $0 parse" >&2
    exit 1
fi

cleanup() {
    cd "$PROJECT_DIR"
    for f in dependencies.yml packages.yml package-lock.yml; do
        if [ -f "${f}.local-dbt-bak" ]; then
            mv "${f}.local-dbt-bak" "$f"
        fi
    done
    rm -rf dbt_packages/snowflake_tpcds_core
}
trap cleanup EXIT

cd "$PROJECT_DIR"

# Back up files that will be modified
for f in dependencies.yml packages.yml package-lock.yml; do
    if [ -f "$f" ]; then
        cp "$f" "${f}.local-dbt-bak"
    fi
done

# Sideline dependencies.yml (projects: is a dbt Cloud Mesh feature)
rm -f dependencies.yml

# Inject the committed stub as a local package
echo "  - local: stubs/snowflake_tpcds_core" >> packages.yml

# Use the committed dummy profile
export DBT_PROFILES_DIR="$PROJECT_DIR/stubs"

dbt deps --quiet
dbt "$@"
