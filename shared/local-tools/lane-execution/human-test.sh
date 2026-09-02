#!/bin/sh

# Topology-neutral exact-ref Human-test lifecycle.
#
# Every operation receives its manifest and selected lane explicitly.  The
# manifest is data and the project hooks below are adapters: they may add
# session/process policy, but they do not select a lane or weaken the Git
# fixation, marker, receipt, or release proofs.

# BEGIN DEVELOPMENT-ONLY SOURCE LOADING
lane_execution_human_test_source_dir=${LANE_EXECUTION_SOURCE_DIR:-}
if [ -z "$lane_execution_human_test_source_dir" ] &&
  [ "${LANE_EXECUTION_HUMAN_TEST_EXECUTE:-0}" = 1 ]; then
  lane_execution_human_test_source_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
fi
if ! command -v lane_manifest_validate >/dev/null 2>&1 &&
  [ -n "$lane_execution_human_test_source_dir" ]; then
  . "$lane_execution_human_test_source_dir/manifest.sh"
fi
if ! command -v lane_execution__canonical_path >/dev/null 2>&1 &&
  [ -n "$lane_execution_human_test_source_dir" ]; then
  . "$lane_execution_human_test_source_dir/preflight.sh"
fi
# END DEVELOPMENT-ONLY SOURCE LOADING

lane_execution_human_test__path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

lane_execution_human_test__regular_file() {
  [ -f "$1" ] && [ ! -L "$1" ]
}

if ! command -v lane_execution_human_test_marker_path >/dev/null 2>&1; then
  lane_execution_human_test_marker_path() {
    printf '%s/nuinui-slot\n' "$(lane_execution__git_dir "$1")"
  }
fi

if ! command -v lane_execution_human_test_session_path >/dev/null 2>&1; then
  lane_execution_human_test_session_path() {
    printf '%s/nuinui-e2e-session\n' "$(lane_execution__git_dir "$1")"
  }
fi

if ! command -v lane_execution_human_test_receipt_path >/dev/null 2>&1; then
  lane_execution_human_test_receipt_path() {
    printf '%s/nuinui-e2e-release-receipt\n' "$(lane_execution__git_dir "$1")"
  }
fi

if ! command -v lane_execution_human_test_start_guard >/dev/null 2>&1; then
  lane_execution_human_test_start_guard() { return 0; }
fi
if ! command -v lane_execution_human_test_release_guard >/dev/null 2>&1; then
  lane_execution_human_test_release_guard() { return 0; }
fi
if ! command -v lane_execution_human_test_local_main_policy >/dev/null 2>&1; then
  lane_execution_human_test_local_main_policy() {
    echo 'BLOCKED: local-main policy is not configured for this project'
    return 1
  }
fi

lane_execution_human_test__context() {
  [ "$#" = 2 ] || return 2
  lane_execution_human_test_context_manifest=$1
  lane_execution_human_test_context_lane=$2
  lane_manifest_validate "$lane_execution_human_test_context_manifest" || return 1
  lane_manifest_validate_lane_name "$lane_execution_human_test_context_manifest" \
    "$lane_execution_human_test_context_lane" >/dev/null 2>&1 || return 1
  [ "$(lane_manifest_lane_role "$lane_execution_human_test_context_manifest" \
    "$lane_execution_human_test_context_lane")" = human-test ] || return 1
  lane_execution_human_test_context_path=$(lane_manifest_lane_path \
    "$lane_execution_human_test_context_manifest" \
    "$lane_execution_human_test_context_lane") || return 1
  lane_execution_human_test_context_path=$(lane_execution__canonical_path \
    "$lane_execution_human_test_context_path") || return 1
  lane_execution_human_test_context_idle=$(lane_manifest_lane_idle_policy \
    "$lane_execution_human_test_context_manifest" \
    "$lane_execution_human_test_context_lane") || return 1
  [ "$lane_execution_human_test_context_idle" = detached ] || {
    echo 'BLOCKED: selected Human-test lane must declare idle=detached'
    return 1
  }
  lane_execution_human_test_context_repository=$(lane_manifest_repository_identity \
    "$lane_execution_human_test_context_manifest") || return 1
  lane_execution_human_test_context_default=$(lane_manifest_default_branch \
    "$lane_execution_human_test_context_manifest") || return 1
  lane_execution__repository_matches "$lane_execution_human_test_context_path" \
    "$lane_execution_human_test_context_repository" || return 1
}

