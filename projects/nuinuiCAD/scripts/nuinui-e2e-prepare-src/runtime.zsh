# E2E preparation runtime context, lane selection, and strict metadata helpers.
VERSION="1.5.0"
E2E_HELPER_INVOCATION="$0"
E2E_WT=""
E2E_LANE=""
VS_CODE_APP="${NUINUI_E2E_VSCODE_APP-/Applications/Visual Studio Code.app}"
DEFAULT_CDP_PORT="${NUINUI_E2E_CDP_PORT-9223}"
E2E_TEMP_PARENT="${NUINUI_E2E_TEMP_PARENT-/private/tmp}"
JAPANESE_LANGUAGE_PACK='MS-CEINTL.vscode-language-pack-ja'
CURRENT_SESSION_KEYS='lane,issue,ref,source_fixture,root,handoff,cdp_port,launch_pid,locale'
PRE_LOCALE_SESSION_KEYS='lane,issue,ref,source_fixture,root,handoff,cdp_port,launch_pid'
LEGACY_SESSION_KEYS='issue,ref,root,handoff,cdp_port,launch_pid'
CLEANUP_RECEIPT_KEYS='version,issue,ref,root'
HANDOFF_KEYS='LANE,ISSUE,TESTED_REF,CHECKOUT,E2E_ROOT,FIXTURE,CDP_PORT,RUST_BIN'
VS_CODE_APP_REAL=''
VS_CODE_APPLICATION_EXECUTABLE=''

e2e_context() {
  E2E_MANIFEST="$(lane_standalone_context_manifest "$E2E_HELPER_INVOCATION" \
    "${NUINUI_E2E_SELFTEST:-0}" "${NUINUI_E2E_MANIFEST:-}")" || return 1
  export NUINUI_RUNTIME_MANIFEST="$E2E_MANIFEST"
  lane_manifest_validate "$E2E_MANIFEST" || {
    echo "BLOCKED: authoritative project lane manifest is invalid"
    return 1
  }
}

select_human_lane() {
  local requested="${1:-}" count=0 candidate
  e2e_context || return 1
  if [[ -n "$requested" ]]; then
    lane_manifest_validate_lane_name "$E2E_MANIFEST" "$requested" >/dev/null 2>&1 || {
      echo "BLOCKED: unknown Human-test lane: $requested"
      return 1
    }
    [[ "$(lane_manifest_lane_role "$E2E_MANIFEST" "$requested")" == human-test ]] || {
      echo "BLOCKED: selected lane is not a declared Human-test lane: $requested"
      return 1
    }
    E2E_LANE="$requested"
  else
    while IFS= read -r candidate; do
      [[ -n "$candidate" ]] || continue
      E2E_LANE="$candidate"
      (( count++ ))
    done <<EOF
$(lane_manifest_lanes_by_role "$E2E_MANIFEST" human-test)
EOF
    if (( count == 0 )); then
      echo 'BLOCKED: no Human-test lane is declared'
      return 1
    fi
    if (( count != 1 )); then
      echo 'BLOCKED: explicit Human-test lane is required when multiple Human-test lanes are declared'
      return 1
    fi
  fi
  E2E_WT="$(lane_manifest_lane_path "$E2E_MANIFEST" "$E2E_LANE")" || return 1
  [[ "$(lane_manifest_lane_idle_policy "$E2E_MANIFEST" "$E2E_LANE")" == detached ]] || {
    echo 'BLOCKED: selected Human-test lane must declare idle=detached'
    return 1
  }
  E2E_REPOSITORY="$(lane_manifest_repository_identity "$E2E_MANIFEST")" || return 1
  E2E_DEFAULT_BRANCH="$(lane_manifest_default_branch "$E2E_MANIFEST")" || return 1
}

