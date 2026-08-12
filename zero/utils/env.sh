#!/data/data/com.termux/files/usr/bin/bash

ZERO_VERSION="1.0.0"

# -------------------------
# User directories
# -------------------------

# configuration
ZERO_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/zero-termux"

# cache
ZERO_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zero-termux"

# user data
ZERO_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/zero-termux-data"

# -------------------------
# Internal CLI paths
# -------------------------

ZERO_BIN="$ZERO_PATH/bin"
ZERO_MODULES="$ZERO_PATH/modules"
ZERO_UTILS="$ZERO_PATH/utils"
ZERO_CLI="$ZERO_PATH/cli"

# -------------------------
# Create directories
# -------------------------

mkdir -p \
  "$ZERO_CONFIG" \
  "$ZERO_CACHE" \
  "$ZERO_DATA"
