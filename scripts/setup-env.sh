#!/usr/bin/env bash
# Prepare the erupt runtime environment: ensure JDK 17+ and Maven are available.
# JDK resolution order: system JDK 17+ -> bundled JDK (vendor/jdk, extracted to
# ~/.erupt-skill/runtime) -> online download.
# On success, writes ~/.erupt-skill/env.sh for run.sh to source.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_JDK_DIR="$SCRIPT_DIR/../vendor/jdk"
SKILL_HOME="${ERUPT_SKILL_HOME:-$HOME/.erupt-skill}"
RUNTIME_DIR="$SKILL_HOME/runtime"
ENV_FILE="$SKILL_HOME/env.sh"
MAVEN_VERSION="3.9.9"
# Downloaded JDK version: Eclipse Temurin (GPLv2 + Classpath Exception, no
# licensing concerns); override with ERUPT_SKILL_JDK
JDK_MAJOR="${ERUPT_SKILL_JDK:-25}"

log() { echo "[erupt-skill] $*" >&2; }

mkdir -p "$RUNTIME_DIR"

# ---------- Platform detection ----------
case "$(uname -s)" in
    Darwin) OS="mac" ;;
    Linux)  OS="linux" ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows" ;;  # Git Bash / MSYS2
    *) log "Unsupported OS: $(uname -s)"; exit 1 ;;
esac
case "$(uname -m)" in
    arm64|aarch64) ARCH="aarch64" ;;
    x86_64|amd64)  ARCH="x64" ;;
    *) log "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

download() { # download <url> <dest>
    log "Downloading: $1"
    curl -fSL --connect-timeout 15 --retry 2 -o "$2" "$1"
}

# ---------- JDK ----------
JAVA_HOME_RESOLVED=""

