e2e_path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

e2e_regular_file() {
  [ -f "$1" ] && [ ! -L "$1" ]
}

e2e_receipt_path() {
  printf '%s/nuinui-e2e-release-receipt\n' "$(gd "$1")"
}

e2e_resolve_ref() {
  local r="$1"
  local f="$2"
  local h=""

  h="$(git -C "$r" rev-parse "$f^{commit}" 2>/dev/null)" || return 1
  nuinui_ownership_valid_sha "$h" || return 1
  printf '%s\n' "$h"
}

e2e_read_marker() {
  local p="$1"

  e2e_regular_file "$p" || return 1
  set -- $(nuinui_ownership_read_fields "$p" issue,ref) || return 1
  [ "$#" = 2 ] || return 1
  nuinui_ownership_valid_issue "$1" || return 1
  nuinui_ownership_valid_sha "$2" || return 1
  printf '%s %s\n' "$1" "$2"
}

e2e_read_session() {
  local p="$1"

  e2e_regular_file "$p" || return 1
  set -- $(nuinui_ownership_read_fields "$p" issue,ref,root,handoff,cdp_port,launch_pid) || return 1
  [ "$#" = 6 ] || return 1
  nuinui_ownership_valid_issue "$1" || return 1
  nuinui_ownership_valid_sha "$2" || return 1
  [ -n "$3" ] || return 1
  [ -n "$4" ] || return 1
  printf '%s\n' "$5" | grep -Eq '^[0-9]+$' || return 1
  printf '%s\n' "$6" | grep -Eq '^[0-9]+$' || return 1
  printf '%s %s %s %s %s %s\n' "$1" "$2" "$3" "$4" "$5" "$6"
}

e2e_read_receipt() {
  local p="$1"

  e2e_regular_file "$p" || return 1
  set -- $(nuinui_ownership_read_fields "$p" version,issue,ref) || return 1
  [ "$#" = 3 ] || return 1
  [ "$1" = 1 ] || return 1
  nuinui_ownership_valid_issue "$2" || return 1
  nuinui_ownership_valid_sha "$3" || return 1
  printf '%s %s %s\n' "$1" "$2" "$3"
}

e2e_checkout_identity() {
  local r="$1"

  gr "$r" &&
    ao "$r" "$RT" &&
    cn "$r" &&
    [ -z "$(bn "$r")" ]
}

e2e_checkout_matches() {
  local r="$1"
  local h="$2"

  e2e_checkout_identity "$r" &&
    [ "$(hh "$r" 2>/dev/null)" = "$h" ]
}

e2e_duplicate_session_matches() {
  local r="$1"
  local i="$2"
  local f="$3"
  local s=""

  s="$(ep "$r")"
  if ! e2e_path_exists "$s"; then
    return 0
  fi
  set -- $(e2e_read_session "$s") || return 1
  [ "$1" = "$i" ] && [ "$2" = "$f" ]
}

e2e_start_duplicate() {
  local i="$1"
  local f="$2"
  local r="$E"
  local k=""
  local s=""
  local marker_issue=""

  k="$(mp "$r")"
  s="$(ep "$r")"
  e2e_regular_file "$k" || {
    echo 'BLOCKED: duplicate E2E start requires a regular exact marker'
    return 1
  }
  set -- $(e2e_read_marker "$k") || {
    echo 'BLOCKED: duplicate E2E start marker is malformed'
    return 1
  }
  marker_issue=$1
  if [ "$marker_issue" != "$i" ] || [ "$2" != "$f" ]; then
    echo 'BLOCKED: duplicate E2E start marker does not match caller Issue/ref'
    echo "expected_issue=$marker_issue"
    echo "actual_issue=$i"
    echo "expected_ref=$2"
    echo "actual_ref=$f"
    return 1
  fi
  e2e_checkout_matches "$r" "$f" || {
    echo 'BLOCKED: duplicate E2E start checkout identity does not match marker ref'
    return 1
  }
  e2e_duplicate_session_matches "$r" "$i" "$f" || {
    echo 'BLOCKED: duplicate E2E start session is malformed or conflicts with marker'
    return 1
  }
  printf 'E2E ALREADY STARTED\nissue=%s\nref=%s\nclean=yes\nmutation=no-op\nstate=BUSY\n' "$i" "$f"
}

