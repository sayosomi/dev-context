# Human-authorized, deterministic exact source-fix executor.
#
# The handoff façade remains the authority for durable implementation
# generation identity.  This fragment owns only the narrow patch, verifier,
# commit, and ordinary-push boundary.

nuinui_exact_fix_valid_sha() {
  nuinui_ownership_valid_sha "$1"
}

nuinui_exact_fix_has_control() {
  printf '%s' "$1" | LC_ALL=C grep -q '[[:cntrl:]]'
}

nuinui_exact_fix_hash() {
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  shasum -a 256 "$1" | awk 'NR == 1 {print $1}'
}

nuinui_exact_fix_usage() {
  printf '%s\n' 'Usage: nuinui exact-fix --issue <SAY-N> --expected-topic <40-sha> --expected-main <40-sha> --patch <absolute-patch-file> --verify <absolute-verifier-file> --message <commit-message> --file <repo-relative-path> [--file <repo-relative-path> ...]'
}

nuinui_exact_fix_parse_args() {
  nuinui_exact_fix_issue=
  nuinui_exact_fix_expected_topic=
  nuinui_exact_fix_expected_main=
  nuinui_exact_fix_patch=
  nuinui_exact_fix_verify=
  nuinui_exact_fix_message=
  nuinui_exact_fix_files=
  nuinui_exact_fix_seen_issue=0
  nuinui_exact_fix_seen_topic=0
  nuinui_exact_fix_seen_main=0
  nuinui_exact_fix_seen_patch=0
  nuinui_exact_fix_seen_verify=0
  nuinui_exact_fix_seen_message=0
  nuinui_exact_fix_file_count=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --issue|--expected-topic|--expected-main|--patch|--verify|--message|--file)
        nuinui_exact_fix_option=$1
        shift
        [ "$#" -gt 0 ] || {
          printf 'ERROR: option %s requires one value\n' "$nuinui_exact_fix_option"
          return 2
        }
        nuinui_exact_fix_value=$1
        shift
        nuinui_exact_fix_has_control "$nuinui_exact_fix_value" && {
          printf 'ERROR: option %s contains a control character\n' "$nuinui_exact_fix_option"
          return 2
        }
        case "$nuinui_exact_fix_option" in
          --issue)
            [ "$nuinui_exact_fix_seen_issue" = 0 ] || { printf 'ERROR: duplicate named option --issue\n'; return 2; }
            nuinui_exact_fix_seen_issue=1; nuinui_exact_fix_issue=$nuinui_exact_fix_value ;;
          --expected-topic)
            [ "$nuinui_exact_fix_seen_topic" = 0 ] || { printf 'ERROR: duplicate named option --expected-topic\n'; return 2; }
            nuinui_exact_fix_seen_topic=1; nuinui_exact_fix_expected_topic=$nuinui_exact_fix_value ;;
          --expected-main)
            [ "$nuinui_exact_fix_seen_main" = 0 ] || { printf 'ERROR: duplicate named option --expected-main\n'; return 2; }
            nuinui_exact_fix_seen_main=1; nuinui_exact_fix_expected_main=$nuinui_exact_fix_value ;;
          --patch)
            [ "$nuinui_exact_fix_seen_patch" = 0 ] || { printf 'ERROR: duplicate named option --patch\n'; return 2; }
            nuinui_exact_fix_seen_patch=1; nuinui_exact_fix_patch=$nuinui_exact_fix_value ;;
          --verify)
            [ "$nuinui_exact_fix_seen_verify" = 0 ] || { printf 'ERROR: duplicate named option --verify\n'; return 2; }
            nuinui_exact_fix_seen_verify=1; nuinui_exact_fix_verify=$nuinui_exact_fix_value ;;
          --message)
            [ "$nuinui_exact_fix_seen_message" = 0 ] || { printf 'ERROR: duplicate named option --message\n'; return 2; }
            nuinui_exact_fix_seen_message=1; nuinui_exact_fix_message=$nuinui_exact_fix_value ;;
          --file)
            [ -n "$nuinui_exact_fix_value" ] || { printf 'ERROR: --file requires a non-empty path\n'; return 2; }
            nuinui_exact_fix_file_count=$((nuinui_exact_fix_file_count + 1))
            if [ -n "$nuinui_exact_fix_files" ]; then
              nuinui_exact_fix_files="$nuinui_exact_fix_files
$nuinui_exact_fix_value"
            else
              nuinui_exact_fix_files=$nuinui_exact_fix_value
            fi
            ;;
        esac
        ;;
      *)
        printf 'ERROR: exact-fix accepts named options only\n'
        return 2
        ;;
    esac
  done

  [ "$nuinui_exact_fix_seen_issue" = 1 ] &&
    [ "$nuinui_exact_fix_seen_topic" = 1 ] &&
    [ "$nuinui_exact_fix_seen_main" = 1 ] &&
    [ "$nuinui_exact_fix_seen_patch" = 1 ] &&
    [ "$nuinui_exact_fix_seen_verify" = 1 ] &&
    [ "$nuinui_exact_fix_seen_message" = 1 ] &&
    [ "$nuinui_exact_fix_file_count" -gt 0 ] || {
      printf 'ERROR: exact-fix requires every named option and at least one --file\n'
      nuinui_exact_fix_usage
      return 2
    }
  nuinui_ownership_valid_issue "$nuinui_exact_fix_issue" || {
    printf 'ERROR: Issue must look like SAY-123\n'
    return 2
  }
  nuinui_exact_fix_valid_sha "$nuinui_exact_fix_expected_topic" || {
    printf 'ERROR: expected topic must be a full 40-character commit SHA\n'
    return 2
  }
  nuinui_exact_fix_valid_sha "$nuinui_exact_fix_expected_main" || {
    printf 'ERROR: expected main must be a full 40-character commit SHA\n'
    return 2
  }
  [ -n "$nuinui_exact_fix_message" ] || {
    printf 'ERROR: commit message must be non-empty\n'
    return 2
  }
  return 0
}

