#!/bin/sh

# Structural context boundary for standalone helpers.
#
# This source locates the project manifest from the helper's own versioned
# scripts directory.  It deliberately does not parse or source the manifest;
# manifest.sh owns that data-only grammar.

lane_standalone_context_manifest() {
  [ "$#" = 3 ] || return 2
  lane_standalone_context_helper=$1
  lane_standalone_context_selftest=$2
  lane_standalone_context_override=$3

  if [ -n "$lane_standalone_context_override" ] &&
    [ "$lane_standalone_context_selftest" != 1 ]; then
    echo 'BLOCKED: test-only manifest override is unavailable outside self-test mode' >&2
    return 1
  fi
  if [ "$lane_standalone_context_selftest" = 1 ] &&
    [ -n "$lane_standalone_context_override" ]; then
    case "$lane_standalone_context_override" in
      /*) ;;
      *) echo 'BLOCKED: test manifest path must be absolute' >&2; return 1 ;;
    esac
    [ -f "$lane_standalone_context_override" ] &&
      [ ! -L "$lane_standalone_context_override" ] &&
      [ -r "$lane_standalone_context_override" ] || {
        echo "BLOCKED: test manifest is not a readable regular file: $lane_standalone_context_override" >&2
        return 1
      }
    printf '%s\n' "$lane_standalone_context_override"
    return 0
  fi

  case "$lane_standalone_context_helper" in
    */*) ;;
    *) lane_standalone_context_helper=$(command -v -- "$lane_standalone_context_helper" 2>/dev/null || true) ;;
  esac
  [ -n "$lane_standalone_context_helper" ] || {
    echo 'BLOCKED: standalone helper location cannot be proven' >&2
    return 1
  }
  case "$lane_standalone_context_helper" in
    /*) ;;
    *) lane_standalone_context_helper=$(CDPATH= cd -- \
      "$(dirname -- "$lane_standalone_context_helper")" 2>/dev/null &&
      pwd -P)/$(basename -- "$lane_standalone_context_helper") || return 1 ;;
  esac
  [ -f "$lane_standalone_context_helper" ] &&
    [ ! -L "$lane_standalone_context_helper" ] || {
      echo 'BLOCKED: standalone helper location cannot be proven' >&2
      return 1
    }
  lane_standalone_context_script_dir=$(CDPATH= cd -- \
    "$(dirname -- "$lane_standalone_context_helper")" 2>/dev/null && pwd -P) || return 1
  [ "$(basename -- "$lane_standalone_context_script_dir")" = scripts ] || {
    echo 'BLOCKED: standalone helper is not in its versioned project scripts directory' >&2
    return 1
  }
  lane_standalone_context_project_dir=$(CDPATH= cd -- \
    "$lane_standalone_context_script_dir/.." 2>/dev/null && pwd -P) || return 1
  lane_standalone_context_manifest=$lane_standalone_context_project_dir/LANES.conf
  [ -f "$lane_standalone_context_manifest" ] &&
    [ ! -L "$lane_standalone_context_manifest" ] &&
    [ -r "$lane_standalone_context_manifest" ] || {
      echo "BLOCKED: authoritative project lane manifest is missing or unreadable: $lane_standalone_context_manifest" >&2
      return 1
    }
  printf '%s\n' "$lane_standalone_context_manifest"
}
