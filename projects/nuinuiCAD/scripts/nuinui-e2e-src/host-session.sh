# Durable generation-bound host-session records. The adapter is fixture-only.

nuinui_e2e_host__metadata_path() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_host_path_git_dir=$(lane_execution__git_dir "$1") || return 1
  case "$2" in
    intent|handoff|ready|cleanup-pending|cleanup)
      printf '%s/nuinui-github-e2e-host-%s-v1.%s\n' \
        "$nuinui_e2e_host_path_git_dir" "$2" \
        "$(nuinui_e2e__generation_hash "$nuinui_e2e_expected_generation")"
      ;;
    *) return 2 ;;
  esac
}

nuinui_e2e_host__kind_from_name() {
  [ "$#" = 1 ] || return 2
  case "$1" in
    nuinui-github-e2e-host-intent-v1.*) printf 'intent\n' ;;
    nuinui-github-e2e-host-handoff-v1.*) printf 'handoff\n' ;;
    nuinui-github-e2e-host-ready-v1.*) printf 'ready\n' ;;
    nuinui-github-e2e-host-cleanup-pending-v1.*) printf 'cleanup-pending\n' ;;
    nuinui-github-e2e-host-cleanup-v1.*) printf 'cleanup\n' ;;
    *) return 1 ;;
  esac
}

nuinui_e2e_host__record_content() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_host_content_state=$1
  nuinui_e2e_host_content_root_identity=$2
  nuinui_e2e_host_root_identity=$nuinui_e2e_host_content_root_identity
  nuinui_e2e_host__owner_content
  printf 'record_state=%s\n' "$nuinui_e2e_host_content_state"
  if [ "$nuinui_e2e_host_content_state" = CLEANED ]; then
    if [ -n "$nuinui_e2e_host_cleanup_handoff_sha" ]; then
      printf 'cleanup_handoff_sha256=%s\n' "$nuinui_e2e_host_cleanup_handoff_sha"
    else
      printf 'cleanup_handoff_sha256=none\n'
    fi
  fi
}

nuinui_e2e_host__record_payload() {
  [ "$#" = 1 ] || return 2
  awk -F= '$1 != "root_identity" && $1 != "record_state" && \
    $1 != "cleanup_handoff_sha256" {print}' "$1"
}

