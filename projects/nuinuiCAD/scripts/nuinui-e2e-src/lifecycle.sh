# Isolated, fixture-only native E2E ownership lifecycle.

nuinui_e2e__exists() { [ -e "$1" ] || [ -L "$1" ]; }

nuinui_e2e__regular() { [ -f "$1" ] && [ ! -L "$1" ]; }

nuinui_e2e__sha256() {
  [ "$#" = 1 ] || return 2
  shasum -a 256 "$1" 2>/dev/null | awk 'NR == 1 {print $1}'
}

nuinui_e2e__generation_hash() {
  printf '%s\n' "$1" | shasum -a 256 2>/dev/null | awk 'NR == 1 {print $1}'
}

nuinui_e2e__under() {
  case "$2" in
    "$1"/*) return 0 ;;
    *) return 1 ;;
  esac
}

nuinui_e2e__origin_identity() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_origin_repo=$1
  nuinui_e2e_origin_fixture_root=$2
  nuinui_e2e_origin=$(git -C "$nuinui_e2e_origin_repo" \
    remote get-url origin 2>/dev/null) || return 1
  case "$nuinui_e2e_origin" in
    https://github.com/sayosomi/nuinuiCAD|https://github.com/sayosomi/nuinuiCAD.git|\
    git@github.com:sayosomi/nuinuiCAD|git@github.com:sayosomi/nuinuiCAD.git|\
    ssh://git@github.com/sayosomi/nuinuiCAD|ssh://git@github.com/sayosomi/nuinuiCAD.git)
      return 0
      ;;
  esac
  lane_execution__repository_matches "$nuinui_e2e_origin_repo" \
    sayosomi/nuinuiCAD || return 1
  nuinui_e2e_origin=${nuinui_e2e_origin%/}
  case "$nuinui_e2e_origin" in
    "$nuinui_e2e_origin_fixture_root"/sayosomi/nuinuiCAD|\
    "$nuinui_e2e_origin_fixture_root"/sayosomi/nuinuiCAD.git|\
    "$nuinui_e2e_origin_fixture_root"/*/sayosomi/nuinuiCAD|\
    "$nuinui_e2e_origin_fixture_root"/*/sayosomi/nuinuiCAD.git) return 0 ;;
    *) return 1 ;;
  esac
}

nuinui_e2e__path_for() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_path_repo=$1
  nuinui_e2e_path_kind=$2
  nuinui_e2e_path_git_dir=$(lane_execution__git_dir "$nuinui_e2e_path_repo") || return 1
  case "$nuinui_e2e_path_kind" in
    active) printf '%s/nuinui-github-e2e-active-v1\n' "$nuinui_e2e_path_git_dir" ;;
    starting) printf '%s/nuinui-github-e2e-starting-v1.%s\n' \
      "$nuinui_e2e_path_git_dir" "$(nuinui_e2e__generation_hash "$nuinui_e2e_expected_generation")" ;;
    cleanup) printf '%s/nuinui-github-e2e-cleanup-v1.%s\n' \
      "$nuinui_e2e_path_git_dir" "$(nuinui_e2e__generation_hash "$nuinui_e2e_expected_generation")" ;;
    release) printf '%s/nuinui-github-e2e-release-v1.%s\n' \
      "$nuinui_e2e_path_git_dir" "$(nuinui_e2e__generation_hash "$nuinui_e2e_expected_generation")" ;;
    releasing) printf '%s/nuinui-github-e2e-releasing-v1.%s\n' \
      "$nuinui_e2e_path_git_dir" "$(nuinui_e2e__generation_hash "$nuinui_e2e_expected_generation")" ;;
    *) return 2 ;;
  esac
}

nuinui_e2e__read_record() {
  [ "$#" -ge 2 ] && [ "$#" -le 3 ] || return 2
  nuinui_e2e_record_path=$1
  nuinui_e2e_record_kind=$2
  nuinui_e2e_record_fixture_policy=${3:-${nuinui_e2e_host_fixture_policy:-required}}
  case "$nuinui_e2e_record_fixture_policy" in required|historical) ;; *) return 2 ;; esac
  nuinui_e2e_record_base_keys=schema_version,issue,issue_url,local_id,lane,repository,checkout,git_dir,manifest,manifest_sha256,default_branch,idle_policy,tested_sha,generation
  case "$nuinui_e2e_record_kind" in
    active) nuinui_e2e_record_keys=$nuinui_e2e_record_base_keys ;;
    cleanup)
      nuinui_e2e_record_proof=$(nuinui_ownership_field "$nuinui_e2e_record_path" proof) || return 1
      case "$nuinui_e2e_record_proof" in
        fixture-no-host-session) nuinui_e2e_record_keys=$nuinui_e2e_record_base_keys,proof ;;
        fixture-host-session-cleaned) nuinui_e2e_record_keys=$nuinui_e2e_record_base_keys,proof,host_cleanup_sha256 ;;
        *) return 1 ;;
      esac
      ;;
    starting|release|releasing) nuinui_e2e_record_keys=$nuinui_e2e_record_base_keys,idle_sha,record_state ;;
    *) return 2 ;;
  esac
  nuinui_e2e__regular "$nuinui_e2e_record_path" || return 1
  nuinui_ownership_validate_exact_file "$nuinui_e2e_record_path" \
    "$nuinui_e2e_record_keys" || return 1
  nuinui_e2e_r_schema=$(nuinui_ownership_field "$nuinui_e2e_record_path" schema_version) || return 1
  nuinui_e2e_r_issue=$(nuinui_ownership_field "$nuinui_e2e_record_path" issue) || return 1
  nuinui_e2e_r_url=$(nuinui_ownership_field "$nuinui_e2e_record_path" issue_url) || return 1
  nuinui_e2e_r_token=$(nuinui_ownership_field "$nuinui_e2e_record_path" local_id) || return 1
  nuinui_e2e_r_lane=$(nuinui_ownership_field "$nuinui_e2e_record_path" lane) || return 1
  nuinui_e2e_r_repository=$(nuinui_ownership_field "$nuinui_e2e_record_path" repository) || return 1
  nuinui_e2e_r_checkout=$(nuinui_ownership_field "$nuinui_e2e_record_path" checkout) || return 1
  nuinui_e2e_r_git_dir=$(nuinui_ownership_field "$nuinui_e2e_record_path" git_dir) || return 1
  nuinui_e2e_r_manifest=$(nuinui_ownership_field "$nuinui_e2e_record_path" manifest) || return 1
  nuinui_e2e_r_manifest_sha=$(nuinui_ownership_field "$nuinui_e2e_record_path" manifest_sha256) || return 1
  nuinui_e2e_r_default=$(nuinui_ownership_field "$nuinui_e2e_record_path" default_branch) || return 1
  nuinui_e2e_r_idle=$(nuinui_ownership_field "$nuinui_e2e_record_path" idle_policy) || return 1
  nuinui_e2e_r_tested=$(nuinui_ownership_field "$nuinui_e2e_record_path" tested_sha) || return 1
  nuinui_e2e_r_generation=$(nuinui_ownership_field "$nuinui_e2e_record_path" generation) || return 1
  [ "$nuinui_e2e_r_schema" = 1 ] || return 1
  nuinui_e2e_r_number=$(nuinui_e2e_identity_number "$nuinui_e2e_r_issue") || return 1
  [ "$nuinui_e2e_r_url" = "$(nuinui_e2e_identity_url "$nuinui_e2e_r_issue")" ] || return 1
  [ "$nuinui_e2e_r_token" = "$(nuinui_e2e_identity_token "$nuinui_e2e_r_issue")" ] || return 1
  lane_manifest_validate_lane_name "$nuinui_e2e_manifest_path" "$nuinui_e2e_r_lane" >/dev/null 2>&1 || return 1
  [ "$nuinui_e2e_r_repository" = sayosomi/nuinuiCAD ] || return 1
  nuinui_e2e_valid_digest "$nuinui_e2e_r_manifest_sha" || return 1
  nuinui_e2e_valid_sha "$nuinui_e2e_r_tested" || return 1
  nuinui_e2e_valid_generation "$nuinui_e2e_r_generation" || return 1
  [ "$nuinui_e2e_r_default" = "$(lane_manifest_default_branch "$nuinui_e2e_manifest_path")" ] || return 1
  [ "$nuinui_e2e_r_idle" = detached ] || return 1
  case "$nuinui_e2e_r_checkout:$nuinui_e2e_r_git_dir:$nuinui_e2e_r_manifest" in
    /*:/*:/*) ;;
    *) return 1 ;;
  esac
  if [ "$nuinui_e2e_record_kind" = cleanup ]; then
    nuinui_e2e_r_proof=$(nuinui_ownership_field "$nuinui_e2e_record_path" proof) || return 1
    case "$nuinui_e2e_r_proof" in
      fixture-no-host-session) ;;
      fixture-host-session-cleaned)
        nuinui_e2e_r_host_cleanup_sha=$(nuinui_ownership_field \
          "$nuinui_e2e_record_path" host_cleanup_sha256) || return 1
        nuinui_e2e_valid_digest "$nuinui_e2e_r_host_cleanup_sha" &&
          nuinui_e2e_host__cleanup_proof_matches \
            "$nuinui_e2e_r_host_cleanup_sha" "$nuinui_e2e_r_issue" \
            "$nuinui_e2e_r_lane" "$nuinui_e2e_r_generation" \
            "$nuinui_e2e_r_tested" "$nuinui_e2e_record_fixture_policy" || return 1
        ;;
      *) return 1 ;;
    esac
  elif [ "$nuinui_e2e_record_kind" = starting ] ||
    [ "$nuinui_e2e_record_kind" = release ] ||
    [ "$nuinui_e2e_record_kind" = releasing ]; then
    nuinui_e2e_r_idle_sha=$(nuinui_ownership_field "$nuinui_e2e_record_path" idle_sha) || return 1
    nuinui_e2e_r_state=$(nuinui_ownership_field "$nuinui_e2e_record_path" record_state) || return 1
    nuinui_e2e_valid_sha "$nuinui_e2e_r_idle_sha" || return 1
    if [ "$nuinui_e2e_record_kind" = starting ]; then
      [ "$nuinui_e2e_r_state" = pending ] || return 1
    elif [ "$nuinui_e2e_record_kind" = release ]; then
      [ "$nuinui_e2e_r_state" = complete ] || return 1
    else
      [ "$nuinui_e2e_r_state" = pending ] || return 1
    fi
  fi
  return 0
}

nuinui_e2e__record_matches_lane() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_match_lane=$1
  nuinui_e2e_match_repo=$2
  nuinui_e2e_match_manifest=$3
  nuinui_e2e_match_path=$(lane_execution__canonical_path "$nuinui_e2e_match_repo") || return 1
  nuinui_e2e_match_git_dir=$(lane_execution__git_dir "$nuinui_e2e_match_repo") || return 1
  [ "$nuinui_e2e_r_lane" = "$nuinui_e2e_match_lane" ] &&
    [ "$nuinui_e2e_r_checkout" = "$nuinui_e2e_match_path" ] &&
    [ "$nuinui_e2e_r_git_dir" = "$nuinui_e2e_match_git_dir" ] &&
    [ "$nuinui_e2e_r_manifest" = "$nuinui_e2e_manifest_path" ] &&
    [ "$nuinui_e2e_r_manifest_sha" = "$nuinui_e2e_manifest_sha" ] &&
    [ "$nuinui_e2e_r_default" = "$nuinui_e2e_default_branch" ] &&
    [ "$nuinui_e2e_match_manifest" = "$nuinui_e2e_manifest_path" ]
}

nuinui_e2e__read_expected_active() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e__read_record "$1" active || return 1
  [ "$nuinui_e2e_r_issue" = "$nuinui_e2e_expected_issue" ] &&
    [ "$nuinui_e2e_r_url" = "$nuinui_e2e_expected_url" ] &&
    [ "$nuinui_e2e_r_token" = "$nuinui_e2e_expected_token" ] &&
    [ "$nuinui_e2e_r_lane" = "$nuinui_e2e_expected_lane" ] &&
    [ "$nuinui_e2e_r_tested" = "$nuinui_e2e_expected_tested" ] &&
    [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_expected_generation" ] &&
    nuinui_e2e__record_matches_lane "$nuinui_e2e_expected_lane" \
      "$nuinui_e2e_expected_repo" "$nuinui_e2e_manifest_path"
}

nuinui_e2e__read_expected_starting() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e__read_record "$1" starting || return 1
  [ "$nuinui_e2e_r_issue" = "$nuinui_e2e_expected_issue" ] &&
    [ "$nuinui_e2e_r_url" = "$nuinui_e2e_expected_url" ] &&
    [ "$nuinui_e2e_r_token" = "$nuinui_e2e_expected_token" ] &&
    [ "$nuinui_e2e_r_lane" = "$nuinui_e2e_expected_lane" ] &&
    [ "$nuinui_e2e_r_tested" = "$nuinui_e2e_expected_tested" ] &&
    [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_expected_generation" ] &&
    nuinui_e2e__record_matches_lane "$nuinui_e2e_expected_lane" \
      "$nuinui_e2e_expected_repo" "$nuinui_e2e_manifest_path"
}

nuinui_e2e__read_expected_cleanup() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e__read_record "$1" cleanup || return 1
  [ "$nuinui_e2e_r_issue" = "$nuinui_e2e_expected_issue" ] &&
    [ "$nuinui_e2e_r_url" = "$nuinui_e2e_expected_url" ] &&
    [ "$nuinui_e2e_r_token" = "$nuinui_e2e_expected_token" ] &&
    [ "$nuinui_e2e_r_lane" = "$nuinui_e2e_expected_lane" ] &&
    [ "$nuinui_e2e_r_tested" = "$nuinui_e2e_expected_tested" ] &&
    [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_expected_generation" ] &&
    nuinui_e2e__record_matches_lane "$nuinui_e2e_expected_lane" \
      "$nuinui_e2e_expected_repo" "$nuinui_e2e_manifest_path"
}

nuinui_e2e__read_expected_release() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e__read_record "$1" release || return 1
  [ "$nuinui_e2e_r_issue" = "$nuinui_e2e_expected_issue" ] &&
    [ "$nuinui_e2e_r_url" = "$nuinui_e2e_expected_url" ] &&
    [ "$nuinui_e2e_r_token" = "$nuinui_e2e_expected_token" ] &&
    [ "$nuinui_e2e_r_lane" = "$nuinui_e2e_expected_lane" ] &&
    [ "$nuinui_e2e_r_tested" = "$nuinui_e2e_expected_tested" ] &&
    [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_expected_generation" ] &&
    nuinui_e2e__record_matches_lane "$nuinui_e2e_expected_lane" \
      "$nuinui_e2e_expected_repo" "$nuinui_e2e_manifest_path"
}

nuinui_e2e__read_expected_releasing() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e__read_record "$1" releasing || return 1
  [ "$nuinui_e2e_r_issue" = "$nuinui_e2e_expected_issue" ] &&
    [ "$nuinui_e2e_r_url" = "$nuinui_e2e_expected_url" ] &&
    [ "$nuinui_e2e_r_token" = "$nuinui_e2e_expected_token" ] &&
    [ "$nuinui_e2e_r_lane" = "$nuinui_e2e_expected_lane" ] &&
    [ "$nuinui_e2e_r_tested" = "$nuinui_e2e_expected_tested" ] &&
    [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_expected_generation" ] &&
    nuinui_e2e__record_matches_lane "$nuinui_e2e_expected_lane" \
      "$nuinui_e2e_expected_repo" "$nuinui_e2e_manifest_path"
}

nuinui_e2e__generation_seen() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_seen_generation=$1
  while IFS= read -r nuinui_e2e_seen_lane || [ -n "$nuinui_e2e_seen_lane" ]; do
    [ -n "$nuinui_e2e_seen_lane" ] || continue
    [ "$(lane_manifest_lane_role "$nuinui_e2e_manifest_path" \
      "$nuinui_e2e_seen_lane")" = human-test ] || continue
    nuinui_e2e_seen_repo=$(lane_manifest_lane_path "$nuinui_e2e_manifest_path" \
      "$nuinui_e2e_seen_lane") || return 1
    nuinui_e2e_seen_git_dir=$(lane_execution__git_dir "$nuinui_e2e_seen_repo") || return 1
    nuinui_e2e_seen_paths=$(find "$nuinui_e2e_seen_git_dir" -maxdepth 1 \
      -name 'nuinui-github-e2e-*' -print 2>/dev/null) || return 1
    while IFS= read -r nuinui_e2e_seen_path || [ -n "$nuinui_e2e_seen_path" ]; do
      [ -n "$nuinui_e2e_seen_path" ] || continue
      nuinui_e2e_seen_name=${nuinui_e2e_seen_path##*/}
      case "$nuinui_e2e_seen_name" in
        nuinui-github-e2e-active-v1) nuinui_e2e_seen_kind=active ;;
        nuinui-github-e2e-starting-v1.*) nuinui_e2e_seen_kind=starting ;;
        nuinui-github-e2e-cleanup-v1.*) nuinui_e2e_seen_kind=cleanup ;;
        nuinui-github-e2e-release-v1.*) nuinui_e2e_seen_kind=release ;;
        nuinui-github-e2e-releasing-v1.*) nuinui_e2e_seen_kind=releasing ;;
        nuinui-github-e2e-host-*)
          nuinui_e2e_seen_kind=$(nuinui_e2e_host__kind_from_name "$nuinui_e2e_seen_name") || return 1
          nuinui_e2e_host__read_record "$nuinui_e2e_seen_path" \
            "$nuinui_e2e_seen_kind" historical || return 1
          [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_seen_generation" ] && return 0
          continue
          ;;
        *) return 1 ;;
      esac
      nuinui_e2e__read_record "$nuinui_e2e_seen_path" "$nuinui_e2e_seen_kind" || return 1
      [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_seen_generation" ] && return 0
    done <<EOF
$nuinui_e2e_seen_paths
EOF
  done <<EOF
$nuinui_e2e_human_lanes
EOF
  return 1
}

