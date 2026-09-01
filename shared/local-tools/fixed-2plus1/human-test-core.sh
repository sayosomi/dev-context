# Exact-ref Human-test lifecycle for the fixed Human-test lane.
# Project adapters may use the guard hooks for session/process policy and
# presentation.  The marker, tested-ref fixation, receipt, and idle release
# mechanics remain here.

fixed_2plus1_human_test_path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

fixed_2plus1_human_test_regular_file() {
  [ -f "$1" ] && [ ! -L "$1" ]
}

fixed_2plus1_human_test_resolve_ref() {
  local repo requested_ref resolved
  repo=$1
  requested_ref=$2
  resolved=$(git -C "$repo" rev-parse "$requested_ref^{commit}" 2>/dev/null) || return 1
  nuinui_ownership_valid_sha "$resolved" || return 1
  printf '%s\n' "$resolved"
}

fixed_2plus1_human_test_read_marker() {
  local path
  path=$1
  fixed_2plus1_human_test_regular_file "$path" || return 1
  set -- $(nuinui_ownership_read_fields "$path" issue,ref) || return 1
  [ "$#" = 2 ] || return 1
  nuinui_ownership_valid_issue "$1" || return 1
  nuinui_ownership_valid_sha "$2" || return 1
  printf '%s %s\n' "$1" "$2"
}

fixed_2plus1_human_test_read_receipt() {
  local path
  path=$1
  fixed_2plus1_human_test_regular_file "$path" || return 1
  set -- $(nuinui_ownership_read_fields "$path" version,issue,ref) || return 1
  [ "$#" = 3 ] || return 1
  [ "$1" = 1 ] || return 1
  nuinui_ownership_valid_issue "$2" || return 1
  nuinui_ownership_valid_sha "$3" || return 1
  printf '%s %s %s\n' "$1" "$2" "$3"
}

fixed_2plus1_human_test_checkout_identity() {
  local repo
  repo=$1
  gr "$repo" &&
    ao "$repo" "$(fixed_2plus1_profile_repository_identity)" &&
    cn "$repo" && [ -z "$(bn "$repo")" ]
}

fixed_2plus1_human_test_checkout_matches() {
  fixed_2plus1_human_test_checkout_identity "$1" && [ "$(hh "$1" 2>/dev/null)" = "$2" ]
}

fixed_2plus1_human_test_write_receipt() {
  local repo issue ref receipt
  repo=$1
  issue=$2
  ref=$3
  receipt=$(fixed_2plus1_profile_human_test_receipt_path "$repo") || return 1
  if fixed_2plus1_human_test_path_exists "$receipt" &&
    ! fixed_2plus1_human_test_regular_file "$receipt"; then
    return 1
  fi
  wa "$receipt" "version=1\nissue=$issue\nref=$ref\n" || return 1
  set -- $(fixed_2plus1_human_test_read_receipt "$receipt") || return 1
  [ "$1 $2 $3" = "1 $issue $ref" ]
}

