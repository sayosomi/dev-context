# E2E preparation runtime context, lane selection, and strict metadata helpers.
VERSION="1.7.0"
E2E_HELPER_INVOCATION="$0"
E2E_WT=""
E2E_LANE=""
VS_CODE_APP="${NUINUI_E2E_VSCODE_APP-/Applications/Visual Studio Code.app}"
DEFAULT_CDP_PORT="${NUINUI_E2E_CDP_PORT-9223}"
E2E_TEMP_PARENT="${NUINUI_E2E_TEMP_PARENT-/private/tmp}"
JAPANESE_LANGUAGE_PACK='MS-CEINTL.vscode-language-pack-ja'
JAPANESE_LANGUAGE_PACK_READY_TIMEOUT="${NUINUI_E2E_JAPANESE_LANGUAGE_PACK_TIMEOUT-30}"
CURRENT_SESSION_KEYS='lane,issue,ref,source_fixture,root,handoff,cdp_port,launch_pid,locale'
PRE_LOCALE_SESSION_KEYS='lane,issue,ref,source_fixture,root,handoff,cdp_port,launch_pid'
PREPARING_SESSION_KEYS='kind,lane,issue,ref,root,prepare_owner,prepare_pid'
LEGACY_SESSION_KEYS='issue,ref,root,handoff,cdp_port,launch_pid'
CLEANUP_RECEIPT_KEYS='version,issue,ref,root'
HANDOFF_KEYS='LANE,ISSUE,TESTED_REF,CHECKOUT,E2E_ROOT,FIXTURE,CDP_PORT,RUST_BIN'
PREPARING_SESSION_OWNER='nuinui-e2e-prepare'
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
  nuinui-e2e-prepare closure-command --issue <SAY-123> [--lane <human-test-lane>]
  nuinui-e2e-prepare recover-split <human-test-lane> <marker-issue> <marker-ref> <session-issue> <session-ref> <e2e-root>
  nuinui-e2e-prepare recover-preparing <human-test-lane> <Issue> <tested-ref> <e2e-root>

Closure order:
  nuinui-e2e-prepare cleanup [<human-test-lane>] <SAY-123> <tested-ref> <e2e-root>
  nuinui e2e-release [<human-test-lane>] <SAY-123> <tested-ref>
  nuinui-e2e-prepare closure-check [<human-test-lane>] <Issue>

Exact duplicate prepare/cleanup: no-op; no status/confirmation. Near-match: BLOCKED.
Every short form requires exactly one declared Human-test lane; a persisted
session never disambiguates a zero- or multi-lane manifest.
recover-split always requires its explicit Human-test lane and only repairs an
exact marker/session split after proving both identities and ownership.
recover-preparing always requires its explicit Human-test lane and only repairs
an exact stale kind=preparing session after proving owner exit and ownership.

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

extract_nls_config_object() {
  awk -v marker='VSCODE_NLS_CONFIG=' '
    BEGIN {
      quote = sprintf("%c", 34)
      backslash = sprintf("%c", 92)
    }
    {
      if (!found) {
        marker_pos = index($0, marker)
        if (marker_pos == 0) {
          next
        }
        text = substr($0, marker_pos + length(marker))
        if (substr(text, 1, 1) != "{") {
          exit 1
        }
        found = 1
      } else {
        text = $0
      }
      for (i = 1; i <= length(text); i++) {
        ch = substr(text, i, 1)
        if (in_string) {
          result = result ch
          if (escaped) {
            escaped = 0
            continue
          }
          if (ch == backslash) {
            escaped = 1
            continue
          }
          if (ch == quote) {
            in_string = 0
          }
          continue
        }
        if (ch == quote) {
          in_string = 1
          result = result ch
          continue
        }
        if (ch == "{") {
          depth++
          result = result ch
          continue
        }
        if (ch == "}") {
          if (depth == 0) {
            exit 1
          }
          depth--
          result = result ch
          if (depth == 0) {
            print result
            done = 1
            exit 0
          }
          continue
        }
        result = result ch
      }
    }
    END {
      if (!done) {
        exit 1
      }
    }
  '
}

