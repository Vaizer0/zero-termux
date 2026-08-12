#!/data/data/com.termux/files/usr/bin/bash

# evitar redeclaraciones
[[ -n "${__ZERO_BOOTSTRAP_LOADED:-}" ]] && return
__ZERO_BOOTSTRAP_LOADED=1

# registro de imports
declare -A __ZERO_IMPORTED

import() {
	local path="${1//@/$ZERO_PATH}.sh"

	if [[ -n "${__ZERO_IMPORTED[$path]}" ]]; then
		return
	fi

	if [[ ! -f "$path" ]]; then
		echo "zero: import error: $path not found" >&2
		exit 1
	fi

	__ZERO_IMPORTED[$path]=1
	source "$path"
}