e2e_write_receipt() {
  local r="$1"
  local i="$2"
  local f="$3"
  local p=""

  p="$(e2e_receipt_path "$r")" || return 1
  if e2e_path_exists "$p" && ! e2e_regular_file "$p"; then
    return 1
  fi
  wa "$p" "version=1\nissue=$i\nref=$f\n" || return 1
  set -- $(e2e_read_receipt "$p") || return 1
  [ "$1 $2 $3" = "1 $i $f" ]
}

e2e_release_duplicate() {
  local i="$1"
  local f="$2"
  local r="$E"
  local s=""
  local p=""
  local receipt_issue=""
  local origin_main=""

  s="$(ep "$r")"
  p="$(e2e_receipt_path "$r")"
  e2e_path_exists "$s" && {
    echo 'BLOCKED: duplicate E2E release requires no session metadata'
    return 1
  }
  e2e_path_exists "$p" || {
    echo 'BLOCKED: E2E release marker is absent and the release receipt is missing'
    return 1
  }
  set -- $(e2e_read_receipt "$p") || {
    echo 'BLOCKED: E2E release receipt is malformed'
    return 1
  }
  receipt_issue=$2
  if [ "$receipt_issue" != "$i" ] || [ "$3" != "$f" ]; then
    echo 'BLOCKED: duplicate E2E release receipt does not match caller Issue/ref'
    echo "expected_issue=$receipt_issue"
    echo "actual_issue=$i"
    echo "expected_ref=$3"
    echo "actual_ref=$f"
    return 1
  fi
  e2e_checkout_identity "$r" || {
    echo 'BLOCKED: duplicate E2E release checkout identity is invalid'
    return 1
  }
  origin_main="$(am "$r")"
  nuinui_ownership_valid_sha "$origin_main" || {
    echo 'BLOCKED: duplicate E2E release could not read authoritative origin/main'
    return 1
  }
  [ "$(hh "$r" 2>/dev/null)" = "$origin_main" ] || {
    echo 'BLOCKED: duplicate E2E release HEAD is not authoritative origin/main'
    return 1
  }
  printf 'E2E ALREADY RELEASED\nissue=%s\nref=%s\norigin_main=%s\nclean=yes\nmutation=no-op\nstate=FREE\n' "$i" "$f" "$origin_main"
}

e2e_release_active() {
  local i="$1"
  local f="$2"
  local r="$E"
  local k=""
  local s=""
  local marker_issue=""
  local origin_main=""

  k="$(mp "$r")"
  s="$(ep "$r")"
  set -- $(e2e_read_marker "$k") || {
    echo 'BLOCKED: E2E release marker is malformed'
    return 1
  }
  marker_issue=$1
  if [ "$marker_issue" != "$i" ] || [ "$2" != "$f" ]; then
    echo 'BLOCKED: E2E release marker does not match caller Issue/ref'
    echo "expected_issue=$marker_issue"
    echo "actual_issue=$i"
    echo "expected_ref=$2"
    echo "actual_ref=$f"
    return 1
  fi
  e2e_path_exists "$s" && {
    echo 'BLOCKED: E2E session metadata must be cleaned up before release'
    return 1
  }
  e2e_checkout_matches "$r" "$f" || {
    echo 'BLOCKED: E2E release checkout identity is invalid'
    return 1
  }
  fp "$r" || {
    echo 'BLOCKED: E2E release fetch/prune failed'
    return 1
  }
  set -- $(e2e_read_marker "$k") || {
    echo 'BLOCKED: E2E release marker changed or became malformed after fetch'
    return 1
  }
  [ "$1" = "$i" ] && [ "$2" = "$f" ] || {
    echo 'BLOCKED: E2E release marker changed after fetch'
    return 1
  }
  e2e_path_exists "$s" && {
    echo 'BLOCKED: E2E session metadata appeared after fetch'
    return 1
  }
  e2e_checkout_matches "$r" "$f" || {
    echo 'BLOCKED: E2E release checkout changed after fetch'
    return 1
  }
  origin_main="$(am "$r")"
  nuinui_ownership_valid_sha "$origin_main" || {
    echo 'BLOCKED: E2E release could not read authoritative origin/main'
    return 1
  }
  e2e_write_receipt "$r" "$i" "$f" || {
    echo 'BLOCKED: could not atomically write the E2E release receipt; marker retained'
    return 1
  }
  sd "$r" "$origin_main" >/dev/null 2>&1 || {
    echo 'BLOCKED: could not detach E2E checkout to authoritative origin/main; marker retained'
    return 1
  }
  e2e_checkout_matches "$r" "$origin_main" || {
    echo 'BLOCKED: E2E checkout did not reach authoritative origin/main; marker retained'
    return 1
  }
  rm "$k" || {
    echo 'BLOCKED: could not remove E2E marker; release receipt retained'
    return 1
  }
  echo 'E2E RELEASED'
}

