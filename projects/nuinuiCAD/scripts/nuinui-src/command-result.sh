# Durable recovery evidence for Human mutation commands.  This fragment wraps
# the public dispatch boundary without becoming an ownership authority.

nuinui_command_result_tracked() {
  case "$1" in
    lane-init|begin|start|resume|release|recover|pr-auto-merge|integrate-clean|e2e-start|e2e-start-local-main|e2e-release|context-sync|context-dev-transition) return 0 ;;
    *) return 1 ;;
  esac
}

nuinui_command_result_repo() {
  if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
    if [ -n "${NUINUI_SELFTEST_RESULT_REPO:-}" ]; then
      printf '%s\n' "$NUINUI_SELFTEST_RESULT_REPO"
      return 0
    fi
    [ -n "${C:-}" ] || return 1
    nuinui_command_result_selftest_parent=$(CDPATH= cd -- "$(dirname -- "$C")" 2>/dev/null && pwd -P) || return 1
    printf '%s/nuinui-selftest-dev-context\n' "$nuinui_command_result_selftest_parent"
    return 0
  fi
  [ -n "${C:-}" ] || return 1
  printf '%s\n' "$C"
}

nuinui_command_result_ensure_repo() {
  nuinui_command_result_repo_path=$1
  if [ "${NUINUI_SELFTEST:-0}" = 1 ] && ! gr "$nuinui_command_result_repo_path"; then
    (umask 077; git init -q "$nuinui_command_result_repo_path") >/dev/null 2>&1 || return 1
  fi
  gr "$nuinui_command_result_repo_path"
}

nuinui_command_result_target_safe() {
  if [ -e "$1" ] || [ -L "$1" ]; then
    [ -f "$1" ] && [ ! -L "$1" ] || return 1
  fi
}

nuinui_command_result_store_dir_safe() {
  if [ -e "$1" ] || [ -L "$1" ]; then
    [ -d "$1" ] && [ ! -L "$1" ] || return 1
  fi
}

nuinui_command_result_prepare_store() {
  nuinui_command_result_for_write=$1
  nuinui_command_result_repo_path=$(nuinui_command_result_repo) || return 1
  if [ "$nuinui_command_result_for_write" = 1 ]; then
    nuinui_command_result_ensure_repo "$nuinui_command_result_repo_path" || return 1
  else
    gr "$nuinui_command_result_repo_path" || return 2
  fi
  nuinui_command_result_git_dir=$(gd "$nuinui_command_result_repo_path") || return 1
  [ -n "$nuinui_command_result_git_dir" ] || return 1
  nuinui_command_result_dir=$nuinui_command_result_git_dir/nuinui-command-result-v1
  if [ "$nuinui_command_result_for_write" = 1 ] &&
    [ ! -e "$nuinui_command_result_dir" ] && [ ! -L "$nuinui_command_result_dir" ]; then
    (umask 077; mkdir "$nuinui_command_result_dir") 2>/dev/null || {
      nuinui_command_result_store_dir_safe "$nuinui_command_result_dir" || return 1
    }
  fi
  nuinui_command_result_store_dir_safe "$nuinui_command_result_dir" || return 1
  nuinui_command_result_state=$nuinui_command_result_dir/state
  nuinui_command_result_output=$nuinui_command_result_dir/output
  nuinui_command_result_target_safe "$nuinui_command_result_state" || return 1
  nuinui_command_result_target_safe "$nuinui_command_result_output" || return 1
}

