#!/bin/sh

lane_execution_ops_context() {
  [ "$#" = 1 ] || return 2
  NUINUI_RUNTIME_MANIFEST=$1
  export NUINUI_RUNTIME_MANIFEST
  lane_manifest_validate "$NUINUI_RUNTIME_MANIFEST"
}
lane_execution_ops_repo() {
  lane_execution_ops_context "$1" || return 1
  il "$2" || return 2
  lane_execution_ops_repo_path=$(lr "$2") || return 1
  lane_execution_ops_repo_path=$(lane_execution__canonical_path "$lane_execution_ops_repo_path") || return 1
  printf '%s\n' "$lane_execution_ops_repo_path"
}
lane_execution_verify() {
  [ "$#" = 5 ] || return 2
  lane_execution_verify_manifest=$1
  lane_execution_verify_lane=$2
  lane_execution_verify_issue=$3
  lane_execution_verify_base=$4
  lane_execution_verify_branch=$5
  lane_execution_ops_context "$lane_execution_verify_manifest" || return 1
  il "$lane_execution_verify_lane" &&
    lane_execution_validate_work_id "$lane_execution_verify_issue" &&
    nuinui_ownership_valid_sha "$lane_execution_verify_base" &&
    lane_execution_validate_issue_branch "$lane_execution_verify_issue" \
      "$lane_execution_verify_branch" || return 2
  lane_execution_verify_repo=$(lr "$lane_execution_verify_lane") || return 1
  lane_execution_verify_repo=$(lane_execution__canonical_path "$lane_execution_verify_repo") || return 1
  gr "$lane_execution_verify_repo" &&
    ao "$lane_execution_verify_repo" "$(lane_manifest_repository_identity "$NUINUI_RUNTIME_MANIFEST")" &&
    cn "$lane_execution_verify_repo" || return 1
  lane_execution_verify_git_dir=$(gd "$lane_execution_verify_repo") || return 1
  nuinui_ownership_validate_initialization "$lane_execution_verify_git_dir/nuinui-implementation-v1" || return 1
  [ ! -e "$lane_execution_verify_git_dir/nuinui-implementation-slot" ] &&
    [ ! -e "$lane_execution_verify_git_dir/nuinui-implementation-lock" ] && nr "$lane_execution_verify_repo" || return 1
  fm "$lane_execution_verify_repo" || return 1
  [ "$(om "$lane_execution_verify_repo")" = "$lane_execution_verify_base" ] || return 1
  id "$lane_execution_verify_lane" "$lane_execution_verify_repo" "$lane_execution_verify_base" || return 1
  git -C "$lane_execution_verify_repo" show-ref --verify --quiet \
    "refs/heads/$lane_execution_verify_branch" && return 1
  [ -z "$(ab "$lane_execution_verify_repo" "$lane_execution_verify_branch")" ] || return 1
  lane_execution_verify_head=$(hh "$lane_execution_verify_repo") || return 1
  [ "$lane_execution_verify_head" = "$lane_execution_verify_base" ] ||
    an "$lane_execution_verify_repo" "$lane_execution_verify_head" "$lane_execution_verify_base" || return 1
  echo VERIFIED
}
lane_execution_lane_init() {
  [ "$#" = 2 ] || return 2
  lane_execution_init_manifest=$1
  lane_execution_init_lane=$2
  lane_execution_ops_context "$lane_execution_init_manifest" || return 1
  il "$lane_execution_init_lane" || return 2
  lane_execution_init_repo=$(lr "$lane_execution_init_lane") || return 1
  lane_execution_init_repo=$(lane_execution__canonical_path "$lane_execution_init_repo") || return 1
  gr "$lane_execution_init_repo" &&
    ao "$lane_execution_init_repo" "$(lane_manifest_repository_identity "$NUINUI_RUNTIME_MANIFEST")" || return 1
  lane_execution_init_git_dir=$(gd "$lane_execution_init_repo") || return 1
  lane_execution_init_marker=$lane_execution_init_git_dir/nuinui-implementation-v1
  if [ -e "$lane_execution_init_marker" ]; then
    nuinui_ownership_validate_initialization "$lane_execution_init_marker" && {
      echo 'ALREADY INITIALIZED'
      return 0
    }
    return 1
  fi
  [ ! -e "$lane_execution_init_git_dir/nuinui-implementation-slot" ] &&
    [ ! -e "$lane_execution_init_git_dir/nuinui-implementation-lock" ] &&
    nr "$lane_execution_init_repo" || return 1
  lane_execution_init_claim=$(gc)
  lo "$lane_execution_init_repo" init "$lane_execution_init_claim" - - - - || return 1
  fm "$lane_execution_init_repo" || return 1
  lane_execution_init_origin=$(om "$lane_execution_init_repo") || return 1
  id "$lane_execution_init_lane" "$lane_execution_init_repo" "$lane_execution_init_origin" || return 1
  wa "$lane_execution_init_marker" 'version=1\n' || return 1
  ul "$lane_execution_init_repo" "$lane_execution_init_claim" || return 1
  echo 'LANE INITIALIZED'
}