nuinui_e2e__record_base() {
  printf 'schema_version=1\n'
  printf 'issue=%s\n' "$nuinui_e2e_expected_issue"
  printf 'issue_url=%s\n' "$nuinui_e2e_expected_url"
  printf 'local_id=%s\n' "$nuinui_e2e_expected_token"
  printf 'lane=%s\n' "$nuinui_e2e_expected_lane"
  printf 'repository=sayosomi/nuinuiCAD\n'
  printf 'checkout=%s\n' "$nuinui_e2e_checkout"
  printf 'git_dir=%s\n' "$nuinui_e2e_git_dir"
  printf 'manifest=%s\n' "$nuinui_e2e_manifest_path"
  printf 'manifest_sha256=%s\n' "$nuinui_e2e_manifest_sha"
  printf 'default_branch=%s\n' "$nuinui_e2e_default_branch"
  printf 'idle_policy=detached\n'
  printf 'tested_sha=%s\n' "$nuinui_e2e_expected_tested"
  printf 'generation=%s\n' "$nuinui_e2e_expected_generation"
}

nuinui_e2e__atomic_create() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_write_path=$1
  nuinui_e2e_write_content=$2
  nuinui_e2e_write_dir=${nuinui_e2e_write_path%/*}
  [ ! -e "$nuinui_e2e_write_path" ] && [ ! -L "$nuinui_e2e_write_path" ] || return 1
  nuinui_e2e_write_tmp=$(mktemp "$nuinui_e2e_write_dir/.nuinui-github-e2e.tmp.XXXXXX") || return 1
  if ! (umask 077; printf '%s' "$nuinui_e2e_write_content" > "$nuinui_e2e_write_tmp"); then
    rm -f "$nuinui_e2e_write_tmp"
    return 1
  fi
  if ! ln "$nuinui_e2e_write_tmp" "$nuinui_e2e_write_path"; then
    rm -f "$nuinui_e2e_write_tmp"
    return 1
  fi
  rm -f "$nuinui_e2e_write_tmp"
  nuinui_e2e__regular "$nuinui_e2e_write_path"
}

nuinui_e2e__remove_exact() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_remove_path=$1
  nuinui_e2e_remove_content=$2
  nuinui_e2e_remove_dir=${nuinui_e2e_remove_path%/*}
  nuinui_e2e__regular "$nuinui_e2e_remove_path" || return 1
  nuinui_e2e_remove_tmp=$(mktemp "$nuinui_e2e_remove_dir/.nuinui-github-e2e.verify.XXXXXX") || return 1
  if ! (umask 077; printf '%s' "$nuinui_e2e_remove_content" > "$nuinui_e2e_remove_tmp"); then
    rm -f "$nuinui_e2e_remove_tmp"
    return 1
  fi
  if ! cmp -s "$nuinui_e2e_remove_tmp" "$nuinui_e2e_remove_path"; then
    rm -f "$nuinui_e2e_remove_tmp"
    return 1
  fi
  rm -f "$nuinui_e2e_remove_tmp" && rm "$nuinui_e2e_remove_path"
}

nuinui_e2e__fixture_context() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_manifest_input=$1
  nuinui_e2e_expected_lane=$2
  nuinui_e2e_manifest_arg_issue=$3
  [ -n "${nuinui_e2e_self_test:-}" ] || {
    echo 'BLOCKED: candidate lifecycle is inactive outside explicit self-test mode'
    return 1
  }
  case "$nuinui_e2e_manifest_input" in /*) ;; *) echo 'BLOCKED: manifest path must be absolute' ; return 1 ;; esac
  nuinui_e2e__regular "$nuinui_e2e_manifest_input" || {
    echo 'BLOCKED: self-test manifest must be a regular, non-symlink file'
    return 1
  }
  nuinui_e2e_manifest_path=$(realpath "$nuinui_e2e_manifest_input" 2>/dev/null) || return 1
  [ "$nuinui_e2e_manifest_path" = "$nuinui_e2e_manifest_input" ] || {
    echo 'BLOCKED: self-test manifest path is not canonical'
    return 1
  }
  [ "${nuinui_e2e_manifest_path##*/}" = LANES.conf ] || {
    echo 'BLOCKED: self-test manifest must be named LANES.conf'
    return 1
  }
  nuinui_e2e_fixture_root=${nuinui_e2e_manifest_path%/*}
  nuinui_e2e_fixture_root=$(realpath "$nuinui_e2e_fixture_root" 2>/dev/null) || return 1
  nuinui_e2e_temp_parent=$(realpath "${TMPDIR:-/tmp}" 2>/dev/null) || return 1
  [ "${nuinui_e2e_fixture_root%/*}" = "$nuinui_e2e_temp_parent" ] || {
    echo 'BLOCKED: self-test manifest is outside its disposable temporary root'
    return 1
  }
  case "${nuinui_e2e_fixture_root##*/}" in nuinui-e2e-fixture.*) ;; *)
    echo 'BLOCKED: self-test root does not have the disposable fixture identity'
    return 1 ;;
  esac
  [ ! -L "$nuinui_e2e_fixture_root" ] && [ -d "$nuinui_e2e_fixture_root" ] || return 1
  nuinui_e2e_fixture_marker=$nuinui_e2e_fixture_root/.nuinui-e2e-fixture
  nuinui_e2e__regular "$nuinui_e2e_fixture_marker" || {
    echo 'BLOCKED: disposable fixture marker is missing or unsafe'
    return 1
  }
  [ "$(cat "$nuinui_e2e_fixture_marker" 2>/dev/null)" = 'schema_version=1' ] || {
    echo 'BLOCKED: disposable fixture marker is malformed'
    return 1
  }
  lane_manifest_validate "$nuinui_e2e_manifest_path" || return 1
  nuinui_e2e_manifest_repository=$(lane_manifest_repository_identity "$nuinui_e2e_manifest_path") || return 1
  [ "$nuinui_e2e_manifest_repository" = sayosomi/nuinuiCAD ] || {
    echo 'BLOCKED: fixture manifest repository identity is not sayosomi/nuinuiCAD'
    return 1
  }
  nuinui_e2e_default_branch=$(lane_manifest_default_branch "$nuinui_e2e_manifest_path") || return 1
  nuinui_e2e_manifest_sha=$(nuinui_e2e__sha256 "$nuinui_e2e_manifest_path") || return 1
  nuinui_e2e_valid_digest "$nuinui_e2e_manifest_sha" || return 1

  nuinui_e2e_manifest_lanes=$(lane_manifest_all_lanes "$nuinui_e2e_manifest_path") || return 1
  [ -n "$nuinui_e2e_manifest_lanes" ] || return 1
  while IFS= read -r nuinui_e2e_manifest_lane || [ -n "$nuinui_e2e_manifest_lane" ]; do
    [ -n "$nuinui_e2e_manifest_lane" ] || continue
    nuinui_e2e_lane_path=$(lane_manifest_lane_path "$nuinui_e2e_manifest_path" \
      "$nuinui_e2e_manifest_lane") || return 1
    case "$nuinui_e2e_lane_path" in /*) ;; *) return 1 ;; esac
    nuinui_e2e_lane_real=$(realpath "$nuinui_e2e_lane_path" 2>/dev/null) || return 1
    [ "$nuinui_e2e_lane_real" = "$nuinui_e2e_lane_path" ] &&
      nuinui_e2e__under "$nuinui_e2e_fixture_root" "$nuinui_e2e_lane_real" || {
        echo "BLOCKED: declared fixture checkout is not a direct disposable target: $nuinui_e2e_manifest_lane"
        return 1
      }
    [ -d "$nuinui_e2e_lane_real" ] && [ ! -L "$nuinui_e2e_lane_real" ] || return 1
    git -C "$nuinui_e2e_lane_real" rev-parse --show-toplevel >/dev/null 2>&1 || return 1
    lane_execution__repository_matches "$nuinui_e2e_lane_real" \
      sayosomi/nuinuiCAD || return 1
    nuinui_e2e__origin_identity "$nuinui_e2e_lane_real" \
      "$nuinui_e2e_fixture_root" || {
        echo "BLOCKED: fixture checkout has a foreign origin: $nuinui_e2e_manifest_lane"
        return 1
      }
  done <<EOF
$nuinui_e2e_manifest_lanes
EOF

  nuinui_e2e_human_lanes=$(lane_manifest_lanes_by_role \
    "$nuinui_e2e_manifest_path" human-test) || return 1
  [ -n "$nuinui_e2e_human_lanes" ] || {
    echo 'BLOCKED: no Human-test lane is declared'
    return 1
  }
  if [ -z "$nuinui_e2e_expected_lane" ]; then
    nuinui_e2e_human_count=$(printf '%s\n' "$nuinui_e2e_human_lanes" | grep -c . || true)
    [ "$nuinui_e2e_human_count" = 1 ] || {
      echo 'BLOCKED: explicit lane is required unless exactly one Human-test lane exists'
      return 1
    }
    nuinui_e2e_expected_lane=$nuinui_e2e_human_lanes
  fi
  lane_manifest_validate_lane_name "$nuinui_e2e_manifest_path" \
    "$nuinui_e2e_expected_lane" >/dev/null 2>&1 || return 1
  [ "$(lane_manifest_lane_role "$nuinui_e2e_manifest_path" \
    "$nuinui_e2e_expected_lane")" = human-test ] || {
    echo 'BLOCKED: selected lane is not a declared Human-test lane'
    return 1
  }
  [ "$(lane_manifest_lane_idle_policy "$nuinui_e2e_manifest_path" \
    "$nuinui_e2e_expected_lane")" = detached ] || {
    echo 'BLOCKED: native candidate requires a detached Human-test idle policy'
    return 1
  }
  nuinui_e2e_expected_repo=$(lane_manifest_lane_path "$nuinui_e2e_manifest_path" \
    "$nuinui_e2e_expected_lane") || return 1
  nuinui_e2e_checkout=$(realpath "$nuinui_e2e_expected_repo" 2>/dev/null) || return 1
  [ "$nuinui_e2e_checkout" = "$nuinui_e2e_expected_repo" ] || return 1
  nuinui_e2e_git_dir=$(lane_execution__git_dir "$nuinui_e2e_checkout") || return 1
  [ -d "$nuinui_e2e_git_dir" ] && [ ! -L "$nuinui_e2e_git_dir" ] || return 1
  nuinui_e2e_expected_issue=$(nuinui_e2e_identity_issue "$nuinui_e2e_manifest_arg_issue") || {
    echo 'BLOCKED: Issue identity is not canonical for sayosomi/nuinuiCAD'
    return 1
  }
  nuinui_e2e_expected_url=$(nuinui_e2e_identity_url "$nuinui_e2e_expected_issue") || return 1
  nuinui_e2e_expected_token=$(nuinui_e2e_identity_token "$nuinui_e2e_expected_issue") || return 1
  nuinui_e2e_valid_generation "$nuinui_e2e_expected_generation" || {
    echo 'BLOCKED: generation must be a unique canonical caller-supplied token'
    return 1
  }
  nuinui_e2e_valid_sha "$nuinui_e2e_expected_tested" || {
    echo 'BLOCKED: tested commit must be an exact lowercase 40-character SHA'
    return 1
  }
  [ "$nuinui_e2e_expected_lane" != '' ]
}

nuinui_e2e__lane_preflight_state() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_check_lane=$1
  nuinui_e2e_check_repo=$2
  nuinui_e2e_check_manifest=$3
  nuinui_e2e_check_git_dir=$(lane_execution__git_dir "$nuinui_e2e_check_repo") || return 1
  for nuinui_e2e_legacy_path in \
    "$nuinui_e2e_check_git_dir/nuinui-slot" \
    "$nuinui_e2e_check_git_dir/nuinui-e2e-session" \
    "$nuinui_e2e_check_git_dir/nuinui-implementation-v1" \
    "$nuinui_e2e_check_git_dir/nuinui-implementation-slot" \
    "$nuinui_e2e_check_git_dir/nuinui-implementation-lock" \
    "$nuinui_e2e_check_git_dir/nuinui-audit-reservation-v1" \
    "$nuinui_e2e_check_git_dir/nuinui-implementation-release-receipt"; do
    if nuinui_e2e__exists "$nuinui_e2e_legacy_path"; then
      echo "  state=BLOCKED reason=foreign-or-legacy-ownership"
      return 1
    fi
  done
  nuinui_e2e_release_dirs=$(find "$nuinui_e2e_check_git_dir" -maxdepth 1 \
    -type d -name 'nuinui-implementation-slot.releasing.*' -print 2>/dev/null) || return 1
  [ -z "$nuinui_e2e_release_dirs" ] || {
    echo '  state=BLOCKED reason=foreign-release-ownership'
    return 1
  }

  nuinui_e2e_lane_active=no
  nuinui_e2e_lane_starting=no
  nuinui_e2e_lane_releasing=no
  nuinui_e2e_native_paths=$(find "$nuinui_e2e_check_git_dir" -maxdepth 1 \
    -name 'nuinui-github-e2e-*' -print 2>/dev/null) || return 1
  while IFS= read -r nuinui_e2e_native_path || [ -n "$nuinui_e2e_native_path" ]; do
    [ -n "$nuinui_e2e_native_path" ] || continue
    nuinui_e2e_native_name=${nuinui_e2e_native_path##*/}
    case "$nuinui_e2e_native_name" in
      nuinui-github-e2e-active-v1) nuinui_e2e_native_kind=active ;;
      nuinui-github-e2e-starting-v1.*) nuinui_e2e_native_kind=starting ;;
      nuinui-github-e2e-cleanup-v1.*) nuinui_e2e_native_kind=cleanup ;;
      nuinui-github-e2e-release-v1.*) nuinui_e2e_native_kind=release ;;
        nuinui-github-e2e-releasing-v1.*) nuinui_e2e_native_kind=releasing ;;
        nuinui-github-e2e-host-*)
          nuinui_e2e_native_kind=$(nuinui_e2e_host__kind_from_name "$nuinui_e2e_native_name") || {
            echo '  state=BLOCKED reason=unknown-host-metadata'
            return 1
          }
          nuinui_e2e_host__read_record "$nuinui_e2e_native_path" \
            "$nuinui_e2e_native_kind" historical || {
            echo '  state=BLOCKED reason=malformed-host-metadata'
            return 1
          }
          nuinui_e2e__record_matches_lane "$nuinui_e2e_check_lane" \
            "$nuinui_e2e_check_repo" "$nuinui_e2e_manifest_path" || return 1
          nuinui_e2e_native_hash=$(nuinui_e2e__generation_hash "$nuinui_e2e_r_generation") || return 1
          case "$nuinui_e2e_native_name" in
            nuinui-github-e2e-host-intent-v1."$nuinui_e2e_native_hash"|\
            nuinui-github-e2e-host-handoff-v1."$nuinui_e2e_native_hash"|\
            nuinui-github-e2e-host-ready-v1."$nuinui_e2e_native_hash"|\
            nuinui-github-e2e-host-cleanup-pending-v1."$nuinui_e2e_native_hash"|\
            nuinui-github-e2e-host-cleanup-v1."$nuinui_e2e_native_hash") ;;
            *) echo '  state=BLOCKED reason=host-generation-path-mismatch'; return 1 ;;
          esac
          continue
          ;;
      *) echo '  state=BLOCKED reason=unknown-native-metadata'; return 1 ;;
    esac
    nuinui_e2e__read_record "$nuinui_e2e_native_path" \
      "$nuinui_e2e_native_kind" historical || {
        echo '  state=BLOCKED reason=malformed-native-metadata'
        return 1
      }
    nuinui_e2e__record_matches_lane "$nuinui_e2e_check_lane" \
      "$nuinui_e2e_check_repo" "$nuinui_e2e_manifest_path" || {
        echo '  state=BLOCKED reason=native-metadata-context-mismatch'
        return 1
      }
    nuinui_e2e_file_hash=$(nuinui_e2e__generation_hash "$nuinui_e2e_r_generation") || return 1
    case "$nuinui_e2e_native_kind:$nuinui_e2e_native_name" in
      cleanup:nuinui-github-e2e-cleanup-v1."$nuinui_e2e_file_hash"|\
      starting:nuinui-github-e2e-starting-v1."$nuinui_e2e_file_hash"|\
      release:nuinui-github-e2e-release-v1."$nuinui_e2e_file_hash"|\
      releasing:nuinui-github-e2e-releasing-v1."$nuinui_e2e_file_hash"|\
      active:nuinui-github-e2e-active-v1) ;;
      *) echo '  state=BLOCKED reason=native-generation-path-mismatch'; return 1 ;;
    esac
    case "$nuinui_e2e_native_kind" in
      active)
        [ "$nuinui_e2e_check_lane" = "$nuinui_e2e_expected_lane" ] &&
          [ "$nuinui_e2e_r_issue" = "$nuinui_e2e_expected_issue" ] &&
          [ "$nuinui_e2e_r_url" = "$nuinui_e2e_expected_url" ] &&
          [ "$nuinui_e2e_r_token" = "$nuinui_e2e_expected_token" ] &&
          [ "$nuinui_e2e_r_tested" = "$nuinui_e2e_expected_tested" ] &&
          [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_expected_generation" ] || {
            echo '  state=BLOCKED reason=foreign-or-mismatched-active-generation'
            return 1
          }
        nuinui_e2e_lane_active=yes
        ;;
      starting)
        [ "$nuinui_e2e_check_lane" = "$nuinui_e2e_expected_lane" ] &&
          [ "$nuinui_e2e_r_issue" = "$nuinui_e2e_expected_issue" ] &&
          [ "$nuinui_e2e_r_tested" = "$nuinui_e2e_expected_tested" ] &&
          [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_expected_generation" ] &&
          { [ "$nuinui_e2e_operation" = recover ] ||
            [ "$nuinui_e2e_operation" = status ] ||
            [ "$nuinui_e2e_operation" = start ]; } || {
            echo '  state=BLOCKED reason=start-recovery-required'
            return 1
          }
        nuinui_e2e_lane_starting=yes
        ;;
      releasing)
        [ "$nuinui_e2e_check_lane" = "$nuinui_e2e_expected_lane" ] &&
          [ "$nuinui_e2e_r_issue" = "$nuinui_e2e_expected_issue" ] &&
          [ "$nuinui_e2e_r_tested" = "$nuinui_e2e_expected_tested" ] &&
          [ "$nuinui_e2e_r_generation" = "$nuinui_e2e_expected_generation" ] &&
          { [ "$nuinui_e2e_operation" = recover ] || [ "$nuinui_e2e_operation" = status ]; } || {
            echo '  state=BLOCKED reason=release-recovery-required'
            return 1
          }
        nuinui_e2e_lane_releasing=yes
        ;;
    esac
  done <<EOF
