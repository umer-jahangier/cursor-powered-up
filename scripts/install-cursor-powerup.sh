#!/usr/bin/env bash
# =============================================================================
# install-cursor-powerup.sh — Backward-compatible shim
# =============================================================================
# Calls the main installer with Cursor as target. Preserved for existing users.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/install.sh" --ide cursor --non-interactive "$@"