lane_execution_remote_topic() {
  lane_execution_remote_topic_result=$(git -C "$1" ls-remote --exit-code --heads origin \
    "refs/heads/$2" 2>/dev/null)
  lane_execution_remote_topic_rc=$?
  case "$lane_execution_remote_topic_rc" in
    0)
      lane_execution_remote_topic_head=$(printf '%s\n' "$lane_execution_remote_topic_result" | awk 'NR == 1 {print $1}')
      lane_execution_remote_topic_ref=$(printf '%s\n' "$lane_execution_remote_topic_result" | awk 'NR == 1 {print $2}')
      [ "$lane_execution_remote_topic_head" = "$3" ] &&
        [ "$lane_execution_remote_topic_ref" = "refs/heads/$2" ] &&
        [ -z "$(printf '%s\n' "$lane_execution_remote_topic_result" | awk 'NR > 1 {print}')" ] || return 1
      echo pushed
      ;;
    2) [ -z "$lane_execution_remote_topic_result" ] && echo absent || return 1 ;;
    *) return 1 ;;
  esac
}

lane_execution_resume_core() {
  [ "$#" = 7 ] || return 2
  lane_execution_resume_manifest=$1
  lane_execution_resume_lane=$2
  lane_execution_resume_issue=$3
  lane_execution_resume_base=$4
  lane_execution_resume_head=$5
  lane_execution_resume_branch=$6
  lane_execution_resume_claim=$7
  lane_execution_ops_context "$lane_execution_resume_manifest" || return 1
  il "$lane_execution_resume_lane" &&
    lane_execution_validate_work_id "$lane_execution_resume_issue" &&
    nuinui_ownership_valid_sha "$lane_execution_resume_base" &&
    nuinui_ownership_valid_sha "$lane_execution_resume_head" &&
    nuinui_ownership_valid_claim "$lane_execution_resume_claim" || return 2
  lane_execution_resume_repo=$(lr "$lane_execution_resume_lane") || return 1
  lane_execution_resume_slot=$(sp "$lane_execution_resume_repo")
  set -- $(nuinui_ownership_parse_slot "$lane_execution_resume_slot/state") || return 1
  [ "$1 $2 $3 $4" = "$lane_execution_resume_issue $lane_execution_resume_branch $lane_execution_resume_base $lane_execution_resume_claim" ] || return 1
  nr "$lane_execution_resume_repo" || return 1
  lane_execution_resume_current_branch=$(bn "$lane_execution_resume_repo")
  lane_execution_resume_current_head=$(hh "$lane_execution_resume_repo") || return 1
  lane_execution_resume_mode=$(lane_execution_remote_topic "$lane_execution_resume_repo" \
    "$lane_execution_resume_branch" "$lane_execution_resume_head") || return 1
  [ "$lane_execution_resume_mode" != absent ] || [ "$lane_execution_resume_head" = "$lane_execution_resume_base" ] || return 1
  fm "$lane_execution_resume_repo" || return 1
  lane_execution_resume_default_head=$(om "$lane_execution_resume_repo") || return 1
  if [ "$lane_execution_resume_current_branch" != "$lane_execution_resume_branch" ] ||
    [ "$lane_execution_resume_current_head" != "$lane_execution_resume_head" ]; then
    id "$lane_execution_resume_lane" "$lane_execution_resume_repo" \
      "$lane_execution_resume_default_head" || return 1
    [ "$lane_execution_resume_current_head" = "$lane_execution_resume_default_head" ] ||
      an "$lane_execution_resume_repo" "$lane_execution_resume_current_head" \
        "$lane_execution_resume_default_head" || return 1
    [ "$(lane_execution_remote_topic "$lane_execution_resume_repo" \
      "$lane_execution_resume_branch" "$lane_execution_resume_head")" = "$lane_execution_resume_mode" ] || return 1
    git -C "$lane_execution_resume_repo" switch "$lane_execution_resume_branch" >/dev/null || return 1
  fi
  [ "$(hh "$lane_execution_resume_repo")" = "$lane_execution_resume_head" ] &&
    cn "$lane_execution_resume_repo" || return 1
  echo 'IMPLEMENTATION RESUMED'
}