$nuinui_e2e_native_paths
EOF
  nuinui_e2e_host__preflight_scan "$nuinui_e2e_check_git_dir" \
    "$nuinui_e2e_check_lane" || {
      echo '  state=BLOCKED reason=host-session-state-conflict'
      return 1
    }
  if [ "$nuinui_e2e_lane_starting" = yes ] &&
    [ "$nuinui_e2e_lane_releasing" = yes ]; then
    echo '  state=BLOCKED reason=conflicting-start-and-release-intents'
    return 1
  fi
  nuinui_e2e_branch=$(git -C "$nuinui_e2e_check_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  nuinui_e2e_head=$(git -C "$nuinui_e2e_check_repo" rev-parse HEAD 2>/dev/null) || return 1
  nuinui_e2e_dirty=$(git -C "$nuinui_e2e_check_repo" status --porcelain 2>/dev/null) || return 1
  [ -z "$nuinui_e2e_branch" ] && [ -z "$nuinui_e2e_dirty" ] || {
    echo '  state=BLOCKED reason=Human-test-checkout-not-clean-detached'
    return 1
  }
  if [ "$nuinui_e2e_lane_active" = yes ]; then
    [ "$nuinui_e2e_check_lane" = "$nuinui_e2e_expected_lane" ] || return 1
    nuinui_e2e_active_path=$(nuinui_e2e__path_for "$nuinui_e2e_check_repo" active) || return 1
    nuinui_e2e__read_expected_active "$nuinui_e2e_active_path" || return 1
    if [ "$nuinui_e2e_lane_starting" = yes ]; then
      case "$nuinui_e2e_operation" in
        status|start|recover) ;;
        *) echo '  state=BLOCKED reason=start-recovery-required'; return 1 ;;
      esac
      nuinui_e2e_starting_path=$(nuinui_e2e__path_for \
        "$nuinui_e2e_check_repo" starting) || return 1
      nuinui_e2e__read_expected_starting "$nuinui_e2e_starting_path" || return 1
      [ "$nuinui_e2e_head" = "$nuinui_e2e_expected_tested" ] &&
        git -C "$nuinui_e2e_check_repo" merge-base --is-ancestor \
          "$nuinui_e2e_r_idle_sha" "$nuinui_e2e_expected_tested" || {
            echo '  state=BLOCKED reason=start-intent-does-not-match-tested-checkout'
            return 1
          }
    fi
    if [ "$nuinui_e2e_lane_releasing" = yes ]; then
      nuinui_e2e_releasing_path=$(nuinui_e2e__path_for "$nuinui_e2e_check_repo" releasing) || return 1
      nuinui_e2e__read_expected_releasing "$nuinui_e2e_releasing_path" || return 1
      nuinui_e2e_lane_intent_idle=$nuinui_e2e_r_idle_sha
      nuinui_e2e_release_path=$(nuinui_e2e__path_for "$nuinui_e2e_check_repo" release) || return 1
      if nuinui_e2e__exists "$nuinui_e2e_release_path"; then
        nuinui_e2e__read_expected_release "$nuinui_e2e_release_path" &&
          [ "$nuinui_e2e_r_idle_sha" = "$nuinui_e2e_lane_intent_idle" ] || return 1
      fi
      [ "$nuinui_e2e_head" = "$nuinui_e2e_expected_tested" ] ||
        [ "$nuinui_e2e_head" = "$nuinui_e2e_r_idle_sha" ] || return 1
      echo '  branch=DETACHED'
      echo "  head=$nuinui_e2e_head"
      echo '  clean=yes'
      echo '  state=RELEASE-PENDING'
      return 0
    fi
    nuinui_e2e_release_path=$(nuinui_e2e__path_for "$nuinui_e2e_check_repo" release) || return 1
    if nuinui_e2e__exists "$nuinui_e2e_release_path"; then
      echo '  state=BLOCKED reason=completed-receipt-precedes-active-marker-without-intent'
      return 1
    fi
    [ "$nuinui_e2e_head" = "$nuinui_e2e_expected_tested" ] || return 1
    case "$nuinui_e2e_operation" in
      admit|status|start|cleanup-proof|release|recover|host-check|host-prepare|host-status|host-cleanup|host-recover|host-closure) ;;
      *) echo '  state=BLOCKED reason=active-generation'; return 1 ;;
    esac
    echo '  branch=DETACHED'
    echo "  head=$nuinui_e2e_head"
    echo '  clean=yes'
    echo '  state=BUSY'
    return 0
  fi
  [ "$nuinui_e2e_lane_releasing" = no ] || {
    nuinui_e2e_releasing_path=$(nuinui_e2e__path_for "$nuinui_e2e_check_repo" releasing) || return 1
    nuinui_e2e_release_path=$(nuinui_e2e__path_for "$nuinui_e2e_check_repo" release) || return 1
    if ! nuinui_e2e__exists "$nuinui_e2e_release_path" ||
      ! nuinui_e2e__read_expected_release "$nuinui_e2e_release_path"; then
      echo '  state=BLOCKED reason=release-transition-without-verifiable-active-marker'
      return 1
    fi
    [ "$nuinui_e2e_head" = "$nuinui_e2e_r_idle_sha" ] || return 1
    echo '  branch=DETACHED'
    echo "  head=$nuinui_e2e_head"
    echo '  clean=yes'
    echo '  state=RELEASE-PENDING'
    return 0
  }
  if [ "$nuinui_e2e_lane_starting" = yes ]; then
    nuinui_e2e_starting_path=$(nuinui_e2e__path_for \
      "$nuinui_e2e_check_repo" starting) || return 1
    nuinui_e2e__read_expected_starting "$nuinui_e2e_starting_path" || return 1
    nuinui_e2e_release_path=$(nuinui_e2e__path_for "$nuinui_e2e_check_repo" release) || return 1
    nuinui_e2e_cleanup_path=$(nuinui_e2e__path_for "$nuinui_e2e_check_repo" cleanup) || return 1
    if nuinui_e2e__exists "$nuinui_e2e_release_path" ||
      nuinui_e2e__exists "$nuinui_e2e_cleanup_path" ||
      [ "$nuinui_e2e_head" != "$nuinui_e2e_r_idle_sha" -a \
        "$nuinui_e2e_head" != "$nuinui_e2e_expected_tested" ] ||
      ! git -C "$nuinui_e2e_check_repo" merge-base --is-ancestor \
        "$nuinui_e2e_r_idle_sha" "$nuinui_e2e_expected_tested"; then
      echo '  state=BLOCKED reason=start-intent-does-not-match-recoverable-checkout'
      return 1
    fi
    echo '  branch=DETACHED'
    echo "  head=$nuinui_e2e_head"
    echo '  clean=yes'
    echo '  state=START-PENDING'
    return 0
  fi
  echo '  branch=DETACHED'
  echo "  head=$nuinui_e2e_head"
  echo '  clean=yes'
  echo '  state=FREE'
  [ -n "$nuinui_e2e_head" ]
}

