# Context-only public command and durable result boundary.
nuinui_candidate_usage() {
  echo 'nuinui-context 0.1.0'
  echo 'Commands: context-audit context-sync context-dev-audit context-dev-transition context-dev-next context-check last-result'
  echo 'Usage: nuinui-context context-audit <expected-main> <expected-artifact-blob>'
  echo 'Usage: nuinui-context context-sync <expected-main> <expected-artifact-blob>'
  echo 'Usage: nuinui-context context-dev-audit <expected-branch> <expected-head>'
  echo 'Usage: nuinui-context context-dev-transition <old-branch> <old-head> <main> <new-branch>'
  echo 'Usage: nuinui-context context-dev-next --old-branch <branch> --old-head <sha> --main <sha> --new-branch <branch>'
  echo 'Usage: nuinui-context context-check | last-result'
}

nuinui_candidate_result_repo() {
  if [ "${NUINUI_SELFTEST:-0}" = 1 ] && [ -n "${NUINUI_SELFTEST_RESULT_REPO:-}" ]; then
    printf '%s\n' "$NUINUI_SELFTEST_RESULT_REPO"
  else
    printf '%s\n' "$C"
  fi
}

nuinui_candidate_result_dir() {
  nuinui_candidate_result_path=$(nuinui_candidate_result_repo)
  gr "$nuinui_candidate_result_path" || return 1
  nuinui_candidate_result_gitdir=$(gd "$nuinui_candidate_result_path") || return 1
  printf '%s/nuinui-context-command-result-v1\n' "$nuinui_candidate_result_gitdir"
}

nuinui_candidate_sha256() {
  nuinui_candidate_hash_capture=$(mktemp "${TMPDIR:-/tmp}/nuinui-context-hash.XXXXXX") || return 1
  if ! shasum -a 256 "$1" >"$nuinui_candidate_hash_capture" 2>/dev/null; then
    rm -f "$nuinui_candidate_hash_capture"
    return 1
  fi
  nuinui_candidate_hash_value=$(awk 'NR==1 {print $1}' "$nuinui_candidate_hash_capture")
  rm -f "$nuinui_candidate_hash_capture"
  [ "${#nuinui_candidate_hash_value}" -eq 64 ] || return 1
  printf '%s\n' "$nuinui_candidate_hash_value" | grep -Eq '^[0-9a-f]{64}$' || return 1
  printf '%s\n' "$nuinui_candidate_hash_value"
}

nuinui_candidate_operation_id() {
  if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
    case "${NUINUI_SELFTEST_OPERATION_ID_FAILURE:-}" in
      fail) return 1 ;;
      malformed) printf '%s\n' malformed; return 0 ;;
      multiline) printf '%040d\njunk\n' 0; return 0 ;;
    esac
  fi
  nuinui_candidate_operation_input=$(mktemp "${TMPDIR:-/tmp}/nuinui-context-operation.XXXXXX") || return 1
  nuinui_candidate_operation_output=$(mktemp "${TMPDIR:-/tmp}/nuinui-context-operation-id.XXXXXX") || {
    rm -f "$nuinui_candidate_operation_input"
    return 1
  }
  if ! (umask 077; printf '%s:%s:%s:%s:%s\n' "$$" "${PPID:-0}" "$(date +%s)" "${RANDOM:-0}" "$(od -An -N16 -tx1 /dev/urandom 2>/dev/null)") >"$nuinui_candidate_operation_input"; then
    rm -f "$nuinui_candidate_operation_input" "$nuinui_candidate_operation_output"
    return 1
  fi
  if ! git hash-object --stdin <"$nuinui_candidate_operation_input" >"$nuinui_candidate_operation_output" 2>/dev/null; then
    rm -f "$nuinui_candidate_operation_input" "$nuinui_candidate_operation_output"
    return 1
  fi
  nuinui_candidate_operation_value=$(cat "$nuinui_candidate_operation_output")
  rm -f "$nuinui_candidate_operation_input" "$nuinui_candidate_operation_output"
  [ "${#nuinui_candidate_operation_value}" -eq 40 ] || return 1
  printf '%s\n' "$nuinui_candidate_operation_value" | grep -Eq '^[0-9a-f]{40}$' || return 1
  printf '%s\n' "$nuinui_candidate_operation_value"
}

nuinui_candidate_timestamp() {
  if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
    case "${NUINUI_SELFTEST_TIMESTAMP_FAILURE:-}" in
      fail) return 1 ;;
      malformed) printf '%s\n' malformed; return 0 ;;
      multiline) printf '%s\n%s\n' '2026-10-13T00:00:00Z' junk; return 0 ;;
    esac
  fi
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

