#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

ensure_jdk25
ensure_gradle
setup_server_dir

echo "JAVA_HOME=$JAVA_HOME"
"$JAVA_HOME/bin/java" -version
echo "GRADLE_HOME=$GRADLE_HOME"
"$GRADLE_HOME/bin/gradle" --version
