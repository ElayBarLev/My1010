#!/bin/bash
# Installs Flutter in Claude Code on the web sessions so analyze/test work.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_VERSION="3.47.5"
FLUTTER_HOME="$HOME/flutter"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  curl -sSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "$HOME"
  git config --global --add safe.directory "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$FLUTTER_HOME/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

flutter config --no-analytics >/dev/null 2>&1 || true
cd "$CLAUDE_PROJECT_DIR"
flutter pub get