nuinui_candidate_last_result() {
  nuinui_candidate_store=$(nuinui_candidate_result_dir) || { echo 'ERROR: result repository unavailable'; return 1; }
  nuinui_candidate_state=$nuinui_candidate_store/state
  nuinui_candidate_output=$nuinui_candidate_store/output
  [ -d "$nuinui_candidate_store" ] && [ ! -L "$nuinui_candidate_store" ] || { echo 'ERROR: no command result is stored'; return 1; }
  [ -f "$nuinui_candidate_state" ] && [ ! -L "$nuinui_candidate_state" ] || { echo 'ERROR: result state is missing or unsafe'; return 1; }
  awk -F= '
    BEGIN { split("version operation_id timestamp command phase result lane issue claim request_sha256 mutation exit output_sha256", k, " "); for(i=1;i<=13;i++) ok[k[i]]=1 }
    { p=index($0,"="); if(!p) bad=1; key=substr($0,1,p-1); value=substr($0,p+1); if(!(key in ok)||key in seen||value=="") bad=1; seen[key]=1; v[key]=value }
    END { if(NR!=13||bad||v["version"]!="1"||v["operation_id"]!~/^[0-9a-f]{40}$/||v["timestamp"]!~/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/||v["command"]!~/^(context-sync|context-dev-transition)$/||v["lane"]!="dev-context"||v["issue"]!="-"||v["claim"]!="-"||v["mutation"]!~/^(yes|no|unknown)$/||v["request_sha256"]!~/^[0-9a-f]{64}$/) exit 1; if(v["phase"]=="STARTED") {if(v["result"]!="INCOMPLETE"||v["mutation"]!="unknown"||v["exit"]!="-"||v["output_sha256"]!="-") exit 1} else if(v["phase"]=="TERMINAL") {if(v["result"]!~/^(SUCCESS|BLOCKED|ERROR)$/||v["exit"]!~/^[0-9]+$/||v["output_sha256"]!~/^[0-9a-f]{64}$/) exit 1} else exit 1 }
  ' "$nuinui_candidate_state" || { echo 'ERROR: stored result state is malformed'; return 1; }
  nuinui_candidate_phase=$(awk -F= '$1=="phase" {print $2}' "$nuinui_candidate_state")
  if [ "$nuinui_candidate_phase" = STARTED ]; then
    printf '🧾 NUINUI LAST RESULT\n'
    awk -F= '$1=="operation_id"||$1=="timestamp"||$1=="command"||$1=="request_sha256" {print}' "$nuinui_candidate_state"
    printf '⭕ result=INCOMPLETE\nmutation=unknown\n⛔ recovery=BLOCKED\ndiagnostic=tracked mutation did not reach terminal finalization\n'
    return 1
  fi
  [ -f "$nuinui_candidate_output" ] && [ ! -L "$nuinui_candidate_output" ] || { echo 'ERROR: terminal result output is missing or unsafe'; return 1; }
  nuinui_candidate_expected_output=$(awk -F= '$1=="output_sha256" {print $2}' "$nuinui_candidate_state")
  [ "$(nuinui_candidate_sha256 "$nuinui_candidate_output")" = "$nuinui_candidate_expected_output" ] || { echo 'ERROR: stored result output hash mismatch'; return 1; }
  echo '🧾 NUINUI LAST RESULT'
  awk -F= '$1=="operation_id"||$1=="timestamp"||$1=="command"||$1=="lane"||$1=="issue"||$1=="claim"||$1=="request_sha256"||$1=="exit"||$1=="output_sha256" {print} $1=="result" {print "⭕ result=" $2} $1=="mutation" {print "mutation=" $2}' "$nuinui_candidate_state"
  printf 'recovery=READY\noutput_begin\n'
  cat "$nuinui_candidate_output"
  printf 'output_end\n'
}

