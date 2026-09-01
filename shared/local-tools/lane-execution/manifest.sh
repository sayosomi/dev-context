#!/bin/sh

# Data-only lane topology manifest API.
#
# The manifest is a deliberately small configuration format, not shell. This
# file parses it with awk and never sources, evaluates, or executes its values.
# All lane enumeration preserves the manifest's declaration order, which is
# explicit and deterministic.

lane_manifest__query() {
  [ "$#" -ge 2 ] || return 2
  lane_manifest_operation=$1
  lane_manifest_manifest=$2
  lane_manifest_query=${3-}

  case "$lane_manifest_operation" in
    validate|all|role-list|lane-valid|lane-role|lane-path|lane-idle|repository|default-branch)
      ;;
    *)
      return 2
      ;;
  esac
  [ -f "$lane_manifest_manifest" ] && [ -r "$lane_manifest_manifest" ] || {
    echo "LANE MANIFEST BLOCKED: manifest is not a readable regular file: $lane_manifest_manifest" >&2
    return 1
  }

  LC_ALL=C awk \
    -v operation="$lane_manifest_operation" \
    -v query="$lane_manifest_query" '
function blocked(message) {
  if (!invalid) {
    print "LANE MANIFEST BLOCKED: " message > "/dev/stderr"
  }
  invalid = 1
}
function valid_repository(value) {
  return value ~ /^[A-Za-z0-9._-]+\/[A-Za-z0-9._-]+$/
}
function valid_default_branch(value) {
  if (value !~ /^[A-Za-z0-9][A-Za-z0-9._\/-]*$/) {
    return 0
  }
  if (value ~ /\/\// || value ~ /\/\.\.?($|\/)/ || value ~ /\.lock$/) {
    return 0
  }
  return 1
}
function valid_path(value) {
  if (value !~ /^\// || value == "/") {
    return 0
  }
  if (value ~ /[[:space:]]/ || value ~ /\/\// || value ~ /\/\.\.?($|\/)/) {
    return 0
  }
  return 1
}
function valid_role(value) {
  return value == "implementation" || value == "human-test"
}
function valid_idle(value) {
  return value == "branch" || value == "detached"
}
function emit_lanes(role,     i, name) {
  for (i = 1; i <= lane_count; i++) {
    name = lane_order[i]
    if (role == "" || lane_field[name SUBSEP "role"] == role) {
      print name
    }
  }
}
BEGIN {
  invalid = 0
  current_lane = ""
  lane_count = 0
  if (operation == "role-list" && query != "implementation" && query != "human-test") {
    blocked("invalid role filter: " query)
  }
}
{
  line = $0
  if (line ~ /^[[:space:]]*$/ || line ~ /^[[:space:]]*#/) {
    next
  }

  if (line ~ /^\[lane [A-Za-z0-9][A-Za-z0-9._-]*\]$/) {
    if (!has_version || !has_repository || !has_default_branch) {
      blocked("lane section appears before the complete header")
    }
    current_lane = substr(line, 7, length(line) - 7)
    if (current_lane in lane_present) {
      blocked("duplicate lane name: " current_lane)
    } else {
      lane_present[current_lane] = 1
      lane_order[++lane_count] = current_lane
    }
    next
  }

  if (line !~ /^[a-z_][a-z0-9_]*=[^[:space:]]+$/) {
    blocked("malformed section or key: " line)
    next
  }

  separator = index(line, "=")
  key = substr(line, 1, separator - 1)
  value = substr(line, separator + 1)
  if (current_lane == "") {
    if (key != "version" && key != "repository" && key != "default_branch") {
      blocked("malformed header key: " key)
      next
    }
    if (header_present[key]) {
      blocked("duplicate header key: " key)
      next
    }
    header_present[key] = 1
    if (key == "version") {
      has_version = 1
      if (value != "1") {
        blocked("unsupported version: " value)
      }
    } else if (key == "repository") {
      has_repository = 1
      repository = value
      if (!valid_repository(value)) {
        blocked("invalid repository identity: " value)
      }
    } else {
      has_default_branch = 1
      default_branch = value
      if (!valid_default_branch(value)) {
        blocked("invalid default branch: " value)
      }
    }
    next
  }

  if (key != "role" && key != "path" && key != "idle") {
    blocked("malformed lane key: " key)
    next
  }
  field_key = current_lane SUBSEP key
  if (field_key in lane_field) {
    blocked("duplicate lane key: " current_lane "." key)
    next
  }
  lane_field[field_key] = value
}
END {
  if (!has_version) {
    blocked("missing required key: version")
  }
  if (!has_repository) {
    blocked("missing required key: repository")
  }
  if (!has_default_branch) {
    blocked("missing required key: default_branch")
  }
  if (lane_count == 0) {
    blocked("manifest declares no lanes")
  }

  for (i = 1; i <= lane_count; i++) {
    name = lane_order[i]
    for (j = 1; j <= 3; j++) {
      if (j == 1) {
        field = "role"
      } else if (j == 2) {
        field = "path"
      } else {
        field = "idle"
      }
      if (!(name SUBSEP field in lane_field)) {
        blocked("missing required lane key: " name "." field)
      }
    }
    if ((name SUBSEP "role") in lane_field && !valid_role(lane_field[name SUBSEP "role"])) {
      blocked("invalid role for lane " name ": " lane_field[name SUBSEP "role"])
    }
    if ((name SUBSEP "path") in lane_field && !valid_path(lane_field[name SUBSEP "path"])) {
      blocked("invalid checkout path for lane " name ": " lane_field[name SUBSEP "path"])
    }
    if ((name SUBSEP "idle") in lane_field && !valid_idle(lane_field[name SUBSEP "idle"])) {
      blocked("invalid idle policy for lane " name ": " lane_field[name SUBSEP "idle"])
    }
  }

  if (invalid) {
    exit 1
  }
  if (operation == "validate") {
    exit 0
  }
  if (operation == "all") {
    emit_lanes("")
    exit 0
  }
  if (operation == "role-list") {
    emit_lanes(query)
    exit 0
  }
  if (operation == "repository") {
    print repository
    exit 0
  }
  if (operation == "default-branch") {
    print default_branch
    exit 0
  }
  if (!(query in lane_present)) {
    blocked("unknown lane name: " query)
    exit 1
  }
  if (operation == "lane-valid") {
    print query
  } else if (operation == "lane-role") {
    print lane_field[query SUBSEP "role"]
  } else if (operation == "lane-path") {
    print lane_field[query SUBSEP "path"]
  } else if (operation == "lane-idle") {
    print lane_field[query SUBSEP "idle"]
  }
}
' "$lane_manifest_manifest"
}