nuinui_e2e_host__read_record() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_host_read_path=$1
  nuinui_e2e_host_read_kind=$2
  nuinui_e2e_host_base_keys=schema_version,issue,issue_url,local_id,lane,repository,checkout,git_dir,manifest,manifest_sha256,default_branch,idle_policy,tested_sha,generation,active_sha256,fixture_path,fixture_sha256,port,locale,adapter,root,root_identity,record_state
  case "$nuinui_e2e_host_read_kind" in
    intent|handoff|ready|cleanup-pending) nuinui_e2e_host_read_keys=$nuinui_e2e_host_base_keys ;;
    cleanup) nuinui_e2e_host_read_keys=$nuinui_e2e_host_base_keys,cleanup_handoff_sha256 ;;
    *) return 2 ;;
  esac
  nuinui_e2e__regular "$nuinui_e2e_host_read_path" || return 1
  nuinui_ownership_validate_exact_file "$nuinui_e2e_host_read_path" \
    "$nuinui_e2e_host_read_keys" || return 1
  nuinui_e2e_host_r_schema=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" schema_version) || return 1
  nuinui_e2e_host_r_issue=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" issue) || return 1
  nuinui_e2e_host_r_url=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" issue_url) || return 1
  nuinui_e2e_host_r_token=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" local_id) || return 1
  nuinui_e2e_host_r_lane=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" lane) || return 1
  nuinui_e2e_host_r_repository=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" repository) || return 1
  nuinui_e2e_host_r_checkout=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" checkout) || return 1
  nuinui_e2e_host_r_git_dir=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" git_dir) || return 1
  nuinui_e2e_host_r_manifest=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" manifest) || return 1
  nuinui_e2e_host_r_manifest_sha=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" manifest_sha256) || return 1
  nuinui_e2e_host_r_default=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" default_branch) || return 1
  nuinui_e2e_host_r_idle=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" idle_policy) || return 1
  nuinui_e2e_host_r_tested=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" tested_sha) || return 1
  nuinui_e2e_host_r_generation=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" generation) || return 1
  nuinui_e2e_host_r_active_sha=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" active_sha256) || return 1
  nuinui_e2e_host_r_fixture=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" fixture_path) || return 1
  nuinui_e2e_host_r_fixture_sha=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" fixture_sha256) || return 1
  nuinui_e2e_host_r_port=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" port) || return 1
  nuinui_e2e_host_r_locale=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" locale) || return 1
  nuinui_e2e_host_r_adapter=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" adapter) || return 1
  nuinui_e2e_host_r_root=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" root) || return 1
  nuinui_e2e_host_r_root_identity=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" root_identity) || return 1
  nuinui_e2e_host_r_state=$(nuinui_ownership_field "$nuinui_e2e_host_read_path" record_state) || return 1
  [ "$nuinui_e2e_host_r_schema" = 1 ] &&
    [ "$nuinui_e2e_host_r_issue" = "$(nuinui_e2e_identity_issue "$nuinui_e2e_host_r_issue")" ] &&
    [ "$nuinui_e2e_host_r_url" = "$(nuinui_e2e_identity_url "$nuinui_e2e_host_r_issue")" ] &&
    [ "$nuinui_e2e_host_r_token" = "$(nuinui_e2e_identity_token "$nuinui_e2e_host_r_issue")" ] || return 1
  [ "$nuinui_e2e_host_r_repository" = sayosomi/nuinuiCAD ] || return 1
  lane_manifest_validate_lane_name "$nuinui_e2e_manifest_path" \
    "$nuinui_e2e_host_r_lane" >/dev/null 2>&1 || return 1
  [ "$(lane_manifest_lane_role "$nuinui_e2e_manifest_path" "$nuinui_e2e_host_r_lane")" = human-test ] || return 1
  [ "$nuinui_e2e_host_r_checkout" = "$nuinui_e2e_checkout" ] &&
    [ "$nuinui_e2e_host_r_git_dir" = "$nuinui_e2e_git_dir" ] &&
    [ "$nuinui_e2e_host_r_manifest" = "$nuinui_e2e_manifest_path" ] &&
    [ "$nuinui_e2e_host_r_manifest_sha" = "$nuinui_e2e_manifest_sha" ] &&
    [ "$nuinui_e2e_host_r_default" = "$nuinui_e2e_default_branch" ] &&
    [ "$nuinui_e2e_host_r_idle" = detached ] || return 1
  nuinui_e2e_valid_sha "$nuinui_e2e_host_r_tested" &&
    nuinui_e2e_valid_generation "$nuinui_e2e_host_r_generation" &&
    nuinui_e2e_valid_digest "$nuinui_e2e_host_r_active_sha" &&
    nuinui_e2e_valid_digest "$nuinui_e2e_host_r_fixture_sha" || return 1
  nuinui_e2e_host__valid_port "$nuinui_e2e_host_r_port" || return 1
  case "$nuinui_e2e_host_r_locale" in default|ja) ;; *) return 1 ;; esac
  [ "$nuinui_e2e_host_r_adapter" = fixture-no-process ] || return 1
  [ "$nuinui_e2e_host_r_root" = "$(nuinui_e2e_host__root_for "$nuinui_e2e_host_r_generation")" ] || return 1
  case "$nuinui_e2e_host_r_root_identity" in
    pending)
      case "$nuinui_e2e_host_read_kind" in intent|cleanup-pending|cleanup) ;;
        *) return 1 ;;
      esac
      ;;
    *:*)
      nuinui_e2e_host_r_dev=${nuinui_e2e_host_r_root_identity%%:*}
      nuinui_e2e_host_r_ino=${nuinui_e2e_host_r_root_identity#*:}
      case "$nuinui_e2e_host_r_dev:$nuinui_e2e_host_r_ino" in *[!0-9:]*|:*|*:) return 1 ;; esac
      ;;
    *) return 1 ;;
  esac
  case "$nuinui_e2e_host_read_kind:$nuinui_e2e_host_r_state" in
    intent:PREPARING|handoff:HANDOFF|ready:READY|cleanup-pending:CLEANUP-PENDING|cleanup:CLEANED) ;;
    *) return 1 ;;
  esac
  nuinui_e2e_host_r_fixture_real=$(realpath "$nuinui_e2e_host_r_fixture" 2>/dev/null) || return 1
  [ "$nuinui_e2e_host_r_fixture_real" = "$nuinui_e2e_host_r_fixture" ] &&
    nuinui_e2e__regular "$nuinui_e2e_host_r_fixture" &&
    [ "$(nuinui_e2e__sha256 "$nuinui_e2e_host_r_fixture")" = "$nuinui_e2e_host_r_fixture_sha" ] || return 1
  case "$nuinui_e2e_host_r_fixture" in "$nuinui_e2e_host_r_checkout"/*) return 1 ;; esac
  if [ "$nuinui_e2e_host_read_kind" = cleanup ]; then
    nuinui_e2e_host_r_handoff_sha=$(nuinui_ownership_field \
      "$nuinui_e2e_host_read_path" cleanup_handoff_sha256) || return 1
    case "$nuinui_e2e_host_r_handoff_sha" in none) ;; *)
      nuinui_e2e_valid_digest "$nuinui_e2e_host_r_handoff_sha" || return 1 ;;
    esac
  fi
  nuinui_e2e_r_generation=$nuinui_e2e_host_r_generation
  nuinui_e2e_r_issue=$nuinui_e2e_host_r_issue
  nuinui_e2e_r_lane=$nuinui_e2e_host_r_lane
  nuinui_e2e_r_tested=$nuinui_e2e_host_r_tested
  nuinui_e2e_r_checkout=$nuinui_e2e_host_r_checkout
  nuinui_e2e_r_git_dir=$nuinui_e2e_host_r_git_dir
  nuinui_e2e_r_manifest=$nuinui_e2e_host_r_manifest
  nuinui_e2e_r_manifest_sha=$nuinui_e2e_host_r_manifest_sha
  nuinui_e2e_r_default=$nuinui_e2e_host_r_default
  return 0
}

nuinui_e2e_host__load_state() {
  nuinui_e2e_host_intent=$(nuinui_e2e_host__metadata_path "$nuinui_e2e_expected_repo" intent) || return 1
  nuinui_e2e_host_handoff=$(nuinui_e2e_host__metadata_path "$nuinui_e2e_expected_repo" handoff) || return 1
  nuinui_e2e_host_ready=$(nuinui_e2e_host__metadata_path "$nuinui_e2e_expected_repo" ready) || return 1
  nuinui_e2e_host_pending=$(nuinui_e2e_host__metadata_path "$nuinui_e2e_expected_repo" cleanup-pending) || return 1
  nuinui_e2e_host_cleanup_receipt=$(nuinui_e2e_host__metadata_path "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e_host_has_intent=no
  nuinui_e2e_host_has_handoff=no
  nuinui_e2e_host_has_ready=no
  nuinui_e2e_host_has_pending=no
  nuinui_e2e_host_has_cleanup=no
  for nuinui_e2e_host_pair in \
    "$nuinui_e2e_host_intent:intent" "$nuinui_e2e_host_handoff:handoff" \
    "$nuinui_e2e_host_ready:ready" "$nuinui_e2e_host_pending:cleanup-pending" \
    "$nuinui_e2e_host_cleanup_receipt:cleanup"; do
    nuinui_e2e_host_path=${nuinui_e2e_host_pair%:*}
    nuinui_e2e_host_kind=${nuinui_e2e_host_pair##*:}
    if nuinui_e2e__exists "$nuinui_e2e_host_path"; then
      nuinui_e2e_host__read_record "$nuinui_e2e_host_path" "$nuinui_e2e_host_kind" || return 1
      [ "$nuinui_e2e_host_r_issue" = "$nuinui_e2e_expected_issue" ] &&
        [ "$nuinui_e2e_host_r_url" = "$nuinui_e2e_expected_url" ] &&
        [ "$nuinui_e2e_host_r_token" = "$nuinui_e2e_expected_token" ] &&
        [ "$nuinui_e2e_host_r_lane" = "$nuinui_e2e_expected_lane" ] &&
        [ "$nuinui_e2e_host_r_generation" = "$nuinui_e2e_expected_generation" ] &&
        [ "$nuinui_e2e_host_r_tested" = "$nuinui_e2e_expected_tested" ] || return 1
      case "$nuinui_e2e_host_kind" in
        intent) nuinui_e2e_host_has_intent=yes ;;
        handoff) nuinui_e2e_host_has_handoff=yes ;;
        ready) nuinui_e2e_host_has_ready=yes ;;
        cleanup-pending) nuinui_e2e_host_has_pending=yes ;;
        cleanup) nuinui_e2e_host_has_cleanup=yes ;;
      esac
    fi
  done
  if [ "$nuinui_e2e_host_has_intent" = no ]; then
    [ "$nuinui_e2e_host_has_handoff" = no ] && [ "$nuinui_e2e_host_has_ready" = no ] &&
      [ "$nuinui_e2e_host_has_pending" = no ] && [ "$nuinui_e2e_host_has_cleanup" = no ] || return 1
    nuinui_e2e_host_root=$(nuinui_e2e_host__root_for "$nuinui_e2e_expected_generation")
    nuinui_e2e__exists "$nuinui_e2e_host_root" && return 1
    nuinui_e2e_host_state=ABSENT
    return 0
  fi
  [ "$nuinui_e2e_host_has_cleanup" = no ] || [ "$nuinui_e2e_host_has_pending" = yes ] || return 1
  [ "$nuinui_e2e_host_has_ready" = no ] || [ "$nuinui_e2e_host_has_handoff" = yes ] || return 1
  nuinui_e2e_host__read_record "$nuinui_e2e_host_intent" intent || return 1
  nuinui_e2e_host_issue=$nuinui_e2e_host_r_issue
  nuinui_e2e_host_url=$nuinui_e2e_host_r_url
  nuinui_e2e_host_token=$nuinui_e2e_host_r_token
  nuinui_e2e_host_lane=$nuinui_e2e_host_r_lane
  nuinui_e2e_host_checkout=$nuinui_e2e_host_r_checkout
  nuinui_e2e_host_git_dir=$nuinui_e2e_host_r_git_dir
  nuinui_e2e_host_manifest=$nuinui_e2e_host_r_manifest
  nuinui_e2e_host_manifest_sha=$nuinui_e2e_host_r_manifest_sha
  nuinui_e2e_host_default_branch=$nuinui_e2e_host_r_default
  nuinui_e2e_host_tested=$nuinui_e2e_host_r_tested
  nuinui_e2e_host_generation=$nuinui_e2e_host_r_generation
  nuinui_e2e_host_active_sha=$nuinui_e2e_host_r_active_sha
  nuinui_e2e_host_fixture=$nuinui_e2e_host_r_fixture
  nuinui_e2e_host_fixture_sha=$nuinui_e2e_host_r_fixture_sha
  nuinui_e2e_host_port=$nuinui_e2e_host_r_port
  nuinui_e2e_host_locale=$nuinui_e2e_host_r_locale
  nuinui_e2e_host_root=$nuinui_e2e_host_r_root
  nuinui_e2e_host_root_identity=$nuinui_e2e_host_r_root_identity
  nuinui_e2e_host_payload=$(nuinui_e2e_host__record_payload "$nuinui_e2e_host_intent") || return 1
  nuinui_e2e_host_identity_pending=$nuinui_e2e_host_r_root_identity
  nuinui_e2e_host_compare_files=
  for nuinui_e2e_host_pair in \
    "$nuinui_e2e_host_handoff:handoff" "$nuinui_e2e_host_ready:ready" \
    "$nuinui_e2e_host_pending:cleanup-pending" "$nuinui_e2e_host_cleanup_receipt:cleanup"; do
    nuinui_e2e_host_path=${nuinui_e2e_host_pair%:*}
    nuinui_e2e_host_kind=${nuinui_e2e_host_pair##*:}
    if nuinui_e2e__exists "$nuinui_e2e_host_path"; then
      nuinui_e2e_host__read_record "$nuinui_e2e_host_path" "$nuinui_e2e_host_kind" || return 1
      [ "$(nuinui_e2e_host__record_payload "$nuinui_e2e_host_path")" = \
        "$nuinui_e2e_host_payload" ] || return 1
      if [ "$nuinui_e2e_host_r_root_identity" = pending ]; then
        case "$nuinui_e2e_host_kind" in cleanup-pending|cleanup) ;;
          *) return 1 ;;
        esac
        [ "$nuinui_e2e_host_identity_pending" = pending ] || return 1
        continue
      fi
      if [ "$nuinui_e2e_host_identity_pending" = pending ]; then
        nuinui_e2e_host_identity_pending=$nuinui_e2e_host_r_root_identity
      else
        [ "$nuinui_e2e_host_identity_pending" = "$nuinui_e2e_host_r_root_identity" ] || return 1
      fi
      nuinui_e2e_host_compare_files="$nuinui_e2e_host_compare_files $nuinui_e2e_host_path"
    fi
  done
  if [ "$nuinui_e2e_host_has_cleanup" = yes ]; then
    if [ "$nuinui_e2e_host_has_handoff" = yes ]; then
      nuinui_e2e_host_expected_handoff_sha=$(nuinui_e2e__sha256 "$nuinui_e2e_host_handoff") || return 1
    else
      nuinui_e2e_host_expected_handoff_sha=none
    fi
    nuinui_e2e_host__read_record "$nuinui_e2e_host_cleanup_receipt" cleanup || return 1
    [ "$nuinui_e2e_host_r_handoff_sha" = "$nuinui_e2e_host_expected_handoff_sha" ] || return 1
  fi
  nuinui_e2e_host_root=$(nuinui_e2e_host__root_for "$nuinui_e2e_expected_generation")
  if [ "$nuinui_e2e_host_identity_pending" = pending ]; then
    if nuinui_e2e__exists "$nuinui_e2e_host_root"; then
      [ -d "$nuinui_e2e_host_root" ] && [ ! -L "$nuinui_e2e_host_root" ] || return 1
      nuinui_e2e_host_actual_identity=$(nuinui_e2e_host__root_identity "$nuinui_e2e_host_root") || return 1
      nuinui_e2e_host__read_record "$nuinui_e2e_host_intent" intent || return 1
      nuinui_e2e_host_root_identity=$nuinui_e2e_host_actual_identity
      nuinui_e2e_host_owner=$(nuinui_e2e_host__owner_path "$nuinui_e2e_host_root")
      nuinui_e2e__regular "$nuinui_e2e_host_owner" || return 1
      nuinui_e2e_host_owner_expected=$(nuinui_e2e_host__owner_content)
      nuinui_e2e_host_owner_tmp=$(mktemp "${nuinui_e2e_host_root}/.owner-verify.XXXXXX") || return 1
      printf '%s' "$nuinui_e2e_host_owner_expected" > "$nuinui_e2e_host_owner_tmp" || {
        rm -f "$nuinui_e2e_host_owner_tmp"
        return 1
      }
      cmp -s "$nuinui_e2e_host_owner_tmp" "$nuinui_e2e_host_owner"
      nuinui_e2e_host_owner_result=$?
      rm -f "$nuinui_e2e_host_owner_tmp"
      [ "$nuinui_e2e_host_owner_result" = 0 ] || return 1
      nuinui_e2e_host_file=$(nuinui_e2e_host__fixture_copy_path "$nuinui_e2e_host_root")
      if nuinui_e2e__exists "$nuinui_e2e_host_file"; then
        nuinui_e2e__regular "$nuinui_e2e_host_file" &&
          [ "$(nuinui_e2e__sha256 "$nuinui_e2e_host_file")" = "$nuinui_e2e_host_fixture_sha" ] || return 1
      fi
      nuinui_e2e_host_entries=$(find "$nuinui_e2e_host_root" -mindepth 1 -maxdepth 1 -print 2>/dev/null) || return 1
      while IFS= read -r nuinui_e2e_host_entry || [ -n "$nuinui_e2e_host_entry" ]; do
        [ -n "$nuinui_e2e_host_entry" ] || continue
        case "$nuinui_e2e_host_entry" in "$nuinui_e2e_host_owner"|"$nuinui_e2e_host_file") ;; *) return 1 ;; esac
        [ ! -L "$nuinui_e2e_host_entry" ] || return 1
      done <<EOF
$nuinui_e2e_host_entries
EOF
    fi
  else
    nuinui_e2e_host_root_identity=$nuinui_e2e_host_identity_pending
    if [ "$nuinui_e2e_host_has_cleanup" = yes ]; then
      nuinui_e2e__exists "$nuinui_e2e_host_root" && return 1
    elif [ "$nuinui_e2e_host_has_pending" = yes ]; then
      if nuinui_e2e__exists "$nuinui_e2e_host_root"; then
        nuinui_e2e_host__verify_root "$nuinui_e2e_host_root" partial || return 1
      fi
    elif [ "$nuinui_e2e_host_has_ready" = yes ]; then
      nuinui_e2e_host__read_record "$nuinui_e2e_host_ready" ready || return 1
      nuinui_e2e_host__verify_root "$nuinui_e2e_host_root" complete || return 1
    elif [ "$nuinui_e2e_host_has_handoff" = yes ]; then
      nuinui_e2e_host__read_record "$nuinui_e2e_host_handoff" handoff || return 1
      nuinui_e2e_host__verify_root "$nuinui_e2e_host_root" complete || return 1
    else
      return 1
    fi
  fi
  if [ "$nuinui_e2e_host_has_cleanup" = yes ]; then
    nuinui_e2e_host_state=CLEANED
  elif [ "$nuinui_e2e_host_has_pending" = yes ]; then
    nuinui_e2e_host_state=CLEANUP-PENDING
  elif [ "$nuinui_e2e_host_has_ready" = yes ]; then
    nuinui_e2e_host_state=READY
  else
    nuinui_e2e_host_state=PREPARING
  fi
  nuinui_e2e_host_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_host_active"; then
    nuinui_e2e_host__read_record "$nuinui_e2e_host_intent" intent || return 1
    [ "$(nuinui_e2e__sha256 "$nuinui_e2e_host_active")" = "$nuinui_e2e_host_active_sha" ] || return 1
  elif [ "$nuinui_e2e_host_state" = CLEANED ]; then
    nuinui_e2e_host_release=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" release) || return 1
    nuinui_e2e_host__read_record "$nuinui_e2e_host_cleanup_receipt" cleanup || return 1
    [ -e "$nuinui_e2e_host_release" ] &&
      nuinui_e2e__read_expected_release "$nuinui_e2e_host_release" || return 1
    nuinui_e2e_host__cleanup_proof_matches \
      "$(nuinui_e2e__sha256 "$nuinui_e2e_host_cleanup_receipt")" || return 1
    [ "$(nuinui_e2e__live_idle_sha "$nuinui_e2e_expected_repo")" = \
      "$nuinui_e2e_r_idle_sha" ] || return 1
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" "$nuinui_e2e_r_idle_sha" || return 1
    nuinui_e2e_host_state=RELEASED
  else
    return 1
  fi
}

nuinui_e2e_host__preflight_scan() {
  [ "$#" = 2 ] || return 2
  nuinui_e2e_host_scan_git_dir=$1
  nuinui_e2e_host_scan_lane=$2
  nuinui_e2e_host_scan_paths=$(find "$nuinui_e2e_host_scan_git_dir" -maxdepth 1 \
    -name 'nuinui-github-e2e-host-*' -print 2>/dev/null) || return 1
  if [ -z "$nuinui_e2e_host_scan_paths" ]; then
    nuinui_e2e_host_orphan_root=$(nuinui_e2e_host__root_for "$nuinui_e2e_expected_generation") || return 1
    nuinui_e2e__exists "$nuinui_e2e_host_orphan_root" && return 1
    nuinui_e2e_host_state=ABSENT
    return 0
  fi
  while IFS= read -r nuinui_e2e_host_scan_path || [ -n "$nuinui_e2e_host_scan_path" ]; do
    [ -n "$nuinui_e2e_host_scan_path" ] || continue
    nuinui_e2e_host_scan_name=${nuinui_e2e_host_scan_path##*/}
    nuinui_e2e_host_scan_kind=$(nuinui_e2e_host__kind_from_name "$nuinui_e2e_host_scan_name") || return 1
    nuinui_e2e_host__read_record "$nuinui_e2e_host_scan_path" "$nuinui_e2e_host_scan_kind" || return 1
    [ "$nuinui_e2e_host_r_lane" = "$nuinui_e2e_host_scan_lane" ] || return 1
    nuinui_e2e_host_scan_hash=$(nuinui_e2e__generation_hash "$nuinui_e2e_host_r_generation") || return 1
    case "$nuinui_e2e_host_scan_name" in
      nuinui-github-e2e-host-intent-v1."$nuinui_e2e_host_scan_hash"|\
      nuinui-github-e2e-host-handoff-v1."$nuinui_e2e_host_scan_hash"|\
      nuinui-github-e2e-host-ready-v1."$nuinui_e2e_host_scan_hash"|\
      nuinui-github-e2e-host-cleanup-pending-v1."$nuinui_e2e_host_scan_hash"|\
      nuinui-github-e2e-host-cleanup-v1."$nuinui_e2e_host_scan_hash") ;;
      *) return 1 ;;
    esac
    [ "$nuinui_e2e_host_r_issue" = "$nuinui_e2e_expected_issue" ] &&
      [ "$nuinui_e2e_host_r_generation" = "$nuinui_e2e_expected_generation" ] &&
      [ "$nuinui_e2e_host_r_tested" = "$nuinui_e2e_expected_tested" ] &&
      [ "$nuinui_e2e_host_r_lane" = "$nuinui_e2e_host_scan_lane" ] || return 1
  done <<EOF