nuinui_candidate_run_tracked() {
  nuinui_candidate_command=$1
  shift
  nuinui_candidate_display=$1
  shift
  nuinui_candidate_request_count=$1
  case "$nuinui_candidate_request_count" in ''|*[!0-9]*|0) echo 'ERROR: invalid command request arity; mutation was not started'; return 1 ;; esac
  shift
  nuinui_candidate_request_file=$(mktemp "${TMPDIR:-/tmp}/nuinui-context-request.XXXXXX") || { echo 'ERROR: unable to capture command request identity; mutation was not started'; return 1; }
  nuinui_candidate_remaining=$nuinui_candidate_request_count
  while [ "$nuinui_candidate_remaining" -gt 0 ]; do
    [ "$#" -gt 0 ] || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: invalid command request arity; mutation was not started'; return 1; }
    printf '%s\0' "$1" >>"$nuinui_candidate_request_file" || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: unable to capture command request identity; mutation was not started'; return 1; }
    shift
    nuinui_candidate_remaining=$((nuinui_candidate_remaining - 1))
  done
  [ "${1:-}" = --backend-- ] && [ "$#" -ge 2 ] || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: invalid tracked command backend boundary; mutation was not started'; return 1; }
  shift
  nuinui_candidate_backend=$1
  shift
  nuinui_candidate_repo=$(nuinui_candidate_result_repo)
  gr "$nuinui_candidate_repo" || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: result repository is unavailable'; return 1; }
  nuinui_candidate_gitdir=$(gd "$nuinui_candidate_repo") || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: unable to resolve result storage'; return 1; }
  nuinui_candidate_store=$nuinui_candidate_gitdir/nuinui-context-command-result-v1
  if [ -e "$nuinui_candidate_store" ] || [ -L "$nuinui_candidate_store" ]; then
    [ -d "$nuinui_candidate_store" ] && [ ! -L "$nuinui_candidate_store" ] || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: result store path is unsafe'; return 1; }
  fi
  for nuinui_candidate_file in state output; do
    if [ -e "$nuinui_candidate_store/$nuinui_candidate_file" ] || [ -L "$nuinui_candidate_store/$nuinui_candidate_file" ]; then
      [ -f "$nuinui_candidate_store/$nuinui_candidate_file" ] && [ ! -L "$nuinui_candidate_store/$nuinui_candidate_file" ] || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: result store file is unsafe'; return 1; }
    fi
  done
  if [ "${NUINUI_SELFTEST:-0}" = 1 ] && [ -n "${NUINUI_SELFTEST_REQUEST_HASH_FAILURE:-}" ]; then
    case "$NUINUI_SELFTEST_REQUEST_HASH_FAILURE" in
      fail) rm -f "$nuinui_candidate_request_file"; echo 'ERROR: unable to allocate request SHA-256; mutation was not started'; return 1 ;;
      malformed) nuinui_candidate_request=malformed ;;
      multiline) nuinui_candidate_request=$(printf '%064d\njunk' 0) ;;
    esac
  else
    nuinui_candidate_request=$(nuinui_candidate_sha256 "$nuinui_candidate_request_file") || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: unable to allocate request SHA-256; mutation was not started'; return 1; }
  fi
  [ "${#nuinui_candidate_request}" -eq 64 ] && printf '%s\n' "$nuinui_candidate_request" | grep -Eq '^[0-9a-f]{64}$' || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: invalid request SHA-256; mutation was not started'; return 1; }
  nuinui_candidate_operation=$(nuinui_candidate_operation_id) || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: unable to allocate command operation ID; mutation was not started'; return 1; }
  [ "${#nuinui_candidate_operation}" -eq 40 ] && printf '%s\n' "$nuinui_candidate_operation" | grep -Eq '^[0-9a-f]{40}$' || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: invalid command operation ID; mutation was not started'; return 1; }
  nuinui_candidate_timestamp=$(nuinui_candidate_timestamp) || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: unable to allocate command timestamp; mutation was not started'; return 1; }
  [ "${#nuinui_candidate_timestamp}" -eq 20 ] && printf '%s\n' "$nuinui_candidate_timestamp" | grep -Eq '^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$' || { rm -f "$nuinui_candidate_request_file"; echo 'ERROR: invalid command timestamp; mutation was not started'; return 1; }
  rm -f "$nuinui_candidate_request_file"
  if [ ! -e "$nuinui_candidate_store" ]; then
    (umask 077; mkdir "$nuinui_candidate_store") || { echo 'ERROR: unable to create result store; mutation was not started'; return 1; }
  fi
  nuinui_candidate_started=$(mktemp "$nuinui_candidate_store/.state.XXXXXX") || return 1
  (umask 077; printf 'version=1\noperation_id=%s\ntimestamp=%s\ncommand=%s\nphase=STARTED\nresult=INCOMPLETE\nlane=dev-context\nissue=-\nclaim=-\nrequest_sha256=%s\nmutation=unknown\nexit=-\noutput_sha256=-\n' "$nuinui_candidate_operation" "$nuinui_candidate_timestamp" "$nuinui_candidate_command" "$nuinui_candidate_request" >"$nuinui_candidate_started") || { rm -f "$nuinui_candidate_started"; return 1; }
  mv -f "$nuinui_candidate_started" "$nuinui_candidate_store/state" || return 1
  nuinui_candidate_capture=$(mktemp "${TMPDIR:-/tmp}/nuinui-context-result.XXXXXX") || return 1
  "$nuinui_candidate_backend" "$@" >"$nuinui_candidate_capture" 2>&1 || nuinui_candidate_rc=$?
  nuinui_candidate_rc=${nuinui_candidate_rc:-0}
  nuinui_candidate_mutation=yes
  grep -Fqx 'mutation=no-op' "$nuinui_candidate_capture" && nuinui_candidate_mutation=no
  nuinui_candidate_result=SUCCESS
  if [ "$nuinui_candidate_rc" -ne 0 ]; then
    if grep -qE '^(BLOCKED:|ERROR:)' "$nuinui_candidate_capture"; then
      if grep -q '^BLOCKED:' "$nuinui_candidate_capture"; then nuinui_candidate_result=BLOCKED; else nuinui_candidate_result=ERROR; fi
      if [ "$nuinui_candidate_result" = BLOCKED ]; then
        nuinui_candidate_mutation=no
      else
        nuinui_candidate_mutation=unknown
      fi
    else nuinui_candidate_result=ERROR; nuinui_candidate_mutation=unknown
    fi
  fi
  nuinui_candidate_first_line=$(sed -n '1p' "$nuinui_candidate_capture")
  case "$nuinui_candidate_first_line" in
    'DEV-CONTEXT ALREADY TRANSITIONED') nuinui_candidate_display='♻️ DEV-CONTEXT ALREADY TRANSITIONED' ;;
    'DEV-CONTEXT TRANSITIONED') nuinui_candidate_display='🔀 DEV-CONTEXT TRANSITIONED' ;;
    'CONTEXT SYNCED') nuinui_candidate_display='🔄 CONTEXT SYNCED' ;;
    *) nuinui_candidate_display="⛔ $nuinui_candidate_command $nuinui_candidate_result" ;;
  esac
  nuinui_candidate_decorated=$(mktemp "${TMPDIR:-/tmp}/nuinui-context-result.XXXXXX") || { rm -f "$nuinui_candidate_capture"; return 1; }
  { printf '%s\n' "$nuinui_candidate_display"; cat "$nuinui_candidate_capture"; } >"$nuinui_candidate_decorated" || { rm -f "$nuinui_candidate_capture" "$nuinui_candidate_decorated"; return 1; }
  mv -f "$nuinui_candidate_decorated" "$nuinui_candidate_capture" || { rm -f "$nuinui_candidate_capture"; return 1; }
  nuinui_candidate_output_sha=$(nuinui_candidate_sha256 "$nuinui_candidate_capture") || { rm -f "$nuinui_candidate_capture"; return 1; }
  nuinui_candidate_final=$(mktemp "$nuinui_candidate_store/.state.XXXXXX") || { rm -f "$nuinui_candidate_capture"; return 1; }
  nuinui_candidate_output_temp=$(mktemp "$nuinui_candidate_store/.output.XXXXXX") || { rm -f "$nuinui_candidate_capture" "$nuinui_candidate_final"; return 1; }
  (umask 077; cat "$nuinui_candidate_capture" >"$nuinui_candidate_output_temp" && printf 'version=1\noperation_id=%s\ntimestamp=%s\ncommand=%s\nphase=TERMINAL\nresult=%s\nlane=dev-context\nissue=-\nclaim=-\nrequest_sha256=%s\nmutation=%s\nexit=%s\noutput_sha256=%s\n' "$nuinui_candidate_operation" "$nuinui_candidate_timestamp" "$nuinui_candidate_command" "$nuinui_candidate_result" "$nuinui_candidate_request" "$nuinui_candidate_mutation" "$nuinui_candidate_rc" "$nuinui_candidate_output_sha" >"$nuinui_candidate_final") || { rm -f "$nuinui_candidate_capture" "$nuinui_candidate_final" "$nuinui_candidate_output_temp"; return 1; }
  mv -f "$nuinui_candidate_output_temp" "$nuinui_candidate_store/output" && mv -f "$nuinui_candidate_final" "$nuinui_candidate_store/state" || { rm -f "$nuinui_candidate_capture" "$nuinui_candidate_final" "$nuinui_candidate_output_temp"; return 1; }
  cat "$nuinui_candidate_capture"
  printf '🧾 NUINUI COMMAND RESULT\n⭕ result=%s\nmutation=%s\nexit=%s\n' "$nuinui_candidate_result" "$nuinui_candidate_mutation" "$nuinui_candidate_rc"
  rm -f "$nuinui_candidate_capture"
  return "$nuinui_candidate_rc"
}