es() {
  local i="$1"
  local f="$2"
  local r="$E"
  local k=""
  local h=""
  local origin_main=""
  local current_head=""

  k="$(mp "$r")"
  nuinui_ownership_valid_issue "$i" || {
    echo 'BLOCKED: invalid E2E Issue'
    return 1
  }
  if e2e_path_exists "$k"; then
    h="$(e2e_resolve_ref "$r" "$f")" || {
      echo 'BLOCKED: tested-ref does not resolve to a commit in the E2E checkout'
      return 1
    }
    e2e_start_duplicate "$i" "$h"
    return $?
  fi
  gr "$r" &&
    ao "$r" "$RT" &&
    cn "$r" &&
    [ -z "$(bn "$r")" ] &&
    ! e2e_path_exists "$(ep "$r")" || {
      echo 'BLOCKED: E2E start requires a valid clean detached checkout with no session'
      return 1
    }
  fp "$r" || {
    echo 'BLOCKED: E2E start fetch/prune failed'
    return 1
  }
  origin_main="$(om "$r")" || {
    echo 'BLOCKED: E2E start could not read origin/main'
    return 1
  }
  nuinui_ownership_valid_sha "$origin_main" || {
    echo 'BLOCKED: E2E start origin/main is invalid'
    return 1
  }
  h="$(e2e_resolve_ref "$r" "$f")" || {
    echo 'BLOCKED: tested-ref does not resolve to a commit in the E2E checkout'
    return 1
  }
  current_head="$(hh "$r")" || return 1
  if [ "$current_head" != "$origin_main" ]; then
    an "$r" "$current_head" "$origin_main" && sd "$r" "$origin_main" >/dev/null 2>&1 || {
      echo 'BLOCKED: E2E checkout cannot safely return to origin/main'
      return 1
    }
  fi
  sd "$r" "$h" >/dev/null 2>&1 || {
    echo 'BLOCKED: E2E checkout cannot be fixed to tested-ref'
    return 1
  }
  wa "$k" "issue=$i\nref=$h\n" || {
    echo 'BLOCKED: could not atomically write E2E marker'
    return 1
  }
  e2e_read_marker "$k" >/dev/null || {
    echo 'BLOCKED: E2E marker verification failed'
    return 1
  }
  echo 'E2E STARTED'
}

el() {
  local i="$1"
  local f="$2"

  nuinui_ownership_valid_issue "$i" &&
    nuinui_ownership_valid_sha "$f" &&
    fm "$M" &&
    [ "$(git -C "$M" branch --show-current)" = codex/interim-sequential ] &&
    cn "$M" &&
    [ "$(hh "$M")" = "$f" ] &&
    an "$M" "$(om "$M")" "$f" || return 1
  es "$i" "$f"
}

ee() {
  local i="$1"
  local f="$2"
  local r="$E"
  local k=""

  k="$(mp "$r")"
  nuinui_ownership_valid_issue "$i" || {
    echo 'BLOCKED: invalid E2E Issue'
    return 1
  }
  nuinui_ownership_valid_sha "$f" || {
    echo 'BLOCKED: tested-ref must be a full commit SHA'
    return 1
  }
  f="$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')"
  if e2e_path_exists "$k"; then
    e2e_release_active "$i" "$f"
  else
    e2e_release_duplicate "$i" "$f"
  fi
}