nuinui_exact_fix_validate_input_file() {
  nuinui_exact_fix_input_name=$1
  nuinui_exact_fix_input_kind=$2
  [ -f "$nuinui_exact_fix_input_name" ] &&
    [ ! -L "$nuinui_exact_fix_input_name" ] ||
    { printf 'BLOCKED: %s must be an existing regular non-symlink file\n' "$nuinui_exact_fix_input_kind"; return 1; }
  nuinui_exact_fix_input_dir=$(CDPATH= cd -- "$(dirname "$nuinui_exact_fix_input_name")" 2>/dev/null && pwd -P) || {
    printf 'BLOCKED: %s parent directory cannot be resolved\n' "$nuinui_exact_fix_input_kind"
    return 1
  }
  nuinui_exact_fix_input_base=$(basename "$nuinui_exact_fix_input_name")
  [ "$nuinui_exact_fix_input_dir/$nuinui_exact_fix_input_base" = "$nuinui_exact_fix_input_name" ] || {
    printf 'BLOCKED: %s path contains a symlinked parent or is not canonical\n' "$nuinui_exact_fix_input_kind"
    return 1
  }
  [ -r "$nuinui_exact_fix_input_name" ] || {
    printf 'BLOCKED: %s is not readable\n' "$nuinui_exact_fix_input_kind"
    return 1
  }
  if [ "$nuinui_exact_fix_input_kind" = verifier ] && [ ! -x "$nuinui_exact_fix_input_name" ]; then
    printf 'BLOCKED: verifier must be executable\n'
    return 1
  fi
}

