# nuinuiCAD-specific remainder for the generated standalone helper.
# Fixed implementation ownership and lifecycle mechanics live in the shared
# fixed-2+1 source modules.

V=1.6.22
P=$0
D=$(CDPATH= cd -- "$(dirname -- "$P")" && pwd -P)
EH=${NUINUI_E2E_STATUS_HELPER:-$D/nuinui-e2e-prepare}
M=$(fixed_2plus1_profile_lane_path "$(fixed_2plus1_profile_implementation_lane_a_name)")
S=$(fixed_2plus1_profile_lane_path "$(fixed_2plus1_profile_implementation_lane_b_name)")
E=$(fixed_2plus1_profile_lane_path "$(fixed_2plus1_profile_human_test_lane_name)")
RT=$(fixed_2plus1_profile_repository_identity)

if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
  C=${NUINUI_DEV_CONTEXT_WT:-}
else
  C=/Users/yosomi/Code/dev-context
fi
if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
  CD=${NUINUI_DEV_CONTEXT_DEV_WT:-}
  [ -z "${NUINUI_SELFTEST_EXPECTED_ORIGIN:-}" ] || CT=$NUINUI_SELFTEST_EXPECTED_ORIGIN
else
  CD=/Users/yosomi/Code/dev-context-dev
  CT=sayosomi/dev-context
fi

nuinui_validate_forensic_worktree() {
  local forensic physical fixed_a fixed_b fixed_h registered expected actual
  forensic=$1
  nuinui_forensic_reason=
  case "$forensic" in /*) ;; *) nuinui_forensic_reason=non-absolute-path; return 1 ;; esac
  [ -d "$forensic" ] || { nuinui_forensic_reason=missing-or-not-directory; return 1; }
  physical=$(CDPATH= cd -- "$forensic" && pwd -P) || {
    nuinui_forensic_reason=non-canonical-path; return 1;
  }
  [ "$physical" = "$forensic" ] || {
    nuinui_forensic_reason=non-canonical-path; return 1;
  }
  fixed_a=$(CDPATH= cd -- "$M" && pwd -P) || {
    nuinui_forensic_reason=registered-inventory-mismatch; return 1;
  }
  fixed_b=$(CDPATH= cd -- "$S" && pwd -P) || {
    nuinui_forensic_reason=registered-inventory-mismatch; return 1;
  }
  fixed_h=$(CDPATH= cd -- "$E" && pwd -P) || {
    nuinui_forensic_reason=registered-inventory-mismatch; return 1;
  }
  case "$physical" in
    "$fixed_a"|"$fixed_b"|"$fixed_h")
      nuinui_forensic_reason=fixed-lane-path; return 1 ;;
  esac
  gr "$forensic" || { nuinui_forensic_reason=not-registered-worktree; return 1; }
  registered=$(git -C "$M" worktree list --porcelain | sed -n 's/^worktree //p')
  printf '%s\n' "$registered" | grep -Fqx "$forensic" || {
    nuinui_forensic_reason=not-registered-worktree; return 1;
  }
  expected=$(printf '%s\n' "$fixed_a" "$fixed_b" "$fixed_h" "$forensic" | sort)
  actual=$(printf '%s\n' "$registered" | sort)
  [ "$actual" = "$expected" ] || {
    nuinui_forensic_reason=registered-inventory-mismatch; return 1;
  }
}

wt() {
  local lane_a lane_b human_lane expected actual
  lane_a=$(CDPATH= cd -- "$M" && pwd -P) || return 1
  lane_b=$(CDPATH= cd -- "$S" && pwd -P) || return 1
  human_lane=$(CDPATH= cd -- "$E" && pwd -P) || return 1
  expected=$(printf '%s\n' "$lane_a" "$lane_b" "$human_lane" | sort) || return 1
  actual=$(git -C "$M" worktree list --porcelain | sed -n 's/^worktree //p' | sort)
  echo worktrees:
  git -C "$M" worktree list | sed 's/^/  /'
  if [ "${nuinui_forensic_option_active:-0}" = 1 ]; then
    [ "${nuinui_forensic_preflight_result:-1}" = 0 ]
  else
    [ "$expected" = "$actual" ]
  fi
}

fixed_2plus1_profile_inventory_guard() {
  local result=0
  nuinui_forensic_preflight_result=0
  if [ "${nuinui_forensic_option_active:-0}" = 1 ]; then
    nuinui_validate_forensic_worktree "${nuinui_forensic_worktree:-}" || {
      nuinui_forensic_preflight_result=1
      result=1
    }
  fi
  wt || result=1
  if [ "${nuinui_forensic_option_active:-0}" = 1 ]; then
    if [ "$nuinui_forensic_preflight_result" = 0 ]; then
      echo 'forensic_exception=active'
    else
      echo 'forensic_exception=BLOCKED'
      echo "forensic_reason=$nuinui_forensic_reason"
    fi
    echo "forensic_worktree=$nuinui_forensic_worktree"
    [ "$nuinui_forensic_preflight_result" = 0 ] || result=1
  fi
  return "$result"
}

fixed_2plus1_profile_after_begin_start() {
  local peer
  peer=$2
  if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
    case "${NUINUI_SELFTEST_BEGIN_AFTER_START:-}" in
      dirty-peer) printf '%s\n' selftest > "$(lr "$peer")/nuinui-selftest-peer-dirty" ;;
      dirty-e2e) printf '%s\n' selftest > "$E/nuinui-selftest-e2e-dirty" ;;
    esac
  fi
}