nuinui_command_result_write_text() {
  nuinui_command_result_write_target=$1
  nuinui_command_result_write_value=$2
  nuinui_command_result_target_safe "$nuinui_command_result_write_target" || return 1
  nuinui_command_result_write_dir=${nuinui_command_result_write_target%/*}
  nuinui_command_result_write_temp=$(mktemp "$nuinui_command_result_write_dir/.nuinui-command-result.XXXXXX") || return 1
  if ! (umask 077; printf '%s\n' "$nuinui_command_result_write_value" > "$nuinui_command_result_write_temp"); then
    rm -f -- "$nuinui_command_result_write_temp"
    return 1
  fi
  [ -f "$nuinui_command_result_write_temp" ] && [ ! -L "$nuinui_command_result_write_temp" ] || {
    rm -f -- "$nuinui_command_result_write_temp"
    return 1
  }
  mv -f -- "$nuinui_command_result_write_temp" "$nuinui_command_result_write_target" || {
    rm -f -- "$nuinui_command_result_write_temp"
    return 1
  }
  [ -f "$nuinui_command_result_write_target" ] && [ ! -L "$nuinui_command_result_write_target" ]
}

nuinui_command_result_replace_output() {
  nuinui_command_result_copy_target=$1
  nuinui_command_result_copy_source=$2
  nuinui_command_result_target_safe "$nuinui_command_result_copy_target" || return 1
  [ -f "$nuinui_command_result_copy_source" ] && [ ! -L "$nuinui_command_result_copy_source" ] || return 1
  nuinui_command_result_copy_dir=${nuinui_command_result_copy_target%/*}
  nuinui_command_result_copy_temp=$(mktemp "$nuinui_command_result_copy_dir/.nuinui-command-result.XXXXXX") || return 1
  if ! (umask 077; cat "$nuinui_command_result_copy_source" > "$nuinui_command_result_copy_temp"); then
    rm -f -- "$nuinui_command_result_copy_temp"
    return 1
  fi
  mv -f -- "$nuinui_command_result_copy_temp" "$nuinui_command_result_copy_target" || {
    rm -f -- "$nuinui_command_result_copy_temp"
    return 1
  }
  [ -f "$nuinui_command_result_copy_target" ] && [ ! -L "$nuinui_command_result_copy_target" ]
}

nuinui_command_result_sha256() {
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  nuinui_command_result_digest=$(shasum -a 256 "$1" | awk 'NR == 1 {print $1}') || return 1
  printf '%s\n' "$nuinui_command_result_digest" | grep -Eq '^[0-9a-f]{64}$' || return 1
  printf '%s\n' "$nuinui_command_result_digest"
}

nuinui_command_result_operation_id() {
  nuinui_command_result_entropy=$(od -An -N16 -tx1 /dev/urandom 2>/dev/null || true)
  printf '%s:%s:%s:%s:%s\n' "$$" "${PPID:-0}" "$(date +%s)" "${RANDOM:-0}" "$nuinui_command_result_entropy" |
    git hash-object --stdin
}

nuinui_command_result_request_metadata() {
  nuinui_command_result_meta_command=$1
  nuinui_command_result_meta_lane=-
  nuinui_command_result_meta_issue=-
  nuinui_command_result_meta_claim=-
  case "$nuinui_command_result_meta_command" in
    lane-init) nuinui_command_result_meta_lane=$2 ;;
    begin|start)
      nuinui_command_result_meta_lane=$2
      nuinui_command_result_meta_issue=$3
      ;;
    resume)
      nuinui_command_result_meta_lane=$2
      nuinui_command_result_meta_issue=$3
      nuinui_command_result_meta_claim=$7
      ;;
    release)
      nuinui_command_result_meta_lane=$2
      nuinui_command_result_meta_claim=$4
      ;;
    recover)
      nuinui_command_result_meta_lane=$2
      nuinui_command_result_meta_claim=$3
      ;;
    integrate-clean)
      nuinui_command_result_meta_lane=$2
      nuinui_command_result_meta_issue=$3
      nuinui_command_result_meta_claim=$4
      ;;
    e2e-start|e2e-start-local-main|e2e-release)
      nuinui_command_result_meta_lane=${NUINUI_COMMAND_RESULT_LANE:--}
      if [ "$#" = 4 ]; then
        nuinui_command_result_meta_issue=$3
      else
        nuinui_command_result_meta_issue=$2
      fi
      ;;
    context-sync|context-dev-transition) nuinui_command_result_meta_lane=dev-context ;;
  esac
  case "$nuinui_command_result_meta_lane" in
    -|dev-context|[A-Za-z0-9._-]*) ;;
    *) nuinui_command_result_meta_lane=- ;;
  esac
  nuinui_ownership_valid_issue "$nuinui_command_result_meta_issue" || nuinui_command_result_meta_issue=-
  nuinui_ownership_valid_claim "$nuinui_command_result_meta_claim" || nuinui_command_result_meta_claim=-
}

nuinui_command_result_state_valid() {
  nuinui_command_result_state_file=$1
  awk '
    BEGIN {
      count=split("version operation_id timestamp command phase result lane issue claim request_sha256 mutation exit output_sha256", keys, " ")
      for (i=1; i<=count; i++) allowed[keys[i]]=1
    }
    {
      equals=index($0, "=")
      if (equals <= 1) { invalid=1; next }
      key=substr($0, 1, equals-1)
      value=substr($0, equals+1)
      if (!(key in allowed) || (key in seen) || value == "") invalid=1
      seen[key]=1
      values[key]=value
    }
    END {
      if (NR != count) invalid=1
      for (i=1; i<=count; i++) if (!(keys[i] in seen)) invalid=1
      if (values["version"] != "1") invalid=1
      if (values["operation_id"] !~ /^[0-9a-f]{40}$/) invalid=1
      if (values["timestamp"] !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) invalid=1
      if (values["command"] !~ /^(lane-init|begin|start|resume|release|recover|pr-auto-merge|integrate-clean|e2e-start|e2e-start-local-main|e2e-release|context-sync|context-dev-transition)$/) invalid=1
      if (values["phase"] !~ /^(STARTED|TERMINAL)$/) invalid=1
      if (values["result"] !~ /^(INCOMPLETE|SUCCESS|BLOCKED|ERROR)$/) invalid=1
      if (values["lane"] !~ /^([A-Za-z0-9._-]+|dev-context|-)$/) invalid=1
      if (values["issue"] !~ /^(SAY-[0-9]+|-)$/) invalid=1
      if (values["claim"] != "-" && values["claim"] !~ /^[0-9A-Za-z][0-9A-Za-z._-]{7,127}$/) invalid=1
      if (values["request_sha256"] !~ /^[0-9a-f]{64}$/) invalid=1
      if (values["mutation"] !~ /^(yes|no|unknown)$/) invalid=1
      if (values["exit"] != "-" && values["exit"] !~ /^[0-9]+$/) invalid=1
      if (values["output_sha256"] != "-" && values["output_sha256"] !~ /^[0-9a-f]{64}$/) invalid=1
      if (values["phase"] == "STARTED" && (values["result"] != "INCOMPLETE" || values["mutation"] != "unknown" || values["exit"] != "-" || values["output_sha256"] != "-")) invalid=1
      if (values["phase"] == "TERMINAL" && (values["result"] !~ /^(SUCCESS|BLOCKED|ERROR)$/ || values["exit"] == "-" || values["output_sha256"] !~ /^[0-9a-f]{64}$/)) invalid=1
      if (values["phase"] == "TERMINAL" && values["result"] == "SUCCESS" && values["exit"] + 0 != 0) invalid=1
      if (values["phase"] == "TERMINAL" && values["result"] ~ /^(BLOCKED|ERROR)$/ && values["exit"] + 0 == 0) invalid=1
      if (values["phase"] == "TERMINAL" && values["result"] == "SUCCESS") {
        if (values["command"] == "lane-init" && (values["lane"] !~ /^[A-Za-z0-9._-]+$/ || values["lane"] == "-" || values["issue"] != "-" || values["claim"] != "-")) invalid=1
        if (values["command"] ~ /^(begin|start)$/ && (values["lane"] !~ /^[A-Za-z0-9._-]+$/ || values["lane"] == "-" || values["issue"] !~ /^SAY-[0-9]+$/ || values["claim"] != "-")) invalid=1
        if (values["command"] == "resume" && (values["lane"] !~ /^[A-Za-z0-9._-]+$/ || values["lane"] == "-" || values["issue"] !~ /^SAY-[0-9]+$/ || values["claim"] == "-")) invalid=1
        if (values["command"] ~ /^(release|recover)$/ && (values["lane"] !~ /^[A-Za-z0-9._-]+$/ || values["lane"] == "-" || values["issue"] != "-" || values["claim"] == "-")) invalid=1
        if (values["command"] == "pr-auto-merge" && (values["lane"] != "-" || values["issue"] != "-" || values["claim"] != "-")) invalid=1
        if (values["command"] == "integrate-clean" && (values["lane"] !~ /^[A-Za-z0-9._-]+$/ || values["lane"] == "-" || values["issue"] !~ /^SAY-[0-9]+$/ || values["claim"] == "-")) invalid=1
        if (values["command"] ~ /^(e2e-start|e2e-start-local-main|e2e-release)$/ && (values["lane"] !~ /^[A-Za-z0-9._-]+$/ || values["lane"] == "-" || values["issue"] !~ /^SAY-[0-9]+$/ || values["claim"] != "-")) invalid=1
        if (values["command"] ~ /^(context-sync|context-dev-transition)$/ && (values["lane"] != "dev-context" || values["issue"] != "-" || values["claim"] != "-")) invalid=1
      }
      if (invalid) exit 1
    }
  ' "$nuinui_command_result_state_file"
}

nuinui_command_result_has_trailing_newline() {
  [ ! -s "$1" ] && return 1
  nuinui_command_result_last_byte=$(tail -c 1 "$1" | od -An -t x1 | tr -d '[:space:]')
  [ "$nuinui_command_result_last_byte" = 0a ]
}

nuinui_command_result_canonical_blocked() {
  awk '/^BLOCKED:/ || /^[A-Z][A-Z0-9 _-]* BLOCKED$/ {found=1} END {exit !found}' "$1"
}

nuinui_command_result_line() {
  grep -Eq "$2" "$1"
}

nuinui_command_result_run() {
  nuinui_command_result_command=$1
  nuinui_command_result_argument_count=$2
  shift 2
  nuinui_command_result_request_metadata "$@"
  case "$nuinui_command_result_argument_count" in ''|*[!0-9]*) printf 'ERROR: invalid command request arity\n'; return 1 ;; esac
  nuinui_command_result_prepare_store 1 || {
    printf 'ERROR: command result store is unsafe or unavailable; mutation was not started\n'
    return 1
  }
  nuinui_command_result_operation=$(nuinui_command_result_operation_id) || {
    printf 'ERROR: unable to allocate command result operation identity; mutation was not started\n'
    return 1
  }
  nuinui_command_result_timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ') || {
    printf 'ERROR: unable to allocate command result timestamp; mutation was not started\n'
    return 1
  }
  nuinui_command_result_request_file=$(mktemp "${TMPDIR:-/tmp}/nuinui-command-request.XXXXXX") || {
    printf 'ERROR: unable to capture command request identity; mutation was not started\n'
    return 1
  }
  nuinui_command_result_request_index=0
  while [ "$nuinui_command_result_request_index" -lt "$nuinui_command_result_argument_count" ]; do
    printf '%s\0' "$1" >> "$nuinui_command_result_request_file" || {
      rm -f -- "$nuinui_command_result_request_file"
      printf 'ERROR: unable to capture command request identity; mutation was not started\n'
      return 1
    }
    shift
    nuinui_command_result_request_index=$((nuinui_command_result_request_index + 1))
  done
  nuinui_command_result_request_sha=$(nuinui_command_result_sha256 "$nuinui_command_result_request_file") || {
    rm -f -- "$nuinui_command_result_request_file"
    printf 'ERROR: unable to hash command request identity; mutation was not started\n'
    return 1
  }
  nuinui_command_result_started_state=$(printf 'version=1\noperation_id=%s\ntimestamp=%s\ncommand=%s\nphase=STARTED\nresult=INCOMPLETE\nlane=%s\nissue=%s\nclaim=%s\nrequest_sha256=%s\nmutation=unknown\nexit=-\noutput_sha256=-\n' \
    "$nuinui_command_result_operation" "$nuinui_command_result_timestamp" "$nuinui_command_result_command" \
    "$nuinui_command_result_meta_lane" "$nuinui_command_result_meta_issue" "$nuinui_command_result_meta_claim" \
    "$nuinui_command_result_request_sha")
  nuinui_command_result_write_text "$nuinui_command_result_state" "$nuinui_command_result_started_state" || {
    rm -f -- "$nuinui_command_result_request_file"
    printf 'ERROR: unable to durably establish STARTED command result; mutation was not started\n'
    return 1
  }
  nuinui_command_result_capture=$(mktemp "${TMPDIR:-/tmp}/nuinui-command-output.XXXXXX") || {
    rm -f -- "$nuinui_command_result_request_file"
    printf 'ERROR: command result output capture is unavailable; mutation did not execute\n'
    return 1
  }
  nuinui_command_result_underlying_rc=0
  "$@" >"$nuinui_command_result_capture" 2>&1 || nuinui_command_result_underlying_rc=$?
  if [ "$nuinui_command_result_underlying_rc" = 0 ] && [ "${nuinui_forensic_option_active:-0}" = 1 ]; then
    nuinui_command_result_has_trailing_newline "$nuinui_command_result_capture" || [ ! -s "$nuinui_command_result_capture" ] || printf '\n' >> "$nuinui_command_result_capture"
    printf 'forensic_exception=active\nforensic_worktree=%s\n' "$nuinui_forensic_worktree" >> "$nuinui_command_result_capture"
  fi
  if [ ! -s "$nuinui_command_result_capture" ]; then
    printf 'ERROR: public command %s failed without a diagnostic\n' "$nuinui_command_result_command" > "$nuinui_command_result_capture"
  fi
  nuinui_command_result_output_sha=$(nuinui_command_result_sha256 "$nuinui_command_result_capture") || {
    rm -f -- "$nuinui_command_result_request_file" "$nuinui_command_result_capture"
    printf 'ERROR: unable to hash canonical command output; result is INCOMPLETE\n'
    return 1
  }
  if nuinui_command_result_line "$nuinui_command_result_capture" '^mutation=no-op$'; then
    nuinui_command_result_mutation=no
  elif nuinui_command_result_line "$nuinui_command_result_capture" '^mutation_state=COMPLETED$'; then
    nuinui_command_result_mutation=yes
  elif nuinui_command_result_line "$nuinui_command_result_capture" '^mutation_state=UNKNOWN$'; then
    nuinui_command_result_mutation=unknown
  elif [ "$nuinui_command_result_underlying_rc" = 0 ]; then
    nuinui_command_result_mutation=yes
  elif [ "$nuinui_command_result_command" = integrate-clean ] && {
    nuinui_command_result_line "$nuinui_command_result_capture" '^ERROR: integration push failed after verified merge commit$' ||
    nuinui_command_result_line "$nuinui_command_result_capture" '^ERROR: integration push read-back mismatch$' ||
    nuinui_command_result_line "$nuinui_command_result_capture" '^ERROR: pushed integration lane state could not be proven$';
  }; then
    nuinui_command_result_mutation=yes
  elif nuinui_command_result_canonical_blocked "$nuinui_command_result_capture"; then
    case "$nuinui_command_result_command" in
      begin|integrate-clean|context-sync|context-dev-transition) nuinui_command_result_mutation=no ;;
      *) nuinui_command_result_mutation=unknown ;;
    esac
  else
    nuinui_command_result_mutation=unknown
  fi
  if [ "$nuinui_command_result_underlying_rc" = 0 ]; then
    nuinui_command_result_result=SUCCESS
  elif nuinui_command_result_canonical_blocked "$nuinui_command_result_capture"; then
    nuinui_command_result_result=BLOCKED
  else
    nuinui_command_result_result=ERROR
  fi
  nuinui_command_result_replace_output "$nuinui_command_result_output" "$nuinui_command_result_capture" || {
    rm -f -- "$nuinui_command_result_request_file" "$nuinui_command_result_capture"
    printf 'ERROR: unable to durably store canonical command output; result is INCOMPLETE\n'
    return 1
  }
  nuinui_command_result_terminal_state=$(printf 'version=1\noperation_id=%s\ntimestamp=%s\ncommand=%s\nphase=TERMINAL\nresult=%s\nlane=%s\nissue=%s\nclaim=%s\nrequest_sha256=%s\nmutation=%s\nexit=%s\noutput_sha256=%s\n' \
    "$nuinui_command_result_operation" "$nuinui_command_result_timestamp" "$nuinui_command_result_command" \
    "$nuinui_command_result_result" "$nuinui_command_result_meta_lane" "$nuinui_command_result_meta_issue" \
    "$nuinui_command_result_meta_claim" "$nuinui_command_result_request_sha" "$nuinui_command_result_mutation" \
    "$nuinui_command_result_underlying_rc" "$nuinui_command_result_output_sha")
  nuinui_command_result_write_text "$nuinui_command_result_state" "$nuinui_command_result_terminal_state" || {
    rm -f -- "$nuinui_command_result_request_file" "$nuinui_command_result_capture"
    printf 'ERROR: unable to durably finalize command result state; result is INCOMPLETE\n'
    return 1
  }
  cat "$nuinui_command_result_capture"
  nuinui_command_result_has_trailing_newline "$nuinui_command_result_capture" || [ ! -s "$nuinui_command_result_capture" ] || printf '\n'
  printf '===== NUINUI COMMAND RESULT =====\noperation_id=%s\ncommand=%s\nresult=%s\nmutation=%s\nexit=%s\n===== END NUINUI COMMAND RESULT =====\n' \
    "$nuinui_command_result_operation" "$nuinui_command_result_command" "$nuinui_command_result_result" \
    "$nuinui_command_result_mutation" "$nuinui_command_result_underlying_rc"
  rm -f -- "$nuinui_command_result_request_file" "$nuinui_command_result_capture"
  return "$nuinui_command_result_underlying_rc"
}

nuinui_command_result_last_failure() {
  printf '===== NUINUI LAST RESULT =====\nrecovery=%s\nresult=%s\ndiagnostic=%s\n===== END NUINUI LAST RESULT =====\n' "$1" "$2" "$3"
}

nuinui_command_result_last_result() {
  nuinui_command_result_prepare_store 0
  nuinui_command_result_read_store_rc=$?
  if [ "$nuinui_command_result_read_store_rc" = 2 ]; then
    nuinui_command_result_last_failure NONE NONE 'no command result is stored'
    return 1
  fi
  if [ "$nuinui_command_result_read_store_rc" != 0 ]; then
    nuinui_command_result_last_failure INVALID INVALID 'command result store path is unsafe or unavailable'
    return 1
  fi
  if [ ! -e "$nuinui_command_result_state" ] && [ ! -L "$nuinui_command_result_state" ]; then
    if [ ! -e "$nuinui_command_result_output" ] && [ ! -L "$nuinui_command_result_output" ]; then
      nuinui_command_result_last_failure NONE NONE 'no command result is stored'
    else
      nuinui_command_result_last_failure INVALID INVALID 'command result output exists without state'
    fi
    return 1
  fi
  nuinui_command_result_state_valid "$nuinui_command_result_state" || {
    nuinui_command_result_last_failure INVALID INVALID 'stored state does not match the strict version=1 schema'
    return 1
  }
  nuinui_command_result_phase=$(nuinui_ownership_field "$nuinui_command_result_state" phase) || return 1
  nuinui_command_result_operation=$(nuinui_ownership_field "$nuinui_command_result_state" operation_id) || return 1
  nuinui_command_result_timestamp=$(nuinui_ownership_field "$nuinui_command_result_state" timestamp) || return 1
  nuinui_command_result_command=$(nuinui_ownership_field "$nuinui_command_result_state" command) || return 1
  nuinui_command_result_result=$(nuinui_ownership_field "$nuinui_command_result_state" result) || return 1
  nuinui_command_result_lane=$(nuinui_ownership_field "$nuinui_command_result_state" lane) || return 1
  nuinui_command_result_issue=$(nuinui_ownership_field "$nuinui_command_result_state" issue) || return 1
  nuinui_command_result_claim=$(nuinui_ownership_field "$nuinui_command_result_state" claim) || return 1
  nuinui_command_result_request_sha=$(nuinui_ownership_field "$nuinui_command_result_state" request_sha256) || return 1
  nuinui_command_result_mutation=$(nuinui_ownership_field "$nuinui_command_result_state" mutation) || return 1
  nuinui_command_result_exit=$(nuinui_ownership_field "$nuinui_command_result_state" exit) || return 1
  nuinui_command_result_output_sha=$(nuinui_ownership_field "$nuinui_command_result_state" output_sha256) || return 1
  if [ "$nuinui_command_result_phase" = STARTED ]; then
    printf '===== NUINUI LAST RESULT =====\noperation_id=%s\ntimestamp=%s\ncommand=%s\nresult=INCOMPLETE\nlane=%s\nissue=%s\nclaim=%s\nrequest_sha256=%s\nmutation=unknown\nexit=-\noutput_sha256=-\nrecovery=BLOCKED\ndiagnostic=tracked mutation did not reach terminal finalization\n===== END NUINUI LAST RESULT =====\n' \
      "$nuinui_command_result_operation" "$nuinui_command_result_timestamp" "$nuinui_command_result_command" \
      "$nuinui_command_result_lane" "$nuinui_command_result_issue" "$nuinui_command_result_claim" "$nuinui_command_result_request_sha"
    return 1
  fi
  [ -f "$nuinui_command_result_output" ] && [ ! -L "$nuinui_command_result_output" ] || {
    nuinui_command_result_last_failure INVALID INVALID 'terminal result output is missing or unsafe'
    return 1
  }
  nuinui_command_result_actual_output_sha=$(nuinui_command_result_sha256 "$nuinui_command_result_output") || {
    nuinui_command_result_last_failure INVALID INVALID 'terminal result output could not be hashed'
    return 1
  }
  [ "$nuinui_command_result_actual_output_sha" = "$nuinui_command_result_output_sha" ] || {
    nuinui_command_result_last_failure INVALID INVALID 'terminal result output hash does not match state'
    return 1
  }
  printf '===== NUINUI LAST RESULT =====\noperation_id=%s\ntimestamp=%s\ncommand=%s\nresult=%s\nlane=%s\nissue=%s\nclaim=%s\nrequest_sha256=%s\nmutation=%s\nexit=%s\noutput_sha256=%s\nrecovery=READY\noutput_begin\n' \
    "$nuinui_command_result_operation" "$nuinui_command_result_timestamp" "$nuinui_command_result_command" \
    "$nuinui_command_result_result" "$nuinui_command_result_lane" "$nuinui_command_result_issue" \
    "$nuinui_command_result_claim" "$nuinui_command_result_request_sha" "$nuinui_command_result_mutation" \
    "$nuinui_command_result_exit" "$nuinui_command_result_output_sha"
  cat "$nuinui_command_result_output"
  nuinui_command_result_has_trailing_newline "$nuinui_command_result_output" || [ ! -s "$nuinui_command_result_output" ] || printf '\n'
  printf 'output_end\n===== END NUINUI LAST RESULT =====\n'
}