$nuinui_e2e_host_scan_paths
EOF
  nuinui_e2e_host__load_state || return 1
  case "$nuinui_e2e_host_state:$nuinui_e2e_operation" in
    ABSENT:*) ;;
    PREPARING:host-check|PREPARING:host-prepare|PREPARING:host-status|PREPARING:host-cleanup|PREPARING:host-recover|PREPARING:host-closure|PREPARING:status|PREPARING:recover) ;;
    READY:host-check|READY:host-prepare|READY:host-status|READY:host-cleanup|READY:host-recover|READY:host-closure|READY:status) ;;
    CLEANUP-PENDING:host-status|CLEANUP-PENDING:host-cleanup|CLEANUP-PENDING:host-recover|CLEANUP-PENDING:host-closure|CLEANUP-PENDING:status|CLEANUP-PENDING:recover) ;;
    CLEANED:host-status|CLEANED:host-cleanup|CLEANED:host-recover|CLEANED:host-closure|CLEANED:release|CLEANED:closure|CLEANED:status|CLEANED:recover) ;;
    RELEASED:host-status|RELEASED:host-cleanup|RELEASED:host-closure|RELEASED:host-recover|RELEASED:status|RELEASED:closure|RELEASED:release) ;;
    *) return 1 ;;
  esac
}

