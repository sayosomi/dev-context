T(){ local R O a f o c h;R=$(mktemp -d "${TMPDIR:-/tmp}/nui.XXXXXX")||return 1;trap 'rm -rf "$R"' EXIT;O=$R/o;M=$R/m;S=$R/s;E=$R/e;RT=;export GIT_AUTHOR_NAME=a GIT_AUTHOR_EMAIL=a@b GIT_COMMITTER_NAME=a GIT_COMMITTER_EMAIL=a@b;git init -q --bare "$O";git init -q -b main "$M";echo a>$M/a;git -C "$M" add a;git -C "$M" commit -qm a;git -C "$M" remote add origin "$O";git -C "$M" push -qu origin main;git -C "$M" worktree add -q --detach "$S" origin/main;git -C "$M" worktree add -q --detach "$E" origin/main;a=$(om "$M");pf >/dev/null 2>&1&&return 1;li main >/dev/null&&li sub >/dev/null||return 1;f=$R/x;printf 'version=2\n'>$f;nuinui_ownership_validate_initialization "$f"&&return 1;o=$(st main SAY-9 "$a" x/say-9-a)||return 1;c=$(echo "$o"|sed -n 's/^  claim=//p');echo b>>$M/a;git -C "$M" add a;git -C "$M" commit -qm b;h=$(hh "$M");rl main "$h" "$c" >/dev/null 2>&1&&return 1;git -C "$M" push -q origin HEAD:main;rl main "$h" "$c" >/dev/null||return 1;echo 'SELFTEST PASS';}
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
  [ -x "$nuinui_selftest_dir/test-nuinui-pr-auto-merge" ] || {
    echo 'SELFTEST BLOCKED: pr-auto-merge test is missing or not executable'
    return 1
  }
  [ -x "$nuinui_selftest_dir/test-nuinui-context-sync" ] || {
    echo 'SELFTEST BLOCKED: context-sync test is missing or not executable'
    return 1
  }
  /bin/sh "$nuinui_selftest_dir/test-nuinui-lifecycle" "$P" || return $?
  /bin/sh "$nuinui_selftest_dir/test-nuinui-pr-auto-merge" "$P" || return $?
  /bin/sh "$nuinui_selftest_dir/test-nuinui-context-sync" "$P"
}
