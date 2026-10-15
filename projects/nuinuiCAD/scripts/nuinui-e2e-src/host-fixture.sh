# Fixture-only host resources. This adapter never launches or signals a process.

nuinui_e2e_host__valid_port() {
  [ "$#" = 1 ] || return 2
  case "$1" in ''|0*|*[!0-9]*) return 1 ;; esac
  [ "${#1}" -le 5 ] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

nuinui_e2e_host__fixture_identity() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_host_fixture_input=$1
  nuinui_e2e_host_fixture_checkout=$2
  case "$nuinui_e2e_host_fixture_input" in /*) ;; *) return 1 ;; esac
  nuinui_e2e__regular "$nuinui_e2e_host_fixture_input" || return 1
  nuinui_e2e_host_fixture_canonical=$(realpath "$nuinui_e2e_host_fixture_input" 2>/dev/null) || return 1
  [ "$nuinui_e2e_host_fixture_canonical" = "$nuinui_e2e_host_fixture_input" ] || return 1
  case "$nuinui_e2e_host_fixture_canonical" in
    "$nuinui_e2e_host_fixture_checkout"/*) return 1 ;;
  esac
  [ -r "$nuinui_e2e_host_fixture_canonical" ] || return 1
  nuinui_e2e_host_fixture_sha=$(nuinui_e2e__sha256 "$nuinui_e2e_host_fixture_canonical") || return 1
  nuinui_e2e_valid_digest "$nuinui_e2e_host_fixture_sha" || return 1
  printf '%s\n%s\n' "$nuinui_e2e_host_fixture_canonical" "$nuinui_e2e_host_fixture_sha"
}

nuinui_e2e_host__production_root_mode() {
  [ "${nuinui_e2e_production:-no}" = yes ] || {
    [ "${nuinui_e2e_self_test:-no}" = yes ] &&
      [ "${NUINUI_E2E_TEST_PRODUCTION_HOST_ROOT:-no}" = yes ]
  }
}

nuinui_e2e_host__production_parent_for_home() {
  [ -n "${HOME:-}" ] || return 1
  case "$HOME" in /*) ;; *) return 1 ;; esac
  [ "$HOME" != / ] || return 1
  printf '%s/.nuinuicad/e2e-hosts\n' "${HOME%/}"
}

nuinui_e2e_host__validate_owned_directory() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_host_directory=$1
  nuinui_e2e_host_directory_policy=$2
  [ -d "$nuinui_e2e_host_directory" ] &&
    [ ! -L "$nuinui_e2e_host_directory" ] &&
    [ "$(realpath "$nuinui_e2e_host_directory" 2>/dev/null)" = \
      "$nuinui_e2e_host_directory" ] &&
    [ "$(stat -f '%u' "$nuinui_e2e_host_directory" 2>/dev/null)" = \
      "$(command id -u 2>/dev/null)" ] || return 1
  nuinui_e2e_host_directory_mode=$(stat -f '%Lp' \
    "$nuinui_e2e_host_directory" 2>/dev/null) || return 1
  case "$nuinui_e2e_host_directory_policy" in
    private)
      [ "$nuinui_e2e_host_directory_mode" = 700 ]
      ;;
    safe-parent)
      case "$nuinui_e2e_host_directory_mode" in
        [0-7][0-7][0-7]) ;;
        *) return 1 ;;
      esac
      case "$nuinui_e2e_host_directory_mode" in
        [0-7][2367][0-7]|[0-7][0-7][2367]) return 1 ;;
      esac
      [ -w "$nuinui_e2e_host_directory" ] &&
        [ -x "$nuinui_e2e_host_directory" ]
      ;;
    *) return 2 ;;
  esac
}

nuinui_e2e_host__ensure_owned_directory() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_host_ensure_directory=$1
  nuinui_e2e_host_ensure_policy=$2
  if nuinui_e2e__exists "$nuinui_e2e_host_ensure_directory"; then
    nuinui_e2e_host__validate_owned_directory \
      "$nuinui_e2e_host_ensure_directory" "$nuinui_e2e_host_ensure_policy"
    return $?
  fi
  (umask 077; mkdir -m 0700 "$nuinui_e2e_host_ensure_directory") 2>/dev/null || return 1
  nuinui_e2e_host__validate_owned_directory \
    "$nuinui_e2e_host_ensure_directory" "$nuinui_e2e_host_ensure_policy"
}

nuinui_e2e_host__validate_production_parent() {
  nuinui_e2e_host__production_root_mode || return 0
  nuinui_e2e_host_home=${HOME:-}
  nuinui_e2e_host_expected_parent=$(nuinui_e2e_host__production_parent_for_home) || return 1
  [ "$(realpath "$nuinui_e2e_host_home" 2>/dev/null)" = \
    "$nuinui_e2e_host_home" ] || return 1
  nuinui_e2e_host__validate_owned_directory \
    "$nuinui_e2e_host_home" safe-parent || return 1
  [ "${nuinui_e2e_host_parent:-$nuinui_e2e_host_expected_parent}" = \
    "$nuinui_e2e_host_expected_parent" ] || return 1
  nuinui_e2e_host_dot_parent=${nuinui_e2e_host_home%/}/.nuinuicad
  nuinui_e2e_host__validate_owned_directory \
    "$nuinui_e2e_host_dot_parent" safe-parent || return 1
  nuinui_e2e_host__validate_owned_directory \
    "$nuinui_e2e_host_expected_parent" private || return 1
}

nuinui_e2e_host__prepare_production_parent() {
  nuinui_e2e_host__production_root_mode || return 0
  nuinui_e2e_host_home=${HOME:-}
  nuinui_e2e_host_expected_parent=$(nuinui_e2e_host__production_parent_for_home) || return 1
  [ "$(realpath "$nuinui_e2e_host_home" 2>/dev/null)" = \
    "$nuinui_e2e_host_home" ] || return 1
  nuinui_e2e_host__validate_owned_directory \
    "$nuinui_e2e_host_home" safe-parent || return 1
  [ "${nuinui_e2e_host_parent:-$nuinui_e2e_host_expected_parent}" = \
    "$nuinui_e2e_host_expected_parent" ] || return 1
  nuinui_e2e_host_dot_parent=${nuinui_e2e_host_home%/}/.nuinuicad
  nuinui_e2e_host__ensure_owned_directory \
    "$nuinui_e2e_host_dot_parent" safe-parent || return 1
  nuinui_e2e_host__ensure_owned_directory \
    "$nuinui_e2e_host_expected_parent" private || return 1
  nuinui_e2e_host__validate_production_parent
}

nuinui_e2e_host__root_for() {
  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || return 2
  nuinui_e2e_host_generation_hash=$(nuinui_e2e__generation_hash "$1") || return 1
  if nuinui_e2e_host__production_root_mode; then
    if [ "${nuinui_e2e_production:-no}" = yes ]; then
      nuinui_e2e_host_root_parent=${nuinui_e2e_host_parent:-}
    else
      nuinui_e2e_host_root_parent=$(nuinui_e2e_host__production_parent_for_home) || return 1
    fi
    [ -n "$nuinui_e2e_host_root_parent" ] || return 1
    if [ "${2:-}" != full ]; then
      # Leave room for VS Code's Unix socket below user-data on macOS.
      printf '%s/.nuinui-e2e-host-%.12s\n' "$nuinui_e2e_host_root_parent" \
        "$nuinui_e2e_host_generation_hash"
      return 0
    fi
  else
    nuinui_e2e_host_root_parent=$nuinui_e2e_fixture_root
  fi
  [ -n "$nuinui_e2e_host_root_parent" ] || return 1
  printf '%s/.nuinui-e2e-host-%s\n' "$nuinui_e2e_host_root_parent" \
    "$nuinui_e2e_host_generation_hash"
}

nuinui_e2e_host__legacy_root_for() {
  [ "$#" = 1 ] || return 2
  printf '/.nuinui-e2e-host-%s\n' \
    "$(nuinui_e2e__generation_hash "$1")"
}

nuinui_e2e_host__root_identity() {
  [ "$#" = 1 ] || return 2
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  stat -f '%d:%i' "$1" 2>/dev/null
}

nuinui_e2e_host__owner_path() {
  [ "$#" = 1 ] || return 2
  printf '%s/.nuinui-github-e2e-host-owner-v1\n' "$1"
}

nuinui_e2e_host__fixture_copy_path() {
  [ "$#" = 1 ] || return 2
  printf '%s/fixture.html\n' "$1"
}

nuinui_e2e_host__owner_content() {
  printf 'schema_version=1\n'
  printf 'issue=%s\n' "$nuinui_e2e_host_issue"
  printf 'issue_url=%s\n' "$nuinui_e2e_host_url"
  printf 'local_id=%s\n' "$nuinui_e2e_host_token"
  printf 'lane=%s\n' "$nuinui_e2e_host_lane"
  printf 'repository=sayosomi/nuinuiCAD\n'
  printf 'checkout=%s\n' "$nuinui_e2e_host_checkout"
  printf 'git_dir=%s\n' "$nuinui_e2e_host_git_dir"
  printf 'manifest=%s\n' "$nuinui_e2e_host_manifest"
  printf 'manifest_sha256=%s\n' "$nuinui_e2e_host_manifest_sha"
  printf 'default_branch=%s\n' "$nuinui_e2e_host_default_branch"
  printf 'idle_policy=detached\n'
  printf 'tested_sha=%s\n' "$nuinui_e2e_host_tested"
  printf 'generation=%s\n' "$nuinui_e2e_host_generation"
  printf 'active_sha256=%s\n' "$nuinui_e2e_host_active_sha"
  printf 'fixture_path=%s\n' "$nuinui_e2e_host_fixture"
  printf 'fixture_sha256=%s\n' "$nuinui_e2e_host_fixture_sha"
  printf 'port=%s\n' "$nuinui_e2e_host_port"
  printf 'locale=%s\n' "$nuinui_e2e_host_locale"
  printf 'adapter=fixture-no-process\n'
  printf 'root=%s\n' "$nuinui_e2e_host_root"
  printf 'root_identity=%s\n' "$nuinui_e2e_host_root_identity"
}

nuinui_e2e_host__atomic_copy() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_host_copy_source=$1
  nuinui_e2e_host_copy_destination=$2
  nuinui_e2e_host_copy_expected_sha=$3
  [ ! -e "$nuinui_e2e_host_copy_destination" ] &&
    [ ! -L "$nuinui_e2e_host_copy_destination" ] || return 1
  nuinui_e2e_host_copy_tmp=$(mktemp "${nuinui_e2e_host_copy_destination%/*}/.fixture-copy.XXXXXX") || return 1
  if ! (umask 077; cp "$nuinui_e2e_host_copy_source" "$nuinui_e2e_host_copy_tmp"); then
    rm -f "$nuinui_e2e_host_copy_tmp"
    return 1
  fi
  nuinui_e2e_host_copy_actual=$(nuinui_e2e__sha256 "$nuinui_e2e_host_copy_tmp") || {
    rm -f "$nuinui_e2e_host_copy_tmp"
    return 1
  }
  if [ "$nuinui_e2e_host_copy_actual" != "$nuinui_e2e_host_copy_expected_sha" ] ||
    ! ln "$nuinui_e2e_host_copy_tmp" "$nuinui_e2e_host_copy_destination"; then
    rm -f "$nuinui_e2e_host_copy_tmp"
    return 1
  fi
  rm -f "$nuinui_e2e_host_copy_tmp"
  [ "$(nuinui_e2e__sha256 "$nuinui_e2e_host_copy_destination")" = \
    "$nuinui_e2e_host_copy_expected_sha" ]
}

nuinui_e2e_host__verify_root() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_host_verify_root=$1
  nuinui_e2e_host_verify_mode=$2
  [ -d "$nuinui_e2e_host_verify_root" ] && [ ! -L "$nuinui_e2e_host_verify_root" ] || return 1
  if nuinui_e2e_host__production_root_mode; then
    nuinui_e2e_host__validate_production_parent &&
      nuinui_e2e_host__validate_owned_directory \
        "$nuinui_e2e_host_verify_root" private || return 1
  fi
  [ "$(realpath "$nuinui_e2e_host_verify_root" 2>/dev/null)" = \
    "$nuinui_e2e_host_root" ] || return 1
  [ "$(nuinui_e2e_host__root_identity "$nuinui_e2e_host_verify_root")" = \
    "$nuinui_e2e_host_root_identity" ] || return 1
  nuinui_e2e_host_owner=$(nuinui_e2e_host__owner_path "$nuinui_e2e_host_verify_root")
  nuinui_e2e_host_fixture_copy=$(nuinui_e2e_host__fixture_copy_path "$nuinui_e2e_host_verify_root")
  nuinui_e2e_host_expected_owner=$(nuinui_e2e_host__owner_content)
  if nuinui_e2e__exists "$nuinui_e2e_host_owner"; then
    nuinui_e2e__regular "$nuinui_e2e_host_owner" || return 1
    printf '%s' "$nuinui_e2e_host_expected_owner" |
      cmp -s - "$nuinui_e2e_host_owner" || return 1
  elif [ "$nuinui_e2e_host_verify_mode" = complete ]; then
    return 1
  fi
  if nuinui_e2e__exists "$nuinui_e2e_host_fixture_copy"; then
    nuinui_e2e__regular "$nuinui_e2e_host_fixture_copy" || return 1
    [ "$(nuinui_e2e__sha256 "$nuinui_e2e_host_fixture_copy")" = \
      "$nuinui_e2e_host_fixture_sha" ] || return 1
  elif [ "$nuinui_e2e_host_verify_mode" = complete ]; then
    return 1
  fi
  nuinui_e2e_host_root_entries=$(find "$nuinui_e2e_host_verify_root" -mindepth 1 \
    -maxdepth 1 -print 2>/dev/null) || return 1
  while IFS= read -r nuinui_e2e_host_root_entry || [ -n "$nuinui_e2e_host_root_entry" ]; do
    [ -n "$nuinui_e2e_host_root_entry" ] || continue
    case "$nuinui_e2e_host_root_entry" in
      "$nuinui_e2e_host_owner"|"$nuinui_e2e_host_fixture_copy") ;;
      *) return 1 ;;
    esac
    [ ! -L "$nuinui_e2e_host_root_entry" ] || return 1
  done <<EOF
$nuinui_e2e_host_root_entries
EOF
  if [ "$nuinui_e2e_host_verify_mode" = complete ]; then
    nuinui_e2e__regular "$nuinui_e2e_host_owner" &&
      nuinui_e2e__regular "$nuinui_e2e_host_fixture_copy"
  else
    return 0
  fi
}

nuinui_e2e_host__remove_root() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_host_remove_mode=$1
  [ "$nuinui_e2e_host_remove_mode" = partial ] ||
    [ "$nuinui_e2e_host_remove_mode" = complete ] || return 2
  if ! nuinui_e2e__exists "$nuinui_e2e_host_root"; then
    return 0
  fi
  nuinui_e2e_host__verify_root "$nuinui_e2e_host_root" partial || return 1
  nuinui_e2e_host_owner=$(nuinui_e2e_host__owner_path "$nuinui_e2e_host_root")
  nuinui_e2e_host_fixture_copy=$(nuinui_e2e_host__fixture_copy_path "$nuinui_e2e_host_root")
  if nuinui_e2e__exists "$nuinui_e2e_host_fixture_copy"; then
    [ "$(nuinui_e2e__sha256 "$nuinui_e2e_host_fixture_copy")" = \
      "$nuinui_e2e_host_fixture_sha" ] || return 1
    rm "$nuinui_e2e_host_fixture_copy" || return 1
  fi
  if nuinui_e2e__exists "$nuinui_e2e_host_owner"; then
    nuinui_e2e_host_expected_owner=$(nuinui_e2e_host__owner_content)
    nuinui_e2e__regular "$nuinui_e2e_host_owner" || return 1
    printf '%s' "$nuinui_e2e_host_expected_owner" |
      cmp -s - "$nuinui_e2e_host_owner" || return 1
    rm "$nuinui_e2e_host_owner" || return 1
  fi
  [ -z "$(find "$nuinui_e2e_host_root" -mindepth 1 -maxdepth 1 -print 2>/dev/null)" ] || return 1
  [ "$(nuinui_e2e_host__root_identity "$nuinui_e2e_host_root")" = \
    "$nuinui_e2e_host_root_identity" ] || return 1
  rmdir "$nuinui_e2e_host_root"
}
