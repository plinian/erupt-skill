#!/usr/bin/env bash
# 仅编译校验（不启动应用），用于修改代码后快速发现语法/注解错误。
# 用法: compile.sh <项目目录>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:?用法: compile.sh <项目目录>}"

bash "$SCRIPT_DIR/setup-env.sh"
# shellcheck disable=SC1091
source "${ERUPT_SKILL_HOME:-$HOME/.erupt-skill}/env.sh"

cd "$PROJECT_DIR"
# shellcheck disable=SC2086
"$MVN" $MVN_SETTINGS_ARG -q -DskipTests compile
echo "[erupt-skill] 编译通过 ✓" >&2
