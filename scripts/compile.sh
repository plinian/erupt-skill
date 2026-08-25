#!/usr/bin/env bash
# Compile-only check (does not start the app), for catching syntax/annotation
# errors quickly after code changes.
# Usage: compile.sh <project-dir>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:?Usage: compile.sh <project-dir>}"

bash "$SCRIPT_DIR/setup-env.sh"
# shellcheck disable=SC1091
source "${ERUPT_SKILL_HOME:-$HOME/.erupt-skill}/env.sh"

cd "$PROJECT_DIR"
# shellcheck disable=SC2086
"$MVN" $MVN_SETTINGS_ARG -q -DskipTests compile
echo "[erupt-skill] Compile OK" >&2