process_nls_config() {
  local root="$1" pid="$2" command_line process_environment nls_config
  command_line="$(ps -ww -p "$pid" -o command= 2>/dev/null || true)"
  [[ -n "$command_line" ]] || return 1
  process_command_line_owned "$root" "$command_line" || return 1
  process_environment="$(ps -wwE -p "$pid" -o command= 2>/dev/null || true)"
  nls_config="$(print -r -- "$process_environment" | extract_nls_config_object || true)"
  if [[ -z "$nls_config" ]]; then
    process_environment="$(ps eww -p "$pid" -o command= 2>/dev/null || true)"
    nls_config="$(print -r -- "$process_environment" | extract_nls_config_object || true)"
  fi
  [[ -n "$nls_config" ]] || return 1
  print -r -- "$nls_config"
}

nls_config_value() {
  local nls_config="$1" key="$2"
  command -v plutil >/dev/null 2>&1 || return 1
  print -r -- "$nls_config" | plutil -extract "$key" raw -o - - 2>/dev/null
}

japanese_readiness_attempts() {
  local timeout="$JAPANESE_LANGUAGE_PACK_READY_TIMEOUT"
  [[ "$timeout" =~ '^[1-9][0-9]*$' ]] || timeout=30
  if (( timeout > 30 )); then
    timeout=30
  fi
  print -r -- "$(( timeout * 2 ))"
}

validate_japanese_extension_installation() {
  local root="$1" code_bin="$2" listing listing_status=0 extension_line evidence="$root/evidence/japanese-extension-list.txt"
  JAPANESE_EXTENSION_INSTALLATION_ERROR=''
  : > "$evidence" || {
    JAPANESE_EXTENSION_INSTALLATION_ERROR='could not create isolated extension-list evidence'
    return 1
  }
  listing="$("$code_bin" \
    --user-data-dir="$root/user-data" \
    --extensions-dir="$root/extensions" \
    --list-extensions \
    --show-versions 2>/dev/null)" || listing_status=$?
  if (( listing_status != 0 )); then
    JAPANESE_EXTENSION_INSTALLATION_ERROR='isolated VS Code CLI extension listing failed'
    return 1
  fi
  extension_line="$(print -r -- "$listing" | awk '
    {
      line=$0
      sub(/^[[:space:]]+/, "", line)
      lower=tolower(line)
      if (lower ~ /^ms-ceintl[.]vscode-language-pack-ja(@|[[:space:]]|$)/) {
        print line
        found=1
        exit
      }
    }
    END { if (!found) exit 1 }
  ')" || true
  if [[ -n "$extension_line" ]]; then
    print -r -- "$extension_line" > "$evidence"
    return 0
  fi
  JAPANESE_EXTENSION_INSTALLATION_ERROR="isolated VS Code CLI did not list $JAPANESE_LANGUAGE_PACK"
  return 1
}

wait_for_japanese_extension_installation() {
  local root="$1" code_bin="$2" attempts attempt
  attempts="$(japanese_readiness_attempts)" || return 1
  for attempt in $(seq 1 "$attempts"); do
    if validate_japanese_extension_installation "$root" "$code_bin"; then
      return 0
    fi
    if (( attempt < attempts )); then
      sleep 0.5
    fi
  done
  return 1
}

