# Checked host-cleanup -> native release -> native final-closure sequence.

nuinui_e2e_host_closure() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_host_closure_manifest=$1
  nuinui_e2e_host_closure_lane=$2
  nuinui_e2e_host_closure_issue=$3
  nuinui_e2e_host__operation_context host-closure \
    "$nuinui_e2e_host_closure_manifest" \
    "$nuinui_e2e_host_closure_lane" \
    "$nuinui_e2e_host_closure_issue" || return 1
  nuinui_e2e_host__load_state || {
    echo 'BLOCKED: host closure cannot resolve one exact validated native generation'
    return 1
  }
  if [ "$nuinui_e2e_host_state" = ABSENT ]; then
    echo 'BLOCKED: host closure requires an active native generation and its host session'
    return 1
  fi
  if [ "$nuinui_e2e_host_state" != RELEASED ]; then
    nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" || {
      echo 'BLOCKED: host closure requires the exact active native generation'
      return 1
    }
    nuinui_e2e_host_closure_cleanup_output=$(nuinui_e2e_host_cleanup \
      "$nuinui_e2e_host_closure_manifest" \
      "$nuinui_e2e_expected_lane" "$nuinui_e2e_expected_issue") || {
        printf '%s\n' "$nuinui_e2e_host_closure_cleanup_output"
        echo 'BLOCKED: host-cleanup stage failed; evidence retained'
        return 1
      }
    printf '%s\n' "$nuinui_e2e_host_closure_cleanup_output"
  fi

  nuinui_e2e_host__operation_context host-closure \
    "$nuinui_e2e_host_closure_manifest" \
    "$nuinui_e2e_expected_lane" "$nuinui_e2e_expected_issue" || return 1
  nuinui_e2e_host__load_state || {
    echo 'BLOCKED: host state changed after cleanup; native release was not attempted'
    return 1
  }
  case "$nuinui_e2e_host_state" in CLEANED|RELEASED) ;; *)
    echo 'BLOCKED: host cleanup is not durably verified; native release was not attempted'
    return 1 ;;
  esac
  nuinui_e2e_host__native_cleanup_proof || {
    echo 'BLOCKED: exact host cleanup receipt is not bound to native cleanup evidence'
    return 1
  }

  if [ "$nuinui_e2e_host_state" != RELEASED ]; then
    nuinui_e2e_host_closure_release_output=$(nuinui_e2e_release \
      "$nuinui_e2e_host_closure_manifest" \
      "$nuinui_e2e_expected_lane" "$nuinui_e2e_expected_issue") || {
        printf '%s\n' "$nuinui_e2e_host_closure_release_output"
        echo 'BLOCKED: native release stage failed; receipt and recovery evidence retained'
        return 1
      }
    printf '%s\n' "$nuinui_e2e_host_closure_release_output"
  fi

  nuinui_e2e_host__operation_context host-closure \
    "$nuinui_e2e_host_closure_manifest" \
    "$nuinui_e2e_expected_lane" "$nuinui_e2e_expected_issue" || return 1
  nuinui_e2e_host__load_state || {
    echo 'BLOCKED: post-release host and native records are inconsistent'
    return 1
  }
  [ "$nuinui_e2e_host_state" = RELEASED ] || {
    echo 'BLOCKED: exact native release receipt and idle checkout are not verified'
    return 1
  }
  nuinui_e2e_host_closure_final_output=$(nuinui_e2e_closure \
    "$nuinui_e2e_host_closure_manifest" \
    "$nuinui_e2e_expected_lane" "$nuinui_e2e_expected_issue") || {
      printf '%s\n' "$nuinui_e2e_host_closure_final_output"
      echo 'BLOCKED: native final-closure stage failed; evidence retained'
      return 1
    }
  printf '%s\n' "$nuinui_e2e_host_closure_final_output"

  nuinui_e2e_host__operation_context host-closure \
    "$nuinui_e2e_host_closure_manifest" \
    "$nuinui_e2e_expected_lane" "$nuinui_e2e_expected_issue" || return 1
  nuinui_e2e_host__load_state || return 1
  [ "$nuinui_e2e_host_state" = RELEASED ] || return 1
  nuinui_e2e_host_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1
  nuinui_e2e__read_expected_release "$nuinui_e2e_host_release" || return 1
  [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
    "$nuinui_e2e_r_idle_sha" ] &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_r_idle_sha" || {
        echo 'BLOCKED: exact native receipt and authoritative clean detached idle checkout failed final verification'
        return 1
      }
  echo 'HOST AND NATIVE CLOSURE VERIFIED'
  echo "issue=$nuinui_e2e_expected_issue"
  echo "lane=$nuinui_e2e_expected_lane"
  echo "tested_sha=$nuinui_e2e_expected_tested"
  echo "idle_sha=$nuinui_e2e_r_idle_sha"
  echo "generation=$nuinui_e2e_expected_generation"
  echo 'host_state=RELEASED'
  echo 'clean=yes'
  echo 'detached=yes'
  echo 'mutation=yes'
}