nuinui_e2e_host__cleanup_proof_matches() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_host_proof_sha=$1
  nuinui_e2e_host_proof_path=$(nuinui_e2e_host__metadata_path \
    "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e__regular "$nuinui_e2e_host_proof_path" || return 1
  [ "$(nuinui_e2e__sha256 "$nuinui_e2e_host_proof_path")" = \
    "$nuinui_e2e_host_proof_sha" ] || return 1
  nuinui_e2e_host__read_record "$nuinui_e2e_host_proof_path" cleanup || return 1
  [ "$nuinui_e2e_host_r_issue" = "$nuinui_e2e_expected_issue" ] &&
    [ "$nuinui_e2e_host_r_lane" = "$nuinui_e2e_expected_lane" ] &&
    [ "$nuinui_e2e_host_r_generation" = "$nuinui_e2e_expected_generation" ] &&
    [ "$nuinui_e2e_host_r_tested" = "$nuinui_e2e_expected_tested" ]
}

nuinui_e2e_host__native_cleanup_proof() {
  nuinui_e2e_host_native_cleanup=$(nuinui_e2e__path_for \
    "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e_host_cleanup_hash=$(nuinui_e2e__sha256 "$nuinui_e2e_host_cleanup_receipt") || return 1
  if nuinui_e2e__exists "$nuinui_e2e_host_native_cleanup"; then
    nuinui_e2e__read_expected_cleanup "$nuinui_e2e_host_native_cleanup" || return 1
    [ "$nuinui_e2e_r_proof" = fixture-host-session-cleaned ] &&
      [ "$nuinui_e2e_r_host_cleanup_sha" = "$nuinui_e2e_host_cleanup_hash" ] || return 1
    return 0
  fi
  nuinui_e2e_host_native_content=$(nuinui_e2e__record_base)
  nuinui_e2e_host_native_content=$nuinui_e2e_host_native_content$(printf '\nproof=fixture-host-session-cleaned\nhost_cleanup_sha256=%s\n' \
    "$nuinui_e2e_host_cleanup_hash")
  nuinui_e2e__atomic_create "$nuinui_e2e_host_native_cleanup" \
    "$nuinui_e2e_host_native_content" || return 1
  nuinui_e2e__read_expected_cleanup "$nuinui_e2e_host_native_cleanup" || return 1
  [ "$nuinui_e2e_r_proof" = fixture-host-session-cleaned ] &&
    [ "$nuinui_e2e_r_host_cleanup_sha" = "$nuinui_e2e_host_cleanup_hash" ]
}

nuinui_e2e_host__operation_context() {
  [ "$#" = 4 ] || return 2
  nuinui_e2e_operation=$1
  nuinui_e2e_host_manifest_arg=$2
  nuinui_e2e_host_lane_arg=$3
  nuinui_e2e_host_issue_arg=$4
  nuinui_e2e__fixture_context "$nuinui_e2e_host_manifest_arg" \
    "$nuinui_e2e_host_lane_arg" "$nuinui_e2e_host_issue_arg" || return 1
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e_host_active=$(nuinui_e2e__path_for "$nuinui_e2e_expected_repo" active) || return 1
  if nuinui_e2e__exists "$nuinui_e2e_host_active"; then
    nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" || {
      echo 'BLOCKED: host operation requires the exact active native generation'
      return 1
    }
    nuinui_e2e_host_active_sha=$(nuinui_e2e__sha256 "$nuinui_e2e_host_active") || return 1
  fi
  nuinui_e2e_host_issue=$nuinui_e2e_expected_issue
  nuinui_e2e_host_url=$nuinui_e2e_expected_url
  nuinui_e2e_host_token=$nuinui_e2e_expected_token
  nuinui_e2e_host_lane=$nuinui_e2e_expected_lane
  nuinui_e2e_host_checkout=$nuinui_e2e_checkout
  nuinui_e2e_host_git_dir=$nuinui_e2e_git_dir
  nuinui_e2e_host_manifest=$nuinui_e2e_manifest_path
  nuinui_e2e_host_manifest_sha=$nuinui_e2e_manifest_sha
  nuinui_e2e_host_default_branch=$nuinui_e2e_default_branch
  nuinui_e2e_host_tested=$nuinui_e2e_expected_tested
  nuinui_e2e_host_generation=$nuinui_e2e_expected_generation
  nuinui_e2e_host_root=$(nuinui_e2e_host__root_for "$nuinui_e2e_host_generation")
}