usage() {
  cat <<'EOF'
Usage:
  nuinui-e2e-prepare check [<human-test-lane>] <SAY-123> <tested-ref> <fixture-path> [--locale ja]
  nuinui-e2e-prepare prepare [<human-test-lane>] <SAY-123> <tested-ref> <fixture-path> [cdp-port] [--locale ja]
  nuinui-e2e-prepare status [<human-test-lane>]
  nuinui-e2e-prepare cleanup [<human-test-lane>] <SAY-123> <tested-ref> <e2e-root>
  nuinui-e2e-prepare closure-check [<human-test-lane>] <SAY-123>

Closure order:
  nuinui-e2e-prepare cleanup [<human-test-lane>] <SAY-123> <tested-ref> <e2e-root>
  nuinui e2e-release [<human-test-lane>] <SAY-123> <tested-ref>
  nuinui-e2e-prepare closure-check [<human-test-lane>] <Issue>

Exact duplicate prepare/cleanup: no-op; no status/confirmation. Near-match: BLOCKED.
Every short form requires exactly one declared Human-test lane; a persisted
session never disambiguates a zero- or multi-lane manifest.

EOF
}

parse_locale_options() {
  local -a args
  local i=1 arg locale_value option_count=0

  LOCALE='default'
  LOCALE_ARGS=()
  args=("$@")
  while (( i <= $# )); do
    arg="${args[i]}"
    case "$arg" in
      --locale)
        (( option_count++ ))
        (( option_count == 1 )) || {
          echo 'ERROR: duplicate --locale option'
          return 2
        }
        (( i < $# )) || {
          echo 'ERROR: --locale requires a value'
          return 2
        }
        locale_value="${args[i+1]}"
        [[ -n "$locale_value" && "$locale_value" != --* ]] || {
          echo 'ERROR: --locale requires a value'
          return 2
        }
        (( i + 1 == $# )) || {
          echo 'ERROR: --locale must be the trailing option'
          return 2
        }
        [[ "$locale_value" == ja ]] || {
          echo "ERROR: unsupported locale: $locale_value"
          return 2
        }
        LOCALE='ja'
        (( i += 2 ))
        ;;
      --locale=*|--locale?*)
        echo "ERROR: malformed locale option: $arg"
        return 2
        ;;
      *)
        LOCALE_ARGS+=("$arg")
        (( i++ ))
        ;;
    esac
  done
}

assert_locale() {
  case "$1" in
    default|ja) ;;
    *) echo "ERROR: unsupported locale: $1"; return 2 ;;
  esac
}

resolve_vscode_app_identity() {
  VS_CODE_APP_REAL="$(resolve_existing_path "$VS_CODE_APP")" || return 1
  [[ -d "$VS_CODE_APP_REAL/Contents" && ! -L "$VS_CODE_APP_REAL/Contents" ]] || return 1
}

