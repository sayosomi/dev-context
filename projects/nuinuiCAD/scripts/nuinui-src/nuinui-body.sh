# nuinuiCAD-specific runtime shell helpers for the generated standalone CLI.
# The product manifest is resolved lazily so version/help/context commands do
# not depend on a healthy lane topology. standalone-context.sh owns the
# structural helper/project relationship.

P=$0
case "$P" in
  */*) ;;
  *) P=$(command -v -- "$P" 2>/dev/null || true) ;;
esac
[ -n "$P" ] && case "$P" in /*) ;; *) P=$(CDPATH= cd -- "$(dirname -- "$P")" 2>/dev/null && pwd -P)/$(basename -- "$P") || true ;; esac
D=$(CDPATH= cd -- "$(dirname -- "$P")" 2>/dev/null && pwd -P || printf '')
EH=${NUINUI_E2E_STATUS_HELPER:-$D/nuinui-e2e-prepare}

if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
  C=${NUINUI_DEV_CONTEXT_WT:-$D}
  CD=${NUINUI_DEV_CONTEXT_DEV_WT:-$D}
  CT=${NUINUI_SELFTEST_EXPECTED_ORIGIN:-sayosomi/dev-context}
else
  C=/Users/yosomi/Code/dev-context
  CD=/Users/yosomi/Code/dev-context-dev
  CT=sayosomi/dev-context
fi

nuinui_require_runtime_manifest() {
  NUINUI_RUNTIME_MANIFEST=$(lane_standalone_context_manifest "$P" \
    "${NUINUI_SELFTEST:-0}" "${NUINUI_SELFTEST_MANIFEST:-}") || return 1
  export NUINUI_RUNTIME_MANIFEST
  lane_manifest_validate "$NUINUI_RUNTIME_MANIFEST" || {
    echo "BLOCKED: authoritative project lane manifest is invalid: $NUINUI_RUNTIME_MANIFEST" >&2
    return 1
  }
}

nuinui_validate_forensic_worktree() {
  [ "$#" = 1 ] || return 2
  nuinui_forensic_reason=
  case "$1" in /*) ;; *) nuinui_forensic_reason=non-absolute-path; return 1 ;; esac
  [ -d "$1" ] || { nuinui_forensic_reason=missing-or-not-directory; return 1; }
  nuinui_forensic_physical=$(CDPATH= cd -- "$1" && pwd -P) || {
    nuinui_forensic_reason=non-canonical-path; return 1;
  }
  [ "$nuinui_forensic_physical" = "$1" ] || {
    nuinui_forensic_reason=non-canonical-path; return 1;
  }
  nuinui_forensic_anchor=
  nuinui_forensic_expected=
  while IFS= read -r nuinui_forensic_lane || [ -n "$nuinui_forensic_lane" ]; do
    [ -n "$nuinui_forensic_lane" ] || continue
    nuinui_forensic_path=$(lane_manifest_lane_path "$NUINUI_RUNTIME_MANIFEST" "$nuinui_forensic_lane") || return 1
    nuinui_forensic_path=$(lane_execution__canonical_path "$nuinui_forensic_path") || return 1
    [ -n "$nuinui_forensic_anchor" ] || nuinui_forensic_anchor=$nuinui_forensic_path
    nuinui_forensic_expected=$nuinui_forensic_expected$nuinui_forensic_path\n
    [ "$nuinui_forensic_path" != "$nuinui_forensic_physical" ] || {
      nuinui_forensic_reason=declared-lane-path; return 1
    }
  done <<EOF
$(lane_manifest_all_lanes "$NUINUI_RUNTIME_MANIFEST")
EOF
  gr "$1" || { nuinui_forensic_reason=not-registered-worktree; return 1; }
  nuinui_forensic_registered=$(git -C "$nuinui_forensic_anchor" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p') || return 1
  printf '%s\n' "$nuinui_forensic_registered" | grep -Fqx "$1" || {
    nuinui_forensic_reason=not-registered-worktree; return 1;
  }
  nuinui_forensic_expected=$(printf '%b%s\n' "$nuinui_forensic_expected" "$nuinui_forensic_physical" | LC_ALL=C sort)
  nuinui_forensic_actual=$(printf '%s\n' "$nuinui_forensic_registered" | LC_ALL=C sort)
  [ "$nuinui_forensic_expected" = "$nuinui_forensic_actual" ] || {
    nuinui_forensic_reason=registered-inventory-mismatch; return 1;
  }
}

nuinui_run_public() {
  nuinui_public_name=$1
  shift
  nuinui_public_output=
  nuinui_public_rc=0
  nuinui_public_output=$("$@" 2>&1) || nuinui_public_rc=$?
  if [ "$nuinui_public_rc" = 0 ] && [ "${nuinui_forensic_option_active:-0}" = 1 ]; then
    case "$nuinui_public_name" in
      begin|start)
        nuinui_public_output=$(printf '%s\nforensic_exception=active\nforensic_worktree=%s' \
          "$nuinui_public_output" "$nuinui_forensic_worktree") ;;
    esac
  fi
  [ -n "$nuinui_public_output" ] ||
    nuinui_public_output=$(printf 'ERROR: public command %s failed without a diagnostic' "$nuinui_public_name")
  printf '%s\n' "$nuinui_public_output" | nuinui_render_human_output "$nuinui_public_name"
  return "$nuinui_public_rc"
}

nuinui_run_tracked() {
  nuinui_tracked_name=$1
  nuinui_tracked_request_count=$2
  shift 2
  nuinui_tracked_display_file=$(mktemp "${TMPDIR:-/tmp}/nuinui-human-output.XXXXXX") || {
    printf 'ERROR: unable to capture tracked command output\n' | nuinui_render_human_output "$nuinui_tracked_name"
    return 1
  }
  nuinui_tracked_rc=0
  nuinui_command_result_run "$nuinui_tracked_name" "$nuinui_tracked_request_count" "$@" \
    >"$nuinui_tracked_display_file" 2>&1 || nuinui_tracked_rc=$?
  nuinui_render_human_output "$nuinui_tracked_name" <"$nuinui_tracked_display_file"
  rm -f -- "$nuinui_tracked_display_file"
  return "$nuinui_tracked_rc"
}

nuinui_forensic_worktree=
nuinui_forensic_option_active=0