lane_execution_human_test__resolve_ref() {
  lane_execution_human_test_ref=$(git -C "$1" rev-parse --verify \
    "$2^{commit}" 2>/dev/null) || return 1
  nuinui_ownership_valid_sha "$lane_execution_human_test_ref" || return 1
  printf '%s\n' "$lane_execution_human_test_ref"
}

lane_execution_human_test__read_marker() {
  lane_execution_human_test_marker=$1
  lane_execution_human_test__regular_file "$lane_execution_human_test_marker" || return 1
  set -- $(nuinui_ownership_read_fields "$lane_execution_human_test_marker" issue,ref) || return 1
  [ "$#" = 2 ] || return 1
  lane_execution_validate_work_id "$1" && nuinui_ownership_valid_sha "$2" || return 1
  printf '%s %s\n' "$1" "$2"
}

lane_execution_human_test__read_receipt() {
  lane_execution_human_test_receipt=$1
  lane_execution_human_test__regular_file "$lane_execution_human_test_receipt" || return 1
  set -- $(nuinui_ownership_read_fields \
    "$lane_execution_human_test_receipt" version,issue,ref) || return 1
  [ "$#" = 3 ] && [ "$1" = 1 ] || return 1
  lane_execution_validate_work_id "$2" && nuinui_ownership_valid_sha "$3" || return 1
  printf '%s %s %s\n' "$1" "$2" "$3"
}

lane_execution_human_test__checkout_identity() {
  lane_execution_human_test_identity_repo=$1
  lane_execution__git_dir "$lane_execution_human_test_identity_repo" >/dev/null || return 1
  lane_execution__repository_matches "$lane_execution_human_test_identity_repo" \
    "$lane_execution_human_test_context_repository" || return 1
  [ -z "$(git -C "$lane_execution_human_test_identity_repo" \
    status --porcelain 2>/dev/null)" ] || return 1
  [ -z "$(git -C "$lane_execution_human_test_identity_repo" \
    symbolic-ref --quiet --short HEAD 2>/dev/null || true)" ]
}

