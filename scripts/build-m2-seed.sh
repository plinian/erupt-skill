#!/usr/bin/env bash
# 重新生成 vendor/m2 依赖种子。模板依赖或 erupt 版本变更后运行一次即可：
#   bash scripts/build-m2-seed.sh
# 会用最新已发布的 erupt 版本 + 模板 pom 在干净仓库中解析全部依赖，打包分卷放回 vendor/m2/。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDOR_M2_DIR="$SKILL_DIR/vendor/m2"

log() { echo "[erupt-skill] $*" >&2; }

bash "$SCRIPT_DIR/setup-env.sh"
# shellcheck disable=SC1091
source "${ERUPT_SKILL_HOME:-$HOME/.erupt-skill}/env.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
proj="$work/seed-proj"
repo="$work/repo"
cp -r "$SKILL_DIR/template" "$proj"

for f in "$proj/pom.xml" "$proj/src/main/resources/application.yml" "$proj/src/main/java/app/Application.java"; do
    sed -i.bak 's/__ARTIFACT_ID__/m2-seed/g' "$f" && rm -f "$f.bak"
done

ver="$(curl -s --max-time 15 "https://maven.aliyun.com/repository/public/xyz/erupt/erupt-spring-boot-starter/maven-metadata.xml" \
    | grep -oE "<version>[0-9]+\.[0-9]+\.[0-9]+</version>" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | sort -V | tail -1)"
[ -n "$ver" ] || { log "无法获取 erupt 最新已发布版本，中止"; exit 1; }
sed -i.bak -E "s|<erupt.version>[0-9.]+</erupt.version>|<erupt.version>$ver</erupt.version>|" "$proj/pom.xml" && rm -f "$proj/pom.xml.bak"
log "使用 erupt $ver 解析依赖（全新仓库，需在线下载，耗时数分钟）..."

# 不用 dependency:go-offline（会多抓 ~60MB 用不到的插件依赖），只跑真实构建收集所需产物
# shellcheck disable=SC2086
(cd "$proj" && "$MVN" $MVN_SETTINGS_ARG -q -Dmaven.repo.local="$repo" -DskipTests package)

find "$repo" -name "*.lastUpdated" -delete
find "$repo" -name "_remote.repositories" -delete

mkdir -p "$VENDOR_M2_DIR"
rm -f "$VENDOR_M2_DIR"/m2-repo.tar.gz.part-*
tar -czf - -C "$repo" . | split -b 90m - "$VENDOR_M2_DIR/m2-repo.tar.gz.part-"

log "种子已更新（erupt ${ver}）："
ls -lh "$VENDOR_M2_DIR"/m2-repo.tar.gz.part-* >&2
log "提示：已预置过的机器删除 ~/.erupt-skill/.m2-seeded 后重跑 setup-env.sh 可应用新种子"
