#!/usr/bin/env bash
# 准备 erupt 项目运行环境：确保 JDK 17+ 与 Maven 可用。
# JDK 顺序：系统 JDK 17+ → skill 内置 JDK（vendor/jdk，解压到 ~/.erupt-skill/runtime）→ 在线下载。
# 成功后生成 ~/.erupt-skill/env.sh，供 run.sh source。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_JDK_DIR="$SCRIPT_DIR/../vendor/jdk"
SKILL_HOME="${ERUPT_SKILL_HOME:-$HOME/.erupt-skill}"
RUNTIME_DIR="$SKILL_HOME/runtime"
ENV_FILE="$SKILL_HOME/env.sh"
MAVEN_VERSION="3.9.9"
# 下载的 JDK 版本：Eclipse Temurin（GPLv2 + Classpath Exception，无授权问题），可用 ERUPT_SKILL_JDK 覆盖
JDK_MAJOR="${ERUPT_SKILL_JDK:-25}"

log() { echo "[erupt-skill] $*" >&2; }

mkdir -p "$RUNTIME_DIR"

# ---------- 平台探测 ----------
case "$(uname -s)" in
    Darwin) OS="mac" ;;
    Linux)  OS="linux" ;;
    *) log "不支持的系统: $(uname -s)（Windows 请参考 SKILL.md 手动安装 JDK17 与 Maven）"; exit 1 ;;
esac
case "$(uname -m)" in
    arm64|aarch64) ARCH="aarch64" ;;
    x86_64|amd64)  ARCH="x64" ;;
    *) log "不支持的架构: $(uname -m)"; exit 1 ;;
esac

download() { # download <url> <dest>
    log "下载: $1"
    curl -fSL --connect-timeout 15 --retry 2 -o "$2" "$1"
}

# ---------- JDK ----------
JAVA_HOME_RESOLVED=""

java_major() { "$1" -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/'; }

if command -v java >/dev/null 2>&1; then
    ver="$(java_major java || echo 0)"
    if [ "${ver:-0}" -ge 17 ] 2>/dev/null; then
        log "使用系统 JDK $ver"
        JAVA_HOME_RESOLVED="${JAVA_HOME:-}"
    fi
fi

if [ -z "$JAVA_HOME_RESOLVED" ] && ! { command -v java >/dev/null 2>&1 && [ "$(java_major java || echo 0)" -ge 17 ] 2>/dev/null; }; then
    bundled_tar="$VENDOR_JDK_DIR/jdk${JDK_MAJOR}-${OS}-${ARCH}.tar.gz"
    existing="$(find "$RUNTIME_DIR" -maxdepth 1 -type d -name "jdk-${JDK_MAJOR}*" 2>/dev/null | head -1 || true)"
    if [ -x "$RUNTIME_DIR/jdk${JDK_MAJOR}-min/bin/java" ]; then
        JAVA_HOME_RESOLVED="$RUNTIME_DIR/jdk${JDK_MAJOR}-min"
        log "使用已缓存内置 JDK: $JAVA_HOME_RESOLVED"
    elif [ -f "$bundled_tar" ]; then
        log "解压 skill 内置 JDK ${JDK_MAJOR}（无需下载）..."
        tar -xzf "$bundled_tar" -C "$RUNTIME_DIR"
        [ -x "$RUNTIME_DIR/jdk${JDK_MAJOR}-min/bin/java" ] || { log "内置 JDK 解压失败"; exit 1; }
        JAVA_HOME_RESOLVED="$RUNTIME_DIR/jdk${JDK_MAJOR}-min"
        log "内置 JDK 就绪: $JAVA_HOME_RESOLVED"
    elif [ -n "$existing" ]; then
        JAVA_HOME_RESOLVED="$existing"
        [ "$OS" = "mac" ] && JAVA_HOME_RESOLVED="$existing/Contents/Home"
        log "使用已缓存 JDK: $JAVA_HOME_RESOLVED"
    else
        tarball="$RUNTIME_DIR/jdk.tar.gz"
        # 主源: Adoptium 官方 API；备源: 清华镜像（国内加速）
        primary="https://api.adoptium.net/v3/binary/latest/${JDK_MAJOR}/ga/${OS}/${ARCH}/jdk/hotspot/normal/eclipse"
        if ! download "$primary" "$tarball"; then
            log "官方源失败，切换清华镜像..."
            listing="https://mirrors.tuna.tsinghua.edu.cn/Adoptium/${JDK_MAJOR}/jdk/${ARCH}/${OS}/"
            file="$(curl -fsSL "$listing" | grep -oE "OpenJDK${JDK_MAJOR}U-jdk_[^\"]*\.tar\.gz" | sort -u | tail -1)"
            [ -n "$file" ] || { log "无法从镜像获取 JDK 文件名"; exit 1; }
            download "${listing}${file}" "$tarball"
        fi
        log "解压 JDK..."
        tar -xzf "$tarball" -C "$RUNTIME_DIR"
        rm -f "$tarball"
        jdkdir="$(find "$RUNTIME_DIR" -maxdepth 1 -type d -name "jdk-${JDK_MAJOR}*" | head -1)"
        [ -n "$jdkdir" ] || { log "JDK 解压失败"; exit 1; }
        JAVA_HOME_RESOLVED="$jdkdir"
        [ "$OS" = "mac" ] && JAVA_HOME_RESOLVED="$jdkdir/Contents/Home"
        log "JDK 安装完成: $JAVA_HOME_RESOLVED"
    fi
fi

# ---------- Maven ----------
MVN_CMD=""
if command -v mvn >/dev/null 2>&1; then
    MVN_CMD="mvn"
    log "使用系统 Maven"
else
    mvn_home="$RUNTIME_DIR/apache-maven-$MAVEN_VERSION"
    if [ ! -x "$mvn_home/bin/mvn" ]; then
        tarball="$RUNTIME_DIR/maven.tar.gz"
        # 主源: 清华镜像（快）；备源: Apache 归档（永久保留所有版本）
        primary="https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
        fallback="https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
        download "$primary" "$tarball" || download "$fallback" "$tarball"
        log "解压 Maven..."
        tar -xzf "$tarball" -C "$RUNTIME_DIR"
        rm -f "$tarball"
        log "Maven 安装完成: $mvn_home"
    else
        log "使用已缓存 Maven: $mvn_home"
    fi
    MVN_CMD="$mvn_home/bin/mvn"
fi

# ---------- Maven 镜像（阿里云，加速依赖下载，可用 ERUPT_SKILL_NO_MIRROR=1 关闭） ----------
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

# ---------- 生成 env.sh ----------
{
    if [ -n "$JAVA_HOME_RESOLVED" ]; then
        echo "export JAVA_HOME=\"$JAVA_HOME_RESOLVED\""
        echo "export PATH=\"$JAVA_HOME_RESOLVED/bin:\$PATH\""
    fi
    echo "export MVN=\"$MVN_CMD\""
    echo "export MVN_SETTINGS_ARG=\"$MVN_SETTINGS_ARG\""
} > "$ENV_FILE"

log "环境就绪 → $ENV_FILE"