lane_execution_human_test__checkout_matches() {
  lane_execution_human_test__checkout_identity "$1" &&
    [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" = "$2" ]
}

lane_execution_human_test__origin_default() {
  lane_execution_human_test_origin=$(lane_execution__origin_default "$1" "$2")
  nuinui_ownership_valid_sha "$lane_execution_human_test_origin" || return 1
  git -C "$1" cat-file -e "$lane_execution_human_test_origin^{commit}" 2>/dev/null || return 1
  printf '%s\n' "$lane_execution_human_test_origin"
}

lane_execution_human_test__atomic_write() {
  lane_execution_human_test_write_path=$1
  lane_execution_human_test_write_tmp=$lane_execution_human_test_write_path.tmp.$$
  [ ! -e "$lane_execution_human_test_write_tmp" ] &&
    [ ! -L "$lane_execution_human_test_write_tmp" ] || return 1
  (umask 077; (set -C; printf '%b' "$2" >"$lane_execution_human_test_write_tmp")) || {
    rm -f "$lane_execution_human_test_write_tmp"
    return 1
  }
  [ -f "$lane_execution_human_test_write_tmp" ] &&
    [ ! -L "$lane_execution_human_test_write_tmp" ] || {
      rm -f "$lane_execution_human_test_write_tmp"
      return 1
    }
  mv "$lane_execution_human_test_write_tmp" "$lane_execution_human_test_write_path" || {
    rm -f "$lane_execution_human_test_write_tmp"
    return 1
  }
}

lane_execution_human_test__write_receipt() {
  lane_execution_human_test_write_issue=$2
  lane_execution_human_test_write_ref=$3
  lane_execution_human_test__atomic_write "$1" \
    "version=1\nissue=$lane_execution_human_test_write_issue\nref=$lane_execution_human_test_write_ref\n" || return 1
  set -- $(lane_execution_human_test__read_receipt "$1") || return 1
  [ "$1" = 1 ] && [ "$2" = "$lane_execution_human_test_write_issue" ] &&
    [ "$3" = "$lane_execution_human_test_write_ref" ]
}

lane_execution_human_test_start() {
  [ "$#" = 4 ] || [ "$#" = 6 ] || return 2
  lane_execution_human_test_manifest=$1
  lane_execution_human_test_lane=$2
  lane_execution_human_test_issue=$3
  lane_execution_human_test_requested_ref=$4
  lane_execution_human_test_started_label=${5-HUMAN-TEST STARTED}
  lane_execution_human_test_duplicate_label=${6-HUMAN-TEST ALREADY STARTED}

  lane_manifest_validate "$lane_execution_human_test_manifest" || {
    echo 'BLOCKED: Human-test manifest is invalid'
    return 1
  }
  lane_execution_validate_work_id "$lane_execution_human_test_issue" || {
    echo 'BLOCKED: invalid Human-test Work-ID'
    return 1
  }
  lane_execution_human_test__context "$lane_execution_human_test_manifest" \
    "$lane_execution_human_test_lane" || {
    echo 'BLOCKED: selected lane is not a declared Human-test lane'
    return 1
  }
  lane_execution_human_test_repo=$lane_execution_human_test_context_path
  lane_execution_human_test_marker=$(lane_execution_human_test_marker_path \
    "$lane_execution_human_test_repo") || return 1
  lane_execution_human_test_session=$(lane_execution_human_test_session_path \
    "$lane_execution_human_test_repo") || return 1
  lane_execution_human_test_ref=$(lane_execution_human_test__resolve_ref \
    "$lane_execution_human_test_repo" "$lane_execution_human_test_requested_ref") || {
    echo 'BLOCKED: tested-ref does not resolve to a commit in the selected Human-test checkout'
    return 1
  }

  if lane_execution_human_test__path_exists "$lane_execution_human_test_marker"; then
    lane_execution_human_test__regular_file "$lane_execution_human_test_marker" || {
      echo 'BLOCKED: Human-test marker has an invalid type'
      return 1
    }
    lane_execution_human_test_start_guard "$lane_execution_human_test_lane" \
      "$lane_execution_human_test_repo" "$lane_execution_human_test_issue" \
      "$lane_execution_human_test_ref" duplicate || return 1
    lane_execution_human_test_marker_record=$(lane_execution_human_test__read_marker \
      "$lane_execution_human_test_marker") || {
      echo 'BLOCKED: duplicate Human-test start marker is malformed'
      return 1
    }
    set -- $lane_execution_human_test_marker_record
    [ "$#" = 2 ] || {
      echo 'BLOCKED: duplicate Human-test start marker is malformed'
      return 1
    }
    lane_execution_human_test_marker_issue=$1
    lane_execution_human_test_marker_ref=$2
    if [ "$lane_execution_human_test_marker_issue" != \
      "$lane_execution_human_test_issue" ] ||
      [ "$lane_execution_human_test_marker_ref" != "$lane_execution_human_test_ref" ]; then
      echo 'BLOCKED: duplicate Human-test start marker does not match caller Work-ID/ref'
      printf 'expected_issue=%s\nactual_issue=%s\nexpected_ref=%s\nactual_ref=%s\n' \
        "$lane_execution_human_test_issue" "$lane_execution_human_test_marker_issue" \
        "$lane_execution_human_test_ref" "$lane_execution_human_test_marker_ref"
      return 1
    fi
    lane_execution_human_test__checkout_matches "$lane_execution_human_test_repo" \
      "$lane_execution_human_test_ref" || {
      echo 'BLOCKED: duplicate Human-test checkout identity does not match marker ref'
      return 1
    }
    printf '%s\nissue=%s\nref=%s\nclean=yes\nmutation=no-op\nstate=BUSY\n' \
      "$lane_execution_human_test_duplicate_label" \
      "$lane_execution_human_test_issue" "$lane_execution_human_test_ref"
    return 0
  fi

  lane_execution_human_test_start_guard "$lane_execution_human_test_lane" \
    "$lane_execution_human_test_repo" "$lane_execution_human_test_issue" \
    "$lane_execution_human_test_ref" active || return 1
  lane_execution_human_test__checkout_identity "$lane_execution_human_test_repo" || {
    echo 'BLOCKED: Human-test start requires a clean detached checkout'
    return 1
  }
  git -C "$lane_execution_human_test_repo" fetch origin --prune >/dev/null 2>&1 || {
    echo 'BLOCKED: Human-test start fetch/prune failed'
    return 1
  }
  lane_execution_human_test_origin=$(lane_execution_human_test__origin_default \
    "$lane_execution_human_test_repo" "$lane_execution_human_test_context_default") || {
    echo 'BLOCKED: Human-test start could not read the authoritative default branch'
    return 1
  }
  lane_execution_human_test_ref=$(lane_execution_human_test__resolve_ref \
    "$lane_execution_human_test_repo" "$lane_execution_human_test_requested_ref") || {
    echo 'BLOCKED: tested-ref does not resolve to a commit in the selected Human-test checkout'
    return 1
  }
  lane_execution_human_test_head=$(git -C "$lane_execution_human_test_repo" \
    rev-parse HEAD 2>/dev/null) || return 1
  if [ "$lane_execution_human_test_head" != "$lane_execution_human_test_origin" ]; then
    git -C "$lane_execution_human_test_repo" merge-base --is-ancestor \
      "$lane_execution_human_test_head" "$lane_execution_human_test_origin" || {
      echo 'BLOCKED: Human-test checkout cannot safely return to the authoritative default branch'
      return 1
    }
    git -C "$lane_execution_human_test_repo" switch --detach \
      "$lane_execution_human_test_origin" >/dev/null 2>&1 || {
      echo 'BLOCKED: Human-test checkout cannot safely return to the authoritative default branch'
      return 1
    }
  fi
  git -C "$lane_execution_human_test_repo" switch --detach \
    "$lane_execution_human_test_ref" >/dev/null 2>&1 || {
    echo 'BLOCKED: Human-test checkout cannot be fixed to tested-ref'
    return 1
  }
  if lane_execution_human_test__path_exists "$lane_execution_human_test_marker"; then
    lane_execution_human_test__regular_file "$lane_execution_human_test_marker" || {
      echo 'BLOCKED: Human-test marker has an invalid type'
      return 1
    }
  fi
  lane_execution_human_test__atomic_write "$lane_execution_human_test_marker" \
    "issue=$lane_execution_human_test_issue\nref=$lane_execution_human_test_ref\n" || {
    echo 'BLOCKED: could not atomically write the Human-test marker'
    return 1
  }
  lane_execution_human_test__read_marker "$lane_execution_human_test_marker" >/dev/null || {
    echo 'BLOCKED: Human-test marker verification failed'
    return 1
  }
  printf '%s\n' "$lane_execution_human_test_started_label"
}

lane_execution_human_test_release() {
  [ "$#" = 4 ] || [ "$#" = 6 ] || return 2
  lane_execution_human_test_manifest=$1
  lane_execution_human_test_lane=$2
  lane_execution_human_test_issue=$3
  lane_execution_human_test_requested_ref=$4
  lane_execution_human_test_released_label=${5-HUMAN-TEST RELEASED}
  lane_execution_human_test_duplicate_label=${6-HUMAN-TEST ALREADY RELEASED}

  lane_manifest_validate "$lane_execution_human_test_manifest" || {
    echo 'BLOCKED: Human-test manifest is invalid'
    return 1
  }
  lane_execution_validate_work_id "$lane_execution_human_test_issue" || {
    echo 'BLOCKED: invalid Human-test Work-ID'
    return 1
  }
  nuinui_ownership_valid_sha "$lane_execution_human_test_requested_ref" || {
    echo 'BLOCKED: tested-ref must be a full commit SHA'
    return 1
  }
  lane_execution_human_test_ref=$(printf '%s' \
    "$lane_execution_human_test_requested_ref" | tr '[:upper:]' '[:lower:]')
  lane_execution_human_test__context "$lane_execution_human_test_manifest" \
    "$lane_execution_human_test_lane" || {
    echo 'BLOCKED: selected lane is not a declared Human-test lane'
    return 1
  }
  lane_execution_human_test_repo=$lane_execution_human_test_context_path
  lane_execution_human_test_marker=$(lane_execution_human_test_marker_path \
    "$lane_execution_human_test_repo") || return 1
  lane_execution_human_test_session=$(lane_execution_human_test_session_path \
    "$lane_execution_human_test_repo") || return 1
  lane_execution_human_test_receipt=$(lane_execution_human_test_receipt_path \
    "$lane_execution_human_test_repo") || return 1

  if lane_execution_human_test__path_exists "$lane_execution_human_test_marker"; then
    lane_execution_human_test__regular_file "$lane_execution_human_test_marker" || {
      echo 'BLOCKED: Human-test marker has an invalid type'
      return 1
    }
    lane_execution_human_test_release_guard "$lane_execution_human_test_lane" \
      "$lane_execution_human_test_repo" "$lane_execution_human_test_issue" \
      "$lane_execution_human_test_ref" active initial || return 1
    lane_execution_human_test_marker_record=$(lane_execution_human_test__read_marker \
      "$lane_execution_human_test_marker") || {
      echo 'BLOCKED: Human-test release marker is malformed'
      return 1
    }
    set -- $lane_execution_human_test_marker_record
    [ "$#" = 2 ] || {
      echo 'BLOCKED: Human-test release marker is malformed'
      return 1
    }
    [ "$1" = "$lane_execution_human_test_issue" ] &&
      [ "$2" = "$lane_execution_human_test_ref" ] || {
      echo 'BLOCKED: Human-test release marker does not match caller Work-ID/ref'
      printf 'expected_issue=%s\nactual_issue=%s\nexpected_ref=%s\nactual_ref=%s\n' \
        "$lane_execution_human_test_issue" "$1" "$lane_execution_human_test_ref" "$2"
      return 1
    }
    lane_execution_human_test__checkout_matches "$lane_execution_human_test_repo" \
      "$lane_execution_human_test_ref" || {
      echo 'BLOCKED: Human-test release checkout identity is invalid'
      return 1
    }
    git -C "$lane_execution_human_test_repo" fetch origin --prune >/dev/null 2>&1 || {
      echo 'BLOCKED: Human-test release fetch/prune failed'
      return 1
    }
    lane_execution_human_test_marker_record=$(lane_execution_human_test__read_marker \
      "$lane_execution_human_test_marker") || {
      echo 'BLOCKED: Human-test release marker changed or became malformed after fetch'
      return 1
    }
    set -- $lane_execution_human_test_marker_record
    [ "$#" = 2 ] || {
      echo 'BLOCKED: Human-test release marker changed or became malformed after fetch'
      return 1
    }
    [ "$1" = "$lane_execution_human_test_issue" ] &&
      [ "$2" = "$lane_execution_human_test_ref" ] || {
      echo 'BLOCKED: Human-test release marker changed after fetch'
      return 1
    }
    lane_execution_human_test_release_guard "$lane_execution_human_test_lane" \
      "$lane_execution_human_test_repo" "$lane_execution_human_test_issue" \
      "$lane_execution_human_test_ref" active after-fetch || return 1
    lane_execution_human_test__checkout_matches "$lane_execution_human_test_repo" \
      "$lane_execution_human_test_ref" || {
      echo 'BLOCKED: Human-test release checkout changed after fetch'
      return 1
    }
    lane_execution_human_test_origin=$(lane_execution_human_test__origin_default \
      "$lane_execution_human_test_repo" "$lane_execution_human_test_context_default") || {
      echo 'BLOCKED: Human-test release could not read the authoritative default branch'
      return 1
    }
    if lane_execution_human_test__path_exists "$lane_execution_human_test_receipt"; then
      lane_execution_human_test__regular_file "$lane_execution_human_test_receipt" || {
        echo 'BLOCKED: Human-test release receipt has an invalid type'
        return 1
      }
      lane_execution_human_test__read_receipt \
        "$lane_execution_human_test_receipt" >/dev/null || {
        echo 'BLOCKED: Human-test release receipt is malformed'
        return 1
      }
    fi
    lane_execution_human_test__write_receipt "$lane_execution_human_test_receipt" \
      "$lane_execution_human_test_issue" "$lane_execution_human_test_ref" || {
      echo 'BLOCKED: could not atomically write the Human-test release receipt; marker retained'
      return 1
    }
    git -C "$lane_execution_human_test_repo" switch --detach \
      "$lane_execution_human_test_origin" >/dev/null 2>&1 || {
      echo 'BLOCKED: could not detach Human-test checkout to the authoritative default branch; marker retained'
      return 1
    }
    lane_execution_human_test__checkout_matches "$lane_execution_human_test_repo" \
      "$lane_execution_human_test_origin" || {
      echo 'BLOCKED: Human-test checkout did not reach the authoritative default branch; marker retained'
      return 1
    }
    rm "$lane_execution_human_test_marker" || {
      echo 'BLOCKED: could not remove the Human-test marker; release receipt retained'
      return 1
    }
    printf '%s\n' "$lane_execution_human_test_released_label"
    return 0
  fi

  lane_execution_human_test_release_guard "$lane_execution_human_test_lane" \
    "$lane_execution_human_test_repo" "$lane_execution_human_test_issue" \
    "$lane_execution_human_test_ref" duplicate initial || return 1
  lane_execution_human_test__path_exists "$lane_execution_human_test_receipt" || {
    echo 'BLOCKED: Human-test marker is absent and the release receipt is missing'
    return 1
  }
  lane_execution_human_test_receipt_record=$(lane_execution_human_test__read_receipt \
    "$lane_execution_human_test_receipt") || {
    echo 'BLOCKED: Human-test release receipt is malformed'
    return 1
  }
  set -- $lane_execution_human_test_receipt_record
  [ "$#" = 3 ] || {
    echo 'BLOCKED: Human-test release receipt is malformed'
    return 1
  }
  [ "$2" = "$lane_execution_human_test_issue" ] &&
    [ "$3" = "$lane_execution_human_test_ref" ] || {
    echo 'BLOCKED: duplicate Human-test release receipt does not match caller Work-ID/ref'
    printf 'expected_issue=%s\nactual_issue=%s\nexpected_ref=%s\nactual_ref=%s\n' \
      "$lane_execution_human_test_issue" "$2" "$lane_execution_human_test_ref" "$3"
    return 1
  }
  lane_execution_human_test__checkout_identity "$lane_execution_human_test_repo" || {
    echo 'BLOCKED: duplicate Human-test release checkout identity is invalid'
    return 1
  }
  lane_execution_human_test_origin=$(lane_execution_human_test__origin_default \
    "$lane_execution_human_test_repo" "$lane_execution_human_test_context_default") || {
    echo 'BLOCKED: duplicate Human-test release could not read the authoritative default branch'
    return 1
  }
  [ "$(git -C "$lane_execution_human_test_repo" rev-parse HEAD 2>/dev/null)" = \
    "$lane_execution_human_test_origin" ] || {
    echo 'BLOCKED: duplicate Human-test release HEAD is not the authoritative default branch'
    return 1
  }
  printf '%s\nissue=%s\nref=%s\norigin_default=%s\nclean=yes\nmutation=no-op\nstate=FREE\n' \
    "$lane_execution_human_test_duplicate_label" "$lane_execution_human_test_issue" \
    "$lane_execution_human_test_ref" "$lane_execution_human_test_origin"
}

lane_execution_human_test_command() {
  [ "$#" -ge 1 ] || return 2
  case "$1" in
    start) shift; lane_execution_human_test_start "$@" ;;
    release) shift; lane_execution_human_test_release "$@" ;;
    *) echo 'Usage: human-test {start|release} <manifest> <human-test-lane> <SAY-123> <tested-ref>' >&2; return 2 ;;
  esac
}

if [ "${LANE_EXECUTION_HUMAN_TEST_EXECUTE:-0}" = 1 ] ||
  [ "${0##*/}" = human-test.sh ]; then
  lane_execution_human_test_command "$@"
fi
