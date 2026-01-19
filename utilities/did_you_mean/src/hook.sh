#!/usr/bin/env bash

# Hook stub for dm: write sentinel when command not found
command_not_found_handle() {
  echo "DM_HOOK" > /tmp/dm_hook_called
}