lane_execution_resume() {
  [ "$#" = 7 ] || return 2
  lane_execution_resume_manifest=$1
  lane_execution_resume_lane=$2
  lane_execution_resume_issue=$3
  lane_execution_resume_base=$4
  lane_execution_resume_head=$5
  lane_execution_resume_branch=$6
  lane_execution_resume_claim=$7
  lane_execution_ops_context "$lane_execution_resume_manifest" || return 1
  lane_execution_resume_repo=$(lr "$lane_execution_resume_lane") || return 1
  lo "$lane_execution_resume_repo" resume "$lane_execution_resume_claim" \
    "$lane_execution_resume_issue" "$lane_execution_resume_branch" \
    "$lane_execution_resume_base" "$lane_execution_resume_head" || return 1
  lane_execution_resume_output=$(lane_execution_resume_core "$@" 2>&1) || {
    return 1
  }
  ul "$lane_execution_resume_repo" "$lane_execution_resume_claim" || return 1
  printf '%s\n' "$lane_execution_resume_output"
  printf '  base=%s\n  claim=%s\n' "$lane_execution_resume_base" "$lane_execution_resume_claim"
}

lane_execution_release_restore_checkout() {
  [ "$#" = 5 ] || return 2
  lane_execution_release_lane=$1
  lane_execution_release_repo=$2
  lane_execution_release_topic=$3
  lane_execution_release_base=$4
  lane_execution_release_head=$5
  lane_execution_release_restore_mutated=no
  set -- $(nuinui_ownership_parse_slot "$(sp "$lane_execution_release_repo")/state") || return 1
  lane_execution_release_issue=$1
  lane_execution_release_claim=$4
  [ "$1 $2 $3 $4" = "$lane_execution_release_issue $lane_execution_release_topic $lane_execution_release_base $lane_execution_release_claim" ] || return 1
  set -- $(nuinui_ownership_parse_lock "$(kp "$lane_execution_release_repo")/state") || return 1
  [ "$1 $2 $3 $4 $5 $6" = "release $lane_execution_release_issue $lane_execution_release_topic $lane_execution_release_base $lane_execution_release_head $lane_execution_release_claim" ] || return 1
  nr "$lane_execution_release_repo" || return 1
  lane_execution_release_before_branch=$(bn "$lane_execution_release_repo")
  lane_execution_release_before_head=$(hh "$lane_execution_release_repo") || return 1
  if [ "$lane_execution_release_before_branch" = "$lane_execution_release_topic" ] &&
    [ "$lane_execution_release_before_head" = "$lane_execution_release_head" ]; then
    cn "$lane_execution_release_repo" && [ -z "$(bo "$lane_execution_release_repo" "$lane_execution_release_topic")" ] || return 1
    return 0
  fi
  cn "$lane_execution_release_repo" || return 1
  nuinui_ownership_valid_sha "$lane_execution_release_before_head" || return 1
  lane_execution_release_topic_head=$(git -C "$lane_execution_release_repo" rev-parse --verify --quiet \
    "refs/heads/$lane_execution_release_topic^{commit}" 2>/dev/null || true)
  lane_execution_release_mode=
  if [ -n "$lane_execution_release_before_branch" ] &&
    [ "$lane_execution_release_before_branch" != "$lane_execution_release_topic" ] &&
    [ "$lane_execution_release_before_head" = "$lane_execution_release_head" ]; then
    lane_execution_release_before_branch_head=$(git -C "$lane_execution_release_repo" rev-parse \
      "refs/heads/$lane_execution_release_before_branch^{commit}" 2>/dev/null || true)
    if [ "$lane_execution_release_before_branch_head" = "$lane_execution_release_head" ]; then
      [ "$lane_execution_release_topic_head" = "$lane_execution_release_head" ] &&
        lane_execution_release_mode=switch
      [ -z "$lane_execution_release_topic_head" ] &&
        [ "$lane_execution_release_before_branch" != "$(lane_execution_runtime_default_branch)" ] &&
        lane_execution_release_mode=rename
    fi
  fi
  if [ -z "$lane_execution_release_mode" ]; then
    id "$lane_execution_release_lane" "$lane_execution_release_repo" \
      "$lane_execution_release_before_head" || return 1
    [ "$lane_execution_release_topic_head" = "$lane_execution_release_head" ] || return 1
    lane_execution_release_mode=canonical
  fi
  fp "$lane_execution_release_repo" || return 1
  lane_execution_release_default_head=$(om "$lane_execution_release_repo") || return 1
  nuinui_ownership_valid_sha "$lane_execution_release_default_head" || return 1
  an "$lane_execution_release_repo" "$lane_execution_release_before_head" \
    "$lane_execution_release_default_head" || return 1
  an "$lane_execution_release_repo" "$lane_execution_release_head" \
    "$lane_execution_release_default_head" || return 1
  [ "$lane_execution_release_base" = "$lane_execution_release_head" ] ||
    an "$lane_execution_release_repo" "$lane_execution_release_base" \
      "$lane_execution_release_head" || return 1
  case "$lane_execution_release_mode" in
    switch|canonical) [ "$lane_execution_release_topic_head" = "$lane_execution_release_head" ] || return 1 ;;
    rename) [ -z "$lane_execution_release_topic_head" ] || return 1 ;;
    *) return 1 ;;
  esac
  [ -z "$(bo "$lane_execution_release_repo" "$lane_execution_release_topic")" ] || return 1
  lane_execution_release_remote_state=$(lane_execution_remote_topic "$lane_execution_release_repo" \
    "$lane_execution_release_topic" "$lane_execution_release_head") || return 1
  fp "$lane_execution_release_repo" || return 1
  [ "$(om "$lane_execution_release_repo")" = "$lane_execution_release_default_head" ] || return 1
  [ "$(lane_execution_remote_topic "$lane_execution_release_repo" \
    "$lane_execution_release_topic" "$lane_execution_release_head")" = "$lane_execution_release_remote_state" ] || return 1
  [ "$(bn "$lane_execution_release_repo")" = "$lane_execution_release_before_branch" ] &&
    [ "$(hh "$lane_execution_release_repo")" = "$lane_execution_release_before_head" ] || return 1
  case "$lane_execution_release_mode" in
    switch|rename)
      [ -n "$lane_execution_release_before_branch" ] &&
        [ "$lane_execution_release_before_branch" != "$lane_execution_release_topic" ] &&
        [ "$lane_execution_release_before_head" = "$lane_execution_release_head" ] || return 1
      ;;
    canonical) id "$lane_execution_release_lane" "$lane_execution_release_repo" \
      "$lane_execution_release_before_head" || return 1 ;;
  esac
  case "$lane_execution_release_mode" in
    switch)
      lane_execution_release_restore_mutated=potential
      git -C "$lane_execution_release_repo" switch "$lane_execution_release_topic" >/dev/null || return 1
      lane_execution_release_restore_mutated=yes
      ;;
    rename)
      lane_execution_release_restore_mutated=potential
      git -C "$lane_execution_release_repo" branch -m "$lane_execution_release_topic" >/dev/null || return 1
      lane_execution_release_restore_mutated=yes
      ;;
    canonical) return 0 ;;
    *) return 1 ;;
  esac
  [ "$(bn "$lane_execution_release_repo")" = "$lane_execution_release_topic" ] &&
    [ "$(hh "$lane_execution_release_repo")" = "$lane_execution_release_head" ] &&
    cn "$lane_execution_release_repo" || return 1
  nr "$lane_execution_release_repo"
}

