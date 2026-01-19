#!/usr/bin/env bash

# dm: main entrypoint for DidYouMean utility
# Source hook logic to intercept command-not-found
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/src/hook.sh"

# TODO: implement interactive suggestion workflow