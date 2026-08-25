#!/usr/bin/env bash
# Build and start an erupt project in one step.
# Usage: run.sh <project-dir> [port]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:?Usage: run.sh <project-dir> [port]}"
PORT="${2:-8080}"

bash "$SCRIPT_DIR/setup-env.sh"
# shellcheck disable=SC1091
source "${ERUPT_SKILL_HOME:-$HOME/.erupt-skill}/env.sh"

cd "$PROJECT_DIR"
echo "[erupt-skill] Compiling project..." >&2
# shellcheck disable=SC2086
"$MVN" $MVN_SETTINGS_ARG -q -DskipTests compile

echo "[erupt-skill] Starting, visit http://localhost:$PORT shortly (login: erupt/erupt)" >&2
# shellcheck disable=SC2086
exec "$MVN" $MVN_SETTINGS_ARG -q spring-boot:run -Dspring-boot.run.arguments="--server.port=$PORT"
