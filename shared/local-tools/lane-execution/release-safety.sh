#!/bin/sh

# Generic duplicate-release proof. This is deliberately read-only and retains
# the v1 release safety envelope independent of the declared lane topology.
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
  set -- $(nuinui_ownership_parse_slot "$(sp "$lane_execution_release_repo")/state") || return 1
  [ "$1 $2 $3 $4" = "$lane_execution_release_issue $lane_execution_release_topic $lane_execution_release_base $lane_execution_release_claim" ] || return 1
  set -- $(nuinui_ownership_parse_lock "$(kp "$lane_execution_release_repo")/state") || return 1
  [ "$1 $2 $3 $4 $5 $6" = "release $lane_execution_release_issue $lane_execution_release_topic $lane_execution_release_base $lane_execution_release_head $lane_execution_release_claim" ] || return 1
  nr "$lane_execution_release_repo"
}

lane_execution_release_duplicate_proof() {
  [ "$#" = 4 ] || return 2
  lane_execution_duplicate_manifest=$1
  lane_execution_duplicate_lane=$2
  lane_execution_duplicate_head=$3
  lane_execution_duplicate_claim=$4
  lane_execution_ops_context "$lane_execution_duplicate_manifest" || return 1
  il "$lane_execution_duplicate_lane" || return 1
  nuinui_ownership_valid_sha "$lane_execution_duplicate_head" || return 1
  nuinui_ownership_valid_claim "$lane_execution_duplicate_claim" || return 1
  lane_execution_duplicate_repo=$(lr "$lane_execution_duplicate_lane") || return 1
  lane_execution_duplicate_git_dir=$(gd "$lane_execution_duplicate_repo") || return 1
  lane_execution_duplicate_slot=$lane_execution_duplicate_git_dir/nuinui-implementation-slot
  lane_execution_duplicate_lock=$lane_execution_duplicate_git_dir/nuinui-implementation-lock
  lane_execution_duplicate_marker=$lane_execution_duplicate_git_dir/nuinui-implementation-v1
  lane_execution_duplicate_receipt=$(rr "$lane_execution_duplicate_repo") || return 1
  [ ! -e "$lane_execution_duplicate_slot" ] && [ ! -L "$lane_execution_duplicate_slot" ] || return 1
  [ ! -e "$lane_execution_duplicate_lock" ] && [ ! -L "$lane_execution_duplicate_lock" ] || return 1
  lane_execution_duplicate_tombstones=$(rds "$lane_execution_duplicate_repo") || return 1
  [ -z "$lane_execution_duplicate_tombstones" ] || return 1
  [ -f "$lane_execution_duplicate_marker" ] && [ ! -L "$lane_execution_duplicate_marker" ] || return 1
  nuinui_ownership_validate_initialization "$lane_execution_duplicate_marker" || return 1
  [ -f "$lane_execution_duplicate_receipt" ] && [ ! -L "$lane_execution_duplicate_receipt" ] || return 1
  set -- $(nuinui_ownership_parse_release_receipt "$lane_execution_duplicate_receipt") || return 1
  [ "$#" = 6 ] || return 1
  lane_execution_duplicate_receipt_lane=$1
  lane_execution_duplicate_receipt_issue=$2
  lane_execution_duplicate_receipt_branch=$3
  lane_execution_duplicate_receipt_base=$4
  lane_execution_duplicate_receipt_checkpoint=$5
  lane_execution_duplicate_receipt_claim=$6
  [ "$lane_execution_duplicate_receipt_lane" = "$lane_execution_duplicate_lane" ] &&
    [ "$lane_execution_duplicate_receipt_checkpoint" = "$lane_execution_duplicate_head" ] &&
    [ "$lane_execution_duplicate_receipt_claim" = "$lane_execution_duplicate_claim" ] || return 1
  an "$lane_execution_duplicate_repo" "$lane_execution_duplicate_receipt_base" \
    "$lane_execution_duplicate_receipt_checkpoint" || return 1
  cn "$lane_execution_duplicate_repo" || return 1
  lane_execution_duplicate_current_head=$(hh "$lane_execution_duplicate_repo") || return 1
  id "$lane_execution_duplicate_lane" "$lane_execution_duplicate_repo" \
    "$lane_execution_duplicate_current_head" || return 1
  lane_execution_duplicate_authoritative=$(am "$lane_execution_duplicate_repo") || return 1
  nuinui_ownership_valid_sha "$lane_execution_duplicate_authoritative" || return 1
  [ "$lane_execution_duplicate_current_head" = "$lane_execution_duplicate_authoritative" ] || return 1
  an "$lane_execution_duplicate_repo" "$lane_execution_duplicate_receipt_checkpoint" \
    "$lane_execution_duplicate_authoritative" || return 1
  lane_execution_duplicate_proven=yes
}
