#!/usr/bin/env bash
# Regenerate the vendor/m2 dependency seed. Run once after template
# dependencies or the erupt version change:
#   bash scripts/build-m2-seed.sh
# Resolves all dependencies of the template pom (with the latest released erupt
# version) into a clean repository, then packs split archives back into vendor/m2/.
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
[ -n "$ver" ] || { log "Could not determine the latest released erupt version, aborting"; exit 1; }
sed -i.bak -E "s|<erupt.version>[0-9.]+</erupt.version>|<erupt.version>$ver</erupt.version>|" "$proj/pom.xml" && rm -f "$proj/pom.xml.bak"
log "Resolving dependencies with erupt $ver (clean repository, downloads online, takes a few minutes)..."

# Skip dependency:go-offline (it pulls ~60MB of unused plugin deps); run a real
# build to collect only what is actually needed
# shellcheck disable=SC2086
(cd "$proj" && "$MVN" $MVN_SETTINGS_ARG -q -Dmaven.repo.local="$repo" -DskipTests package)

find "$repo" -name "*.lastUpdated" -delete
find "$repo" -name "_remote.repositories" -delete

mkdir -p "$VENDOR_M2_DIR"
rm -f "$VENDOR_M2_DIR"/m2-repo.tar.gz.part-*
tar -czf - -C "$repo" . | split -b 90m - "$VENDOR_M2_DIR/m2-repo.tar.gz.part-"

log "Seed updated (erupt ${ver}):"
ls -lh "$VENDOR_M2_DIR"/m2-repo.tar.gz.part-* >&2
log "Tip: on machines already seeded, delete ~/.erupt-skill/.m2-seeded and rerun setup-env.sh to apply the new seed"