plist_cf_bundle_executable() {
  local plist="$1" value=''

  if command -v plutil >/dev/null 2>&1; then
    value="$(plutil -extract CFBundleExecutable raw -o - "$plist" 2>/dev/null || true)"
  fi
  if [[ -z "$value" && -x /usr/libexec/PlistBuddy ]]; then
    value="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist" 2>/dev/null || true)"
  fi
  if [[ -z "$value" ]]; then
    value="$(awk '
      /<key>CFBundleExecutable<\/key>/ { wanted=1; next }
      wanted && /<string>/ {
        line=$0
        sub(/^.*<string>/, "", line)
        sub(/<\/string>.*$/, "", line)
        print line
        exit
      }
      wanted && /<key>/ { exit }
    ' "$plist" 2>/dev/null || true)"
  fi
  [[ -n "$value" && "$value" != */* && "$value" != '.' && "$value" != '..' ]] || return 1
  print -r -- "$value"
}

resolve_vscode_application_executable() {
  local plist executable_name
  resolve_vscode_app_identity || return 1
  plist="$VS_CODE_APP_REAL/Contents/Info.plist"
  [[ -f "$plist" && ! -L "$plist" ]] || return 1
  executable_name="$(plist_cf_bundle_executable "$plist")" || return 1
  VS_CODE_APPLICATION_EXECUTABLE="$VS_CODE_APP_REAL/Contents/MacOS/$executable_name"
  [[ -x "$VS_CODE_APPLICATION_EXECUTABLE" && ! -d "$VS_CODE_APPLICATION_EXECUTABLE" ]] || return 1
}

process_command_line_owned() {
  local root="$1" command_line="$2"
  [[ -n "$command_line" ]] || return 2
  [[ "$command_line" == *"$root/user-data"* ]] || return 1
  resolve_vscode_app_identity || return 1
  [[ "$command_line" == *"$VS_CODE_APP/Contents/"* ||
    "$command_line" == *"$VS_CODE_APP_REAL/Contents/"* ]]
}
resolve_existing_path() {
  local input_path="$1"

  command -v realpath >/dev/null 2>&1 || return 1
  realpath "$input_path" 2>/dev/null
}

session_path() {
  local git_dir=""
  git_dir="$(git -C "$E2E_WT" rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  printf '%s/nuinui-e2e-session\n' "$git_dir"
}

marker_path() {
  local git_dir=""
  git_dir="$(git -C "$E2E_WT" rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  printf '%s/nuinui-slot\n' "$git_dir"
}

metadata_value() {
  local metadata="$1"
  local key="$2"
  local -a values

  values=("${(@f)$(sed -n "s/^${key}=//p" "$metadata")}")
  (( ${#values} == 1 )) || return 1
  print -r -- "$values[1]"
}
handoff_value() {
  local value="$(metadata_value "$1" "$2")" || return 1
  [[ ${#value} -ge 2 && "${value[1]}" == "'" && "${value[-1]}" == "'" ]] || return 1
  print -r -- "${value[2,-2]}"
}

path_exists() {
  [[ -e "$1" || -L "$1" ]]
}

metadata_matches() {
  local metadata="$1"
  local keys="$2"
  [[ -f "$metadata" && ! -L "$metadata" ]] || return 1
  awk -v keys="$keys" '
    BEGIN { count=split(keys, expected, ","); for (i=1; i<=count; i++) allowed[expected[i]]=1 }
    {
      equals=index($0, "=")
      if (equals <= 1) { invalid=1; next }
      key=substr($0, 1, equals-1)
      value=substr($0, equals+1)
      if (!(key in allowed) || (key in seen) || value == "") { invalid=1; next }
      seen[key]=1
    }
    END { for (i=1; i<=count; i++) if (!(expected[i] in seen)) invalid=1; if (invalid) exit 1 }
  ' "$metadata"
}

session_kind() {
  local metadata="$1"
  metadata_matches "$metadata" "$CURRENT_SESSION_KEYS" && { echo current; return 0; }
  metadata_matches "$metadata" "$PRE_LOCALE_SESSION_KEYS" && { echo pre-locale; return 0; }
  metadata_matches "$metadata" "$LEGACY_SESSION_KEYS" && { echo legacy; return 0; }
  return 1
}

load_session() {
  local metadata="$1"
  SESSION_KIND="$(session_kind "$metadata")" || return 1
  SESSION_ISSUE="$(metadata_value "$metadata" issue)" || return 1; SESSION_REF="$(metadata_value "$metadata" ref)" || return 1
  SESSION_ROOT="$(metadata_value "$metadata" root)" || return 1; SESSION_HANDOFF="$(metadata_value "$metadata" handoff)" || return 1
  SESSION_CDP_PORT="$(metadata_value "$metadata" cdp_port)" || return 1; SESSION_LAUNCH_PID="$(metadata_value "$metadata" launch_pid)" || return 1
  if [[ "$SESSION_KIND" == current || "$SESSION_KIND" == pre-locale ]]; then
    SESSION_LANE="$(metadata_value "$metadata" lane)" || return 1
    [[ -n "$SESSION_LANE" ]] || return 1
    SESSION_SOURCE_FIXTURE="$(metadata_value "$metadata" source_fixture)" || return 1
    case "$SESSION_SOURCE_FIXTURE" in /*) ;; *) return 1 ;; esac
    [[ "$SESSION_SOURCE_FIXTURE" != */ && "$SESSION_SOURCE_FIXTURE" != *'/./'* && "$SESSION_SOURCE_FIXTURE" != *'/../'* && "$SESSION_SOURCE_FIXTURE" != *//* ]] || return 1
    [[ ! -e "$SESSION_SOURCE_FIXTURE" && ! -L "$SESSION_SOURCE_FIXTURE" || -f "$SESSION_SOURCE_FIXTURE" && ! -L "$SESSION_SOURCE_FIXTURE" && "$(resolve_existing_path "$SESSION_SOURCE_FIXTURE")" == "$SESSION_SOURCE_FIXTURE" ]] || return 1
    if [[ "$SESSION_KIND" == current ]]; then
      SESSION_LOCALE="$(metadata_value "$metadata" locale)" || return 1
      assert_locale "$SESSION_LOCALE" >/dev/null || return 1
    else
      SESSION_LOCALE='pre-locale/default'
    fi
  fi
  [[ "$SESSION_ISSUE" =~ '^SAY-[0-9]+$' && "$SESSION_REF" =~ '^[0-9a-fA-F]{40}$' && -n "$SESSION_ROOT" && -n "$SESSION_HANDOFF" && -n "$SESSION_CDP_PORT" && -n "$SESSION_LAUNCH_PID" ]] || return 1
  assert_port "$SESSION_CDP_PORT" || return 1
  [[ "$SESSION_LAUNCH_PID" =~ '^[1-9][0-9]*$' ]] || return 1
}

assert_marker() {
  local marker="$1"
  metadata_matches "$marker" 'issue,ref' || { echo "BLOCKED: E2E marker is malformed"; return 1; }
  MARKER_ISSUE="$(metadata_value "$marker" issue)" || return 1
  MARKER_REF="$(metadata_value "$marker" ref)" || return 1
  [[ "$MARKER_ISSUE" =~ '^SAY-[0-9]+$' && "$MARKER_REF" =~ '^[0-9a-fA-F]{40}$' ]] || { echo "BLOCKED: E2E marker contains invalid identity"; return 1; }
}

assert_port() {
  [[ "$1" =~ '^[1-9][0-9]{0,4}$' ]] && (( $1 <= 65535 ))
}

assert_session_root() {
  local root="$1" relative="${1#"${E2E_TEMP_PARENT%/}"/}" parent_real root_real
  [[ "$relative" != "$root" && "$relative" == nuinui-vscode-e2e.* && "$relative" != */* ]] || return 1
  parent_real="$(resolve_existing_path "$E2E_TEMP_PARENT")" || return 1
  [[ ! -L "$root" ]] || return 1
  if [[ -e "$root" ]]; then
    [[ -d "$root" ]] || return 1
    root_real="$(resolve_existing_path "$root")" || return 1
    [[ "$(dirname "$root_real")" == "$parent_real" ]] || return 1
  fi
}

assert_session_handoff() {
  [[ "$2" == "$E2E_TEMP_PARENT/nuinui-${1}-human-e2e.env" ]]
}

assert_handoff_file() {
  local handoff="$1" issue="$2" tested_ref="$3" root="$4" cdp_port="$5" source_fixture="$6" prepared_fixture root_real
  [[ -f "$handoff" && ! -L "$handoff" ]] || return 1
  metadata_matches "$handoff" "$HANDOFF_KEYS" || return 1
  [[ "$(handoff_value "$handoff" LANE)" == "$E2E_LANE" ]] || return 1
  prepared_fixture="$(handoff_value "$handoff" FIXTURE)" || return 1
  [[ -z "$source_fixture" || "$prepared_fixture" == "$root/$(basename "$source_fixture")" ]] || return 1
  [[ "$prepared_fixture" == "$root/"* && -f "$prepared_fixture" && ! -L "$prepared_fixture" ]] || return 1
  root_real="$(resolve_existing_path "$root")" || return 1
  [[ "$(handoff_value "$handoff" ISSUE)" == "$issue" &&
    "$(handoff_value "$handoff" TESTED_REF)" == "$tested_ref" &&
    "$(resolve_existing_path "$(handoff_value "$handoff" CHECKOUT)")" == "$(resolve_existing_path "$E2E_WT")" &&
    "$(handoff_value "$handoff" E2E_ROOT)" == "$root" &&
    "$(handoff_value "$handoff" CDP_PORT)" == "$cdp_port" ]] || return 1
  [[ "$(resolve_existing_path "$prepared_fixture")" == "$root_real"/* ]] || return 1
  PREPARED_FIXTURE="$prepared_fixture"
}

process_ids_for_root() {
  local root="$1"
  pgrep -f "user-data-dir=$root/user-data" 2>/dev/null || true
}

assert_process_ownership() {
  local root="$1" launch_pid="$2" command_line pid require_launch="${3:-0}"
  local -a pids
  assert_session_root "$root" || return 1
  if [[ -n "$launch_pid" && "$launch_pid" =~ '^[1-9][0-9]*$' ]] && kill -0 "$launch_pid" >/dev/null 2>&1; then
    command_line="$(ps -ww -p "$launch_pid" -o command= 2>/dev/null || true)"
    if [[ -z "$command_line" ]]; then
      if [[ "$require_launch" == 1 ]]; then
        echo "BLOCKED: recorded launch PID is not running"
        return 1
      fi
    else
      process_command_line_owned "$root" "$command_line" || { echo "BLOCKED: launch PID ownership mismatch"; return 1; }
    fi
  elif [[ "$require_launch" == 1 ]]; then
    echo "BLOCKED: recorded launch PID is not running"
    return 1
  fi
  pids=("${(@f)$(process_ids_for_root "$root")}")
  for pid in "${pids[@]}"; do
    [[ -z "$pid" ]] && continue
    command_line="$(ps -ww -p "$pid" -o command= 2>/dev/null || true)"
    [[ -n "$command_line" ]] || continue
    process_command_line_owned "$root" "$command_line" || { echo "BLOCKED: E2E process ownership is ambiguous"; return 1; }
  done
}

assert_cdp_reachable() {
  local cdp_port="$1"
  assert_port "$cdp_port" || return 1
  command -v curl >/dev/null 2>&1 || return 1
  curl --max-time 1 -fsS "http://127.0.0.1:${cdp_port}/json/version" >/dev/null 2>&1
}

stop_owned_processes() {
  local root="$1" launch_pid="$2" pid command_line remaining
  local -a pids
  local -a matching_pids
  assert_process_ownership "$root" "$launch_pid" 0 || return 1
  matching_pids=()
  if [[ -n "$launch_pid" ]] && kill -0 "$launch_pid" >/dev/null 2>&1; then
    command_line="$(ps -ww -p "$launch_pid" -o command= 2>/dev/null || true)"
    if [[ -n "$command_line" ]]; then
      process_command_line_owned "$root" "$command_line" || return 1
      matching_pids+=("$launch_pid")
    fi
  fi
  pids=("${(@f)$(process_ids_for_root "$root")}")
  for pid in "${pids[@]}"; do
    [[ -z "$pid" ]] && continue
    command_line="$(ps -ww -p "$pid" -o command= 2>/dev/null || true)"
    [[ -n "$command_line" ]] || continue
    process_command_line_owned "$root" "$command_line" || return 1
    (( ${matching_pids[(Ie)$pid]} == 0 )) && matching_pids+=("$pid")
  done

  for pid in "${matching_pids[@]}"; do
    kill -TERM "$pid" >/dev/null 2>&1 || {
      kill -0 "$pid" >/dev/null 2>&1 || continue
      return 1
    }
  done
  for _ in $(seq 1 10); do
    remaining=0
    for pid in "${matching_pids[@]}"; do
      kill -0 "$pid" >/dev/null 2>&1 && remaining=1
    done
    (( remaining == 0 )) && return 0
    sleep 0.2
  done
  for pid in "${matching_pids[@]}"; do
    kill -0 "$pid" >/dev/null 2>&1 || continue
    kill -KILL "$pid" >/dev/null 2>&1 || {
      kill -0 "$pid" >/dev/null 2>&1 || continue
      return 1
    }
  done
  return 0
}

assert_fixture_external() {
  local fixture="$1"
  local fixture_real=""
  local repo_real=""

  [[ -d "$E2E_WT" ]] || return 0

  fixture_real="$(resolve_existing_path "$fixture")" || {
    echo "ERROR: could not resolve fixture path"
    echo "FIXTURE: $fixture"
    return 1
  }
  repo_real="$(resolve_existing_path "$E2E_WT")" || {
    echo "ERROR: could not resolve e2e checkout path"
    echo "PATH: $E2E_WT"
    return 1
  }

  case "$fixture_real" in
    "$repo_real"|"$repo_real"/*)
      echo "BLOCKED: fixture resolves inside dedicated e2e checkout"
      echo "FIXTURE: $fixture_real"
      echo "CHECKOUT: $repo_real"
      return 1
      ;;
  esac
}

assert_inputs() {
  local issue="$1"
  local tested_ref="$2"
  local fixture="$3"

  [[ "$issue" =~ '^SAY-[0-9]+$' ]] || { echo "ERROR: Issue must look like SAY-123"; return 2; }
  [[ "$tested_ref" =~ '^[0-9a-fA-F]{40}$' ]] || { echo "ERROR: tested-ref must be a full commit SHA"; return 2; }
  [[ -f "$fixture" ]] || { echo "BLOCKED: fixture does not exist"; echo "FIXTURE: $fixture"; return 1; }
  assert_fixture_external "$fixture" || return $?
}

assert_checkout() {
  local issue="$1"
  local tested_ref="$2"
  local repo="$E2E_WT"
  local origin=""
  local dirty=""
  local branch=""
  local head=""
  local marker=""
  local marker_issue=""
  local marker_ref=""

  [[ -d "$repo" ]] || { echo "BLOCKED: Human-test checkout does not exist"; echo "PATH: $repo"; return 1; }
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "BLOCKED: e2e checkout is not a Git worktree"
    echo "PATH: $repo"
    return 1
  }

  origin="$(git -C "$repo" remote get-url origin 2>/dev/null)" || {
    echo "BLOCKED: e2e origin remote is missing"
    return 1
  }
  ao "$repo" "$E2E_REPOSITORY" || {
    echo "BLOCKED: unexpected e2e repository origin"
    echo "ACTUAL: $origin"
    return 1
  }

  dirty="$(git -C "$repo" status --porcelain)"
  [[ -z "$dirty" ]] || {
    echo "BLOCKED: e2e checkout is dirty"
    git -C "$repo" status --short
    return 1
  }

  branch="$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  case "$(lane_manifest_lane_idle_policy "$E2E_MANIFEST" "$E2E_LANE")" in
    detached) [[ -z "$branch" ]] || { echo "BLOCKED: Human-test checkout is not detached"; return 1; } ;;
    branch) [[ "$branch" == "$E2E_DEFAULT_BRANCH" ]] || { echo "BLOCKED: Human-test checkout is not on the declared idle branch"; return 1; } ;;
    *) echo 'BLOCKED: selected Human-test lane has unsupported idle policy'; return 1 ;;
  esac

  head="$(git -C "$repo" rev-parse HEAD)" || return 1
  [[ "$head" == "$tested_ref" ]] || {
    echo "BLOCKED: e2e HEAD does not match tested-ref"
    echo "HEAD:       $head"
    echo "TESTED_REF: $tested_ref"
    return 1
  }

  marker="$(marker_path)" || return 1
  [[ -f "$marker" && ! -L "$marker" ]] || {
    echo "BLOCKED: e2e marker is missing; run the lane e2e-start helper first"
    echo "MARKER: $marker"
    return 1
  }

  assert_marker "$marker" || return 1
  marker_issue="$MARKER_ISSUE"
  marker_ref="$MARKER_REF"
  [[ "$marker_issue" == "$issue" ]] || {
    echo "BLOCKED: e2e marker Issue mismatch"
    echo "MARKER_ISSUE: $marker_issue"
    echo "REQUESTED:    $issue"
    return 1
  }
  [[ "$marker_ref" == "$tested_ref" ]] || {
    echo "BLOCKED: e2e marker ref mismatch"
    echo "MARKER_REF: $marker_ref"
    echo "TESTED_REF: $tested_ref"
    return 1
  }

  echo "E2E CHECKOUT VERIFIED"
  echo "  issue=$issue"
  echo "  tested_ref=$tested_ref"
  echo "  checkout=$repo"
  echo "  marker=$marker"
}