lane_execution_release_delete_checkout() {
  [ "$#" = 3 ] || return 2
  lane_execution_release_delete_lane=$1
  lane_execution_release_delete_head=$2
  lane_execution_release_delete_topic=$3
  lane_execution_release_delete_repo=$(lr "$lane_execution_release_delete_lane") || return 1
  cn "$lane_execution_release_delete_repo" || return 1
  lane_execution_release_delete_branch=$(bn "$lane_execution_release_delete_repo")
  lane_execution_release_delete_current_head=$(hh "$lane_execution_release_delete_repo") || return 1
  lane_execution_release_delete_ref=
  [ "$lane_execution_release_delete_branch" = "$lane_execution_release_delete_topic" ] &&
    [ "$lane_execution_release_delete_current_head" = "$lane_execution_release_delete_head" ] &&
    lane_execution_release_delete_ref=$lane_execution_release_delete_topic
  lane_execution_release_delete_form=$(lane_manifest_lane_idle_policy "$NUINUI_RUNTIME_MANIFEST" \
    "$lane_execution_release_delete_lane") || return 1
  lane_execution_release_delete_default=$(lane_execution_runtime_default_branch)
  case "$lane_execution_release_delete_form" in
    branch)
      [ "$lane_execution_release_delete_branch" = "$lane_execution_release_delete_topic" ] ||
        [ "$lane_execution_release_delete_branch" = "$lane_execution_release_delete_default" ] || return 1
      git -C "$lane_execution_release_delete_repo" switch "$lane_execution_release_delete_default" >/dev/null &&
        git -C "$lane_execution_release_delete_repo" merge --ff-only \
          "origin/$lane_execution_release_delete_default" >/dev/null || return 1
      ;;
    detached)
      [ "$lane_execution_release_delete_branch" = "$lane_execution_release_delete_topic" ] ||
        [ -z "$lane_execution_release_delete_branch" ] || return 1
      [ "$lane_execution_release_delete_current_head" = "$lane_execution_release_delete_head" ] ||
        an "$lane_execution_release_delete_repo" "$lane_execution_release_delete_current_head" \
          "origin/$lane_execution_release_delete_default" || return 1
      sd "$lane_execution_release_delete_repo" "origin/$lane_execution_release_delete_default" || return 1
      ;;
    *) return 1 ;;
  esac
  if [ -n "$lane_execution_release_delete_ref" ]; then
    [ "$(git -C "$lane_execution_release_delete_repo" rev-parse \
      "refs/heads/$lane_execution_release_delete_ref^{commit}" 2>/dev/null)" = "$lane_execution_release_delete_head" ] &&
      [ -z "$(bo "$lane_execution_release_delete_repo" "$lane_execution_release_delete_ref")" ] &&
      git -C "$lane_execution_release_delete_repo" update-ref -d \
        "refs/heads/$lane_execution_release_delete_ref" "$lane_execution_release_delete_head" || return 1
  fi
  echo RELEASED
}

