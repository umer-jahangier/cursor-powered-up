#!/usr/bin/env bash
# Backwards-compatibility wrapper — calls the unified install.sh.
# Previously this script ran the power-up phases separately.
# Now install.sh handles everything in one pass.
#
# Usage: ./scripts/install-cursor-powerup.sh [args...]
#   Same flags as install.sh are passed through.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/install.sh" "$@"
