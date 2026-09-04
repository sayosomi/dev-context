#!/bin/sh

# nuinuiCAD executable policy for the generic lane-execution runtime.  Lane
# topology remains in LANES.conf; this file contains only project semantics.

lane_execution_validate_issue_branch() {
  lane_execution_validate_work_id "$1" || return 1
  git check-ref-format --branch "$2" >/dev/null 2>&1 || return 1
  [ "$(nuinui_ownership_issue_from_branch "$2")" = "$1" ]
}

lane_execution_validate_work_id() {
  printf '%s\n' "$1" | grep -Eq '^SAY-[0-9]+$'
}

lane_execution_human_test_preflight() {
  lane_execution_nuinui_human_lane=$1
  lane_execution_nuinui_human_repo=$2
  lane_execution_nuinui_human_manifest=$3
  lane_execution_nuinui_human_git_dir=$(git -C "$lane_execution_nuinui_human_repo" rev-parse --absolute-git-dir 2>/dev/null) || return 1
  lane_execution_nuinui_human_branch=$(git -C "$lane_execution_nuinui_human_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  lane_execution_nuinui_human_head=$(git -C "$lane_execution_nuinui_human_repo" rev-parse HEAD 2>/dev/null || true)
  lane_execution_nuinui_human_dirty=$(git -C "$lane_execution_nuinui_human_repo" status --porcelain 2>/dev/null)
  lane_execution_nuinui_human_marker=$lane_execution_nuinui_human_git_dir/nuinui-slot
  lane_execution_nuinui_human_session=$lane_execution_nuinui_human_git_dir/nuinui-e2e-session
  lane_execution_nuinui_human_session_present=0
  [ -e "$lane_execution_nuinui_human_session" ] || [ -L "$lane_execution_nuinui_human_session" ] &&
    lane_execution_nuinui_human_session_present=1
  printf '  branch=%s\n' "${lane_execution_nuinui_human_branch:-DETACHED}"
  printf '  head=%s\n' "$lane_execution_nuinui_human_head"
  printf '  clean=%s\n' "$([ -z "$lane_execution_nuinui_human_dirty" ] && echo yes || echo no)"
  printf '  marker=%s\n' "$([ -e "$lane_execution_nuinui_human_marker" ] || [ -L "$lane_execution_nuinui_human_marker" ] && echo present || echo none)"
  printf '  session=%s\n' "$([ -e "$lane_execution_nuinui_human_session" ] || [ -L "$lane_execution_nuinui_human_session" ] && echo present || echo none)"
  printf '  state=%s\n' "$([ -z "$lane_execution_nuinui_human_dirty" ] &&
    [ -z "$lane_execution_nuinui_human_branch" ] &&
    [ "$lane_execution_nuinui_human_session_present" = 0 ] && echo FREE || echo BLOCKED)"
  [ -n "$lane_execution_nuinui_human_lane" ] &&
    [ -n "$lane_execution_nuinui_human_manifest" ] &&
    [ -n "$lane_execution_nuinui_human_head" ] &&
    [ -z "$lane_execution_nuinui_human_dirty" ] &&
    [ -z "$lane_execution_nuinui_human_branch" ] &&
    [ "$lane_execution_nuinui_human_session_present" = 0 ]
}
