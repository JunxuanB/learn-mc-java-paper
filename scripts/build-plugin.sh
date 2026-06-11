#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

ensure_jdk25
TOOLCHAIN_JAVA_HOME="$JAVA_HOME"
ensure_gradle
setup_server_dir

cd "$ROOT_DIR"
GRADLE_LAUNCHER_HOME="$(find_gradle_launcher_home)"
JAVA_HOME="$GRADLE_LAUNCHER_HOME" "$GRADLE_HOME/bin/gradle" \
    -Dorg.gradle.java.installations.paths="$TOOLCHAIN_JAVA_HOME" \
    -Dorg.gradle.java.installations.auto-download=false \
    --no-daemon build "$@"

plugin_jar="$(find "$ROOT_DIR/build/libs" -maxdepth 1 -name 'LearnPaperHello-*.jar' -type f | sort | tail -n 1)"
if [[ -z "$plugin_jar" ]]; then
    echo "Could not find built plugin jar in build/libs." >&2
    exit 1
fi

cp "$plugin_jar" "$SERVER_DIR/plugins/LearnPaperHello.jar"
echo "Deployed $plugin_jar -> $SERVER_DIR/plugins/LearnPaperHello.jar"
