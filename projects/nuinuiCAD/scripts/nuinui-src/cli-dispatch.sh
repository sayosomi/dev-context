# Public command membership, usage, validation, routing, and dispatch.
# K is consumed by both usage and the existing context-check implementation.
V=1.6.18
K='preflight verify lane-init begin start resume release recover pr-auto-merge integrate-clean e2e-start e2e-start-local-main e2e-release context-audit context-sync context-dev-audit context-dev-transition doctor transition-audit context-check self-test last-result'

nuinui_validate_public_issue_branch() {
  local nuinui_request_issue nuinui_request_branch nuinui_request_occurrences
  local nuinui_request_occurrence nuinui_request_identifier nuinui_request_identifiers
  local nuinui_request_found

  nuinui_request_issue=$1
  nuinui_request_branch=$2

  if ! nuinui_ownership_valid_issue "$nuinui_request_issue"; then
    printf 'ERROR: requested Issue is invalid\n'
    printf 'expected=SAY-<digits>\nfound=%s\nbranch=%s\n' \
      "$nuinui_request_issue" "$nuinui_request_branch"
    return 1
  fi
  if ! nuinui_ownership_valid_branch "$nuinui_request_branch"; then
    printf 'ERROR: invalid Git branch syntax\n'
    printf 'expected=%s\nfound=invalid\nbranch=%s\n' \
      "$nuinui_request_issue" "$nuinui_request_branch"
    return 1
  fi

  nuinui_request_identifiers=
  nuinui_request_occurrences=$(printf '%s\n' "$nuinui_request_branch" | grep -Eio 'say-[0-9]+' || true)
  for nuinui_request_occurrence in $nuinui_request_occurrences; do
    nuinui_request_identifier=$(printf '%s\n' "$nuinui_request_occurrence" | tr '[:lower:]' '[:upper:]')
    case " $nuinui_request_identifiers " in
      *" $nuinui_request_identifier "*) ;;
      *)
        if [ -n "$nuinui_request_identifiers" ]; then
          nuinui_request_identifiers="$nuinui_request_identifiers $nuinui_request_identifier"
        else
          nuinui_request_identifiers=$nuinui_request_identifier
        fi
        ;;
    esac
  done

  set -- $nuinui_request_identifiers
  case "$#" in
    1)
      [ "$1" = "$nuinui_request_issue" ] && return 0
      printf 'ERROR: branch issue identifier does not match requested Issue\n'
      printf 'expected=%s\nfound=%s\nbranch=%s\n' \
        "$nuinui_request_issue" "$1" "$nuinui_request_branch"
      ;;
    0)
      printf 'ERROR: branch does not contain requested issue identifier\n'
      printf 'expected=%s\nfound=-\nbranch=%s\n' \
        "$nuinui_request_issue" "$nuinui_request_branch"
      ;;
    *)
      nuinui_request_found=$(printf '%s\n' "$nuinui_request_identifiers" | tr ' ' ',')
      printf 'ERROR: branch contains multiple issue identifiers\n'
      printf 'expected=%s\nfound=%s\nbranch=%s\n' \
        "$nuinui_request_issue" "$nuinui_request_found" "$nuinui_request_branch"
      ;;
  esac
  return 1
}

nuinui_usage() {
  echo "nuinui $V"
  echo "Commands: $K"
}

nuinui_run_public() {
  nuinui_public_name=$1
  shift
  nuinui_public_output=
  nuinui_public_rc=0
  nuinui_public_output=$( "$@" 2>&1 ) || nuinui_public_rc=$?
  if [ "$nuinui_public_rc" = 0 ] && [ "${nuinui_forensic_option_active:-0}" = 1 ]; then
    case "$nuinui_public_name" in
      begin|start)
        nuinui_public_output=$(printf '%s\nforensic_exception=active\nforensic_worktree=%s' \
          "$nuinui_public_output" "$nuinui_forensic_worktree")
        ;;
    esac
  fi
  if [ -n "$nuinui_public_output" ]; then
    printf '%s\n' "$nuinui_public_output"
  else
    printf 'ERROR: public command %s failed without a diagnostic\n' "$nuinui_public_name"
  fi
  return "$nuinui_public_rc"
}