lane_execution_write_release_receipt() {
  [ "$#" = 7 ] || return 2
  lane_execution_receipt_repo=$1
  lane_execution_receipt_lane=$2
  lane_execution_receipt_issue=$3
  lane_execution_receipt_branch=$4
  lane_execution_receipt_base=$5
  lane_execution_receipt_head=$6
  lane_execution_receipt_claim=$7
  lane_execution_receipt_path=$(rr "$lane_execution_receipt_repo") || return 1
  wa "$lane_execution_receipt_path" \
    "version=1\nlane=$lane_execution_receipt_lane\nissue=$lane_execution_receipt_issue\nbranch=$lane_execution_receipt_branch\nbase=$lane_execution_receipt_base\ncheckpoint=$lane_execution_receipt_head\nclaim=$lane_execution_receipt_claim\n" || return 1
  set -- $(nuinui_ownership_parse_release_receipt "$lane_execution_receipt_path") || return 1
  [ "$1 $2 $3 $4 $5 $6" = "$lane_execution_receipt_lane $lane_execution_receipt_issue $lane_execution_receipt_branch $lane_execution_receipt_base $lane_execution_receipt_head $lane_execution_receipt_claim" ]
}

lane_execution_release_raw() {
  [ "$#" = 4 ] || return 2
  lane_execution_release_raw_manifest=$1
  lane_execution_release_raw_lane=$2
  lane_execution_release_raw_head=$3
  lane_execution_release_raw_claim=$4
  lane_execution_ops_context "$lane_execution_release_raw_manifest" || return 1
  il "$lane_execution_release_raw_lane" &&
    nuinui_ownership_valid_sha "$lane_execution_release_raw_head" &&
    nuinui_ownership_valid_claim "$lane_execution_release_raw_claim" || return 2
  lane_execution_release_raw_repo=$(lr "$lane_execution_release_raw_lane") || return 1
  lane_execution_release_raw_slot=$(sp "$lane_execution_release_raw_repo")
  set -- $(nuinui_ownership_parse_slot "$lane_execution_release_raw_slot/state") || return 1
  lane_execution_release_raw_issue=$1
  lane_execution_release_raw_topic=$2
  lane_execution_release_raw_base=$3
  [ "$4" = "$lane_execution_release_raw_claim" ] && [ ! -e "$(kp "$lane_execution_release_raw_repo")" ] && nr "$lane_execution_release_raw_repo" || return 1
  lo "$lane_execution_release_raw_repo" release "$lane_execution_release_raw_claim" \
    "$lane_execution_release_raw_issue" "$lane_execution_release_raw_topic" \
    "$lane_execution_release_raw_base" "$lane_execution_release_raw_head" || return 1
  lane_execution_release_restore_checkout "$lane_execution_release_raw_lane" \
    "$lane_execution_release_raw_repo" "$lane_execution_release_raw_topic" \
    "$lane_execution_release_raw_base" "$lane_execution_release_raw_head" || {
    [ "${lane_execution_release_restore_mutated:-no}" = no ] &&
      ul "$lane_execution_release_raw_repo" "$lane_execution_release_raw_claim" >/dev/null 2>&1 || true
    return 1
  }
  fp "$lane_execution_release_raw_repo" || return 1
  an "$lane_execution_release_raw_repo" "$lane_execution_release_raw_head" \
    "$(om "$lane_execution_release_raw_repo")" || return 1
  wa "$lane_execution_release_raw_slot/checkpoint" "$lane_execution_release_raw_head\n" || return 1
  lane_execution_release_raw_tombstone=$(rp "$lane_execution_release_raw_repo" \
    "$lane_execution_release_raw_claim")
  mv "$lane_execution_release_raw_slot" "$lane_execution_release_raw_tombstone" || return 1
  [ "${NUINUI_SELFTEST_CRASH_AT:-}" = release-after-rename ] && return 97
  lane_execution_release_delete_checkout "$lane_execution_release_raw_lane" \
    "$lane_execution_release_raw_head" "$lane_execution_release_raw_topic" >/dev/null || return 1
  lane_execution_write_release_receipt "$lane_execution_release_raw_repo" \
    "$lane_execution_release_raw_lane" "$lane_execution_release_raw_issue" \
    "$lane_execution_release_raw_topic" "$lane_execution_release_raw_base" \
    "$lane_execution_release_raw_head" "$lane_execution_release_raw_claim" || return 1
  rm "$lane_execution_release_raw_tombstone/checkpoint" \
    "$lane_execution_release_raw_tombstone/state" &&
    rmdir "$lane_execution_release_raw_tombstone" &&
    ul "$lane_execution_release_raw_repo" "$lane_execution_release_raw_claim" || return 1
  printf '  claim=%s\n' "$lane_execution_release_raw_claim"
}