# The generic preflight owns manifest parsing and the complete registered
# worktree comparison. This adapter adds only the native/legacy metadata rules.
lane_execution_human_test_preflight() {
  nuinui_e2e__lane_preflight_state "$1" "$2" "$3"
}

nuinui_e2e__preflight() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_preflight_tmp=$(mktemp "${TMPDIR:-/tmp}/nuinui-e2e-preflight.XXXXXX") || return 1
  if ! lane_execution_preflight "$1" >"$nuinui_e2e_preflight_tmp" 2>&1; then
    cat "$nuinui_e2e_preflight_tmp" >&2
    rm -f "$nuinui_e2e_preflight_tmp"
    echo 'BLOCKED: full candidate fixture preflight failed' >&2
    return 1
  fi
  if ! awk '
    /^lane name=/ {
      role=""
      for (i=1; i<=NF; i++) if ($i ~ /^role=/) { role=substr($i, 6) }
    }
    /^  state=/ && role == "implementation" {
      state=$0
      sub(/^  state=/, "", state)
      sub(/[[:space:]].*$/, "", state)
      if (state != "FREE") invalid=1
    }
    END { exit invalid }
  ' "$nuinui_e2e_preflight_tmp"; then
    cat "$nuinui_e2e_preflight_tmp" >&2
    rm -f "$nuinui_e2e_preflight_tmp"
    echo 'BLOCKED: implementation lane has active or pending ownership' >&2
    return 1
  fi
  cat "$nuinui_e2e_preflight_tmp"
  rm -f "$nuinui_e2e_preflight_tmp"
}