nuinui_run_tracked() {
  nuinui_tracked_name=$1
  nuinui_tracked_request_count=$2
  shift 2
  nuinui_command_result_run "$nuinui_tracked_name" "$nuinui_tracked_request_count" "$@"
}

nuinui_forensic_worktree=
nuinui_forensic_option_active=0

case "$1" in
  version)
    [ "$#" = 1 ] || { echo 'Usage: nuinui version'; exit 2; }
    echo "$V"
    exit 0
    ;;
  --help|-h|help|'')
    nuinui_usage
    [ -n "$1" ] && exit 0 || exit 2
    ;;
  preflight)
    if [ "$#" = 3 ] && [ "$2" = --forensic-worktree ]; then
      nuinui_forensic_worktree=$3
      nuinui_forensic_option_active=1
    elif [ "$#" != 1 ]; then
      echo 'Usage: nuinui preflight [--forensic-worktree <absolute-path>]'
      exit 2
    fi
    nuinui_run_public preflight pf
    exit $?
    ;;
  verify)
    [ "$#" = 5 ] || { echo 'Usage: nuinui verify <main|sub> <SAY-123> <expected-base-sha> <branch>'; exit 2; }
    nuinui_validate_public_issue_branch "$3" "$5" || exit $?
    nuinui_run_public verify vr "$2" "$3" "$4" "$5"
    exit $?
    ;;
  lane-init)
    [ "$#" = 2 ] || { echo 'Usage: nuinui lane-init <main|sub>'; exit 2; }
    nuinui_run_tracked lane-init "$#" "$@" li "$2"
    exit $?
    ;;
  begin)
    if [ "$#" = 8 ] && [ "$7" = --forensic-worktree ]; then
      nuinui_forensic_worktree=$8
      nuinui_forensic_option_active=1
    elif [ "$#" != 6 ]; then
      echo 'Usage: nuinui begin <main|sub> <SAY-123> <expected-base-sha> <branch> <FREE|SAY-123> [--forensic-worktree <absolute-path>]'
      exit 2
    fi
    nuinui_validate_public_issue_branch "$3" "$5" || exit $?
    nuinui_run_tracked begin "$#" "$@" lifecycle_begin "$2" "$3" "$4" "$5" "$6"
    exit $?
    ;;
  start)
    if [ "$#" = 7 ] && [ "$6" = --forensic-worktree ]; then
      nuinui_forensic_worktree=$7
      nuinui_forensic_option_active=1
    elif [ "$#" != 5 ]; then
      echo 'Usage: nuinui start <main|sub> <SAY-123> <expected-base-sha> <branch> [--forensic-worktree <absolute-path>]'
      exit 2
    fi
    nuinui_validate_public_issue_branch "$3" "$5" || exit $?
    nuinui_run_tracked start "$#" "$@" lifecycle_start_command "$2" "$3" "$4" "$5"
    exit $?
    ;;
  resume)
    [ "$#" = 7 ] || { echo 'Usage: nuinui resume <main|sub> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>'; exit 2; }
    nuinui_run_tracked resume "$#" "$@" lifecycle_resume_command "$2" "$3" "$4" "$5" "$6" "$7"
    exit $?
    ;;
  release)
    [ "$#" = 4 ] || { echo 'Usage: nuinui release <main|sub> <merged-checkpoint-sha> <expected-claim>'; exit 2; }
    nuinui_run_tracked release "$#" "$@" lifecycle_release_command "$2" "$3" "$4"
    exit $?
    ;;
  recover)
    [ "$#" = 3 ] || { echo 'Usage: nuinui recover <main|sub> <expected-claim>'; exit 2; }
    nuinui_run_tracked recover "$#" "$@" rc "$2" "$3"
    exit $?
    ;;
  pr-auto-merge)
    [ "$#" = 4 ] || { echo 'Usage: nuinui pr-auto-merge <pr-number> <expected-head-sha> <expected-main-sha>'; exit 2; }
    nuinui_run_tracked pr-auto-merge "$#" "$@" pam "$2" "$3" "$4"
    exit $?
    ;;
  integrate-clean)
    [ "$#" = 8 ] || { echo 'Usage: nuinui integrate-clean <main|sub> <SAY-123> <expected-claim> <expected-topic-head> <expected-main> <verification-script> <expected-files-manifest|->'; exit 2; }
    nuinui_run_tracked integrate-clean "$#" "$@" integration_clean_command "$2" "$3" "$4" "$5" "$6" "$7" "$8"
    exit $?
    ;;
  e2e-start)
    [ "$#" = 3 ] || { echo 'Usage: nuinui e2e-start <SAY-123> <tested-ref>'; exit 2; }
    nuinui_run_tracked e2e-start "$#" "$@" es "$2" "$3"
    exit $?
    ;;
  e2e-start-local-main)
    [ "$#" = 3 ] || { echo 'Usage: nuinui e2e-start-local-main <SAY-123> <tested-ref>'; exit 2; }
    nuinui_run_tracked e2e-start-local-main "$#" "$@" el "$2" "$3"
    exit $?
    ;;
  e2e-release)
    [ "$#" = 3 ] || { echo 'Usage: nuinui e2e-release <SAY-123> <tested-ref>'; exit 2; }
    nuinui_run_tracked e2e-release "$#" "$@" ee "$2" "$3"
    exit $?
    ;;
  context-audit)
    [ "$#" = 3 ] || { echo 'Usage: nuinui context-audit <expected-main> <expected-artifact-blob>'; exit 2; }
    nuinui_run_public context-audit context_audit_command "$2" "$3"
    exit $?
    ;;
  context-sync)
    [ "$#" = 3 ] || { echo 'Usage: nuinui context-sync <expected-main> <expected-artifact-blob>'; exit 2; }
    nuinui_run_tracked context-sync "$#" "$@" sy "$2" "$3"
    exit $?
    ;;
  context-dev-audit)
    [ "$#" = 3 ] || { echo 'Usage: nuinui context-dev-audit <expected-branch> <expected-head>'; exit 2; }
    nuinui_run_public context-dev-audit context_dev_audit_command "$2" "$3"
    exit $?
    ;;
  context-dev-transition)
    [ "$#" = 5 ] || { echo 'Usage: nuinui context-dev-transition <expected-old-branch> <expected-old-head> <expected-main> <new-branch>'; exit 2; }
    nuinui_run_tracked context-dev-transition "$#" "$@" context_dev_transition_command "$2" "$3" "$4" "$5"
    exit $?
    ;;
  doctor)
    if [ "$#" = 2 ]; then
      [ "$2" = --full ] || { echo 'Usage: nuinui doctor [--full]'; exit 2; }
      shift
    elif [ "$#" != 1 ]; then
      echo 'Usage: nuinui doctor [--full]'
      exit 2
    fi
    nuinui_run_public doctor doctor "$@"
    exit $?
    ;;
  transition-audit)
    [ "$#" = 1 ] || { echo 'Usage: nuinui transition-audit'; exit 2; }
    nuinui_run_public transition-audit ta
    exit $?
    ;;
  context-check)
    [ "$#" = 1 ] || { nuinui_usage; exit 2; }
    nuinui_run_public context-check cc
    exit $?
    ;;
  self-test)
    [ "$#" = 1 ] || { nuinui_usage; exit 2; }
    nuinui_run_public self-test nuinui_self_test
    exit $?
    ;;
  last-result)
    [ "$#" = 1 ] || { echo 'Usage: nuinui last-result'; exit 2; }
    nuinui_run_public last-result nuinui_command_result_last_result
    exit $?
    ;;
  *)
    nuinui_usage
    exit 2
    ;;
esac