java_major() { "$1" -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/'; }
jdk_ok() { [ -x "$1/bin/java" ] || [ -x "$1/bin/java.exe" ]; }  # java.exe on Windows

if command -v java >/dev/null 2>&1; then
    ver="$(java_major java || echo 0)"
    if [ "${ver:-0}" -ge 17 ] 2>/dev/null; then
        log "Using system JDK $ver"
        JAVA_HOME_RESOLVED="${JAVA_HOME:-}"
    fi
fi

if [ -z "$JAVA_HOME_RESOLVED" ] && ! { command -v java >/dev/null 2>&1 && [ "$(java_major java || echo 0)" -ge 17 ] 2>/dev/null; }; then
    bundled_tar="$VENDOR_JDK_DIR/jdk${JDK_MAJOR}-${OS}-${ARCH}.tar.gz"
    existing="$(find "$RUNTIME_DIR" -maxdepth 1 -type d -name "jdk-${JDK_MAJOR}*" 2>/dev/null | head -1 || true)"
    if jdk_ok "$RUNTIME_DIR/jdk${JDK_MAJOR}-min"; then
        JAVA_HOME_RESOLVED="$RUNTIME_DIR/jdk${JDK_MAJOR}-min"
        log "Using cached bundled JDK: $JAVA_HOME_RESOLVED"
    elif [ -f "$bundled_tar" ]; then
        log "Extracting bundled JDK ${JDK_MAJOR} (no download needed)..."
        tar -xzf "$bundled_tar" -C "$RUNTIME_DIR"
        jdk_ok "$RUNTIME_DIR/jdk${JDK_MAJOR}-min" || { log "Failed to extract bundled JDK"; exit 1; }
        JAVA_HOME_RESOLVED="$RUNTIME_DIR/jdk${JDK_MAJOR}-min"
        log "Bundled JDK ready: $JAVA_HOME_RESOLVED"
    elif [ -n "$existing" ]; then
        JAVA_HOME_RESOLVED="$existing"
        [ "$OS" = "mac" ] && JAVA_HOME_RESOLVED="$existing/Contents/Home"
        log "Using cached JDK: $JAVA_HOME_RESOLVED"
    else
        pkg_ext="tar.gz"; [ "$OS" = "windows" ] && pkg_ext="zip"
        tarball="$RUNTIME_DIR/jdk.$pkg_ext"
        # Primary: official Adoptium API; fallback: Tsinghua mirror (faster in China)
        primary="https://api.adoptium.net/v3/binary/latest/${JDK_MAJOR}/ga/${OS}/${ARCH}/jdk/hotspot/normal/eclipse"
        if ! download "$primary" "$tarball"; then
            log "Official source failed, switching to Tsinghua mirror..."
            listing="https://mirrors.tuna.tsinghua.edu.cn/Adoptium/${JDK_MAJOR}/jdk/${ARCH}/${OS}/"
            file="$(curl -fsSL "$listing" | grep -oE "OpenJDK${JDK_MAJOR}U-jdk_[^\"]*\.${pkg_ext}" | sort -u | tail -1)"
            [ -n "$file" ] || { log "Could not resolve JDK filename from mirror"; exit 1; }
            download "${listing}${file}" "$tarball"
        fi
        log "Extracting JDK..."
        if [ "$pkg_ext" = "zip" ]; then
            unzip -q "$tarball" -d "$RUNTIME_DIR" 2>/dev/null || tar -xf "$tarball" -C "$RUNTIME_DIR"
        else
            tar -xzf "$tarball" -C "$RUNTIME_DIR"
        fi
        rm -f "$tarball"
        jdkdir="$(find "$RUNTIME_DIR" -maxdepth 1 -type d -name "jdk-${JDK_MAJOR}*" | head -1)"
        [ -n "$jdkdir" ] || { log "Failed to extract JDK"; exit 1; }
        JAVA_HOME_RESOLVED="$jdkdir"
        [ "$OS" = "mac" ] && JAVA_HOME_RESOLVED="$jdkdir/Contents/Home"
        log "JDK installed: $JAVA_HOME_RESOLVED"
    fi
fi

# ---------- Maven ----------
MVN_CMD=""
if command -v mvn >/dev/null 2>&1; then
    MVN_CMD="mvn"
    log "Using system Maven"
else
    mvn_home="$RUNTIME_DIR/apache-maven-$MAVEN_VERSION"
    if [ ! -x "$mvn_home/bin/mvn" ]; then
        tarball="$RUNTIME_DIR/maven.tar.gz"
        # Primary: Tsinghua mirror (fast); fallback: Apache archive (keeps all versions)
        primary="https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
        fallback="https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
        download "$primary" "$tarball" || download "$fallback" "$tarball"
        log "Extracting Maven..."
        tar -xzf "$tarball" -C "$RUNTIME_DIR"
        rm -f "$tarball"
        log "Maven installed: $mvn_home"
    else
        log "Using cached Maven: $mvn_home"
    fi
    MVN_CMD="$mvn_home/bin/mvn"
fi

# ---------- Seed Maven dependencies (bundled with skill, first build needs no download) ----------
VENDOR_M2_DIR="$SCRIPT_DIR/../vendor/m2"
seed_marker="$SKILL_HOME/.m2-seeded"
if [ ! -f "$seed_marker" ] && ls "$VENDOR_M2_DIR"/m2-repo.tar.gz.part-* >/dev/null 2>&1; then
    m2_repo="$HOME/.m2/repository"
    mkdir -p "$m2_repo"
    log "Seeding Maven dependencies into $m2_repo ..."
    cat "$VENDOR_M2_DIR"/m2-repo.tar.gz.part-* | tar -xzf - -C "$m2_repo"
    touch "$seed_marker"
    log "Seeding done (reused by later builds; delete $seed_marker to re-seed)"
fi

# ---------- Maven mirror (Aliyun, speeds up dependency downloads; disable with ERUPT_SKILL_NO_MIRROR=1) ----------
MVN_SETTINGS_ARG=""
if [ "${ERUPT_SKILL_NO_MIRROR:-}" != "1" ]; then
    settings="$SKILL_HOME/settings.xml"
    if [ ! -f "$settings" ]; then
        cat > "$settings" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0">
    <mirrors>
        <mirror>
            <id>aliyun</id>
            <mirrorOf>central</mirrorOf>
            <name>Aliyun Central Mirror</name>
            <url>https://maven.aliyun.com/repository/public</url>
        </mirror>
    </mirrors>
</settings>
EOF
    fi
    MVN_SETTINGS_ARG="-s $settings"
fi

# ---------- Wait for background warmup (avoid two mvn processes writing ~/.m2 concurrently) ----------
if [ "${ERUPT_SKILL_WARMUP:-}" != "1" ] && [ -f "$SKILL_HOME/warmup.lock" ]; then
    warmup_pid="$(cat "$SKILL_HOME/warmup.lock" 2>/dev/null || true)"
    if [ -n "$warmup_pid" ] && kill -0 "$warmup_pid" 2>/dev/null; then
        log "Dependency warmup in progress, waiting for it to finish (avoids concurrent writes to the Maven local repository)..."
        while kill -0 "$warmup_pid" 2>/dev/null; do sleep 3; done
        log "Warmup finished, continuing"
    else
        rm -f "$SKILL_HOME/warmup.lock"  # stale lock left by a dead process
    fi
fi

# ---------- Generate env.sh ----------
{
    if [ -n "$JAVA_HOME_RESOLVED" ]; then
        echo "export JAVA_HOME=\"$JAVA_HOME_RESOLVED\""
        echo "export PATH=\"$JAVA_HOME_RESOLVED/bin:\$PATH\""
    fi
    echo "export MVN=\"$MVN_CMD\""
    echo "export MVN_SETTINGS_ARG=\"$MVN_SETTINGS_ARG\""
} > "$ENV_FILE"

log "Environment ready -> $ENV_FILE"