fixed_2plus1_human_test_start() {
  local issue requested_ref repo marker session tested_ref origin_main current_head
  local marker_issue marker_ref started_label already_started_label
  issue=$1
  requested_ref=$2
  started_label=$3
  already_started_label=$4
  fixed_2plus1_profile_guard || {
    echo 'BLOCKED: Human-test profile contract is invalid'
    return 1
  }
  nuinui_ownership_valid_issue "$issue" || {
    echo 'BLOCKED: invalid Human-test Work-ID'
    return 1
  }
  repo=$(fixed_2plus1_profile_lane_path \
    "$(fixed_2plus1_profile_human_test_lane_name)") || return 1
  marker=$(fixed_2plus1_profile_human_test_marker_path "$repo") || return 1
  session=$(fixed_2plus1_profile_human_test_session_path "$repo") || return 1
  tested_ref=$(fixed_2plus1_human_test_resolve_ref "$repo" "$requested_ref") || {
    echo 'BLOCKED: tested-ref does not resolve to a commit in the Human-test checkout'
    return 1
  }

  if fixed_2plus1_human_test_path_exists "$marker"; then
    fixed_2plus1_profile_human_test_start_guard \
      "$repo" "$issue" "$tested_ref" duplicate || return 1
    set -- $(fixed_2plus1_human_test_read_marker "$marker") || {
      echo 'BLOCKED: duplicate Human-test start marker is malformed'
      return 1
    }
    marker_issue=$1
    marker_ref=$2
    if [ "$marker_issue" != "$issue" ] || [ "$marker_ref" != "$tested_ref" ]; then
      echo 'BLOCKED: duplicate Human-test start marker does not match caller Work-ID/ref'
      printf 'expected_issue=%s\nactual_issue=%s\nexpected_ref=%s\nactual_ref=%s\n' \
        "$marker_issue" "$issue" "$marker_ref" "$tested_ref"
      return 1
    fi
    fixed_2plus1_human_test_checkout_matches "$repo" "$tested_ref" || {
      echo 'BLOCKED: duplicate Human-test start checkout identity does not match marker ref'
      return 1
    }
    printf '%s\nissue=%s\nref=%s\nclean=yes\nmutation=no-op\nstate=BUSY\n' \
      "$already_started_label" "$issue" "$tested_ref"
    return 0
  fi

  fixed_2plus1_profile_human_test_start_guard \
    "$repo" "$issue" "$tested_ref" active || return 1
  gr "$repo" && ao "$repo" "$(fixed_2plus1_profile_repository_identity)" &&
    cn "$repo" && [ -z "$(bn "$repo")" ] || {
      echo 'BLOCKED: Human-test start requires a clean detached checkout'
      return 1
    }
  fp "$repo" || {
    echo 'BLOCKED: Human-test start fetch/prune failed'
    return 1
  }
  origin_main=$(om "$repo") || {
    echo 'BLOCKED: Human-test start could not read the authoritative default branch'
    return 1
  }
  nuinui_ownership_valid_sha "$origin_main" || {
    echo 'BLOCKED: Human-test start authoritative default branch is invalid'
    return 1
  }
  tested_ref=$(fixed_2plus1_human_test_resolve_ref "$repo" "$requested_ref") || {
    echo 'BLOCKED: tested-ref does not resolve to a commit in the Human-test checkout'
    return 1
  }
  current_head=$(hh "$repo") || return 1
  if [ "$current_head" != "$origin_main" ]; then
    an "$repo" "$current_head" "$origin_main" && sd "$repo" "$origin_main" || {
      echo 'BLOCKED: Human-test checkout cannot safely return to the authoritative default branch'
      return 1
    }
  fi
  sd "$repo" "$tested_ref" >/dev/null 2>&1 || {
    echo 'BLOCKED: Human-test checkout cannot be fixed to tested-ref'
    return 1
  }
  wa "$marker" "issue=$issue\nref=$tested_ref\n" || {
    echo 'BLOCKED: could not atomically write the Human-test marker'
    return 1
  }
  fixed_2plus1_human_test_read_marker "$marker" >/dev/null || {
    echo 'BLOCKED: Human-test marker verification failed'
    return 1
  }
  printf '%s\n' "$started_label"
}

