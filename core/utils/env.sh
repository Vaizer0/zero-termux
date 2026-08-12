#!/data/data/com.termux/files/usr/bin/bash

CORE_VERSION="1.0.0"

# -------------------------
# User directories
# -------------------------

# configuration
CORE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/zero-termux"

# cache
CORE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zero-termux"

# user data
CORE_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/zero-termux-data"

# -------------------------
# Internal CLI paths
# -------------------------

CORE_BIN="$CORE_PATH/bin"
CORE_MODULES="$CORE_PATH/modules"
CORE_UTILS="$CORE_PATH/utils"
CORE_CLI="$CORE_PATH/cli"

# -------------------------
# Create directories
# -------------------------

mkdir -p \
  "$CORE_CONFIG" \
  "$CORE_CACHE" \
  "$CORE_DATA"
