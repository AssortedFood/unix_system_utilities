#!/usr/bin/env bash

# install: set up hook for DidYouMean utility
# Source hook logic to intercept command-not-found
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/src/hook.sh"

# TODO: implement installation of hook into shell initialization