nuinui_candidate_run_readonly() {
  nuinui_candidate_heading=$1
  shift
  nuinui_candidate_capture=$(mktemp "${TMPDIR:-/tmp}/nuinui-context-readonly.XXXXXX") || { echo 'ERROR: unable to capture command output'; return 1; }
  nuinui_candidate_rc=0
  "$@" >"$nuinui_candidate_capture" 2>&1 || nuinui_candidate_rc=$?
  [ "$nuinui_candidate_rc" = 0 ] && printf '%s\n' "$nuinui_candidate_heading"
  cat "$nuinui_candidate_capture"
  rm -f "$nuinui_candidate_capture"
  return "$nuinui_candidate_rc"
}

nuinui_context_dev_next_parse() {
  context_next_seen=''
  context_next_old_branch= context_next_old_head= context_next_main= context_next_new_branch=
  while [ "$#" -gt 0 ]; do
    case "$1" in --old-branch) context_next_key=old_branch ;; --old-head) context_next_key=old_head ;; --main) context_next_key=main ;; --new-branch) context_next_key=new_branch ;; *) echo "ERROR: unknown option $1"; echo 'expected named options: --old-branch --old-head --main --new-branch'; return 2 ;; esac
    case " $context_next_seen " in *" $context_next_key "*) echo "ERROR: duplicate named option --$context_next_key"; return 2 ;; esac
    context_next_seen="$context_next_seen $context_next_key"
    [ "$#" -ge 2 ] && [ -n "$2" ] || { echo "ERROR: named option --$context_next_key requires a non-empty value"; return 2; }
    case "$2" in --*) echo "ERROR: named option --$context_next_key is missing its value before $2"; return 2 ;; esac
    case "$context_next_key" in old_branch) context_next_old_branch=$2 ;; old_head) context_next_old_head=$2 ;; main) context_next_main=$2 ;; new_branch) context_next_new_branch=$2 ;; esac
    shift 2
  done
  for context_next_key in old_branch old_head main new_branch; do
    case " $context_next_seen " in *" $context_next_key "*) ;; *) echo "ERROR: missing required named option --$context_next_key"; return 2 ;; esac
  done
}

