#!/bin/sh

# nuinuiCAD adapter contract for the generic lane-execution preflight.  This
# source is intentionally not part of the current standalone generator input;
# #145 will assemble the generic runtime and this explicit project hook.

lane_execution_validate_issue_branch() {
  fixed_2plus1_profile_validate_issue_branch "$1" "$2"
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
  printf '  branch=%s\n' "${lane_execution_nuinui_human_branch:-DETACHED}"
  printf '  head=%s\n' "$lane_execution_nuinui_human_head"
  printf '  clean=%s\n' "$([ -z "$lane_execution_nuinui_human_dirty" ] && echo yes || echo no)"
  printf '  marker=%s\n' "$([ -e "$lane_execution_nuinui_human_marker" ] || [ -L "$lane_execution_nuinui_human_marker" ] && echo present || echo none)"
  printf '  session=%s\n' "$([ -e "$lane_execution_nuinui_human_session" ] || [ -L "$lane_execution_nuinui_human_session" ] && echo present || echo none)"
  printf '  state=%s\n' "$([ -z "$lane_execution_nuinui_human_dirty" ] && [ -z "$lane_execution_nuinui_human_branch" ] && echo FREE || echo BLOCKED)"
  [ -n "$lane_execution_nuinui_human_lane" ] &&
    [ -n "$lane_execution_nuinui_human_manifest" ] &&
    [ -n "$lane_execution_nuinui_human_head" ] &&
    [ -z "$lane_execution_nuinui_human_dirty" ] &&
    [ -z "$lane_execution_nuinui_human_branch" ]
}