lane_execution_release_command() {
  [ "$#" = 4 ] || return 2
  lane_execution_release_command_manifest=$1
  lane_execution_release_command_lane=$2
  lane_execution_release_command_head=$3
  lane_execution_release_command_claim=$4
  lane_execution_ops_context "$lane_execution_release_command_manifest" || return 1
  lane_execution_release_command_repo=$(lr "$lane_execution_release_command_lane") || {
    echo 'ERROR: lane must be an implementation lane'
    return 2
  }
  lane_execution_release_command_git_dir=$(gd "$lane_execution_release_command_repo") || return 1
  lane_execution_release_command_slot=$lane_execution_release_command_git_dir/nuinui-implementation-slot
  lane_execution_release_command_receipt=$(rr "$lane_execution_release_command_repo")
  if [ ! -e "$lane_execution_release_command_slot" ] && [ -f "$lane_execution_release_command_receipt" ] &&
    [ ! -e "$lane_execution_release_command_git_dir/nuinui-implementation-lock" ]; then
    set -- $(nuinui_ownership_parse_release_receipt "$lane_execution_release_command_receipt") || return 1
    [ "$1" = "$lane_execution_release_command_lane" ] && [ "$5" = "$lane_execution_release_command_head" ] &&
      [ "$6" = "$lane_execution_release_command_claim" ] || return 1
    fp "$lane_execution_release_command_repo" || return 1
    [ "$(hh "$lane_execution_release_command_repo")" = "$(om "$lane_execution_release_command_repo")" ] || return 1
    id "$lane_execution_release_command_lane" "$lane_execution_release_command_repo" \
      "$(om "$lane_execution_release_command_repo")" || return 1
    printf 'IMPLEMENTATION ALREADY RELEASED\nlane=%s\nissue=%s\nbase=%s\nsaved_checkpoint=%s\nreleased_claim=%s\nreleased_branch=%s\norigin_main=%s\nclean=yes\nmutation=no-op\nstate=FREE\n' \
      "$lane_execution_release_command_lane" "$2" "$4" "$5" "$6" "$3" "$(om "$lane_execution_release_command_repo")"
    return 0
  fi
  set -- $(nuinui_ownership_parse_slot "$lane_execution_release_command_slot/state") || return 1
  lane_execution_release_command_issue=$1
  lane_execution_release_command_topic=$2
  lane_execution_release_command_base=$3
  [ "$4" = "$lane_execution_release_command_claim" ] || return 1
  lane_execution_release_command_output=$(lane_execution_release_raw \
    "$lane_execution_release_command_manifest" "$lane_execution_release_command_lane" \
    "$lane_execution_release_command_head" "$lane_execution_release_command_claim" 2>&1) || {
    printf 'BLOCKED: release mutation completion could not be proven\nlane=%s\nissue=%s\nsaved_checkpoint=%s\nreleased_claim=%s\nreleased_branch=%s\nstate=BLOCKED\n' \
      "$lane_execution_release_command_lane" "$lane_execution_release_command_issue" \
      "$lane_execution_release_command_head" "$lane_execution_release_command_claim" \
      "$lane_execution_release_command_topic"
    [ -z "$lane_execution_release_command_output" ] || printf 'mutation_output:\n%s\n' "$lane_execution_release_command_output"
    return 1
  }
  lane_execution_release_command_origin=$(am "$lane_execution_release_command_repo") || return 1
  lane_execution_release_command_idle_branch=$(bn "$lane_execution_release_command_repo")
  lane_execution_release_command_idle_head=$(hh "$lane_execution_release_command_repo") || return 1
  id "$lane_execution_release_command_lane" "$lane_execution_release_command_repo" \
    "$lane_execution_release_command_origin" || return 1
  printf 'IMPLEMENTATION RELEASED\nlane=%s\nissue=%s\nsaved_checkpoint=%s\nreleased_claim=%s\nreleased_branch=%s\nidle_branch=%s\nidle_head=%s\norigin_main=%s\nclean=yes\nstate=FREE\n' \
    "$lane_execution_release_command_lane" "$lane_execution_release_command_issue" \
    "$lane_execution_release_command_head" "$lane_execution_release_command_claim" \
    "$lane_execution_release_command_topic" "${lane_execution_release_command_idle_branch:-DETACHED}" \
    "$lane_execution_release_command_idle_head" "$lane_execution_release_command_origin"
}

