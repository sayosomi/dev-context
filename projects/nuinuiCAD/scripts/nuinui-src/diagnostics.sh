doctor() {
  [ "$#" = 0 ] || [ "$#" = 1 ] || return 2
  [ "$#" = 0 ] || [ "$1" = --full ] || return 2
  nuinui_require_runtime_manifest || return 1
  nuinui_doctor_result=0
  lane_execution_preflight "$NUINUI_RUNTIME_MANIFEST" >/dev/null || nuinui_doctor_result=1
  if [ "${1:-}" = --full ]; then
    nuinui_doctor_human_lanes=$(lane_manifest_lanes_by_role "$NUINUI_RUNTIME_MANIFEST" human-test)
    while IFS= read -r nuinui_doctor_human_lane || [ -n "$nuinui_doctor_human_lane" ]; do
      [ -n "$nuinui_doctor_human_lane" ] || continue
      nuinui_doctor_human_path=$(lane_manifest_lane_path "$NUINUI_RUNTIME_MANIFEST" "$nuinui_doctor_human_lane") || nuinui_doctor_result=1
      [ -x "$EH" ] && "$EH" status "$nuinui_doctor_human_lane" || nuinui_doctor_result=1
    done <<EOF
$nuinui_doctor_human_lanes
EOF
  fi
  dc || nuinui_doctor_result=1
  [ "$nuinui_doctor_result" = 0 ]
}
cc() {
  [ -d "$C" ] || return 1
  nuinui_context_result=0
  find "$C" -type f -name '*.md' | while IFS= read -r nuinui_context_file; do
    grep -oE '\]\([^)]+\)' "$nuinui_context_file" 2>/dev/null |
      sed -E 's/^\]\(([^)#]+).*$/\1/' |
      while IFS= read -r nuinui_context_link; do
        case "$nuinui_context_link" in
          ''|'#'*|http://*|https://*|mailto:*) continue ;;
          /*) nuinui_context_target=$nuinui_context_link ;;
          *) nuinui_context_target=$(dirname "$nuinui_context_file")/$nuinui_context_link ;;
        esac
        [ -e "$nuinui_context_target" ] || exit 17
      done || nuinui_context_result=1
    grep -q 'ONLY-CHATGPT\.md' "$nuinui_context_file" && nuinui_context_result=1 || :
  done
  for nuinui_context_command in $K; do
    grep -q '`nuinui '"$nuinui_context_command" \
      "$C/projects/nuinuiCAD/LOCAL-TOOLS.md" || nuinui_context_result=1
  done
  echo "nuinui $V"
  if [ "$nuinui_context_result" = 0 ]; then echo 'CONTEXT CHECK PASS'; else echo 'CONTEXT CHECK BLOCKED'; return 1; fi
}

ta() {
  nuinui_require_runtime_manifest || return 1
  nuinui_transition_source_lane=$(lane_manifest_lanes_by_role "$NUINUI_RUNTIME_MANIFEST" implementation | while IFS= read -r lane; do
    [ "$(lane_manifest_lane_idle_policy "$NUINUI_RUNTIME_MANIFEST" "$lane")" = branch ] && printf '%s\n' "$lane"
  done)
  [ "$(printf '%s\n' "$nuinui_transition_source_lane" | grep -c . || true)" = 1 ] || return 1
  nuinui_transition_source=$(lr "$nuinui_transition_source_lane") || return 1
  echo 'TRANSITION AUDIT (read-only)'
  [ -f "$C/projects/nuinuiCAD/CODEX-ONLY-INTERIM.md" ] || return 1
  grep -q 'Status: \\*\\*Active\\*\\*' "$C/projects/nuinuiCAD/CODEX-ONLY-INTERIM.md" || return 1
  fm "$nuinui_transition_source" || return 1
  [ "$(bn "$nuinui_transition_source")" = codex/interim-sequential ] || return 1
  cn "$nuinui_transition_source" || return 1
  echo 'TRANSITION AUDIT PREPARED'
}
