#!/usr/bin/env bash
# 一键构建并启动 erupt 项目。
# 用法: run.sh <项目目录> [端口]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:?用法: run.sh <项目目录> [端口]}"
PORT="${2:-8080}"

bash "$SCRIPT_DIR/setup-env.sh"
# shellcheck disable=SC1091
source "${ERUPT_SKILL_HOME:-$HOME/.erupt-skill}/env.sh"

cd "$PROJECT_DIR"
echo "[erupt-skill] 编译项目..." >&2
# shellcheck disable=SC2086
"$MVN" $MVN_SETTINGS_ARG -q -DskipTests compile

echo "[erupt-skill] 启动中，稍后访问 http://localhost:$PORT （账号/密码: erupt/erupt）" >&2
# shellcheck disable=SC2086
exec "$MVN" $MVN_SETTINGS_ARG -q spring-boot:run -Dspring-boot.run.arguments="--server.port=$PORT"
