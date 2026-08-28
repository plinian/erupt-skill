#!/usr/bin/env bash
# Dependency warmup: after the environment is ready, run a real build of the
# template project so Spring Boot / erupt dependencies are pre-downloaded into
# ~/.m2, making the user's first project build nearly download-free.
# Designed to run in the background (SKILL.md step 0); failure never blocks the
# main flow (run.sh falls back to downloading on demand).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../template"
SKILL_HOME="${ERUPT_SKILL_HOME:-$HOME/.erupt-skill}"
LOCK_FILE="$SKILL_HOME/warmup.lock"

log() { echo "[erupt-warmup] $*" >&2; }

# Prepare environment (JDK/Maven/m2 seed); ERUPT_SKILL_WARMUP=1 tells setup-env
# to skip its "wait for warmup" logic
ERUPT_SKILL_WARMUP=1 bash "$SCRIPT_DIR/setup-env.sh" || exit 1
# shellcheck disable=SC1091
source "$SKILL_HOME/env.sh"

# Resolve the erupt version the generated project will actually use (latest
# released, same query as SKILL.md step 4), so warmup pre-downloads the matching
# artifacts instead of the template's fallback version. Fall back to the template
# default if the query fails, and never go below it (mirrors step 4's "higher of").
template_ver="$(grep -oE '<erupt.version>[0-9.]+</erupt.version>' "$TEMPLATE_DIR/pom.xml" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
latest_ver="$(curl -s --max-time 10 "https://maven.aliyun.com/repository/public/xyz/erupt/erupt-spring-boot-starter/maven-metadata.xml" \
    | grep -oE '<version>[0-9]+\.[0-9]+\.[0-9]+</version>' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1)"
erupt_ver="$(printf '%s\n%s\n' "$template_ver" "${latest_ver:-$template_ver}" | sort -V | tail -1)"

# Key the marker on template pom content + resolved erupt version: a template
# change or a new erupt release both trigger a fresh warmup automatically
pom_sum="$(cksum "$TEMPLATE_DIR/pom.xml" | awk '{print $1}')"
marker="$SKILL_HOME/.warmed-${pom_sum}-${erupt_ver}"
if [ -f "$marker" ]; then
    log "Dependencies already warmed (erupt $erupt_ver), skipping"
    exit 0
fi

echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

work="$SKILL_HOME/warmup-app"
rm -rf "$work"
cp -R "$TEMPLATE_DIR" "$work"
grep -rl "__ARTIFACT_ID__" "$work" 2>/dev/null | while IFS= read -r f; do
    sed -e 's/__ARTIFACT_ID__/erupt-warmup/g' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
# Pin the warmup pom to the resolved erupt version so the cached jars match
sed -i.bak -E "s|<erupt.version>[0-9.]+</erupt.version>|<erupt.version>$erupt_ver</erupt.version>|" "$work/pom.xml" && rm -f "$work/pom.xml.bak"

log "Warming up Maven dependencies for erupt $erupt_ver (runs in background, does not block requirement analysis or code generation)..."
cd "$work"
# shellcheck disable=SC2086
if "$MVN" $MVN_SETTINGS_ARG -q -DskipTests package; then
    touch "$marker"
    log "Warmup done, first build will reuse the local repository"
else
    log "Warmup incomplete (network or version issue), first build will fetch missing dependencies"
fi
rm -rf "$work"
