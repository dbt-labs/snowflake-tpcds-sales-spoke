#!/usr/bin/env python3
"""Validate a dbt manifest.json for project fixture completeness.

Runs a series of checks against a manifest file and reports results.
Checks can be required (failure exits 1) or advisory (reported but not blocking).

Usage:
    python scripts/verify_manifest.py
    python scripts/verify_manifest.py --manifest path/to/manifest.json

To generate a manifest first:
    scripts/with-local-dbt.sh parse && python scripts/verify_manifest.py
"""

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

DEFAULT_MANIFEST = "target/manifest.json"
PROJECT_NAME = "snowflake_tpcds_sales_spoke"

# dbt core materialization types (all adapters)
CORE_MATERIALIZATIONS = {"view", "table", "incremental", "ephemeral"}

# materialized_view is a core type but NOT supported on Snowflake --
# Snowflake uses dynamic_table instead.
SNOWFLAKE_MATERIALIZATIONS = {"dynamic_table"}

BUILTIN_MATERIALIZATIONS = (
    CORE_MATERIALIZATIONS
    | SNOWFLAKE_MATERIALIZATIONS
    | {"materialized_view"}
    | {"seed", "snapshot", "test"}  # internal dbt materializations for non-model resource types
)

MIN_CUSTOM_MATERIALIZATIONS = 2

# dbt resource types per https://docs.getdbt.com/reference/global-configs/resource-type
ALL_RESOURCE_TYPES = {
    "analysis",
    "exposure",
    "metric",
    "model",
    "saved_query",
    "seed",
    "semantic_model",
    "snapshot",
    "source",
    "test",
    "unit_test",
}


_USE_COLOR = sys.stdout.isatty()


def _color(text: str, code: str) -> str:
    if not _USE_COLOR:
        return text
    return f"\033[{code}m{text}\033[0m"


def _green(text: str) -> str:
    return _color(text, "32")


def _red(text: str) -> str:
    return _color(text, "31")


def _yellow(text: str) -> str:
    return _color(text, "33")


def _bold(text: str) -> str:
    return _color(text, "1")


def _dim(text: str) -> str:
    return _color(text, "2")


@dataclass
class CheckResult:
    name: str
    passed: bool
    message: str
    required: bool = True

    @property
    def status_label(self) -> str:
        if self.passed:
            return _green("✓ PASS")
        if self.required:
            return _red("✗ FAIL")
        return _yellow("⚠ WARN")


Check = Callable[[dict, str], CheckResult]


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------


def check_materialization_types(manifest: dict, project_name: str) -> CheckResult:
    """All core + adapter materialization types must be present, plus >= 2 custom types."""
    found: set[str] = set()
    for node in manifest.get("nodes", {}).values():
        if node.get("package_name") == project_name:
            mat = node.get("config", {}).get("materialized")
            if mat:
                found.add(mat)

    missing_core = CORE_MATERIALIZATIONS - found
    missing_snowflake = SNOWFLAKE_MATERIALIZATIONS - found

    custom_found = found - BUILTIN_MATERIALIZATIONS
    enough_custom = len(custom_found) >= MIN_CUSTOM_MATERIALIZATIONS

    missing = missing_core | missing_snowflake
    passed = not missing and enough_custom

    parts = []
    if missing:
        parts.append(f"Missing required: {sorted(missing)}")
    if not enough_custom:
        parts.append(
            f"Need >= {MIN_CUSTOM_MATERIALIZATIONS} custom types, "
            f"found {len(custom_found)}: {sorted(custom_found)}"
        )
    if passed:
        parts.append(
            f"Core: {sorted(CORE_MATERIALIZATIONS & found)}, "
            f"Snowflake: {sorted(SNOWFLAKE_MATERIALIZATIONS & found)}, "
            f"Custom: {sorted(custom_found)}"
        )

    return CheckResult(
        name="materialization_types",
        passed=passed,
        message=". ".join(parts),
    )


def check_resource_types(manifest: dict, project_name: str) -> CheckResult:
    """Advisory: check which dbt resource types are represented."""
    # TODO: Promote to required once all resource types are present.
    # Remediation (adding metrics, semantic_models, etc.) is out of scope
    # for this validator -- tracked separately.
    found: set[str] = set()
    for section in (
        "nodes",
        "sources",
        "exposures",
        "metrics",
        "semantic_models",
        "saved_queries",
        "unit_tests",
    ):
        for resource in manifest.get(section, {}).values():
            if resource.get("package_name") == project_name:
                found.add(resource.get("resource_type"))

    found.discard(None)
    present = ALL_RESOURCE_TYPES & found
    missing = ALL_RESOURCE_TYPES - found

    parts = [f"Present ({len(present)}/{len(ALL_RESOURCE_TYPES)}): {sorted(present)}"]
    if missing:
        parts.append(f"Missing: {sorted(missing)}")

    return CheckResult(
        name="resource_types",
        passed=not missing,
        required=False,
        message=". ".join(parts),
    )


# ---------------------------------------------------------------------------
# Registry -- add new checks here
# ---------------------------------------------------------------------------

CHECKS: list[Check] = [
    check_materialization_types,
    check_resource_types,
]


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate a dbt manifest for project fixture completeness.",
    )
    parser.add_argument(
        "--manifest",
        default=DEFAULT_MANIFEST,
        help=f"Path to manifest.json (default: {DEFAULT_MANIFEST})",
    )
    args = parser.parse_args()

    project_dir = Path(__file__).resolve().parent.parent
    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute():
        manifest_path = project_dir / manifest_path

    if not manifest_path.exists():
        print(f"{_red('✗')} Manifest not found: {manifest_path}", file=sys.stderr)
        print(file=sys.stderr)
        print("  Generate one first:", file=sys.stderr)
        print(f"    {_dim('scripts/with-local-dbt.sh parse')}", file=sys.stderr)
        sys.exit(1)

    with open(manifest_path) as f:
        manifest = json.load(f)

    results = [check(manifest, PROJECT_NAME) for check in CHECKS]

    print()
    print(_bold("Manifest Validation"))
    print(_dim("─" * 60))
    for r in results:
        print(f"  {r.status_label}  {_bold(r.name)}")
        for line in r.message.split(". "):
            print(f"         {_dim(line)}")
    print(_dim("─" * 60))

    required_failures = [r for r in results if not r.passed and r.required]
    if required_failures:
        print(
            _red(f"✗ FAILED: {len(required_failures)} required check(s) did not pass.")
        )
        sys.exit(1)
    else:
        print(_green("✓ All required checks passed."))


if __name__ == "__main__":
    main()