nuinui_e2e__checked_out() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_checkout_repo=$1
  nuinui_e2e_checkout_sha=$2
  [ -z "$(git -C "$nuinui_e2e_checkout_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)" ] &&
    [ -z "$(git -C "$nuinui_e2e_checkout_repo" status --porcelain 2>/dev/null)" ] &&
    [ "$(git -C "$nuinui_e2e_checkout_repo" rev-parse HEAD 2>/dev/null)" = "$nuinui_e2e_checkout_sha" ]
}

nuinui_e2e__live_idle_sha() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_live_sha=$(lane_execution__origin_default "$1" "$nuinui_e2e_default_branch") || return 1
  nuinui_e2e_valid_sha "$nuinui_e2e_live_sha" || return 1
  printf '%s\n' "$nuinui_e2e_live_sha"
}

nuinui_e2e__failpoint() {
  [ "${nuinui_e2e_test_failpoint:-}" = "$1" ]
}

nuinui_e2e__refresh_tested_ref() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_refresh_repo=$1
  nuinui_e2e_refresh_tested=$2
  git -C "$nuinui_e2e_refresh_repo" fetch origin --prune >/dev/null 2>&1 || {
    echo 'BLOCKED: Human-test start fetch/prune failed'
    return 1
  }
  nuinui_e2e_refresh_live=$(nuinui_e2e__live_idle_sha \
    "$nuinui_e2e_refresh_repo") || {
      echo 'BLOCKED: authoritative default revision is unavailable'
      return 1
    }
  [ "$nuinui_e2e_refresh_live" = "$nuinui_e2e_refresh_tested" ] || {
    echo 'BLOCKED: tested SHA is not the authoritative default-branch commit'
    return 1
  }
  nuinui_e2e_refresh_commit=$(git -C "$nuinui_e2e_refresh_repo" \
    rev-parse --verify "$nuinui_e2e_refresh_tested^{commit}" 2>/dev/null) || {
      echo 'BLOCKED: tested SHA is not an existing commit in the Human-test checkout'
      return 1
    }
  [ "$nuinui_e2e_refresh_commit" = "$nuinui_e2e_refresh_tested" ] || {
    echo 'BLOCKED: tested SHA did not resolve to its exact commit'
    return 1
  }
}

nuinui_e2e__starting_content() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_starting_idle_sha=$1
  nuinui_e2e__record_base
  printf 'idle_sha=%s\nrecord_state=pending\n' "$nuinui_e2e_starting_idle_sha"
}

