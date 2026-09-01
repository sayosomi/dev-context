T() {
  local R O M S E manifest base output claim
  R=$(CDPATH= cd -- "$(mktemp -d "${TMPDIR:-/tmp}/nui.XXXXXX")" && pwd -P) || return 1
  trap 'rm -rf "$R"' EXIT HUP INT TERM
  O=$R/sayosomi/nuinuiCAD.git
  M=$R/main
  S=$R/implementation
  E=$R/human
  manifest=$R/LANES.conf
  export NUINUI_SELFTEST=1
  export NUINUI_RUNTIME_MANIFEST=$manifest
  export NUINUI_SELFTEST_RESULT_REPO=$R/result
  export GIT_AUTHOR_NAME=a GIT_AUTHOR_EMAIL=a@b
  export GIT_COMMITTER_NAME=a GIT_COMMITTER_EMAIL=a@b
  mkdir -p "$R/sayosomi"
  git init -q --bare "$O"
  git init -q -b main "$M"
  git -C "$M" config user.name a
  git -C "$M" config user.email a@b
  printf '%s\n' a > "$M/a"
  git -C "$M" add a
  git -C "$M" commit -qm a
  git -C "$M" remote add origin "$O"
  git -C "$M" push -qu origin main
  git -C "$M" worktree add -q --detach "$S" origin/main
  git -C "$M" worktree add -q --detach "$E" origin/main
  git init -q "$R/result"
  printf '%s\n' \
    'version=1' \
    'repository=sayosomi/nuinuiCAD' \
    'default_branch=main' \
    '' \
    '[lane main-source]' \
    'role=implementation' \
    "path=$M" \
    'idle=branch' \
    '' \
    '[lane implementation]' \
    'role=implementation' \
    "path=$S" \
    'idle=detached' \
    '' \
    '[lane human]' \
    'role=human-test' \
    "path=$E" \
    'idle=detached' > "$manifest"
  if lane_execution_preflight "$manifest" >/dev/null 2>&1; then return 1; fi
  lane_execution_lane_init "$manifest" 'main-source' >/dev/null || return 1
  lane_execution_lane_init "$manifest" implementation >/dev/null || return 1
  base=$(om "$M") || return 1
  output=$(lane_execution_start "$manifest" implementation SAY-9 "$base" \
    codex/SAY-9-self-test) || return 1
  claim=$(printf '%s\n' "$output" | sed -n 's/^claim=//p')
  [ -n "$claim" ] || return 1
  lane_execution_release_command "$manifest" implementation "$base" "$claim" \
    >/dev/null || return 1
  echo 'SELFTEST PASS'
}

nuinui_self_test() {
  ( T )
  nuinui_selftest_rc=$?
  [ "$nuinui_selftest_rc" = 0 ] || return "$nuinui_selftest_rc"

  if [ -n "$NUINUI_SELFTEST_TEST_DIR" ]; then
    nuinui_selftest_dir=$NUINUI_SELFTEST_TEST_DIR
  else
    nuinui_selftest_dir=$D
    if [ ! -f "$nuinui_selftest_dir/test-nuinui-lifecycle" ] &&
      [ -f "$PWD/projects/nuinuiCAD/scripts/test-nuinui-lifecycle" ]; then
      nuinui_selftest_dir=$PWD/projects/nuinuiCAD/scripts
    fi
  fi
  [ -f "$nuinui_selftest_dir/test-nuinui-lifecycle" ] || {
    echo 'SELFTEST BLOCKED: lifecycle test is missing'
    return 1
  }
  [ -x "$nuinui_selftest_dir/test-nuinui-runtime" ] || {
    echo 'SELFTEST BLOCKED: runtime test is missing or not executable'
    return 1
  }
  [ -x "$nuinui_selftest_dir/test-nuinui-command-result" ] || {
    echo 'SELFTEST BLOCKED: command-result test is missing or not executable'
    return 1
  }
  [ -x "$nuinui_selftest_dir/test-nuinui-pr-auto-merge" ] || {
    echo 'SELFTEST BLOCKED: pr-auto-merge test is missing or not executable'
    return 1
  }
  [ -x "$nuinui_selftest_dir/test-nuinui-integration-clean" ] || {
    echo 'SELFTEST BLOCKED: integration-clean test is missing or not executable'
    return 1
  }
  [ -x "$nuinui_selftest_dir/test-nuinui-context-sync" ] || {
    echo 'SELFTEST BLOCKED: context-sync test is missing or not executable'
    return 1
  }
  [ -x "$nuinui_selftest_dir/test-nuinui-source-budget" ] || {
    echo 'SELFTEST BLOCKED: source-budget test is missing or not executable'
    return 1
  }
  /bin/sh "$nuinui_selftest_dir/test-nuinui-runtime" "$P" || return $?
  /bin/sh "$nuinui_selftest_dir/test-nuinui-command-result" "$P" || return $?
  /bin/sh "$nuinui_selftest_dir/test-nuinui-lifecycle" "$P" || return $?
  /bin/sh "$nuinui_selftest_dir/test-nuinui-pr-auto-merge" "$P" || return $?
  /bin/sh "$nuinui_selftest_dir/test-nuinui-integration-clean" "$P" || return $?
  /bin/sh "$nuinui_selftest_dir/test-nuinui-context-sync" "$P" || return $?
  /bin/sh "$nuinui_selftest_dir/test-nuinui-source-budget"
}