lane_execution_recover() {
  [ "$#" = 3 ] || return 2
  lane_execution_recover_manifest=$1
  lane_execution_recover_lane=$2
  lane_execution_recover_claim=$3
  lane_execution_ops_context "$lane_execution_recover_manifest" || return 1
  il "$lane_execution_recover_lane" && nuinui_ownership_valid_claim "$lane_execution_recover_claim" || return 2
  lane_execution_recover_repo=$(lr "$lane_execution_recover_lane") || return 1
  lane_execution_recover_lock=$(kp "$lane_execution_recover_repo")
  [ -f "$lane_execution_recover_lock/state" ] || return 1
  set -- $(nuinui_ownership_parse_lock "$lane_execution_recover_lock/state") || return 1
  lane_execution_recover_operation=$1
  lane_execution_recover_issue=$2
  lane_execution_recover_branch=$3
  lane_execution_recover_base=$4
  lane_execution_recover_head=$5
  [ "$6" = "$lane_execution_recover_claim" ] || return 1
  case "$lane_execution_recover_operation" in
    init)
      fm "$lane_execution_recover_repo" || return 1
      id "$lane_execution_recover_lane" "$lane_execution_recover_repo" "$(om "$lane_execution_recover_repo")" || return 1
      [ -e "$(ip "$lane_execution_recover_repo")" ] || wa "$(ip "$lane_execution_recover_repo")" 'version=1\n'
      nuinui_ownership_validate_initialization "$(ip "$lane_execution_recover_repo")" || return 1
      ul "$lane_execution_recover_repo" "$lane_execution_recover_claim" || return 1
      ;;
    start)
      set -- $(nuinui_ownership_parse_slot "$(sp "$lane_execution_recover_repo")/state") || return 1
      [ "$1 $2 $3 $4" = "$lane_execution_recover_issue $lane_execution_recover_branch $lane_execution_recover_base $lane_execution_recover_claim" ] || return 1
      lane_execution_recover_origin=$(om "$lane_execution_recover_repo") || return 1
      lane_execution_recover_idle=$(lane_manifest_lane_idle_policy \
        "$NUINUI_RUNTIME_MANIFEST" "$lane_execution_recover_lane") || return 1
      lane_execution_recover_current_branch=$(bn "$lane_execution_recover_repo")
      lane_execution_recover_current_head=$(hh "$lane_execution_recover_repo") || return 1
      if [ "$lane_execution_recover_current_branch" = "$lane_execution_recover_branch" ]; then
        [ "$lane_execution_recover_current_head" = "$lane_execution_recover_base" ] || return 1
        [ "$(git -C "$lane_execution_recover_repo" rev-parse \
          "refs/heads/$lane_execution_recover_branch^{commit}" 2>/dev/null)" = \
          "$lane_execution_recover_base" ] || return 1
        cn "$lane_execution_recover_repo" || return 1
      else
        [ "$lane_execution_recover_current_head" = "$lane_execution_recover_origin" ] || return 1
        lane_execution__idle_for_start "$lane_execution_recover_repo" \
          "$lane_execution_recover_lane" "$lane_execution_recover_idle" \
          "$(lane_execution_runtime_default_branch)" "$lane_execution_recover_origin" || return 1
        [ ! -e "$(bo "$lane_execution_recover_repo" \
          "$lane_execution_recover_branch")" ] || return 1
        [ -z "$(git -C "$lane_execution_recover_repo" show-ref --verify \
          --quiet "refs/heads/$lane_execution_recover_branch" && echo present || true)" ] || return 1
        git -C "$lane_execution_recover_repo" switch -c \
          "$lane_execution_recover_branch" "$lane_execution_recover_base" >/dev/null || return 1
      fi
      ul "$lane_execution_recover_repo" "$lane_execution_recover_claim" || return 1
      ;;
    resume) lane_execution_resume_core "$lane_execution_recover_manifest" \
      "$lane_execution_recover_lane" "$lane_execution_recover_issue" \
      "$lane_execution_recover_base" "$lane_execution_recover_head" \
      "$lane_execution_recover_branch" "$lane_execution_recover_claim" >/dev/null || return 1
      ul "$lane_execution_recover_repo" "$lane_execution_recover_claim" || return 1
      ;;
    release)
      lane_execution_recover_slot=$(sp "$lane_execution_recover_repo")
      lane_execution_recover_tombstone=$(rp "$lane_execution_recover_repo" \
        "$lane_execution_recover_claim")
      lane_execution_recover_releasing=$(rds "$lane_execution_recover_repo") || return 1
      [ "$(printf '%s\n' "$lane_execution_recover_releasing" | grep -c . || true)" -le 1 ] || return 1
      if [ -n "$lane_execution_recover_releasing" ]; then
        [ "$lane_execution_recover_releasing" = "$lane_execution_recover_tombstone" ] || return 1
        set -- $(nuinui_ownership_parse_releasing "$lane_execution_recover_releasing") || return 1
        [ "$1 $2 $3 $4 $5" = "$lane_execution_recover_issue $lane_execution_recover_branch $lane_execution_recover_base $lane_execution_recover_claim $lane_execution_recover_head" ] || return 1
      else
        [ -d "$lane_execution_recover_slot" ] || return 1
        set -- $(nuinui_ownership_parse_slot "$lane_execution_recover_slot/state") || return 1
        [ "$1 $2 $3 $4" = "$lane_execution_recover_issue $lane_execution_recover_branch $lane_execution_recover_base $lane_execution_recover_claim" ] || return 1
        [ ! -e "$lane_execution_recover_slot/checkpoint" ] ||
          [ "$(cat "$lane_execution_recover_slot/checkpoint")" = "$lane_execution_recover_head" ] || return 1
        wa "$lane_execution_recover_slot/checkpoint" "$lane_execution_recover_head\n" || return 1
        mv "$lane_execution_recover_slot" "$lane_execution_recover_tombstone" || return 1
      fi
      fp "$lane_execution_recover_repo" || return 1
      lane_execution_recover_default_head=$(om "$lane_execution_recover_repo") || return 1
      an "$lane_execution_recover_repo" "$lane_execution_recover_head" \
        "$lane_execution_recover_default_head" || return 1
      lane_execution_release_delete_checkout "$lane_execution_recover_lane" \
        "$lane_execution_recover_head" "$lane_execution_recover_branch" >/dev/null || return 1
      lane_execution_write_release_receipt "$lane_execution_recover_repo" \
        "$lane_execution_recover_lane" "$lane_execution_recover_issue" \
        "$lane_execution_recover_branch" "$lane_execution_recover_base" \
        "$lane_execution_recover_head" "$lane_execution_recover_claim" || return 1
      rm "$lane_execution_recover_tombstone/checkpoint" \
        "$lane_execution_recover_tombstone/state" &&
        rmdir "$lane_execution_recover_tombstone" || return 1
      ul "$lane_execution_recover_repo" "$lane_execution_recover_claim" || return 1
      ;;
    *) return 1 ;;
  esac
  printf 'RECOVERED operation=%s\n' "$lane_execution_recover_operation"
}

lane_execution_cli_implementation_operation() {
  lane_execution_cli_operation=$1
  lane_execution_cli_manifest=$2
  lane_execution_cli_lane=$3
  shift 3
  case "$lane_execution_cli_operation" in
    verify) lane_execution_verify "$lane_execution_cli_manifest" "$lane_execution_cli_lane" "$@" ;;
    lane-init) lane_execution_lane_init "$lane_execution_cli_manifest" "$lane_execution_cli_lane" ;;
    resume) lane_execution_resume "$lane_execution_cli_manifest" "$lane_execution_cli_lane" "$@" ;;
    release) lane_execution_release_command "$lane_execution_cli_manifest" "$lane_execution_cli_lane" "$@" ;;
    recover) lane_execution_recover "$lane_execution_cli_manifest" "$lane_execution_cli_lane" "$@" ;;
    integrate-clean) NUINUI_RUNTIME_MANIFEST=$lane_execution_cli_manifest integration_clean_command \
      "$lane_execution_cli_lane" "$@" ;;
    *) echo "BLOCKED: unsupported implementation operation: $lane_execution_cli_operation"; return 2 ;;
  esac
}