nuinui_e2e_host__input_parameters() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_host_fixture_rows=$(nuinui_e2e_host__fixture_identity \
    "$1" "$nuinui_e2e_host_checkout") || {
      echo 'BLOCKED: fixture must be a canonical, regular external file outside the Human-test checkout' >&2
      return 1
    }
  nuinui_e2e_host_fixture=$(printf '%s\n' "$nuinui_e2e_host_fixture_rows" | sed -n '1p')
  nuinui_e2e_host_fixture_sha=$(printf '%s\n' "$nuinui_e2e_host_fixture_rows" | sed -n '2p')
  nuinui_e2e_host_port=$2
  nuinui_e2e_host_locale=$3
  nuinui_e2e_host__valid_port "$nuinui_e2e_host_port" || {
    echo 'BLOCKED: host fixture port must be an explicit integer from 1 through 65535' >&2
    return 1
  }
  case "$nuinui_e2e_host_locale" in default|ja) ;; *) return 1 ;; esac
}

nuinui_e2e_host__assert_input_match() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_host__input_parameters "$1" "$2" "$3" || return 1
  [ "$nuinui_e2e_host_state" = ABSENT ] || {
    nuinui_e2e_host__read_record "$nuinui_e2e_host_intent" intent || return 1
    [ "$nuinui_e2e_host_r_fixture" = "$nuinui_e2e_host_fixture" ] &&
      [ "$nuinui_e2e_host_r_fixture_sha" = "$nuinui_e2e_host_fixture_sha" ] &&
      [ "$nuinui_e2e_host_r_port" = "$nuinui_e2e_host_port" ] &&
      [ "$nuinui_e2e_host_r_locale" = "$nuinui_e2e_host_locale" ] || return 1
  }
}