nuinui_e2e__finish_start() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_finish_starting=$1
  nuinui_e2e_finish_active=$2
  nuinui_e2e_finish_interrupted=$3
  nuinui_e2e__read_expected_starting "$nuinui_e2e_finish_starting" || {
    echo 'BLOCKED: startup intent does not match the requested issue, lane, SHA, or generation'
    return 1
  }
  nuinui_e2e_finish_idle_sha=$nuinui_e2e_r_idle_sha
  nuinui_e2e_finish_start_content=$(nuinui_e2e__starting_content \
    "$nuinui_e2e_finish_idle_sha") || return 1
  nuinui_e2e_finish_active_content=$(nuinui_e2e__record_base) || return 1
  nuinui_e2e__refresh_tested_ref "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_expected_tested" || return 1
  if nuinui_e2e__exists "$nuinui_e2e_finish_active"; then
    nuinui_e2e__read_expected_active "$nuinui_e2e_finish_active" &&
      nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
        "$nuinui_e2e_expected_tested" || {
          echo 'BLOCKED: active marker does not verify the interrupted startup checkout'
          return 1
        }
    nuinui_e2e__remove_exact "$nuinui_e2e_finish_starting" \
      "$nuinui_e2e_finish_start_content" || {
        echo 'BLOCKED: verified active marker remains with startup recovery evidence'
        return 1
      }
    return 0
  fi

  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e__read_expected_starting "$nuinui_e2e_finish_starting" || return 1
  [ "$nuinui_e2e_r_idle_sha" = "$nuinui_e2e_finish_idle_sha" ] &&
    git -C "$nuinui_e2e_expected_repo" merge-base --is-ancestor \
      "$nuinui_e2e_finish_idle_sha" "$nuinui_e2e_expected_tested" || {
        echo 'BLOCKED: startup idle revision cannot safely transition to tested SHA'
        return 1
      }
  nuinui_e2e_finish_head=$(git -C "$nuinui_e2e_expected_repo" \
    rev-parse HEAD 2>/dev/null) || return 1
  [ -z "$(git -C "$nuinui_e2e_expected_repo" \
    symbolic-ref --quiet --short HEAD 2>/dev/null || true)" ] &&
    [ -z "$(git -C "$nuinui_e2e_expected_repo" status --porcelain 2>/dev/null)" ] &&
    { [ "$nuinui_e2e_finish_head" = "$nuinui_e2e_finish_idle_sha" ] ||
      [ "$nuinui_e2e_finish_head" = "$nuinui_e2e_expected_tested" ]; } || {
        echo 'BLOCKED: startup interruption left an unrecognized Human-test checkout'
        return 1
      }
  if [ "$nuinui_e2e_finish_head" != "$nuinui_e2e_expected_tested" ]; then
    git -C "$nuinui_e2e_expected_repo" switch --detach \
      "$nuinui_e2e_expected_tested" >/dev/null 2>&1 || {
        echo 'BLOCKED: guarded fixture start could not detach to tested SHA; startup intent retained'
        return 1
      }
  fi
  if [ "$nuinui_e2e_finish_interrupted" = yes ] &&
    nuinui_e2e__failpoint after-start-checkout; then
    echo 'BLOCKED: injected interruption after tested checkout; startup recovery evidence retained'
    return 1
  fi
  nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_expected_tested" &&
    nuinui_e2e__refresh_tested_ref "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_expected_tested" || {
        echo 'BLOCKED: tested checkout verification failed; startup intent retained'
        return 1
      }
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e__read_expected_starting "$nuinui_e2e_finish_starting" &&
    [ "$nuinui_e2e_r_idle_sha" = "$nuinui_e2e_finish_idle_sha" ] &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_expected_tested" || {
        echo 'BLOCKED: startup fixation changed before active marker publication'
        return 1
      }
  nuinui_e2e__atomic_create "$nuinui_e2e_finish_active" \
    "$nuinui_e2e_finish_active_content" || {
      echo 'BLOCKED: active marker already exists or could not be atomically published; startup intent retained'
      return 1
    }
  nuinui_e2e__read_expected_active "$nuinui_e2e_finish_active" &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_expected_tested" || {
        echo 'BLOCKED: active marker verification failed; exact startup evidence retained'
        return 1
      }
  if [ "$nuinui_e2e_finish_interrupted" = yes ] &&
    nuinui_e2e__failpoint after-start-active-marker; then
    echo 'BLOCKED: injected interruption after active marker publication; startup recovery evidence retained'
    return 1
  fi
  nuinui_e2e__remove_exact "$nuinui_e2e_finish_starting" \
    "$nuinui_e2e_finish_start_content" || {
      echo 'BLOCKED: verified active marker remains with startup recovery evidence'
      return 1
    }
}

nuinui_e2e_admit() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_operation=admit
  nuinui_e2e_manifest_arg=$1
  nuinui_e2e_lane_arg=$2
  nuinui_e2e_issue_arg=$3
  nuinui_e2e__fixture_context "$nuinui_e2e_manifest_arg" \
    "$nuinui_e2e_lane_arg" "$nuinui_e2e_issue_arg" || return 1
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_active"; then
    nuinui_e2e__read_expected_active "$nuinui_e2e_active" || {
      echo 'BLOCKED: active native generation does not match admission request'
      return 1
    }
    printf 'ADMISSION ALREADY ACTIVE\nissue=%s\nlane=%s\ngeneration=%s\nmutation=no-op\n' \
      "$nuinui_e2e_expected_issue" "$nuinui_e2e_expected_lane" \
      "$nuinui_e2e_expected_generation"
    return 0
  fi
  [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
    "$nuinui_e2e_expected_tested" ] || {
      echo 'BLOCKED: tested SHA is not the authoritative default-branch commit'
      return 1
    }
  nuinui_e2e_idle_sha=$(git -C "$nuinui_e2e_expected_repo" \
    rev-parse HEAD 2>/dev/null) || return 1
  nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_idle_sha" || {
      echo 'BLOCKED: Human-test lane is not FREE at its clean detached idle revision'
      return 1
    }
  printf 'ADMISSION READY\nissue=%s\nurl=%s\nlocal_id=%s\nlane=%s\ntested_sha=%s\ngeneration=%s\nmutation=no\n' \
    "$nuinui_e2e_expected_issue" "$nuinui_e2e_expected_url" \
    "$nuinui_e2e_expected_token" "$nuinui_e2e_expected_lane" \
    "$nuinui_e2e_expected_tested" "$nuinui_e2e_expected_generation"
}

nuinui_e2e_status() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_operation=status
  nuinui_e2e_manifest_arg=$1
  nuinui_e2e_lane_arg=$2
  nuinui_e2e_issue_arg=$3
  nuinui_e2e__fixture_context "$nuinui_e2e_manifest_arg" \
    "$nuinui_e2e_lane_arg" "$nuinui_e2e_issue_arg" || return 1
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_active"; then
    nuinui_e2e__read_expected_active "$nuinui_e2e_active" || return 1
    printf 'NATIVE E2E ACTIVE\nissue=%s\nlane=%s\ntested_sha=%s\ngeneration=%s\nmutation=no\n' \
      "$nuinui_e2e_expected_issue" "$nuinui_e2e_expected_lane" \
      "$nuinui_e2e_expected_tested" "$nuinui_e2e_expected_generation"
    return 0
  fi
  nuinui_e2e_starting=$(nuinui_e2e__path_for \
    "$nuinui_e2e_expected_repo" starting) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_starting"; then
    nuinui_e2e__read_expected_starting "$nuinui_e2e_starting" || return 1
    printf 'NATIVE E2E START-PENDING\nissue=%s\nlane=%s\ntested_sha=%s\ngeneration=%s\nmutation=no\n' \
      "$nuinui_e2e_expected_issue" "$nuinui_e2e_expected_lane" \
      "$nuinui_e2e_expected_tested" "$nuinui_e2e_expected_generation"
    return 0
  fi
  nuinui_e2e_releasing=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" releasing) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_releasing"; then
    echo 'NATIVE E2E RELEASE-PENDING'
    echo "generation=$nuinui_e2e_expected_generation"
    echo 'mutation=no'
    return 0
  fi
  nuinui_e2e_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_release"; then
    nuinui_e2e__read_expected_release "$nuinui_e2e_release" || return 1
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" "$nuinui_e2e_r_idle_sha" || {
        echo 'BLOCKED: completed receipt does not match the detached idle checkout'
        return 1
      }
    printf 'NATIVE E2E RELEASED\nissue=%s\nlane=%s\ntested_sha=%s\ngeneration=%s\nidle_sha=%s\nmutation=no\n' \
      "$nuinui_e2e_expected_issue" "$nuinui_e2e_expected_lane" \
      "$nuinui_e2e_expected_tested" "$nuinui_e2e_expected_generation" \
      "$nuinui_e2e_r_idle_sha"
    return 0
  fi
  printf 'NATIVE E2E FREE\nissue=%s\nlane=%s\nmutation=no\n' \
    "$nuinui_e2e_expected_issue" "$nuinui_e2e_expected_lane"
}

