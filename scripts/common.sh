#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/.tools"
JDKS_DIR="$ROOT_DIR/.jdks"
SERVER_DIR="$ROOT_DIR/server"
GRADLE_VERSION="${GRADLE_VERSION:-9.5.1}"
PAPER_JAR="${PAPER_JAR:-}"

mkdir -p "$TOOLS_DIR" "$JDKS_DIR"

find_paper_jar() {
    if [[ -n "$PAPER_JAR" ]]; then
        printf '%s\n' "$PAPER_JAR"
        return
    fi

    local jar
    jar="$(find "$ROOT_DIR" -maxdepth 1 -name 'paper-*.jar' -type f | sort | tail -n 1)"
    if [[ -z "$jar" ]]; then
        echo "No paper-*.jar found in $ROOT_DIR" >&2
        exit 1
    fi
    printf '%s\n' "$jar"
}

jdk_home_from_project() {
    if [[ -x "$JDKS_DIR/current/Contents/Home/bin/java" ]]; then
        printf '%s\n' "$JDKS_DIR/current/Contents/Home"
    elif [[ -x "$JDKS_DIR/current/bin/java" ]]; then
        printf '%s\n' "$JDKS_DIR/current"
    fi
}

java_major() {
    local java_bin="$1"
    "$java_bin" -XshowSettings:properties -version 2>&1 \
        | awk -F '= ' '/java.specification.version/ { print $2; exit }' \
        | awk -F '.' '{ print $NF }'
}

find_gradle_launcher_home() {
    if [[ -n "${GRADLE_LAUNCHER_JAVA_HOME:-}" && -x "$GRADLE_LAUNCHER_JAVA_HOME/bin/java" ]]; then
        printf '%s\n' "$GRADLE_LAUNCHER_JAVA_HOME"
        return
    fi

    if command -v /usr/libexec/java_home >/dev/null 2>&1; then
        local home
        home="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
        if [[ -n "$home" && -x "$home/bin/java" && "$(java_major "$home/bin/java")" -ge 17 ]]; then
            printf '%s\n' "$home"
            return
        fi
    fi

    if command -v java >/dev/null 2>&1; then
        local java_bin java_home
        java_bin="$(command -v java)"
        java_home="$(cd "$(dirname "$java_bin")/.." && pwd)"
        if [[ -x "$java_home/bin/java" && "$(java_major "$java_home/bin/java")" -ge 17 ]]; then
            printf '%s\n' "$java_home"
            return
        fi
    fi

    printf '%s\n' "$JAVA_HOME"
}

ensure_jdk25() {
    local project_home
    project_home="$(jdk_home_from_project || true)"
    if [[ -n "$project_home" && "$(java_major "$project_home/bin/java")" -ge 25 ]]; then
        export JAVA_HOME="$project_home"
        export PATH="$JAVA_HOME/bin:$PATH"
        return
    fi

    if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" && "$(java_major "$JAVA_HOME/bin/java")" -ge 25 ]]; then
        export PATH="$JAVA_HOME/bin:$PATH"
        return
    fi

    if command -v /usr/libexec/java_home >/dev/null 2>&1; then
        local system_home
        system_home="$(/usr/libexec/java_home -v 25 2>/dev/null || true)"
        if [[ -n "$system_home" && -x "$system_home/bin/java" && "$(java_major "$system_home/bin/java")" -ge 25 ]]; then
            export JAVA_HOME="$system_home"
            export PATH="$JAVA_HOME/bin:$PATH"
            return
        fi
    fi

    local os arch url archive extract_dir extracted
    os="$(uname -s)"
    arch="$(uname -m)"

    case "$os:$arch" in
        Darwin:arm64)
            url="https://api.adoptium.net/v3/binary/latest/25/ga/mac/aarch64/jdk/hotspot/normal/eclipse"
            archive="$TOOLS_DIR/jdk25-mac-aarch64.tar.gz"
            ;;
        Darwin:x86_64)
            url="https://api.adoptium.net/v3/binary/latest/25/ga/mac/x64/jdk/hotspot/normal/eclipse"
            archive="$TOOLS_DIR/jdk25-mac-x64.tar.gz"
            ;;
        Linux:arm64|Linux:aarch64)
            url="https://api.adoptium.net/v3/binary/latest/25/ga/linux/aarch64/jdk/hotspot/normal/eclipse"
            archive="$TOOLS_DIR/jdk25-linux-aarch64.tar.gz"
            ;;
        Linux:x86_64)
            url="https://api.adoptium.net/v3/binary/latest/25/ga/linux/x64/jdk/hotspot/normal/eclipse"
            archive="$TOOLS_DIR/jdk25-linux-x64.tar.gz"
            ;;
        *)
            echo "Unsupported platform for automatic JDK download: $os $arch" >&2
            echo "Install JDK 25+, or set JAVA_HOME to a JDK 25+ installation." >&2
            exit 1
            ;;
    esac

    extract_dir="$JDKS_DIR/download"
    rm -rf "$extract_dir"
    mkdir -p "$extract_dir"

    echo "Downloading JDK 25..."
    curl -fL "$url" -o "$archive"
    tar -xzf "$archive" -C "$extract_dir"

    extracted="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    if [[ -z "$extracted" ]]; then
        echo "JDK archive did not contain a top-level directory." >&2
        exit 1
    fi

    rm -rf "$JDKS_DIR/current"
    mv "$extracted" "$JDKS_DIR/current"
    rm -rf "$extract_dir"

    project_home="$(jdk_home_from_project || true)"
    export JAVA_HOME="$project_home"
    export PATH="$JAVA_HOME/bin:$PATH"
}

ensure_gradle() {
    local gradle_home="$TOOLS_DIR/gradle-$GRADLE_VERSION"
    if [[ ! -x "$gradle_home/bin/gradle" ]]; then
        local zip="$TOOLS_DIR/gradle-$GRADLE_VERSION-bin.zip"
        echo "Downloading Gradle $GRADLE_VERSION..."
        curl -fL "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip" -o "$zip"
        rm -rf "$gradle_home"
        unzip -q "$zip" -d "$TOOLS_DIR"
    fi
    export GRADLE_HOME="$gradle_home"
    export PATH="$GRADLE_HOME/bin:$PATH"
}

setup_server_dir() {
    local jar
    jar="$(find_paper_jar)"

    mkdir -p "$SERVER_DIR/plugins"
    ln -sf "$jar" "$SERVER_DIR/paper.jar"

    if [[ ! -f "$SERVER_DIR/eula.txt" ]]; then
        cat > "$SERVER_DIR/eula.txt" <<'EULA'
# You must agree to the Minecraft EULA to run this local development server:
# https://aka.ms/MinecraftEULA
eula=true
EULA
    fi

    if [[ ! -f "$SERVER_DIR/server.properties" ]]; then
        cat > "$SERVER_DIR/server.properties" <<'PROPERTIES'
motd=Learn Paper Dev Server
server-port=25565
online-mode=true
gamemode=creative
difficulty=easy
spawn-protection=0
view-distance=8
simulation-distance=4
enable-command-block=true
enforce-secure-profile=true
PROPERTIES
    fi
}
