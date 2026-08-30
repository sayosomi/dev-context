# Public command membership, usage, validation, routing, and dispatch.
# K is consumed by both usage and the existing context-check implementation.
K='preflight verify lane-init begin start resume release recover pr-auto-merge e2e-start e2e-start-local-main e2e-release context-sync doctor transition-audit context-check self-test'

nuinui_usage() {
  echo "nuinui $V"
  echo "Commands: $K"
}

nuinui_run_public() {
  nuinui_public_name=$1
  shift
  nuinui_public_output=
  nuinui_public_rc=0
  nuinui_public_output=$( "$@" 2>&1 ) || nuinui_public_rc=$?
  if [ -n "$nuinui_public_output" ]; then
    printf '%s\n' "$nuinui_public_output"
  else
    printf 'ERROR: public command %s failed without a diagnostic\n' "$nuinui_public_name"
  fi
  return "$nuinui_public_rc"
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
  [ -x "$nuinui_selftest_dir/test-nuinui-pr-auto-merge" ] || {
    echo 'SELFTEST BLOCKED: pr-auto-merge test is missing or not executable'
    return 1
  }
  /bin/sh "$nuinui_selftest_dir/test-nuinui-lifecycle" "$P" || return $?
  /bin/sh "$nuinui_selftest_dir/test-nuinui-pr-auto-merge" "$P"
}

case "$1" in
  version)
    [ "$#" = 1 ] || { echo 'Usage: nuinui version'; exit 2; }
    echo "$V"
    exit 0
    ;;
  --help|-h|help|'')
    nuinui_usage
    [ -n "$1" ] && exit 0 || exit 2
    ;;
  preflight)
    [ "$#" = 1 ] || { echo 'Usage: nuinui preflight'; exit 2; }
    nuinui_run_public preflight pf
    exit $?
    ;;
  verify)
    [ "$#" = 5 ] || { echo 'Usage: nuinui verify <main|sub> <SAY-123> <expected-base-sha> <branch>'; exit 2; }
    nuinui_run_public verify vr "$2" "$3" "$4" "$5"
    exit $?
    ;;
  lane-init)
    [ "$#" = 2 ] || { echo 'Usage: nuinui lane-init <main|sub>'; exit 2; }
    nuinui_run_public lane-init li "$2"
    exit $?
    ;;
  begin)
    [ "$#" = 6 ] || { echo 'Usage: nuinui begin <main|sub> <SAY-123> <expected-base-sha> <branch> <FREE|SAY-123>'; exit 2; }
    nuinui_run_public begin lifecycle_begin "$2" "$3" "$4" "$5" "$6"
    exit $?
    ;;
  start)
    [ "$#" = 5 ] || { echo 'Usage: nuinui start <main|sub> <SAY-123> <expected-base-sha> <branch>'; exit 2; }
    nuinui_run_public start lifecycle_start_command "$2" "$3" "$4" "$5"
    exit $?
    ;;
  resume)
    [ "$#" = 7 ] || { echo 'Usage: nuinui resume <main|sub> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>'; exit 2; }
    nuinui_run_public resume lifecycle_resume_command "$2" "$3" "$4" "$5" "$6" "$7"
    exit $?
    ;;
  release)
    [ "$#" = 4 ] || { echo 'Usage: nuinui release <main|sub> <merged-checkpoint-sha> <expected-claim>'; exit 2; }
    nuinui_run_public release lifecycle_release_command "$2" "$3" "$4"
    exit $?
    ;;
  recover)
    [ "$#" = 3 ] || { echo 'Usage: nuinui recover <main|sub> <expected-claim>'; exit 2; }
    nuinui_run_public recover rc "$2" "$3"
    exit $?
    ;;
  pr-auto-merge)
    [ "$#" = 4 ] || { echo 'Usage: nuinui pr-auto-merge <pr-number> <expected-head-sha> <expected-main-sha>'; exit 2; }
    nuinui_run_public pr-auto-merge pam "$2" "$3" "$4"
    exit $?
    ;;
  e2e-start)
    [ "$#" = 3 ] || { echo 'Usage: nuinui e2e-start <SAY-123> <tested-ref>'; exit 2; }
    nuinui_run_public e2e-start es "$2" "$3"
    exit $?
    ;;
  e2e-start-local-main)
    [ "$#" = 3 ] || { echo 'Usage: nuinui e2e-start-local-main <SAY-123> <tested-ref>'; exit 2; }
    nuinui_run_public e2e-start-local-main el "$2" "$3"
    exit $?
    ;;
  e2e-release)
    [ "$#" = 1 ] || { echo 'Usage: nuinui e2e-release'; exit 2; }
    nuinui_run_public e2e-release ee
    exit $?
    ;;
  context-sync)
    [ "$#" = 1 ] || { echo 'Usage: nuinui context-sync'; exit 2; }
    nuinui_run_public context-sync sy
    exit $?
    ;;
  doctor)
    if [ "$#" = 2 ]; then
      [ "$2" = --full ] || { echo 'Usage: nuinui doctor [--full]'; exit 2; }
      shift
    elif [ "$#" != 1 ]; then
      echo 'Usage: nuinui doctor [--full]'
      exit 2
    fi
    nuinui_run_public doctor doctor "$@"
    exit $?
    ;;
  transition-audit)
    [ "$#" = 1 ] || { echo 'Usage: nuinui transition-audit'; exit 2; }
    nuinui_run_public transition-audit ta
    exit $?
    ;;
  context-check)
    [ "$#" = 1 ] || { nuinui_usage; exit 2; }
    nuinui_run_public context-check cc
    exit $?
    ;;
  self-test)
    [ "$#" = 1 ] || { nuinui_usage; exit 2; }
    nuinui_run_public self-test nuinui_self_test
    exit $?
    ;;
  *)
    nuinui_usage
    exit 2
    ;;
esac