nuinui_e2e_host_check() {
  [ "$#" = 6 ] || return 2
  nuinui_e2e_host__operation_context host-check "$1" "$2" "$3" || return 1
  nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" || {
    echo 'BLOCKED: host check requires the exact active native generation'
    return 1
  }
  nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_expected_tested" || {
      echo 'BLOCKED: host fixture check requires the exact clean detached tested checkout'
      return 1
    }
  nuinui_e2e_host__load_state || {
    echo 'BLOCKED: host-session metadata or resources are conflicting or malformed'
    return 1
  }
  nuinui_e2e_host__assert_input_match "$4" "$5" "$6" || {
    echo 'BLOCKED: host fixture request differs from the exact recorded session'
    return 1
  }
  case "$nuinui_e2e_host_state" in
    ABSENT|READY) ;;
    *) echo "BLOCKED: host session is $nuinui_e2e_host_state"; return 1 ;;
  esac
  printf 'HOST FIXTURE CHECK READY\nissue=%s\nlane=%s\ntested_sha=%s\ngeneration=%s\nfixture=%s\nport=%s\nlocale=%s\nadapter=fixture-no-process\nstate=%s\nmutation=no\n' \
    "$nuinui_e2e_expected_issue" "$nuinui_e2e_expected_lane" \
    "$nuinui_e2e_expected_tested" "$nuinui_e2e_expected_generation" \
    "$nuinui_e2e_host_fixture" "$nuinui_e2e_host_port" \
    "$nuinui_e2e_host_locale" "$nuinui_e2e_host_state"
}