fixed_2plus1_human_test_release() {
  local issue tested_ref repo marker session receipt marker_issue marker_ref
  local receipt_issue receipt_ref origin_main
  local released_label already_released_label
  issue=$1
  tested_ref=$2
  released_label=$3
  already_released_label=$4
  fixed_2plus1_profile_guard || {
    echo 'BLOCKED: Human-test profile contract is invalid'
    return 1
  }
  nuinui_ownership_valid_issue "$issue" || {
    echo 'BLOCKED: invalid Human-test Work-ID'
    return 1
  }
  nuinui_ownership_valid_sha "$tested_ref" || {
    echo 'BLOCKED: tested-ref must be a full commit SHA'
    return 1
  }
  tested_ref=$(printf '%s' "$tested_ref" | tr '[:upper:]' '[:lower:]')
  repo=$(fixed_2plus1_profile_lane_path \
    "$(fixed_2plus1_profile_human_test_lane_name)") || return 1
  marker=$(fixed_2plus1_profile_human_test_marker_path "$repo") || return 1
  session=$(fixed_2plus1_profile_human_test_session_path "$repo") || return 1
  receipt=$(fixed_2plus1_profile_human_test_receipt_path "$repo") || return 1

  if fixed_2plus1_human_test_path_exists "$marker"; then
    fixed_2plus1_profile_human_test_release_guard \
      "$repo" "$issue" "$tested_ref" active initial || return 1
    set -- $(fixed_2plus1_human_test_read_marker "$marker") || {
      echo 'BLOCKED: Human-test release marker is malformed'
      return 1
    }
    marker_issue=$1
    marker_ref=$2
    if [ "$marker_issue" != "$issue" ] || [ "$marker_ref" != "$tested_ref" ]; then
      echo 'BLOCKED: Human-test release marker does not match caller Work-ID/ref'
      printf 'expected_issue=%s\nactual_issue=%s\nexpected_ref=%s\nactual_ref=%s\n' \
        "$marker_issue" "$issue" "$marker_ref" "$tested_ref"
      return 1
    fi
    fixed_2plus1_human_test_checkout_matches "$repo" "$tested_ref" || {
      echo 'BLOCKED: Human-test release checkout identity is invalid'
      return 1
    }
    fp "$repo" || {
      echo 'BLOCKED: Human-test release fetch/prune failed'
      return 1
    }
    set -- $(fixed_2plus1_human_test_read_marker "$marker") || {
      echo 'BLOCKED: Human-test release marker changed or became malformed after fetch'
      return 1
    }
    [ "$1" = "$issue" ] && [ "$2" = "$tested_ref" ] || {
      echo 'BLOCKED: Human-test release marker changed after fetch'
      return 1
    }
    fixed_2plus1_profile_human_test_release_guard \
      "$repo" "$issue" "$tested_ref" active after-fetch || return 1
    fixed_2plus1_human_test_checkout_matches "$repo" "$tested_ref" || {
      echo 'BLOCKED: Human-test release checkout changed after fetch'
      return 1
    }
    origin_main=$(am "$repo") || return 1
    nuinui_ownership_valid_sha "$origin_main" || {
      echo 'BLOCKED: Human-test release could not read the authoritative default branch'
      return 1
    }
    fixed_2plus1_human_test_write_receipt "$repo" "$issue" "$tested_ref" || {
      echo 'BLOCKED: could not atomically write the Human-test release receipt; marker retained'
      return 1
    }
    sd "$repo" "$origin_main" >/dev/null 2>&1 || {
      echo 'BLOCKED: could not detach Human-test checkout to the authoritative default branch; marker retained'
      return 1
    }
    fixed_2plus1_human_test_checkout_matches "$repo" "$origin_main" || {
      echo 'BLOCKED: Human-test checkout did not reach the authoritative default branch; marker retained'
      return 1
    }
    rm "$marker" || {
      echo 'BLOCKED: could not remove the Human-test marker; release receipt retained'
      return 1
    }
    printf '%s\n' "$released_label"
    return 0
  fi

  fixed_2plus1_profile_human_test_release_guard \
    "$repo" "$issue" "$tested_ref" duplicate initial || return 1
  fixed_2plus1_human_test_path_exists "$receipt" || {
    echo 'BLOCKED: Human-test marker is absent and the release receipt is missing'
    return 1
  }
  set -- $(fixed_2plus1_human_test_read_receipt "$receipt") || {
    echo 'BLOCKED: Human-test release receipt is malformed'
    return 1
  }
  receipt_issue=$2
  receipt_ref=$3
  if [ "$receipt_issue" != "$issue" ] || [ "$receipt_ref" != "$tested_ref" ]; then
    echo 'BLOCKED: duplicate Human-test release receipt does not match caller Work-ID/ref'
    printf 'expected_issue=%s\nactual_issue=%s\nexpected_ref=%s\nactual_ref=%s\n' \
      "$receipt_issue" "$issue" "$receipt_ref" "$tested_ref"
    return 1
  fi
  fixed_2plus1_human_test_checkout_identity "$repo" || {
    echo 'BLOCKED: duplicate Human-test release checkout identity is invalid'
    return 1
  }
  origin_main=$(am "$repo") || {
    echo 'BLOCKED: duplicate Human-test release could not read the authoritative default branch'
    return 1
  }
  nuinui_ownership_valid_sha "$origin_main" || return 1
  [ "$(hh "$repo" 2>/dev/null)" = "$origin_main" ] || {
    echo 'BLOCKED: duplicate Human-test release HEAD is not the authoritative default branch'
    return 1
  }
  printf '%s\nissue=%s\nref=%s\norigin_default=%s\nclean=yes\nmutation=no-op\nstate=FREE\n' \
    "$already_released_label" "$issue" "$tested_ref" "$origin_main"
}
