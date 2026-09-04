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
  command -v lane_execution_nuinui_human_test_classify >/dev/null 2>&1 || {
    echo '  state=BLOCKED reason=human-test-classifier-unavailable'
    return 1
  }
  lane_execution_nuinui_human_test_classify "$@"
}