nuinui_e2e_host_prepare() {
  [ "$#" = 6 ] || return 2
  nuinui_e2e_host_check_output=$(nuinui_e2e_host_check \
    "$1" "$2" "$3" "$4" "$5" "$6") || {
      printf '%s\n' "$nuinui_e2e_host_check_output"
      return 1
    }
  nuinui_e2e_host__operation_context host-prepare "$1" "$2" "$3" || return 1
  nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" || {
    echo 'BLOCKED: host preparation requires the exact active native generation'
    return 1
  }
  nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_expected_tested" || return 1
  nuinui_e2e_host__load_state || return 1
  nuinui_e2e_host__assert_input_match "$4" "$5" "$6" || {
    echo 'BLOCKED: host preparation parameters conflict with the exact recorded session'
    return 1
  }
  if [ "$nuinui_e2e_host_state" = READY ]; then
    echo 'HOST FIXTURE ALREADY READY (fixture-no-process)'
    echo 'mutation=no-op'
    return 0
  fi
  [ "$nuinui_e2e_host_state" = ABSENT ] || {
    echo "BLOCKED: host preparation cannot continue from $nuinui_e2e_host_state"
    return 1
  }
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_expected_tested" || {
        echo 'BLOCKED: native generation or clean tested checkout changed before PREPARING intent'
        return 1
      }
  nuinui_e2e_host__load_state || return 1
  [ "$nuinui_e2e_host_state" = ABSENT ] &&
    nuinui_e2e_host__assert_input_match "$4" "$5" "$6" || {
      echo 'BLOCKED: host session or fixture parameters changed before PREPARING intent'
      return 1
    }
  nuinui_e2e_host_root=$(nuinui_e2e_host__root_for "$nuinui_e2e_expected_generation") || return 1
  nuinui_e2e__exists "$nuinui_e2e_host_root" && {
    echo 'BLOCKED: generation-specific host root already exists without matching durable records'
    return 1
  }
  nuinui_e2e_host_root_identity=pending
  nuinui_e2e_host_intent_content=$(nuinui_e2e_host__record_content PREPARING pending)
  nuinui_e2e_host_intent=$(nuinui_e2e_host__metadata_path \
    "$nuinui_e2e_expected_repo" intent) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_host_intent" \
    "$nuinui_e2e_host_intent_content" || {
      echo 'BLOCKED: durable PREPARING intent could not be created'
      return 1
    }
  nuinui_e2e__failpoint after-host-intent && {
    echo 'BLOCKED: injected interruption after PREPARING intent; recovery evidence retained'
    return 1
  }
  mkdir "$nuinui_e2e_host_root" 2>/dev/null || {
    echo 'BLOCKED: generation-specific fixture host root could not be created'
    return 1
  }
  nuinui_e2e_host_root_identity=$(nuinui_e2e_host__root_identity "$nuinui_e2e_host_root") || return 1
  nuinui_e2e_host_owner=$(nuinui_e2e_host__owner_path "$nuinui_e2e_host_root")
  nuinui_e2e_host_owner_content=$(nuinui_e2e_host__owner_content)
  nuinui_e2e__atomic_create "$nuinui_e2e_host_owner" \
    "$nuinui_e2e_host_owner_content" || {
      echo 'BLOCKED: exact fixture root owner record could not be created'
      return 1
    }
  nuinui_e2e_host_fixture_copy=$(nuinui_e2e_host__fixture_copy_path "$nuinui_e2e_host_root")
  nuinui_e2e_host__atomic_copy "$nuinui_e2e_host_fixture" \
    "$nuinui_e2e_host_fixture_copy" "$nuinui_e2e_host_fixture_sha" || {
      echo 'BLOCKED: fixture resource could not be atomically created and verified'
      return 1
    }
  nuinui_e2e__failpoint after-host-resources && {
    echo 'BLOCKED: injected interruption after owned fixture resources; recovery evidence retained'
    return 1
  }
  nuinui_e2e_host_handoff_content=$(nuinui_e2e_host__record_content HANDOFF \
    "$nuinui_e2e_host_root_identity")
  nuinui_e2e_host_handoff=$(nuinui_e2e_host__metadata_path \
    "$nuinui_e2e_expected_repo" handoff) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_host_handoff" \
    "$nuinui_e2e_host_handoff_content" || {
      echo 'BLOCKED: exact generation-bound handoff could not be created'
      return 1
    }
  nuinui_e2e__failpoint after-host-handoff && {
    echo 'BLOCKED: injected interruption after handoff; recovery evidence retained'
    return 1
  }
  nuinui_e2e_host__verify_root "$nuinui_e2e_host_root" complete || {
    echo 'BLOCKED: fixture resources or ownership changed before READY'
    return 1
  }
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_expected_tested" || return 1
  nuinui_e2e_host_ready_content=$(nuinui_e2e_host__record_content READY \
    "$nuinui_e2e_host_root_identity")
  nuinui_e2e_host_ready=$(nuinui_e2e_host__metadata_path \
    "$nuinui_e2e_expected_repo" ready) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_host_ready" \
    "$nuinui_e2e_host_ready_content" || {
      echo 'BLOCKED: READY state could not be durably published'
      return 1
    }
  nuinui_e2e_host__read_record "$nuinui_e2e_host_ready" ready &&
    nuinui_e2e_host__verify_root "$nuinui_e2e_host_root" complete || return 1
  echo 'HOST FIXTURE READY (fixture-no-process; no Human Manual E2E was run)'
  echo "issue=$nuinui_e2e_expected_issue"
  echo "lane=$nuinui_e2e_expected_lane"
  echo "tested_sha=$nuinui_e2e_expected_tested"
  echo "generation=$nuinui_e2e_expected_generation"
  echo "root=$nuinui_e2e_host_root"
  echo 'mutation=yes'
}

nuinui_e2e_host_status() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_host__operation_context host-status "$1" "$2" "$3" || return 1
  nuinui_e2e_host__load_state || {
    echo 'BLOCKED: host-session metadata or resources are malformed or foreign'
    return 1
  }
  if [ "$nuinui_e2e_host_state" != RELEASED ]; then
    nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" || {
      echo 'BLOCKED: host status requires the exact active native generation or its verified release receipt'
      return 1
    }
  fi
  printf 'HOST SESSION %s\nissue=%s\nlane=%s\ntested_sha=%s\ngeneration=%s\nadapter=fixture-no-process\nmutation=no\n' \
    "$nuinui_e2e_host_state" "$nuinui_e2e_expected_issue" \
    "$nuinui_e2e_expected_lane" "$nuinui_e2e_expected_tested" \
    "$nuinui_e2e_expected_generation"
}