set -- "$@"
case "${1:-}" in
  ''|-h|--help|help) nuinui_candidate_usage; exit 0 ;;
  context-audit) [ "$#" = 3 ] || { echo 'Usage: nuinui-context context-audit <expected-main> <expected-artifact-blob>'; exit 2; }; nuinui_candidate_run_readonly '🔎 AUDIT COMPLETE' context_audit_command "$2" "$3"; exit $? ;;
  context-sync) [ "$#" = 3 ] || { echo 'Usage: nuinui-context context-sync <expected-main> <expected-artifact-blob>'; exit 2; }; nuinui_candidate_run_tracked context-sync '🔄 CONTEXT SYNCED' 3 context-sync "$2" "$3" --backend-- sy "$2" "$3"; exit $? ;;
  context-dev-audit) [ "$#" = 3 ] || { echo 'Usage: nuinui-context context-dev-audit <expected-branch> <expected-head>'; exit 2; }; nuinui_candidate_run_readonly '🔎 DEV-CONTEXT AUDIT COMPLETE' context_dev_audit_command "$2" "$3"; exit $? ;;
  context-dev-transition) [ "$#" = 5 ] || { echo 'Usage: nuinui-context context-dev-transition <old-branch> <old-head> <main> <new-branch>'; exit 2; }; nuinui_candidate_run_tracked context-dev-transition '🔀 DEV-CONTEXT TRANSITIONED' 5 context-dev-transition "$2" "$3" "$4" "$5" --backend-- context_dev_transition_command "$2" "$3" "$4" "$5"; exit $? ;;
  context-dev-next) shift; nuinui_context_dev_next_parse "$@" || exit $?; nuinui_candidate_run_tracked context-dev-transition '🔀 DEV-CONTEXT TRANSITIONED' "$(( $# + 1 ))" context-dev-transition "$@" --backend-- context_dev_next_command "$context_next_old_branch" "$context_next_old_head" "$context_next_main" "$context_next_new_branch"; exit $? ;;
  context-check) [ "$#" = 1 ] || { nuinui_candidate_usage; exit 2; }; context_check_command; exit $? ;;
  last-result) [ "$#" = 1 ] || { echo 'Usage: nuinui-context last-result'; exit 2; }; nuinui_candidate_last_result; exit $? ;;
  *) echo "ERROR: unknown command: $1"; nuinui_candidate_usage; exit 2 ;;
esac
