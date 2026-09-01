#!/bin/sh

# Fixed 2+1 profile contract.
#
# A project profile is assembled before this fragment.  The contract keeps
# the shared implementation independent from project names, paths, and
# work-management syntax.  Optional hooks are deliberately no-ops unless a
# profile or project adapter supplies them.

fixed_2plus1_profile_contract_ready() {
  local function_name lane_a lane_b human_lane default_branch lane path form

  for function_name in \
    fixed_2plus1_profile_implementation_lane_a_name \
    fixed_2plus1_profile_implementation_lane_b_name \
    fixed_2plus1_profile_human_test_lane_name \
    fixed_2plus1_profile_is_implementation_lane \
    fixed_2plus1_profile_lane_path \
    fixed_2plus1_profile_repository_identity \
    fixed_2plus1_profile_default_branch \
    fixed_2plus1_profile_idle_checkout_form \
    fixed_2plus1_profile_human_test_marker_path \
    fixed_2plus1_profile_human_test_session_path \
    fixed_2plus1_profile_human_test_receipt_path \
    fixed_2plus1_profile_valid_work_id \
    fixed_2plus1_profile_work_id_from_branch \
    fixed_2plus1_profile_validate_issue_branch; do
    command -v "$function_name" >/dev/null 2>&1 || return 1
  done

  lane_a=$(fixed_2plus1_profile_implementation_lane_a_name) || return 1
  lane_b=$(fixed_2plus1_profile_implementation_lane_b_name) || return 1
  human_lane=$(fixed_2plus1_profile_human_test_lane_name) || return 1
  default_branch=$(fixed_2plus1_profile_default_branch) || return 1
  [ -n "$lane_a" ] && [ -n "$lane_b" ] && [ -n "$human_lane" ] || return 1
  [ "$lane_a" != "$lane_b" ] && [ "$lane_a" != "$human_lane" ] &&
    [ "$lane_b" != "$human_lane" ] || return 1
  [ -n "$(fixed_2plus1_profile_repository_identity)" ] || return 1
  fixed_2plus1_profile_valid_branch_name "$default_branch" || return 1

  for lane in "$lane_a" "$lane_b" "$human_lane"; do
    path=$(fixed_2plus1_profile_lane_path "$lane") || return 1
    case "$path" in /*) ;; *) return 1 ;; esac
  done
  for lane in "$lane_a" "$lane_b"; do
    form=$(fixed_2plus1_profile_idle_checkout_form "$lane") || return 1
    case "$form" in branch|detached) ;; *) return 1 ;; esac
  done
}

fixed_2plus1_profile_valid_branch_name() {
  git check-ref-format --branch "$1" >/dev/null 2>&1
}

if ! command -v fixed_2plus1_profile_inventory_guard >/dev/null 2>&1; then
  fixed_2plus1_profile_inventory_guard() { return 0; }
fi
if ! command -v fixed_2plus1_profile_human_test_preflight >/dev/null 2>&1; then
  fixed_2plus1_profile_human_test_preflight() { return 0; }
fi
if ! command -v fixed_2plus1_profile_human_test_start_guard >/dev/null 2>&1; then
  fixed_2plus1_profile_human_test_start_guard() { return 0; }
fi
if ! command -v fixed_2plus1_profile_human_test_release_guard >/dev/null 2>&1; then
  fixed_2plus1_profile_human_test_release_guard() { return 0; }
fi
if ! command -v fixed_2plus1_profile_after_begin_start >/dev/null 2>&1; then
  fixed_2plus1_profile_after_begin_start() { return 0; }
fi
if ! command -v fixed_2plus1_profile_origin_matches >/dev/null 2>&1; then
  fixed_2plus1_profile_origin_matches() {
    [ -z "$2" ] || git -C "$1" remote get-url origin 2>/dev/null | grep -Fq "$2"
  }
fi
