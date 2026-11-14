# Checked host-cleanup -> native release -> native final-closure sequence.

nuinui_e2e_host__closure_without_session() {
  [ "$#" = 0 ] || return 2
  nuinui_e2e_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  nuinui_e2e_cleanup=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1

  if ! nuinui_e2e__exists "$nuinui_e2e_active"; then
    nuinui_e2e__read_expected_cleanup "$nuinui_e2e_cleanup" || {
      echo 'BLOCKED: absent-host closure requires exact native cleanup evidence'
      return 1
    }
    [ "$nuinui_e2e_r_proof" = fixture-no-host-session ] || {
      echo 'BLOCKED: cleanup receipt does not prove the host session was absent'
      return 1
    }
    nuinui_e2e__read_expected_release "$nuinui_e2e_release" || {
      echo 'BLOCKED: absent-host closure cannot resume without the exact completed release receipt'
      return 1
    }
    (nuinui_e2e__closure) || {
      echo 'BLOCKED: native no-host final closure failed; existing evidence retained'
      return 1
    }
    nuinui_e2e__read_expected_release "$nuinui_e2e_release" || return 1
    nuinui_e2e_host_no_session_idle_sha=$nuinui_e2e_r_idle_sha
    nuinui_e2e_host_no_session_mutation=no-op
  else
    nuinui_e2e__read_expected_active "$nuinui_e2e_active" || {
      echo 'BLOCKED: absent-host closure requires the exact active native generation'
      return 1
    }
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_expected_tested" || {
        echo 'BLOCKED: absent-host closure requires a clean detached tested checkout'
        return 1
      }
    nuinui_e2e__record_no_host_cleanup_proof host-closure || return 1
    echo 'HOST CLOSURE: releasing native generation without a host session' >&2
    (nuinui_e2e__release) || {
      echo 'BLOCKED: native release stage failed; receipt and recovery evidence retained'
      return 1
    }
    nuinui_e2e_host__load_state || {
      echo 'BLOCKED: host state changed after native release; final closure was not attempted'
      return 1
    }
    [ "$nuinui_e2e_host_state" = ABSENT ] || {
      echo 'BLOCKED: a host session appeared during no-host closure'
      return 1
    }
    (nuinui_e2e__closure) || {
      echo 'BLOCKED: native no-host final closure failed; evidence retained'
      return 1
    }
    nuinui_e2e__read_expected_release "$nuinui_e2e_release" || return 1
    nuinui_e2e_host_no_session_idle_sha=$nuinui_e2e_r_idle_sha
    nuinui_e2e_host_no_session_mutation=yes
  fi

  echo 'NATIVE E2E NO-HOST CLOSURE VERIFIED'
  echo "issue=$nuinui_e2e_expected_issue"
  echo "lane=$nuinui_e2e_expected_lane"
  echo "tested_sha=$nuinui_e2e_expected_tested"
  echo "idle_sha=$nuinui_e2e_host_no_session_idle_sha"
  echo "generation=$nuinui_e2e_expected_generation"
  echo 'host_state=ABSENT'
  echo 'host_session=none'
  echo 'clean=yes'
  echo 'detached=yes'
  echo "mutation=$nuinui_e2e_host_no_session_mutation"
}

nuinui_e2e_host_closure() {
  [ "$#" = 3 ] || return 2
  echo 'HOST CLOSURE: checking session' >&2
  nuinui_e2e_host__operation_context host-closure "$1" "$2" "$3" || return 1
  nuinui_e2e_host__load_state || {
    echo 'BLOCKED: host closure cannot resolve one exact validated native generation'
    return 1
  }
  case "$nuinui_e2e_host_state" in
    ABSENT)
      nuinui_e2e_host__closure_without_session
      return $?
      ;;
    CLEANED|RELEASED) ;;
    *)
      nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" || {
        echo 'BLOCKED: host closure requires the exact active native generation'
        return 1
      }
      echo 'HOST CLOSURE: cleaning up host' >&2
      # Stream stage output. Subshells keep stage-local context changes isolated.
      (nuinui_e2e_host_abnormal_exit_recovery=no; nuinui_e2e_host__cleanup) || {
        echo 'BLOCKED: host-cleanup stage failed; evidence retained'
        return 1
      }
      nuinui_e2e_host__load_state || {
        echo 'BLOCKED: host state changed after cleanup; native release was not attempted'
        return 1
      }
      ;;
  esac
  case "$nuinui_e2e_host_state" in CLEANED|RELEASED) ;; *)
    echo 'BLOCKED: host cleanup is not durably verified; native release was not attempted'
    return 1 ;;
  esac
  nuinui_e2e_host__native_cleanup_proof || {
    echo 'BLOCKED: exact host cleanup receipt is not bound to native cleanup evidence'
    return 1
  }

  # Context and full topology/history were checked at entry. Reuse the existing
  # stage bodies; each still verifies its current generation and mutation data.
  if [ "$nuinui_e2e_host_state" != RELEASED ]; then
    echo 'HOST CLOSURE: releasing native generation' >&2
    (nuinui_e2e__release) || {
      echo 'BLOCKED: native release stage failed; receipt and recovery evidence retained'
      return 1
    }
    nuinui_e2e_host__load_state || {
      echo 'BLOCKED: post-release host and native records are inconsistent'
      return 1
    }
  fi
  [ "$nuinui_e2e_host_state" = RELEASED ] || {
    echo 'BLOCKED: exact native release receipt and idle checkout are not verified'
    return 1
  }
  echo 'HOST CLOSURE: verifying completion' >&2
  (nuinui_e2e__closure) || {
    echo 'BLOCKED: native final-closure stage failed; evidence retained'
    return 1
  }

  nuinui_e2e_host_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1
  nuinui_e2e__read_expected_release "$nuinui_e2e_host_release" || return 1
  echo 'HOST AND NATIVE CLOSURE VERIFIED'
  echo "issue=$nuinui_e2e_expected_issue"
  echo "lane=$nuinui_e2e_expected_lane"
  echo "tested_sha=$nuinui_e2e_expected_tested"
  echo "idle_sha=$nuinui_e2e_r_idle_sha"
  echo "generation=$nuinui_e2e_expected_generation"
  echo "adapter=$nuinui_e2e_host_adapter"
  echo 'host_state=RELEASED'
  echo 'clean=yes'
  echo 'detached=yes'
  echo 'mutation=yes'
}
