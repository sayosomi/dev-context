# nuinuiCAD Human-test adapter. Exact-ref marker/receipt and idle transition
# mechanics are owned by shared human-test-core.sh.

e2e_path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

e2e_regular_file() {
  [ -f "$1" ] && [ ! -L "$1" ]
}

e2e_read_session() {
  local path=$1 source_fixture issue ref root handoff cdp_port launch_pid
  e2e_regular_file "$path" || return 1
  if nuinui_ownership_validate_exact_file "$path" issue,ref,source_fixture,root,handoff,cdp_port,launch_pid; then
    source_fixture=$(nuinui_ownership_field "$path" source_fixture) || return 1
    case "$source_fixture" in /*) ;; *) return 1 ;; esac
  elif ! nuinui_ownership_validate_exact_file "$path" issue,ref,root,handoff,cdp_port,launch_pid; then
    return 1
  fi
  issue=$(nuinui_ownership_field "$path" issue) || return 1
  ref=$(nuinui_ownership_field "$path" ref) || return 1
  root=$(nuinui_ownership_field "$path" root) || return 1
  handoff=$(nuinui_ownership_field "$path" handoff) || return 1
  cdp_port=$(nuinui_ownership_field "$path" cdp_port) || return 1
  launch_pid=$(nuinui_ownership_field "$path" launch_pid) || return 1
  nuinui_ownership_valid_issue "$issue" && nuinui_ownership_valid_sha "$ref" || return 1
  [ -n "$root" ] && [ -n "$handoff" ] || return 1
  printf '%s\n' "$cdp_port" | grep -Eq '^[0-9]+$' || return 1
  printf '%s\n' "$launch_pid" | grep -Eq '^[0-9]+$' || return 1
  printf '%s %s %s %s %s %s\n' "$issue" "$ref" "$root" "$handoff" "$cdp_port" "$launch_pid"
}

e2e_duplicate_session_matches() {
  local repo=$1 issue=$2 ref=$3 session
  session=$(ep "$repo")
  if ! e2e_path_exists "$session"; then return 0; fi
  set -- $(e2e_read_session "$session") || return 1
  [ "$1" = "$issue" ] && [ "$2" = "$ref" ]
}

fixed_2plus1_profile_human_test_preflight() {
  local repo=$E branch dirty marker
  echo "e2e path=$repo"
  gr "$repo" || return 1
  branch=$(bn "$repo")
  dirty=$(git -C "$repo" status --porcelain)
  marker=$(mp "$repo")
  echo "  branch=${branch:-DETACHED}"
  echo "  head=$(hh "$repo")"
  echo "  clean=$([ -z "$dirty" ] && echo yes || echo no) marker=$([ -f "$marker" ] && echo present || echo none)"
  [ ! -f "$marker" ] || sed 's/^/    /' "$marker"
  [ -z "$dirty" ]
}

fixed_2plus1_profile_human_test_start_guard() {
  local repo=$1 issue=$2 ref=$3 mode=$4
  case "$mode" in
    active)
      e2e_path_exists "$(ep "$repo")" && {
        echo 'BLOCKED: E2E start requires a valid clean detached checkout with no session'
        return 1
      }
      return 0
      ;;
    duplicate)
      e2e_duplicate_session_matches "$repo" "$issue" "$ref" || {
        echo 'BLOCKED: duplicate E2E start session is malformed or conflicts with marker'
        return 1
      }
      ;;
    *) return 1 ;;
  esac
}

fixed_2plus1_profile_human_test_release_guard() {
  local repo=$1 issue=$2 ref=$3 mode=$4 stage=$5
  if [ "$mode" = duplicate ]; then
    e2e_path_exists "$(ep "$repo")" && {
      echo 'BLOCKED: duplicate E2E release requires no session metadata'
      return 1
    }
    return 0
  fi
  if e2e_path_exists "$(ep "$repo")"; then
    if [ "$stage" = after-fetch ]; then
      echo 'BLOCKED: E2E session metadata appeared after fetch'
    else
      echo 'BLOCKED: E2E session metadata must be cleaned up before release'
    fi
    return 1
  fi
}

es() {
  fixed_2plus1_human_test_start "$1" "$2" 'E2E STARTED' 'E2E ALREADY STARTED'
}

el() {
  local issue=$1 ref=$2
  nuinui_ownership_valid_issue "$issue" &&
    nuinui_ownership_valid_sha "$ref" &&
    fm "$M" &&
    [ "$(git -C "$M" branch --show-current)" = codex/interim-sequential ] &&
    cn "$M" && [ "$(hh "$M")" = "$ref" ] &&
    an "$M" "$(om "$M")" "$ref" || return 1
  es "$issue" "$ref"
}

ee() {
  local output rc
  output=
  rc=0
  output=$(fixed_2plus1_human_test_release "$1" "$2" 'E2E RELEASED' 'E2E ALREADY RELEASED' 2>&1) || rc=$?
  printf '%s\n' "$output" | sed 's/^origin_default=/origin_main=/'
  return "$rc"
}