nuinui_e2e_start() {
  [ "$#" = 4 ] || return 2
  nuinui_e2e_operation=start
  nuinui_e2e_manifest_arg=$1
  nuinui_e2e_lane_arg=$2
  nuinui_e2e_issue_arg=$3
  nuinui_e2e_expected_tested=$4
  nuinui_e2e__fixture_context "$nuinui_e2e_manifest_arg" \
    "$nuinui_e2e_lane_arg" "$nuinui_e2e_issue_arg" || return 1
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  nuinui_e2e_starting=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" starting) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_active"; then
    nuinui_e2e__read_expected_active "$nuinui_e2e_active" || {
      echo 'BLOCKED: active native generation differs from exact duplicate request'
      return 1
    }
    [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
      "$nuinui_e2e_expected_tested" ] &&
      nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
        "$nuinui_e2e_expected_tested" || {
          echo 'BLOCKED: exact duplicate is no longer fresh and verified'
          return 1
        }
    echo 'NATIVE E2E ALREADY STARTED'
    echo "issue=$nuinui_e2e_expected_issue"
    echo "generation=$nuinui_e2e_expected_generation"
    echo 'mutation=no-op'
    return 0
  fi
  if nuinui_e2e__exists "$nuinui_e2e_starting"; then
    echo 'BLOCKED: interrupted startup requires explicit recovery'
    return 1
  fi
  nuinui_e2e_cleanup=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1
  nuinui_e2e_releasing=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" releasing) || return 1
  for nuinui_e2e_old_path in "$nuinui_e2e_cleanup" "$nuinui_e2e_release" "$nuinui_e2e_releasing"; do
    if nuinui_e2e__exists "$nuinui_e2e_old_path"; then
      echo 'BLOCKED: generation identity has already been used or is incomplete'
      return 1
    fi
  done
  if nuinui_e2e__generation_seen "$nuinui_e2e_expected_generation"; then
    echo 'BLOCKED: generation identity has already been used in this fixture topology'
    return 1
  fi
  nuinui_e2e_idle_sha=$(git -C "$nuinui_e2e_expected_repo" \
    rev-parse HEAD 2>/dev/null) || return 1
  nuinui_e2e_valid_sha "$nuinui_e2e_idle_sha" &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_idle_sha" || {
        echo 'BLOCKED: start requires a FREE clean detached Human-test idle checkout'
        return 1
      }
  nuinui_e2e__refresh_tested_ref "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_expected_tested" || return 1
  git -C "$nuinui_e2e_expected_repo" merge-base --is-ancestor \
    "$nuinui_e2e_idle_sha" "$nuinui_e2e_expected_tested" || {
      echo 'BLOCKED: Human-test idle checkout cannot safely transition to tested SHA'
      return 1
    }
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  [ "$(git -C "$nuinui_e2e_expected_repo" rev-parse HEAD 2>/dev/null)" = \
    "$nuinui_e2e_idle_sha" ] &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_idle_sha" &&
    [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
      "$nuinui_e2e_expected_tested" ] || {
        echo 'BLOCKED: freshness or checkout topology changed before startup intent'
        return 1
      }
  nuinui_e2e_starting_content=$(nuinui_e2e__starting_content \
    "$nuinui_e2e_idle_sha") || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_starting" \
    "$nuinui_e2e_starting_content" || {
      echo 'BLOCKED: startup intent could not be atomically published'
      return 1
    }
  nuinui_e2e__failpoint after-start-intent && {
    echo 'BLOCKED: injected interruption after startup intent; recovery evidence retained'
    return 1
  }
  nuinui_e2e__finish_start "$nuinui_e2e_starting" \
    "$nuinui_e2e_active" yes || return 1
  echo 'NATIVE E2E FIXTURE STARTED'
  echo "issue=$nuinui_e2e_expected_issue"
  echo "url=$nuinui_e2e_expected_url"
  echo "local_id=$nuinui_e2e_expected_token"
  echo "lane=$nuinui_e2e_expected_lane"
  echo "tested_sha=$nuinui_e2e_expected_tested"
  echo "generation=$nuinui_e2e_expected_generation"
  echo 'mutation=yes'
}

nuinui_e2e_cleanup_proof() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_operation=cleanup-proof
  nuinui_e2e_manifest_arg=$1
  nuinui_e2e_lane_arg=$2
  nuinui_e2e_issue_arg=$3
  nuinui_e2e__fixture_context "$nuinui_e2e_manifest_arg" \
    "$nuinui_e2e_lane_arg" "$nuinui_e2e_issue_arg" || return 1
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  nuinui_e2e_host_state=${nuinui_e2e_host_state:-ABSENT}
  [ "$nuinui_e2e_host_state" = ABSENT ] || {
    echo 'BLOCKED: bare cleanup-proof cannot bypass a host-session record'
    return 1
  }
  nuinui_e2e_cleanup=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e__read_expected_active "$nuinui_e2e_active" || {
    echo 'BLOCKED: cleanup proof requires the exact active generation'
    return 1
  }
  nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_expected_tested" || {
      echo 'BLOCKED: fixture cleanup proof requires a clean detached tested checkout'
      return 1
    }
  nuinui_e2e_cleanup=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e_cleanup_content=$(nuinui_e2e__record_base)
  nuinui_e2e_cleanup_content=$nuinui_e2e_cleanup_content$(printf '\nproof=fixture-no-host-session\n')
  if nuinui_e2e__exists "$nuinui_e2e_cleanup"; then
    nuinui_e2e__read_expected_cleanup "$nuinui_e2e_cleanup" || return 1
    echo 'NATIVE E2E CLEANUP PROOF ALREADY RECORDED'
    echo 'mutation=no-op'
    return 0
  fi
  nuinui_e2e__atomic_create "$nuinui_e2e_cleanup" "$nuinui_e2e_cleanup_content" || {
    echo 'BLOCKED: cleanup proof could not be atomically published'
    return 1
  }
  nuinui_e2e__read_expected_cleanup "$nuinui_e2e_cleanup" || return 1
  echo 'NATIVE E2E FIXTURE CLEANUP PROVED'
  echo 'proof=fixture-no-host-session'
  echo "generation=$nuinui_e2e_expected_generation"
  echo 'mutation=yes'
}

nuinui_e2e_release() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_operation=release
  nuinui_e2e_manifest_arg=$1
  nuinui_e2e_lane_arg=$2
  nuinui_e2e_issue_arg=$3
  nuinui_e2e__fixture_context "$nuinui_e2e_manifest_arg" \
    "$nuinui_e2e_lane_arg" "$nuinui_e2e_issue_arg" || return 1
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  nuinui_e2e_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1
  if ! nuinui_e2e__exists "$nuinui_e2e_active"; then
    nuinui_e2e_cleanup=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" cleanup) || return 1
    nuinui_e2e__read_expected_cleanup "$nuinui_e2e_cleanup" &&
      nuinui_e2e__read_expected_release "$nuinui_e2e_release" &&
      [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
        "$nuinui_e2e_r_idle_sha" ] &&
      nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
        "$nuinui_e2e_r_idle_sha" || {
          echo 'BLOCKED: repeated release has no exact verified receipt or idle checkout'
          return 1
        }
    echo 'NATIVE E2E ALREADY RELEASED'
    echo 'mutation=no-op'
    return 0
  fi
  nuinui_e2e__read_expected_active "$nuinui_e2e_active" || {
    echo 'BLOCKED: release requires the exact active generation'
    return 1
  }
  nuinui_e2e_cleanup=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e__read_expected_cleanup "$nuinui_e2e_cleanup" || {
    echo 'BLOCKED: generation-matched fixture cleanup evidence is required'
    return 1
  }
  nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_expected_tested" || {
      echo 'BLOCKED: release requires the clean detached tested checkout'
      return 1
    }
  nuinui_e2e_marker_content=$(nuinui_e2e__record_base)
  nuinui_e2e_idle_sha=$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo") || {
    echo 'BLOCKED: authoritative detached idle revision is unavailable'
    return 1
  }
  git -C "$nuinui_e2e_expected_repo" cat-file -e \
    "$nuinui_e2e_idle_sha^{commit}" 2>/dev/null || {
      echo 'BLOCKED: authoritative idle revision is absent from the fixture object store'
      return 1
    }
  nuinui_e2e_releasing=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" releasing) || return 1
  nuinui_e2e_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1
  nuinui_e2e_releasing_content=$(nuinui_e2e__record_base)
  nuinui_e2e_releasing_content=$nuinui_e2e_releasing_content$(printf '\nidle_sha=%s\nrecord_state=pending\n' "$nuinui_e2e_idle_sha")
  nuinui_e2e_release_content=$(nuinui_e2e__record_base)
  nuinui_e2e_release_content=$nuinui_e2e_release_content$(printf '\nidle_sha=%s\nrecord_state=complete\n' "$nuinui_e2e_idle_sha")
  if nuinui_e2e__exists "$nuinui_e2e_release"; then
    nuinui_e2e__read_expected_release "$nuinui_e2e_release" || return 1
    [ "$nuinui_e2e_r_idle_sha" = "$nuinui_e2e_idle_sha" ] || return 1
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" "$nuinui_e2e_idle_sha" || return 1
    echo 'NATIVE E2E ALREADY RELEASED'
    echo 'mutation=no-op'
    return 0
  fi
  nuinui_e2e__exists "$nuinui_e2e_releasing" && {
    echo 'BLOCKED: interrupted release requires explicit recovery'
    return 1
  }
  # Durable intent is published before any checkout change. It records the
  # exact generation and target idle SHA needed by narrowly bounded recovery.
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
    "$nuinui_e2e_idle_sha" ] &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_expected_tested" || {
        echo 'BLOCKED: release freshness changed at its mutation boundary'
        return 1
      }
  nuinui_e2e__atomic_create "$nuinui_e2e_releasing" \
    "$nuinui_e2e_releasing_content" || {
      echo 'BLOCKED: release intent could not be atomically published'
      return 1
    }
  nuinui_e2e__failpoint after-intent && {
    echo 'BLOCKED: injected interruption after release intent; recovery evidence retained'
    return 1
  }
  nuinui_e2e__read_expected_active "$nuinui_e2e_active" &&
    nuinui_e2e__read_expected_cleanup "$nuinui_e2e_cleanup" &&
    nuinui_e2e__read_expected_releasing "$nuinui_e2e_releasing" &&
    [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
      "$nuinui_e2e_idle_sha" ] &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_expected_tested" || {
        echo 'BLOCKED: release mutation boundary no longer matches its exact intent'
        return 1
      }
  if [ "$nuinui_e2e_expected_tested" != "$nuinui_e2e_idle_sha" ]; then
    git -C "$nuinui_e2e_expected_repo" switch --detach \
      "$nuinui_e2e_idle_sha" >/dev/null 2>&1 || {
        echo 'BLOCKED: checkout could not return to authoritative detached idle revision; intent retained'
        return 1
      }
  fi
  nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" "$nuinui_e2e_idle_sha" &&
    [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
      "$nuinui_e2e_idle_sha" ] || {
        echo 'BLOCKED: detached idle checkout verification failed; intent retained'
        return 1
      }
  nuinui_e2e__failpoint after-idle-checkout && {
    echo 'BLOCKED: injected interruption after idle checkout; recovery evidence retained'
    return 1
  }
  nuinui_e2e__atomic_create "$nuinui_e2e_release" \
    "$nuinui_e2e_release_content" || {
      echo 'BLOCKED: release receipt could not be published; active marker and intent retained'
      return 1
    }
  nuinui_e2e__read_expected_release "$nuinui_e2e_release" &&
    [ "$nuinui_e2e_r_idle_sha" = "$nuinui_e2e_idle_sha" ] || {
      echo 'BLOCKED: release receipt verification failed; active marker retained'
      return 1
    }
  nuinui_e2e__failpoint after-receipt && {
    echo 'BLOCKED: injected interruption after verified receipt; active marker retained'
    return 1
  }
  nuinui_e2e__remove_exact "$nuinui_e2e_active" "$nuinui_e2e_marker_content" || {
    echo 'BLOCKED: active marker changed; verified receipt and recovery intent retained'
    return 1
  }
  nuinui_e2e__failpoint after-active-removal && {
    echo 'BLOCKED: injected interruption after active marker removal; receipt and intent retained'
    return 1
  }
  nuinui_e2e__remove_exact "$nuinui_e2e_releasing" \
    "$nuinui_e2e_releasing_content" || {
      echo 'BLOCKED: release intent changed after marker removal; receipt retained'
      return 1
    }
  echo 'NATIVE E2E FIXTURE RELEASED'
  echo "issue=$nuinui_e2e_expected_issue"
  echo "tested_sha=$nuinui_e2e_expected_tested"
  echo "idle_sha=$nuinui_e2e_idle_sha"
  echo "generation=$nuinui_e2e_expected_generation"
  echo 'receipt=verified-before-active-marker-removal'
  echo 'mutation=yes'
}

