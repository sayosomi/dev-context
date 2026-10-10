# Public audit CLI argument parsing and tracked-command dispatch.
# Keep the request-count and result-envelope inputs identical to the public adapter.

nuinui_audit_begin_parse_args() {
  nuinui_audit_cli_issue=
  nuinui_audit_cli_lane=
  nuinui_audit_cli_revision=
  nuinui_audit_cli_issue_seen=0
  nuinui_audit_cli_lane_seen=0
  nuinui_audit_cli_revision_seen=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --issue)
        [ "$nuinui_audit_cli_issue_seen" = 0 ] || { echo 'ERROR: duplicate named option --issue'; return 2; }
        nuinui_audit_cli_issue_seen=1
        nuinui_audit_cli_option=--issue
        ;;
      --lane)
        [ "$nuinui_audit_cli_lane_seen" = 0 ] || { echo 'ERROR: duplicate named option --lane'; return 2; }
        nuinui_audit_cli_lane_seen=1
        nuinui_audit_cli_option=--lane
        ;;
      --revision)
        [ "$nuinui_audit_cli_revision_seen" = 0 ] || { echo 'ERROR: duplicate named option --revision'; return 2; }
        nuinui_audit_cli_revision_seen=1
        nuinui_audit_cli_option=--revision
        ;;
      --*|-*) echo "ERROR: unknown option $1"; return 2 ;;
      *) echo "ERROR: unexpected positional argument $1"; return 2 ;;
    esac
    [ "$#" -ge 2 ] && [ -n "$2" ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' "$nuinui_audit_cli_option"
      return 2
    }
    case "$2" in
      --*) printf 'ERROR: named option %s is missing its value before %s\n' "$nuinui_audit_cli_option" "$2"; return 2 ;;
    esac
    case "$nuinui_audit_cli_option" in
      --issue) nuinui_audit_cli_issue=$2 ;;
      --lane) nuinui_audit_cli_lane=$2 ;;
      --revision) nuinui_audit_cli_revision=$2 ;;
    esac
    shift 2
  done
  [ "$nuinui_audit_cli_issue_seen" = 1 ] || { echo 'ERROR: missing required named option --issue'; return 2; }
  [ "$nuinui_audit_cli_lane_seen" = 1 ] || { echo 'ERROR: missing required named option --lane'; return 2; }
  [ "$nuinui_audit_cli_revision_seen" = 1 ] || { echo 'ERROR: missing required named option --revision'; return 2; }
  printf '%s\n' "$nuinui_audit_cli_issue" | grep -Eq '^SAY-[0-9]+$' || { echo 'ERROR: --issue must be SAY-<digits>'; return 2; }
  printf '%s\n' "$nuinui_audit_cli_lane" | grep -Eq '^[A-Za-z0-9._-]+$' || { echo 'ERROR: --lane is malformed'; return 2; }
  printf '%s\n' "$nuinui_audit_cli_revision" | grep -Eq '^[[:xdigit:]]{40}$' || { echo 'ERROR: --revision must be a full 40-character SHA'; return 2; }
}

nuinui_audit_release_parse_args() {
  nuinui_audit_cli_issue=
  nuinui_audit_cli_revision=
  nuinui_audit_cli_issue_seen=0
  nuinui_audit_cli_revision_seen=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --issue)
        [ "$nuinui_audit_cli_issue_seen" = 0 ] || { echo 'ERROR: duplicate named option --issue'; return 2; }
        nuinui_audit_cli_issue_seen=1
        nuinui_audit_cli_option=--issue
        ;;
      --revision)
        [ "$nuinui_audit_cli_revision_seen" = 0 ] || { echo 'ERROR: duplicate named option --revision'; return 2; }
        nuinui_audit_cli_revision_seen=1
        nuinui_audit_cli_option=--revision
        ;;
      --*|-*) echo "ERROR: unknown option $1"; return 2 ;;
      *) echo "ERROR: unexpected positional argument $1"; return 2 ;;
    esac
    [ "$#" -ge 2 ] && [ -n "$2" ] || {
      printf 'ERROR: named option %s requires a non-empty value\n' "$nuinui_audit_cli_option"
      return 2
    }
    case "$2" in
      --*) printf 'ERROR: named option %s is missing its value before %s\n' "$nuinui_audit_cli_option" "$2"; return 2 ;;
    esac
    case "$nuinui_audit_cli_option" in
      --issue) nuinui_audit_cli_issue=$2 ;;
      --revision) nuinui_audit_cli_revision=$2 ;;
    esac
    shift 2
  done
  [ "$nuinui_audit_cli_issue_seen" = 1 ] || { echo 'ERROR: missing required named option --issue'; return 2; }
  [ "$nuinui_audit_cli_revision_seen" = 1 ] || { echo 'ERROR: missing required named option --revision'; return 2; }
  printf '%s\n' "$nuinui_audit_cli_issue" | grep -Eq '^SAY-[0-9]+$' || { echo 'ERROR: --issue must be SAY-<digits>'; return 2; }
  printf '%s\n' "$nuinui_audit_cli_revision" | grep -Eq '^[[:xdigit:]]{40}$' || { echo 'ERROR: --revision must be a full 40-character SHA'; return 2; }
}

nuinui_audit_cli_dispatch() {
  nuinui_audit_request_count=$(($# - 1))
  nuinui_audit_cli_command=$1
  shift
  case "$nuinui_audit_cli_command" in
    audit-begin)
      nuinui_audit_begin_parse_args "$@" || return $?
      nuinui_require_runtime_manifest || return 1
      nuinui_run_tracked audit-begin "$nuinui_audit_request_count" "$@" \
        nuinui_audit_begin "$NUINUI_RUNTIME_MANIFEST" \
        "$nuinui_audit_cli_issue" "$nuinui_audit_cli_lane" "$nuinui_audit_cli_revision"
      ;;
    audit-release)
      nuinui_audit_release_parse_args "$@" || return $?
      nuinui_require_runtime_manifest || return 1
      nuinui_run_tracked audit-release "$nuinui_audit_request_count" "$@" \
        nuinui_audit_release "$NUINUI_RUNTIME_MANIFEST" \
        "$nuinui_audit_cli_issue" "$nuinui_audit_cli_revision"
      ;;
  esac
}
