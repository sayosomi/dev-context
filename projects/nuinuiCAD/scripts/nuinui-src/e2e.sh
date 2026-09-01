# nuinuiCAD compatibility adapters for the generic Human-test runtime.

e2e_path_exists() { [ -e "$1" ] || [ -L "$1" ]; }
e2e_regular_file() { [ -f "$1" ] && [ ! -L "$1" ]; }

es() {
  [ "$#" = 3 ] || return 2
  lane_execution_human_test_start "$NUINUI_RUNTIME_MANIFEST" "$1" "$2" "$3" \
    'E2E STARTED' 'E2E ALREADY STARTED'
}
el() {
  [ "$#" = 3 ] || return 2
  lane_execution_human_test_local_main_policy "$NUINUI_RUNTIME_MANIFEST" \
    "$1" "$2" "$3" || return 1
  es "$@"
}

ee() {
  [ "$#" = 3 ] || return 2
  lane_execution_human_test_release "$NUINUI_RUNTIME_MANIFEST" "$1" "$2" "$3" \
    'E2E RELEASED' 'E2E ALREADY RELEASED'
}
