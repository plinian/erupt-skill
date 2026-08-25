#!/usr/bin/env bash
# Build the bundled minimal JDK runtimes under vendor/jdk (maintainer tool, not
# used at skill runtime).
#
# How it works: download a full JDK that ships jmods, then use jlink to
# cross-build a minimal runtime for the target platform.
# Note: Temurin 24+ release archives no longer include jmods (JEP 493); use
# Azul Zulu (GPLv2+CE) instead:
#   curl "https://api.azul.com/metadata/v1/zulu/packages/?java_version=25&java_package_type=jdk&javafx_bundled=false&release_status=ga&latest=true&os=macos&arch=aarch64&archive_type=tar.gz"
#   The download_url in the returned JSON is the full JDK archive (with jmods).
# The module list covers erupt compilation (jdk.compiler for Maven javac) and
# runtime (Spring Boot + JPA + POI Excel export; java.desktop provides
# java.beans and java.awt and must NOT be stripped).
# Locales limited to en/zh, zip-9 compression; output is about half the size of
# a full JDK.
#
# Usage: build-jdk.sh <jmods-dir-of-full-JDK> <target-platform-id>
# Example: build-jdk.sh /tmp/jdk-25.0.1+8/jmods mac-aarch64
#          (jlink must come from a JDK of the same version that runs on this
#          machine; see the JLINK variable)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_JDK_DIR="$SCRIPT_DIR/../vendor/jdk"
JMODS_DIR="${1:?Usage: build-jdk.sh <jmods-dir> <platform-id, e.g. mac-aarch64>}"
PLATFORM="${2:?Usage: build-jdk.sh <jmods-dir> <platform-id, e.g. mac-aarch64>}"
JDK_MAJOR=25
JLINK="${JLINK:-jlink}"

MODULES="java.base,java.sql,java.naming,java.management,java.instrument,\
java.net.http,java.security.jgss,java.scripting,java.xml,java.desktop,\
jdk.compiler,jdk.unsupported,jdk.crypto.cryptoki,jdk.zipfs,jdk.charsets,\
jdk.management,jdk.localedata"

out="$(mktemp -d)/jdk${JDK_MAJOR}-min"
"$JLINK" \
    --module-path "$JMODS_DIR" \
    --add-modules "$MODULES" \
    --include-locales=en,zh \
    --compress=zip-9 --no-header-files --no-man-pages --strip-debug \
    --output "$out"

mkdir -p "$VENDOR_JDK_DIR"
tarball="$VENDOR_JDK_DIR/jdk${JDK_MAJOR}-${PLATFORM}.tar.gz"
tar -czf "$tarball" -C "$(dirname "$out")" "jdk${JDK_MAJOR}-min"
rm -rf "$(dirname "$out")"
echo "[build-jdk] Done: $tarball ($(du -h "$tarball" | cut -f1 | tr -d ' '))" >&2