nuinui_exact_fix_validate_path() {
  nuinui_exact_fix_path=$1
  case "$nuinui_exact_fix_path" in
    /*|.|..|./*|../*|*/./*|*/../*|*//*)
      printf 'BLOCKED: declared path is not a normalized repository-relative path: %s\n' "$nuinui_exact_fix_path"
      return 1
      ;;
  esac
  printf '%s' "$nuinui_exact_fix_path" | LC_ALL=C grep -Eq '[*?\[]' && {
    printf 'BLOCKED: declared path contains an unsafe pathspec character: %s\n' "$nuinui_exact_fix_path"
    return 1
  }
  nuinui_exact_fix_candidate=$nuinui_exact_fix_repo/$nuinui_exact_fix_path
  [ -f "$nuinui_exact_fix_candidate" ] && [ ! -L "$nuinui_exact_fix_candidate" ] || {
    printf 'BLOCKED: declared path is not an existing regular file: %s\n' "$nuinui_exact_fix_path"
    return 1
  }
  nuinui_exact_fix_parent=$(CDPATH= cd -- "$(dirname "$nuinui_exact_fix_candidate")" 2>/dev/null && pwd -P) || return 1
  [ "$nuinui_exact_fix_parent/$(basename "$nuinui_exact_fix_candidate")" = "$nuinui_exact_fix_candidate" ] || {
    printf 'BLOCKED: declared path resolves through a symlinked parent: %s\n' "$nuinui_exact_fix_path"
    return 1
  }
  nuinui_exact_fix_stage=$(git --literal-pathspecs -C "$nuinui_exact_fix_repo" ls-files --stage -- "$nuinui_exact_fix_path" 2>/dev/null) || {
    printf 'BLOCKED: declared path is not tracked: %s\n' "$nuinui_exact_fix_path"
    return 1
  }
  [ "$(printf '%s\n' "$nuinui_exact_fix_stage" | awk 'NF {count++} END {print count+0}')" = 1 ] || {
    printf 'BLOCKED: declared path has ambiguous index entries: %s\n' "$nuinui_exact_fix_path"
    return 1
  }
  nuinui_exact_fix_mode=$(printf '%s\n' "$nuinui_exact_fix_stage" | cut -c1-6)
  case "$nuinui_exact_fix_mode" in 100644|100755) ;; *)
    printf 'BLOCKED: declared path is not a regular non-gitlink file: %s\n' "$nuinui_exact_fix_path"
    return 1
    ;;
  esac
  nuinui_exact_fix_head_stage=$(git --literal-pathspecs -C "$nuinui_exact_fix_repo" ls-tree "$nuinui_exact_fix_prior_head" -- "$nuinui_exact_fix_path" 2>/dev/null) || return 1
  [ "$(printf '%s\n' "$nuinui_exact_fix_head_stage" | awk 'NF {count++} END {print count+0}')" = 1 ] || {
    printf 'BLOCKED: declared path is not present exactly once at prior HEAD: %s\n' "$nuinui_exact_fix_path"
    return 1
  }
  nuinui_exact_fix_head_mode=$(printf '%s\n' "$nuinui_exact_fix_head_stage" | awk 'NR == 1 {print $1}')
  [ "$nuinui_exact_fix_head_mode" = "$nuinui_exact_fix_mode" ] || {
    printf 'BLOCKED: declared path mode changed before exact-fix: %s\n' "$nuinui_exact_fix_path"
    return 1
  }
}

nuinui_exact_fix_sorted_files() {
  printf '%s\n' "$nuinui_exact_fix_files" | sort
}

nuinui_exact_fix_changed_files() {
  nuinui_exact_fix_diff_index=$1
  git --literal-pathspecs -C "$nuinui_exact_fix_repo" diff --no-renames --name-status \
    "$nuinui_exact_fix_diff_index" 2>/dev/null |
    awk -F '	' 'NF == 2 && $1 == "M" {print $2}'
}

nuinui_exact_fix_validate_patch_shape() {
  if grep -Eiq '^(GIT binary patch|new file mode |deleted file mode |old mode |new mode |similarity index |rename from |rename to |copy from |copy to |Submodule )' "$nuinui_exact_fix_patch_snapshot"; then
    printf 'BLOCKED: patch contains an unsupported add, delete, rename, copy, binary, or submodule operation\n'
    return 1
  fi
  if grep -Eq '^diff --git a/[^ ]+ b/[^ ]+$' "$nuinui_exact_fix_patch_snapshot"; then
    :
  else
    printf 'BLOCKED: patch is not a standard textual Git patch\n'
    return 1
  fi
}

nuinui_exact_fix_temp_modes_are_textual() {
  while IFS= read -r nuinui_exact_fix_mode_path ||
    [ -n "$nuinui_exact_fix_mode_path" ]; do
    [ -n "$nuinui_exact_fix_mode_path" ] || continue
    nuinui_exact_fix_temp_stage=$(GIT_INDEX_FILE="$nuinui_exact_fix_temp_index" \
      git --literal-pathspecs -C "$nuinui_exact_fix_repo" ls-files --stage -- \
      "$nuinui_exact_fix_mode_path" 2>/dev/null) || return 1
    [ "$(printf '%s\n' "$nuinui_exact_fix_temp_stage" | awk 'NF {count++} END {print count+0}')" = 1 ] || return 1
    nuinui_exact_fix_temp_mode=$(printf '%s\n' "$nuinui_exact_fix_temp_stage" | cut -c1-6)
    nuinui_exact_fix_head_stage=$(git --literal-pathspecs -C "$nuinui_exact_fix_repo" \
      ls-tree "$nuinui_exact_fix_prior_head" -- "$nuinui_exact_fix_mode_path" 2>/dev/null) || return 1
    nuinui_exact_fix_head_mode=$(printf '%s\n' "$nuinui_exact_fix_head_stage" | awk 'NR == 1 {print $1}')
    [ "$nuinui_exact_fix_temp_mode" = "$nuinui_exact_fix_head_mode" ] || return 1
  done < "$nuinui_exact_fix_root/changed-sorted"
}

nuinui_exact_fix_canonical_diff() {
  nuinui_exact_fix_diff_index_kind=$1
  if [ "$nuinui_exact_fix_diff_index_kind" = cached ]; then
    git --literal-pathspecs -C "$nuinui_exact_fix_repo" --no-pager diff --cached \
      --binary --full-index --no-ext-diff --no-textconv --no-color \
      --src-prefix=a/ --dst-prefix=b/ "$nuinui_exact_fix_prior_head"
  else
    git --literal-pathspecs -C "$nuinui_exact_fix_repo" --no-pager diff \
      --binary --full-index --no-ext-diff --no-textconv --no-color \
      --src-prefix=a/ --dst-prefix=b/ "$nuinui_exact_fix_prior_head"
  fi
}

nuinui_exact_fix_diff_is_expected() {
  nuinui_exact_fix_actual_kind=$1
  nuinui_exact_fix_actual_file=$nuinui_exact_fix_root/actual-$nuinui_exact_fix_actual_kind.diff
  nuinui_exact_fix_canonical_diff "$nuinui_exact_fix_actual_kind" > "$nuinui_exact_fix_actual_file" || return 1
  cmp -s "$nuinui_exact_fix_expected_diff" "$nuinui_exact_fix_actual_file"
}

nuinui_exact_fix_untracked_is_empty() {
  [ -z "$(git --literal-pathspecs -C "$nuinui_exact_fix_repo" ls-files --others --exclude-standard)" ]
}

nuinui_exact_fix_ignored_is_baseline() {
  git --literal-pathspecs -C "$nuinui_exact_fix_repo" ls-files --others --ignored --exclude-standard |
    sort > "$nuinui_exact_fix_root/ignored-now"
  cmp -s "$nuinui_exact_fix_root/ignored-before" "$nuinui_exact_fix_root/ignored-now"
}

nuinui_exact_fix_remote_ref() {
  nuinui_exact_fix_remote_ref_name=$1
  nuinui_exact_fix_remote_expected=$2
  nuinui_exact_fix_remote_raw=
  nuinui_exact_fix_remote_rc=0
  nuinui_exact_fix_remote_raw=$(git -C "$nuinui_exact_fix_repo" ls-remote --exit-code origin \
    "$nuinui_exact_fix_remote_ref_name" 2>/dev/null) || nuinui_exact_fix_remote_rc=$?
  [ "$nuinui_exact_fix_remote_rc" = 0 ] || {
    printf 'BLOCKED: authoritative remote ref is unavailable: %s\n' "$nuinui_exact_fix_remote_ref_name"
    return 1
  }
  [ "$(printf '%s\n' "$nuinui_exact_fix_remote_raw" | awk 'NF {count++} END {print count+0}')" = 1 ] || {
    printf 'BLOCKED: authoritative remote ref lookup is ambiguous: %s\n' "$nuinui_exact_fix_remote_ref_name"
    return 1
  }
  nuinui_exact_fix_remote_ref_read=$(printf '%s\n' "$nuinui_exact_fix_remote_raw" | awk 'NR == 1 {print $2}')
  [ "$nuinui_exact_fix_remote_ref_read" = "$nuinui_exact_fix_remote_ref_name" ] || {
    printf 'BLOCKED: authoritative remote ref name is ambiguous: %s\n' "$nuinui_exact_fix_remote_ref_name"
    return 1
  }
  nuinui_exact_fix_remote_sha=$(printf '%s\n' "$nuinui_exact_fix_remote_raw" | awk 'NR == 1 {print $1}')
  nuinui_exact_fix_valid_sha "$nuinui_exact_fix_remote_sha" || {
    printf 'BLOCKED: authoritative remote ref SHA is invalid: %s\n' "$nuinui_exact_fix_remote_ref_name"
    return 1
  }
  case "$nuinui_exact_fix_remote_ref_name" in
    refs/heads/$nuinui_exact_fix_default_branch) nuinui_exact_fix_rmain=$nuinui_exact_fix_remote_sha ;;
    refs/heads/$nuinui_exact_fix_branch) nuinui_exact_fix_rtopic=$nuinui_exact_fix_remote_sha ;;
  esac
  [ "$nuinui_exact_fix_remote_sha" = "$nuinui_exact_fix_remote_expected" ] || {
    printf 'BLOCKED: authoritative remote ref changed: %s\nexpected=%s\nactual=%s\n' \
      "$nuinui_exact_fix_remote_ref_name" "$nuinui_exact_fix_remote_expected" "$nuinui_exact_fix_remote_sha"
    return 1
  }
}

nuinui_exact_fix_freshness() {
  nuinui_exact_fix_expected_head=${1:-$nuinui_exact_fix_prior_head}
  nuinui_exact_fix_rmain=unknown
  nuinui_exact_fix_rtopic=unknown
  nuinui_handoff_issue=$nuinui_exact_fix_issue
  nuinui_handoff_main=$nuinui_exact_fix_expected_main
  nuinui_handoff_resolve_identity || return 1
  [ "$nuinui_handoff_lane" = "$nuinui_exact_fix_lane" ] &&
    [ "$nuinui_handoff_repo" = "$nuinui_exact_fix_repo" ] &&
    [ "$nuinui_handoff_issue" = "$nuinui_exact_fix_issue" ] &&
    [ "$nuinui_handoff_branch" = "$nuinui_exact_fix_branch" ] &&
    [ "$nuinui_handoff_base" = "$nuinui_exact_fix_base" ] &&
    [ "$nuinui_handoff_claim" = "$nuinui_exact_fix_claim" ] &&
    [ "$nuinui_handoff_checkpoint" = "$nuinui_exact_fix_expected_head" ] &&
    [ "$nuinui_handoff_match_slot_snapshot" = "$nuinui_exact_fix_slot_snapshot" ] || {
      printf 'BLOCKED: durable implementation generation identity changed during exact-fix\n'
      return 1
    }
  [ "$(bn "$nuinui_exact_fix_repo")" = "$nuinui_exact_fix_branch" ] &&
    [ "$(hh "$nuinui_exact_fix_repo")" = "$nuinui_exact_fix_expected_head" ] || {
      printf 'BLOCKED: branch or prior topic HEAD changed during exact-fix\n'
      return 1
    }
  nuinui_exact_fix_gitdir=$(gd "$nuinui_exact_fix_repo") || return 1
  [ ! -e "$nuinui_exact_fix_gitdir/nuinui-implementation-lock" ] &&
    [ ! -L "$nuinui_exact_fix_gitdir/nuinui-implementation-lock" ] || {
      printf 'BLOCKED: implementation lane mutation lock exists\n'
      return 1
    }
  nuinui_exact_fix_release_pending=$(rds "$nuinui_exact_fix_repo") || {
    printf 'BLOCKED: unable to discover release-pending state\n'
    return 1
  }
  [ -z "$nuinui_exact_fix_release_pending" ] || {
    printf 'BLOCKED: implementation lane has release-pending state\n'
    return 1
  }
  nuinui_exact_fix_branch_ref=refs/heads/$nuinui_exact_fix_branch
  nuinui_exact_fix_default_branch=$(lane_execution_runtime_default_branch) || return 1
  nuinui_exact_fix_remote_ref "refs/heads/$nuinui_exact_fix_default_branch" \
    "$nuinui_exact_fix_expected_main" || return 1
  nuinui_exact_fix_remote_ref "$nuinui_exact_fix_branch_ref" \
    "$nuinui_exact_fix_prior_head" || return 1
}

nuinui_exact_fix_safe_restore() {
  nuinui_exact_fix_restore_head=$(hh "$nuinui_exact_fix_repo" 2>/dev/null || true)
  nuinui_exact_fix_restore_branch=$(bn "$nuinui_exact_fix_repo" 2>/dev/null || true)
  [ "$nuinui_exact_fix_restore_head" = "$nuinui_exact_fix_prior_head" ] &&
    [ "$nuinui_exact_fix_restore_branch" = "$nuinui_exact_fix_branch" ] || return 1
  nuinui_exact_fix_gitdir=$(gd "$nuinui_exact_fix_repo" 2>/dev/null) || return 1
  [ ! -e "$nuinui_exact_fix_gitdir/MERGE_HEAD" ] && [ ! -L "$nuinui_exact_fix_gitdir/MERGE_HEAD" ] || return 1
  [ -n "${nuinui_exact_fix_expected_diff:-}" ] &&
    [ -f "$nuinui_exact_fix_expected_diff" ] || return 1
  nuinui_exact_fix_diff_is_expected cached || return 1
  nuinui_exact_fix_diff_is_expected full || return 1
  nuinui_exact_fix_restore_names=$nuinui_exact_fix_root/restore-names
  {
    git --literal-pathspecs -C "$nuinui_exact_fix_repo" diff --name-only "$nuinui_exact_fix_prior_head"
    git --literal-pathspecs -C "$nuinui_exact_fix_repo" diff --cached --name-only
  } | sort -u > "$nuinui_exact_fix_restore_names"
  nuinui_exact_fix_sorted_files > "$nuinui_exact_fix_root/declared-sorted"
  while IFS= read -r nuinui_exact_fix_restore_path ||
    [ -n "$nuinui_exact_fix_restore_path" ]; do
    [ -n "$nuinui_exact_fix_restore_path" ] || continue
    grep -Fqx -- "$nuinui_exact_fix_restore_path" "$nuinui_exact_fix_root/declared-sorted" || return 1
  done < "$nuinui_exact_fix_restore_names"
  nuinui_exact_fix_untracked_is_empty || return 1
  nuinui_exact_fix_ignored_is_baseline || return 1
  while IFS= read -r nuinui_exact_fix_restore_path ||
    [ -n "$nuinui_exact_fix_restore_path" ]; do
    [ -n "$nuinui_exact_fix_restore_path" ] || continue
    git --literal-pathspecs -C "$nuinui_exact_fix_repo" restore \
      --source "$nuinui_exact_fix_prior_head" --staged --worktree -- \
      "$nuinui_exact_fix_restore_path" || return 1
  done < "$nuinui_exact_fix_root/declared-sorted"
  [ "$(hh "$nuinui_exact_fix_repo")" = "$nuinui_exact_fix_prior_head" ] &&
    [ "$(bn "$nuinui_exact_fix_repo")" = "$nuinui_exact_fix_branch" ] &&
    [ -z "$(git --literal-pathspecs -C "$nuinui_exact_fix_repo" status --porcelain -uall)" ] &&
    nuinui_exact_fix_untracked_is_empty &&
    nuinui_exact_fix_ignored_is_baseline
}

nuinui_exact_fix_preproof_failure() {
  printf 'BLOCKED: %s\n' "$1"
  printf 'mutation=no\nclean=yes\n'
  return 1
}

nuinui_exact_fix_postmutation_failure() {
  nuinui_exact_fix_reason=$1
  if nuinui_exact_fix_safe_restore; then
    printf 'BLOCKED: %s\nmutation=no\nclean=yes\nrestored=yes\n' "$nuinui_exact_fix_reason"
  else
    printf 'ERROR: %s; safe restoration could not be proven\nmutation=unknown\nclean=unknown\nrestored=not-proven\n' "$nuinui_exact_fix_reason"
  fi
  return 1
}

nuinui_exact_fix_push_failure() {
  nuinui_exact_fix_push_reason=$1
  nuinui_exact_fix_push_clean=no
  [ -z "$(git --literal-pathspecs -C "$nuinui_exact_fix_repo" status --porcelain -uall)" ] && nuinui_exact_fix_push_clean=yes
  nuinui_exact_fix_branch_ref=refs/heads/$nuinui_exact_fix_branch
  nuinui_exact_fix_default_branch=${nuinui_exact_fix_default_branch:-$(lane_execution_runtime_default_branch 2>/dev/null || true)}
  [ -n "$nuinui_exact_fix_default_branch" ] &&
    nuinui_exact_fix_remote_ref "refs/heads/$nuinui_exact_fix_default_branch" \
      "$nuinui_exact_fix_expected_main" >/dev/null || true
  nuinui_exact_fix_remote_ref "$nuinui_exact_fix_branch_ref" \
    "$nuinui_exact_fix_prior_head" >/dev/null || true
  printf 'ERROR: %s\nlane=%s\nissue=%s\nclaim=%s\nbranch=%s\nbase=%s\nprior_topic=%s\nhead=%s\nexpected_main=%s\ncurrent_remote_main=%s\ncurrent_remote_topic=%s\nmutation=yes\nclean=%s\nlocal_commit_preserved=yes\n' \
    "$nuinui_exact_fix_push_reason" "$nuinui_exact_fix_lane" "$nuinui_exact_fix_issue" \
    "$nuinui_exact_fix_claim" "$nuinui_exact_fix_branch" "$nuinui_exact_fix_base" \
    "$nuinui_exact_fix_prior_head" "$(hh "$nuinui_exact_fix_repo" 2>/dev/null || printf unknown)" \
    "$nuinui_exact_fix_expected_main" "$nuinui_exact_fix_rmain" \
    "$nuinui_exact_fix_rtopic" "$nuinui_exact_fix_push_clean"
  return 1
}

nuinui_exact_fix() {
  nuinui_exact_fix_parse_args "$@" || return $?
  nuinui_exact_fix_root=$(mktemp -d /tmp/nuinui-exact-fix.XXXXXX) || {
    printf 'ERROR: unable to create private exact-fix workspace\nmutation=no\nclean=yes\n'
    return 1
  }
  trap 'rm -rf -- "$nuinui_exact_fix_root"' EXIT HUP INT TERM

  nuinui_exact_fix_validate_input_file "$nuinui_exact_fix_patch" patch || return 1
  nuinui_exact_fix_validate_input_file "$nuinui_exact_fix_verify" verifier || return 1
  nuinui_exact_fix_patch_hash_before=$(nuinui_exact_fix_hash "$nuinui_exact_fix_patch") || return 1
  nuinui_exact_fix_verify_hash_before=$(nuinui_exact_fix_hash "$nuinui_exact_fix_verify") || return 1
  cp -p "$nuinui_exact_fix_patch" "$nuinui_exact_fix_root/patch" || return 1
  cp -p "$nuinui_exact_fix_verify" "$nuinui_exact_fix_root/verifier" || return 1
  nuinui_exact_fix_patch_snapshot=$nuinui_exact_fix_root/patch
  nuinui_exact_fix_verifier_snapshot=$nuinui_exact_fix_root/verifier
  [ "$(nuinui_exact_fix_hash "$nuinui_exact_fix_patch_snapshot")" = "$nuinui_exact_fix_patch_hash_before" ] || return 1
  [ "$(nuinui_exact_fix_hash "$nuinui_exact_fix_verifier_snapshot")" = "$nuinui_exact_fix_verify_hash_before" ] || return 1
  [ "$(nuinui_exact_fix_hash "$nuinui_exact_fix_patch")" = "$nuinui_exact_fix_patch_hash_before" ] || return 1
  [ "$(nuinui_exact_fix_hash "$nuinui_exact_fix_verify")" = "$nuinui_exact_fix_verify_hash_before" ] || return 1

  nuinui_handoff_issue=$nuinui_exact_fix_issue
  nuinui_handoff_main=$nuinui_exact_fix_expected_main
  nuinui_handoff_resolve_identity || return 1
  nuinui_exact_fix_lane=$nuinui_handoff_lane
  nuinui_exact_fix_repo=$nuinui_handoff_repo
  nuinui_exact_fix_branch=$nuinui_handoff_branch
  nuinui_exact_fix_base=$nuinui_handoff_base
  nuinui_exact_fix_claim=$nuinui_handoff_claim
  nuinui_exact_fix_prior_head=$nuinui_handoff_checkpoint
  nuinui_exact_fix_slot_snapshot=$nuinui_handoff_match_slot_snapshot
  NUINUI_EXACT_FIX_RESOLVED_LANE=$nuinui_exact_fix_lane
  NUINUI_EXACT_FIX_RESOLVED_ISSUE=$nuinui_exact_fix_issue
  NUINUI_EXACT_FIX_RESOLVED_CLAIM=$nuinui_exact_fix_claim
  [ "$nuinui_exact_fix_prior_head" = "$nuinui_exact_fix_expected_topic" ] || {
    nuinui_exact_fix_preproof_failure 'resolved current HEAD does not equal --expected-topic'
    return $?
  }
  nuinui_handoff_derive_topic_mode || return 1
  [ "$nuinui_handoff_topic" = exact ] || {
    nuinui_exact_fix_preproof_failure 'expected topic branch is not present at the resolved current HEAD'
    return $?
  }
  nuinui_handoff_run_check > "$nuinui_exact_fix_root/handoff.log" 2>&1 || {
    cat "$nuinui_exact_fix_root/handoff.log"
    return 1
  }
  [ "$(bn "$nuinui_exact_fix_repo")" = "$nuinui_exact_fix_branch" ] || {
    nuinui_exact_fix_preproof_failure 'resolved checkout is not on the claimed branch'
    return $?
  }
  [ "$(hh "$nuinui_exact_fix_repo")" = "$nuinui_exact_fix_prior_head" ] || {
    nuinui_exact_fix_preproof_failure 'resolved checkout HEAD changed before patch validation'
    return $?
  }
  nuinui_exact_fix_repo=$(CDPATH= cd -- "$nuinui_exact_fix_repo" && pwd -P) || return 1

  nuinui_exact_fix_sorted_files > "$nuinui_exact_fix_root/declared-sorted"
  nuinui_exact_fix_duplicate_count=$(uniq -d "$nuinui_exact_fix_root/declared-sorted" | wc -l | tr -d ' ')
  [ "$nuinui_exact_fix_duplicate_count" = 0 ] || {
    nuinui_exact_fix_preproof_failure 'declared file set contains duplicate paths'
    return $?
  }
  while IFS= read -r nuinui_exact_fix_path ||
    [ -n "$nuinui_exact_fix_path" ]; do
    [ -n "$nuinui_exact_fix_path" ] || continue
    nuinui_exact_fix_validate_path "$nuinui_exact_fix_path" || return 1
  done < "$nuinui_exact_fix_root/declared-sorted"
  git --literal-pathspecs -C "$nuinui_exact_fix_repo" ls-files --others --ignored --exclude-standard |
    sort > "$nuinui_exact_fix_root/ignored-before"

  nuinui_exact_fix_validate_patch_shape || return 1
  git --literal-pathspecs -C "$nuinui_exact_fix_repo" apply --check --index \
    --whitespace=nowarn "$nuinui_exact_fix_patch_snapshot" >/dev/null 2>&1 || {
      nuinui_exact_fix_preproof_failure 'patch is not exactly applicable to the resolved clean checkout'
      return $?
    }
  nuinui_exact_fix_temp_index=$nuinui_exact_fix_root/index
  GIT_INDEX_FILE="$nuinui_exact_fix_temp_index" git --literal-pathspecs -C "$nuinui_exact_fix_repo" read-tree "$nuinui_exact_fix_prior_head" || return 1
  GIT_INDEX_FILE="$nuinui_exact_fix_temp_index" git --literal-pathspecs -C "$nuinui_exact_fix_repo" apply \
    --cached --whitespace=nowarn "$nuinui_exact_fix_patch_snapshot" >/dev/null 2>&1 || return 1
  nuinui_exact_fix_changed_files_cached=$(GIT_INDEX_FILE="$nuinui_exact_fix_temp_index" git --literal-pathspecs -C "$nuinui_exact_fix_repo" diff --cached \
    --no-renames --name-status "$nuinui_exact_fix_prior_head" 2>/dev/null) || return 1
  printf '%s\n' "$nuinui_exact_fix_changed_files_cached" |
    awk -F '	' 'NF != 2 || $1 != "M" {bad=1} END {exit bad}' || {
      nuinui_exact_fix_preproof_failure 'patch changes something other than existing regular file contents'
      return $?
    }
  printf '%s\n' "$nuinui_exact_fix_changed_files_cached" | awk -F '	' '{print $2}' | sort > "$nuinui_exact_fix_root/changed-sorted"
  cmp -s "$nuinui_exact_fix_root/declared-sorted" "$nuinui_exact_fix_root/changed-sorted" || {
    nuinui_exact_fix_preproof_failure 'patch changed a file set different from the declared --file set'
    return $?
  }
  nuinui_exact_fix_temp_modes_are_textual || {
    nuinui_exact_fix_preproof_failure 'patch changes file mode or non-regular Git object state'
    return $?
  }
  nuinui_exact_fix_expected_diff=$nuinui_exact_fix_root/expected.diff
  GIT_INDEX_FILE="$nuinui_exact_fix_temp_index" nuinui_exact_fix_canonical_diff cached > "$nuinui_exact_fix_expected_diff" || return 1
  [ -s "$nuinui_exact_fix_expected_diff" ] || return 1

  git --literal-pathspecs -C "$nuinui_exact_fix_repo" apply --index \
    --whitespace=nowarn "$nuinui_exact_fix_patch_snapshot" >/dev/null 2>&1 || {
      nuinui_exact_fix_postmutation_failure 'patch application failed after applicability proof'
      return $?
    }
  nuinui_exact_fix_diff_is_expected cached || {
    nuinui_exact_fix_postmutation_failure 'staged diff is not the deterministic expected diff'
    return $?
  }
  nuinui_exact_fix_diff_is_expected full || {
    nuinui_exact_fix_postmutation_failure 'working-tree diff is not the deterministic expected diff'
    return $?
  }
  nuinui_exact_fix_untracked_is_empty || {
    nuinui_exact_fix_postmutation_failure 'patch application created an unexpected untracked file'
    return $?
  }
  nuinui_exact_fix_ignored_is_baseline || {
    nuinui_exact_fix_postmutation_failure 'patch application changed the ignored-file set'
    return $?
  }
  [ "$(nuinui_exact_fix_hash "$nuinui_exact_fix_verify")" = "$nuinui_exact_fix_verify_hash_before" ] || {
    nuinui_exact_fix_postmutation_failure 'verifier changed before execution'
    return $?
  }
  nuinui_exact_fix_verify_output=$nuinui_exact_fix_root/verifier-output
  nuinui_exact_fix_verify_rc=0
  (CDPATH= cd -- "$nuinui_exact_fix_repo" && "$nuinui_exact_fix_verifier_snapshot") > "$nuinui_exact_fix_verify_output" 2>&1 ||
    nuinui_exact_fix_verify_rc=$?
  if [ "$nuinui_exact_fix_verify_rc" != 0 ]; then
    cat "$nuinui_exact_fix_verify_output"
    nuinui_exact_fix_postmutation_failure 'verifier did not pass'
    return $?
  fi
  [ "$(nuinui_exact_fix_hash "$nuinui_exact_fix_verify")" = "$nuinui_exact_fix_verify_hash_before" ] || {
    nuinui_exact_fix_postmutation_failure 'verifier changed during execution'
    return $?
  }
  nuinui_exact_fix_diff_is_expected cached || {
    nuinui_exact_fix_postmutation_failure 'verifier changed the staged diff'
    return $?
  }
  nuinui_exact_fix_diff_is_expected full || {
    nuinui_exact_fix_postmutation_failure 'verifier changed the working-tree diff'
    return $?
  }
  nuinui_exact_fix_untracked_is_empty || {
    nuinui_exact_fix_postmutation_failure 'verifier created an unexpected untracked file'
    return $?
  }
  nuinui_exact_fix_ignored_is_baseline || {
    nuinui_exact_fix_postmutation_failure 'verifier changed the ignored-file set'
    return $?
  }
  nuinui_exact_fix_freshness || {
    nuinui_exact_fix_postmutation_failure 'freshness proof failed before commit'
    return $?
  }
  nuinui_exact_fix_diff_is_expected cached || {
    nuinui_exact_fix_postmutation_failure 'final staged diff changed before commit'
    return $?
  }
  while IFS= read -r nuinui_exact_fix_path ||
    [ -n "$nuinui_exact_fix_path" ]; do
    [ -n "$nuinui_exact_fix_path" ] || continue
    git --literal-pathspecs -C "$nuinui_exact_fix_repo" add -- "$nuinui_exact_fix_path" || {
      nuinui_exact_fix_postmutation_failure 'exact declared-file staging failed'
      return $?
    }
  done < "$nuinui_exact_fix_root/declared-sorted"
  nuinui_exact_fix_diff_is_expected cached || {
    nuinui_exact_fix_postmutation_failure 'staged diff changed after exact file staging'
    return $?
  }

  nuinui_exact_fix_commit_output=$nuinui_exact_fix_root/commit-output
  nuinui_exact_fix_commit_rc=0
  git -C "$nuinui_exact_fix_repo" commit -m "$nuinui_exact_fix_message" > "$nuinui_exact_fix_commit_output" 2>&1 ||
    nuinui_exact_fix_commit_rc=$?
  if [ "$nuinui_exact_fix_commit_rc" != 0 ]; then
    cat "$nuinui_exact_fix_commit_output"
    if [ "$(hh "$nuinui_exact_fix_repo" 2>/dev/null || true)" = "$nuinui_exact_fix_prior_head" ]; then
      nuinui_exact_fix_postmutation_failure 'ordinary commit failed before HEAD advanced'
      return $?
    fi
    printf 'ERROR: commit command failed after HEAD advanced; preserving local state\nmutation=yes\nclean=unknown\nlocal_commit_preserved=yes\n'
    return 1
  fi
  nuinui_exact_fix_new_head=$(hh "$nuinui_exact_fix_repo") || return 1
  nuinui_exact_fix_parent_count=$(git -C "$nuinui_exact_fix_repo" rev-list --parents -n 1 "$nuinui_exact_fix_new_head" | awk '{print NF}')
  [ "$nuinui_exact_fix_parent_count" = 2 ] || {
    printf 'ERROR: resulting commit is not one ordinary single-parent commit; preserving local state\nmutation=yes\nclean=unknown\nlocal_commit_preserved=yes\n'
    return 1
  }
  git --literal-pathspecs -C "$nuinui_exact_fix_repo" --no-pager diff \
    --binary --full-index --no-ext-diff --no-textconv --no-color \
    --src-prefix=a/ --dst-prefix=b/ "$nuinui_exact_fix_prior_head" "$nuinui_exact_fix_new_head" > \
    "$nuinui_exact_fix_root/commit.diff" || return 1
  cmp -s "$nuinui_exact_fix_expected_diff" "$nuinui_exact_fix_root/commit.diff" || {
    printf 'ERROR: resulting commit diff is not the deterministic expected diff; preserving local state\nmutation=yes\nclean=unknown\nlocal_commit_preserved=yes\n'
    return 1
  }
  nuinui_exact_fix_freshness "$nuinui_exact_fix_new_head" || {
    nuinui_exact_fix_push_failure 'post-commit freshness proof failed before push'
    return $?
  }
  nuinui_exact_fix_push_output=$nuinui_exact_fix_root/push-output
  nuinui_exact_fix_push_rc=0
  git -C "$nuinui_exact_fix_repo" push origin "$nuinui_exact_fix_branch" > "$nuinui_exact_fix_push_output" 2>&1 ||
    nuinui_exact_fix_push_rc=$?
  if [ "$nuinui_exact_fix_push_rc" != 0 ]; then
    cat "$nuinui_exact_fix_push_output"
    nuinui_exact_fix_push_failure 'push failed after verified exact-fix commit'
    return $?
  fi
  nuinui_exact_fix_remote_ref "refs/heads/$nuinui_exact_fix_branch" "$nuinui_exact_fix_new_head" || {
    cat "$nuinui_exact_fix_push_output"
    nuinui_exact_fix_push_failure 'pushed exact-fix branch read-back did not equal the new HEAD'
    return $?
  }
  [ -z "$(git --literal-pathspecs -C "$nuinui_exact_fix_repo" status --porcelain -uall)" ] &&
    nuinui_exact_fix_untracked_is_empty &&
    nuinui_exact_fix_ignored_is_baseline || {
      nuinui_exact_fix_push_failure 'checkout cleanliness could not be proven after push'
      return $?
    }
  printf 'EXACT-FIX VERIFIED\nlane=%s\nissue=%s\nclaim=%s\nbranch=%s\nbase=%s\nprior_topic=%s\nhead=%s\nexpected_main=%s\nverification=PASS\nfile_set=VERIFIED\nmutation=yes\nclean=yes\nmessage=%s\n' \
    "$nuinui_exact_fix_lane" "$nuinui_exact_fix_issue" "$nuinui_exact_fix_claim" \
    "$nuinui_exact_fix_branch" "$nuinui_exact_fix_base" "$nuinui_exact_fix_prior_head" \
    "$nuinui_exact_fix_new_head" "$nuinui_exact_fix_expected_main" "$nuinui_exact_fix_message"
  return 0
}