nuinui_e2e_recover() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_operation=recover
  nuinui_e2e_manifest_arg=$1
  nuinui_e2e_lane_arg=$2
  nuinui_e2e_issue_arg=$3
  nuinui_e2e__fixture_context "$nuinui_e2e_manifest_arg" \
    "$nuinui_e2e_lane_arg" "$nuinui_e2e_issue_arg" || return 1
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  nuinui_e2e_cleanup=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1
  nuinui_e2e_releasing=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" releasing) || return 1
  nuinui_e2e_starting=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" starting) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_starting"; then
    nuinui_e2e__finish_start "$nuinui_e2e_starting" "$nuinui_e2e_active" no || return 1
    echo 'NATIVE E2E START RECOVERED'
    echo "issue=$nuinui_e2e_expected_issue"
    echo "tested_sha=$nuinui_e2e_expected_tested"
    echo "generation=$nuinui_e2e_expected_generation"
    echo 'marker=verified-after-tested-checkout'
    echo 'mutation=yes'
    return 0
  fi
  if ! nuinui_e2e__exists "$nuinui_e2e_releasing"; then
    if ! nuinui_e2e__exists "$nuinui_e2e_active" &&
      nuinui_e2e__exists "$nuinui_e2e_release" &&
      nuinui_e2e__read_expected_release "$nuinui_e2e_release" &&
      [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
        "$nuinui_e2e_r_idle_sha" ] &&
      nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" "$nuinui_e2e_r_idle_sha"; then
      echo 'NATIVE E2E RECOVERY ALREADY COMPLETE'
      echo 'mutation=no-op'
      return 0
    fi
    echo 'BLOCKED: no exact interrupted release is available for recovery'
    return 1
  fi
  nuinui_e2e__read_expected_releasing "$nuinui_e2e_releasing" || {
    echo 'BLOCKED: release intent does not match the requested issue, lane, SHA, or generation'
    return 1
  }
  nuinui_e2e_recovery_idle_sha=$nuinui_e2e_r_idle_sha
  nuinui_e2e__read_expected_cleanup "$nuinui_e2e_cleanup" || {
    echo 'BLOCKED: exact generation-matched cleanup evidence is missing'
    return 1
  }
  [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
    "$nuinui_e2e_recovery_idle_sha" ] || {
      echo 'BLOCKED: authoritative idle SHA changed after release interruption'
      return 1
    }
  nuinui_e2e_expected_head=$(git -C "$nuinui_e2e_expected_repo" rev-parse HEAD 2>/dev/null) || return 1
  [ -z "$(git -C "$nuinui_e2e_expected_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)" ] &&
    [ -z "$(git -C "$nuinui_e2e_expected_repo" status --porcelain 2>/dev/null)" ] &&
    { [ "$nuinui_e2e_expected_head" = "$nuinui_e2e_expected_tested" ] ||
      [ "$nuinui_e2e_expected_head" = "$nuinui_e2e_recovery_idle_sha" ]; } || {
        echo 'BLOCKED: interrupted checkout is not in an exact recoverable detached state'
        return 1
      }
  if nuinui_e2e__exists "$nuinui_e2e_active"; then
    nuinui_e2e__read_expected_active "$nuinui_e2e_active" || return 1
    nuinui_e2e_marker_content=$(nuinui_e2e__record_base)
  else
    [ "$nuinui_e2e_expected_head" = "$nuinui_e2e_recovery_idle_sha" ] || {
      echo 'BLOCKED: active marker is absent before the idle checkout was verified'
      return 1
    }
  fi
  nuinui_e2e_releasing_content=$(nuinui_e2e__record_base)
  nuinui_e2e_releasing_content=$nuinui_e2e_releasing_content$(printf '\nidle_sha=%s\nrecord_state=pending\n' "$nuinui_e2e_recovery_idle_sha")
  nuinui_e2e_release_content=$(nuinui_e2e__record_base)
  nuinui_e2e_release_content=$nuinui_e2e_release_content$(printf '\nidle_sha=%s\nrecord_state=complete\n' "$nuinui_e2e_recovery_idle_sha")
  if [ "$nuinui_e2e_expected_head" = "$nuinui_e2e_expected_tested" ]; then
    git -C "$nuinui_e2e_expected_repo" switch --detach \
      "$nuinui_e2e_recovery_idle_sha" >/dev/null 2>&1 || {
        echo 'BLOCKED: exact recovery could not restore detached idle checkout; evidence retained'
        return 1
      }
  fi
  nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_recovery_idle_sha" &&
    [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
      "$nuinui_e2e_recovery_idle_sha" ] || {
        echo 'BLOCKED: exact recovery could not verify authoritative detached idle checkout'
        return 1
      }
  if nuinui_e2e__exists "$nuinui_e2e_release"; then
    nuinui_e2e__read_expected_release "$nuinui_e2e_release" &&
      [ "$nuinui_e2e_r_idle_sha" = "$nuinui_e2e_recovery_idle_sha" ] || {
        echo 'BLOCKED: existing release receipt conflicts with recovery intent'
        return 1
      }
  else
    nuinui_e2e__atomic_create "$nuinui_e2e_release" \
      "$nuinui_e2e_release_content" || {
        echo 'BLOCKED: recovered release receipt could not be published'
        return 1
      }
    nuinui_e2e__read_expected_release "$nuinui_e2e_release" || return 1
  fi
  if nuinui_e2e__exists "$nuinui_e2e_active"; then
    nuinui_e2e__remove_exact "$nuinui_e2e_active" "$nuinui_e2e_marker_content" || {
      echo 'BLOCKED: exact active marker changed during recovery; receipt retained'
      return 1
    }
  fi
  nuinui_e2e__remove_exact "$nuinui_e2e_releasing" \
    "$nuinui_e2e_releasing_content" || {
      echo 'BLOCKED: exact recovery intent changed after marker resolution'
      return 1
    }
  echo 'NATIVE E2E RELEASE RECOVERED'
  echo "generation=$nuinui_e2e_expected_generation"
  echo "idle_sha=$nuinui_e2e_recovery_idle_sha"
  echo 'receipt=verified-before-active-marker-removal'
  echo 'mutation=yes'
}

nuinui_e2e_closure() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_operation=closure
  nuinui_e2e_manifest_arg=$1
  nuinui_e2e_lane_arg=$2
  nuinui_e2e_issue_arg=$3
  nuinui_e2e__fixture_context "$nuinui_e2e_manifest_arg" \
    "$nuinui_e2e_lane_arg" "$nuinui_e2e_issue_arg" || return 1
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  nuinui_e2e_releasing=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" releasing) || return 1
  nuinui_e2e_cleanup=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_active" || nuinui_e2e__exists "$nuinui_e2e_releasing"; then
    echo 'BLOCKED: final closure requires no active marker or pending release intent'
    return 1
  fi
  nuinui_e2e__read_expected_cleanup "$nuinui_e2e_cleanup" || {
    echo 'BLOCKED: final closure requires exact generation-matched cleanup evidence'
    return 1
  }
  nuinui_e2e__read_expected_release "$nuinui_e2e_release" || {
    echo 'BLOCKED: final closure requires the exact completed release receipt'
    return 1
  }
  nuinui_e2e_closure_idle_sha=$nuinui_e2e_r_idle_sha
  [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
    "$nuinui_e2e_closure_idle_sha" ] &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_closure_idle_sha" || {
        echo 'BLOCKED: final detached checkout or authoritative idle revision is not verified'
        return 1
      }
  echo 'NATIVE E2E FINAL CLOSURE VERIFIED'
  echo "issue=$nuinui_e2e_expected_issue"
  echo "lane=$nuinui_e2e_expected_lane"
  echo "tested_sha=$nuinui_e2e_expected_tested"
  echo "idle_sha=$nuinui_e2e_closure_idle_sha"
  echo "generation=$nuinui_e2e_expected_generation"
  echo 'clean=yes'
  echo 'detached=yes'
  echo 'registered_topology=verified'
  echo 'mutation=no'
}