lane_manifest_validate() {
  [ "$#" = 1 ] || return 2
  lane_manifest__query validate "$1" >/dev/null
}

lane_manifest_all_lanes() {
  [ "$#" = 1 ] || return 2
  lane_manifest__query all "$1"
}

lane_manifest_lanes_by_role() {
  [ "$#" = 2 ] || return 2
  lane_manifest__query role-list "$1" "$2"
}

lane_manifest_validate_lane_name() {
  [ "$#" = 2 ] || return 2
  lane_manifest__query lane-valid "$1" "$2" >/dev/null
}

lane_manifest_lane_name_valid() {
  lane_manifest_validate_lane_name "$@"
}

lane_manifest_lane_role() {
  [ "$#" = 2 ] || return 2
  lane_manifest__query lane-role "$1" "$2"
}

lane_manifest_lane_path() {
  [ "$#" = 2 ] || return 2
  lane_manifest__query lane-path "$1" "$2"
}

lane_manifest_lane_idle_policy() {
  [ "$#" = 2 ] || return 2
  lane_manifest__query lane-idle "$1" "$2"
}

lane_manifest_repository_identity() {
  [ "$#" = 1 ] || return 2
  lane_manifest__query repository "$1"
}

lane_manifest_default_branch() {
  [ "$#" = 1 ] || return 2
  lane_manifest__query default-branch "$1"
}
