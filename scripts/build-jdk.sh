#!/usr/bin/env bash
# 构建 vendor/jdk 下的内置最小 JDK 运行时（维护者使用，非 skill 运行时脚本）。
#
# 原理：下载带 jmods 的完整 JDK，用 jlink 交叉构建目标平台的最小运行时。
# 注意：Temurin 24+ 的发行包不再附带 jmods（JEP 493），需改用 Azul Zulu（GPLv2+CE）：
#   curl "https://api.azul.com/metadata/v1/zulu/packages/?java_version=25&java_package_type=jdk&javafx_bundled=false&release_status=ga&latest=true&os=macos&arch=aarch64&archive_type=tar.gz"
#   返回 JSON 中 download_url 即完整 JDK 包（含 jmods）。
# 模块清单覆盖 erupt 编译（jdk.compiler 供 Maven javac）与运行（Spring Boot + JPA +
# POI Excel 导出，java.desktop 提供 java.beans 与 java.awt，不可裁）。
# locale 只保留 en/zh，zip-9 压缩，产物约为完整 JDK 的一半。
#
# 用法: build-jdk.sh <完整JDK的jmods目录> <目标平台标识>
# 示例: build-jdk.sh /tmp/jdk-25.0.1+8/jmods mac-aarch64
#       （jlink 需用与 jmods 同版本、可在本机运行的 JDK 执行，见 JLINK 变量）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_JDK_DIR="$SCRIPT_DIR/../vendor/jdk"
JMODS_DIR="${1:?用法: build-jdk.sh <jmods目录> <平台标识如 mac-aarch64>}"
PLATFORM="${2:?用法: build-jdk.sh <jmods目录> <平台标识如 mac-aarch64>}"
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
echo "[build-jdk] 完成: $tarball ($(du -h "$tarball" | cut -f1 | tr -d ' '))" >&2
