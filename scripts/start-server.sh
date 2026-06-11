#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

ensure_jdk25
setup_server_dir

MC_XMS="${MC_XMS:-1G}"
MC_XMX="${MC_XMX:-2G}"

cd "$SERVER_DIR"
exec "$JAVA_HOME/bin/java" -Xms"$MC_XMS" -Xmx"$MC_XMX" -jar paper.jar --nogui