inspect_japanese_effective_locale() {
  local root="$1" launch_pid="$2" pid command_line nls_config user_locale resolved_locale
  local language_pack_hash language_pack_id language_pack_support translations_config translations_config_real messages_file messages_real user_data_real
  local reason=''
  local -a pids

  EFFECTIVE_LOCALE=''
  JAPANESE_LOCALE_READINESS_REASON=''
  assert_process_ownership "$root" "$launch_pid" 1 >/dev/null 2>&1 || {
    JAPANESE_LOCALE_READINESS_REASON='owned VS Code process proof was unavailable'
    return 1
  }
  pids=("$launch_pid" "${(@f)$(process_ids_for_root "$root")}")
  for pid in "${pids[@]}"; do
    [[ -n "$pid" && "$pid" =~ '^[1-9][0-9]*$' ]] || continue
    kill -0 "$pid" >/dev/null 2>&1 || continue
    command_line="$(ps -ww -p "$pid" -o command= 2>/dev/null || true)"
    [[ -n "$command_line" ]] || continue
    process_command_line_owned "$root" "$command_line" || continue
    nls_config="$(process_nls_config "$root" "$pid" 2>/dev/null || true)"
    if [[ -z "$nls_config" ]]; then
      reason='owned VS Code process did not expose VSCODE_NLS_CONFIG'
      continue
    fi
    user_locale="$(nls_config_value "$nls_config" userLocale || true)"
    resolved_locale="$(nls_config_value "$nls_config" resolvedLanguage || true)"
    [[ -n "$resolved_locale" ]] && EFFECTIVE_LOCALE="$resolved_locale"
    if [[ "$user_locale" != ja || "$resolved_locale" != ja ]]; then
      reason="running VS Code host did not resolve Japanese (userLocale=$user_locale, resolvedLanguage=$resolved_locale)"
      continue
    fi
    if ! validate_japanese_language_pack_state "$root"; then
      reason="Japanese language-pack cache was not valid ($JAPANESE_LANGUAGE_PACK_STATE_ERROR)"
      continue
    fi
    language_pack_id="$(nls_config_value "$nls_config" _languagePackId || true)"
    language_pack_hash="$(nls_config_value "$(<"$root/user-data/languagepacks.json")" ja.hash || true)"
    language_pack_support="$(nls_config_value "$nls_config" _languagePackSupport || true)"
    translations_config="$(nls_config_value "$nls_config" _translationsConfigFile || true)"
    messages_file="$(nls_config_value "$nls_config" languagePack.messagesFile || true)"
    user_data_real="$(resolve_existing_path "$root/user-data" || true)"
    translations_config_real="$(resolve_existing_path "$translations_config" || true)"
    messages_real="$(resolve_existing_path "$messages_file" || true)"
    if [[ -z "$language_pack_hash" || "$language_pack_id" != "$language_pack_hash.ja" ||
      "$language_pack_support" != true || "$translations_config" != /* ||
      -z "$translations_config_real" || ! -f "$translations_config_real" || -L "$translations_config_real" ||
      "$messages_file" != /* || -z "$messages_real" || ! -f "$messages_real" || -L "$messages_real" ||
      -z "$user_data_real" || "$translations_config_real" != "$user_data_real"/* ||
      "$messages_real" != "$user_data_real"/* ]]; then
      reason='Japanese locale was selected but active language-pack metadata/support was incomplete'
      continue
    fi
    return 0
  done
  JAPANESE_LOCALE_READINESS_REASON="${reason:-no owned VS Code process provided Japanese NLS evidence}"
  return 1
}

wait_for_japanese_effective_locale() {
  local root="$1" launch_pid="$2" attempts attempt
  attempts="$(japanese_readiness_attempts)" || return 1
  for attempt in $(seq 1 "$attempts"); do
    if inspect_japanese_effective_locale "$root" "$launch_pid"; then
      return 0
    fi
    [[ -n "$EFFECTIVE_LOCALE" ]] && return 1
    if (( attempt < attempts )); then
      sleep 0.5
    fi
  done
  return 1
}

wait_for_cdp() {
  local cdp_port="$1" evidence="$2"
  for _ in $(seq 1 120); do
    if curl --max-time 1 -fsS \
      "http://127.0.0.1:${cdp_port}/json/version" \
      > "$evidence"; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}

wait_for_japanese_language_pack_state() {
  local root="$1" attempts attempt
  attempts="$(japanese_readiness_attempts)" || return 1
  for attempt in $(seq 1 "$attempts"); do
    if validate_japanese_language_pack_state "$root"; then
      return 0
    fi
    if (( attempt < attempts )); then
      sleep 0.5
    fi
  done
  return 1
}

validate_japanese_language_pack_state() {
  local root="$1" languagepacks="$root/user-data/languagepacks.json" hash translation translation_real extensions_real
  JAPANESE_LANGUAGE_PACK_STATE_ERROR=''
  [[ -f "$languagepacks" && ! -L "$languagepacks" ]] || {
    JAPANESE_LANGUAGE_PACK_STATE_ERROR='user-data/languagepacks.json is missing'
    return 1
  }
  plutil -convert json -o /dev/null "$languagepacks" >/dev/null 2>&1 || {
    JAPANESE_LANGUAGE_PACK_STATE_ERROR='user-data/languagepacks.json is not valid JSON'
    return 1
  }
  hash="$(plutil -extract ja.hash raw -expect string -o - "$languagepacks" 2>/dev/null || true)"
  [[ -n "$hash" ]] || {
    JAPANESE_LANGUAGE_PACK_STATE_ERROR='languagepacks.json has no ja string hash'
    return 1
  }
  translation="$(plutil -extract ja.translations.vscode raw -expect string -o - "$languagepacks" 2>/dev/null || true)"
  [[ "$translation" == /* ]] || {
    JAPANESE_LANGUAGE_PACK_STATE_ERROR='ja translations.vscode is not an absolute path'
    return 1
  }
  [[ -f "$translation" && ! -L "$translation" ]] || {
    JAPANESE_LANGUAGE_PACK_STATE_ERROR='ja translations.vscode does not resolve to a regular file'
    return 1
  }
  translation_real="$(resolve_existing_path "$translation" || true)"
  [[ -n "$translation_real" && -f "$translation_real" && ! -L "$translation_real" ]] || {
    JAPANESE_LANGUAGE_PACK_STATE_ERROR='ja translations.vscode does not resolve to a regular file'
    return 1
  }
  extensions_real="$(resolve_existing_path "$root/extensions" || true)"
  [[ -n "$extensions_real" && "$translation_real" == "$extensions_real"/* ]] || {
    JAPANESE_LANGUAGE_PACK_STATE_ERROR='ja translations.vscode is outside the isolated extensions root'
    return 1
  }
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
  metadata_matches "$metadata" "$PREPARING_SESSION_KEYS" && { echo preparing; return 0; }
  metadata_matches "$metadata" "$LEGACY_SESSION_KEYS" && { echo legacy; return 0; }
  return 1
}

load_session() {
  local metadata="$1"
  SESSION_LANE=''; SESSION_SOURCE_FIXTURE=''; SESSION_LOCALE=''
  SESSION_PREPARE_OWNER=''; SESSION_PREPARE_PID=''
  SESSION_HANDOFF=''; SESSION_CDP_PORT=''; SESSION_LAUNCH_PID=''
  SESSION_KIND="$(session_kind "$metadata")" || return 1
  SESSION_ISSUE="$(metadata_value "$metadata" issue)" || return 1; SESSION_REF="$(metadata_value "$metadata" ref)" || return 1
  SESSION_ROOT="$(metadata_value "$metadata" root)" || return 1
  if [[ "$SESSION_KIND" == preparing ]]; then
    SESSION_LANE="$(metadata_value "$metadata" lane)" || return 1
    SESSION_PREPARE_OWNER="$(metadata_value "$metadata" prepare_owner)" || return 1
    SESSION_PREPARE_PID="$(metadata_value "$metadata" prepare_pid)" || return 1
    [[ "$SESSION_LANE" =~ '^[A-Za-z0-9._-]+$' &&
      "$SESSION_PREPARE_OWNER" == "$PREPARING_SESSION_OWNER" &&
      "$SESSION_PREPARE_PID" =~ '^[1-9][0-9]*$' ]] || return 1
    [[ "$SESSION_ISSUE" =~ '^SAY-[0-9]+$' &&
      "$SESSION_REF" =~ '^[0-9a-fA-F]{40}$' ]] || return 1
    assert_session_root "$SESSION_ROOT" || return 1
    return 0
  fi
  SESSION_HANDOFF="$(metadata_value "$metadata" handoff)" || return 1
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