nuinui_e2e_host_cleanup() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_host__operation_context host-cleanup "$1" "$2" "$3" || return 1
  nuinui_e2e_host__load_state || {
    echo 'BLOCKED: host cleanup cannot prove exact session and resource ownership'
    return 1
  }
  case "$nuinui_e2e_host_state" in
    RELEASED)
      echo 'HOST FIXTURE ALREADY CLEANED AND RELEASED'
      echo 'mutation=no-op'
      return 0
      ;;
    CLEANED)
      nuinui_e2e_host__native_cleanup_proof || return 1
      echo 'HOST FIXTURE ALREADY CLEANED'
      echo 'mutation=no-op'
      return 0
      ;;
    READY|PREPARING|CLEANUP-PENDING) ;;
    *) echo 'BLOCKED: no owned host session exists'; return 1 ;;
  esac
  nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" || return 1
  nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
    "$nuinui_e2e_expected_tested" || {
      echo 'BLOCKED: host cleanup requires exact clean detached tested checkout'
      return 1
    }
  if [ "$nuinui_e2e_host_state" != CLEANUP-PENDING ]; then
    nuinui_e2e_host_cleanup_pending_content=$(nuinui_e2e_host__record_content \
      CLEANUP-PENDING "$nuinui_e2e_host_root_identity")
    nuinui_e2e_host_pending=$(nuinui_e2e_host__metadata_path \
      "$nuinui_e2e_expected_repo" cleanup-pending) || return 1
    nuinui_e2e__atomic_create "$nuinui_e2e_host_pending" \
      "$nuinui_e2e_host_cleanup_pending_content" || return 1
  fi
  nuinui_e2e__failpoint after-host-cleanup-pending && {
    echo 'BLOCKED: injected interruption after CLEANUP-PENDING; recovery evidence retained'
    return 1
  }
  nuinui_e2e_host__remove_root partial || {
    echo 'BLOCKED: host fixture root contains foreign or uncertain resources; retained'
    return 1
  }
  nuinui_e2e__failpoint after-host-resource-removal && {
    echo 'BLOCKED: injected interruption after verified fixture removal; cleanup intent retained'
    return 1
  }
  nuinui_e2e__preflight "$nuinui_e2e_manifest_path" >/dev/null || return 1
  nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" &&
    nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
      "$nuinui_e2e_expected_tested" || {
        echo 'BLOCKED: exact active generation or tested checkout changed after resource removal'
        return 1
      }
  nuinui_e2e_host__load_state || return 1
  [ "$nuinui_e2e_host_state" = CLEANUP-PENDING ] || {
    echo 'BLOCKED: cleanup intent changed before the durable cleanup receipt'
    return 1
  }
  nuinui_e2e_host_cleanup_handoff_sha=none
  if [ "$nuinui_e2e_host_has_handoff" = yes ]; then
    nuinui_e2e_host_cleanup_handoff_sha=$(nuinui_e2e__sha256 "$nuinui_e2e_host_handoff") || return 1
  fi
  nuinui_e2e_host_cleanup_content=$(nuinui_e2e_host__record_content CLEANED \
    "$nuinui_e2e_host_root_identity")
  nuinui_e2e_host_cleanup_receipt=$(nuinui_e2e_host__metadata_path \
    "$nuinui_e2e_expected_repo" cleanup) || return 1
  nuinui_e2e__atomic_create "$nuinui_e2e_host_cleanup_receipt" \
    "$nuinui_e2e_host_cleanup_content" || {
      echo 'BLOCKED: durable host cleanup receipt could not be published'
      return 1
    }
  nuinui_e2e_host__read_record "$nuinui_e2e_host_cleanup_receipt" cleanup || return 1
  [ ! -e "$nuinui_e2e_host_root" ] && [ ! -L "$nuinui_e2e_host_root" ] || return 1
  nuinui_e2e_host__native_cleanup_proof || {
    echo 'BLOCKED: native cleanup proof could not bind the verified host cleanup receipt'
    return 1
  }
  echo 'HOST FIXTURE CLEANUP VERIFIED (fixture-no-process)'
  echo "generation=$nuinui_e2e_expected_generation"
  echo 'state=CLEANED'
  echo 'native_cleanup_proof=host-receipt-bound'
  echo 'mutation=yes'
}

nuinui_e2e_host_recover() {
  [ "$#" = 3 ] || return 2
  nuinui_e2e_host__operation_context host-recover "$1" "$2" "$3" || return 1
  nuinui_e2e_host__load_state || {
    echo 'BLOCKED: fresh host metadata, native generation, and checkout evidence do not agree'
    return 1
  }
  case "$nuinui_e2e_host_state" in
    PREPARING|CLEANUP-PENDING)
      nuinui_e2e__read_expected_active "$nuinui_e2e_host_active" || return 1
      nuinui_e2e__checked_out "$nuinui_e2e_expected_repo" \
        "$nuinui_e2e_expected_tested" || return 1
      nuinui_e2e_host_operation_before=$nuinui_e2e_host_state
      nuinui_e2e_host_recovered=$(nuinui_e2e_host_cleanup "$1" "$2" "$3") || {
        echo "$nuinui_e2e_host_recovered"
        return 1
      }
      printf '%s\n' "$nuinui_e2e_host_recovered"
      echo "HOST FIXTURE RECOVERED FROM $nuinui_e2e_host_operation_before"
      echo 'mutation=yes'
      ;;
    CLEANED|RELEASED)
      nuinui_e2e_host__native_cleanup_proof || return 1
      echo 'HOST FIXTURE RECOVERY ALREADY COMPLETE'
      echo 'mutation=no-op'
      ;;
    *)
      echo 'BLOCKED: host recovery requires an exact interrupted preparation or cleanup'
      return 1
      ;;
  esac
}
