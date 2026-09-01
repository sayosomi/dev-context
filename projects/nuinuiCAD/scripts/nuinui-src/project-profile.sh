#!/bin/sh

# nuinuiCAD adapter for the shared fixed 2+1 execution core.

fixed_2plus1_profile_implementation_lane_a_name() { printf '%s\n' main; }
fixed_2plus1_profile_implementation_lane_b_name() { printf '%s\n' sub; }
fixed_2plus1_profile_human_test_lane_name() { printf '%s\n' e2e; }

fixed_2plus1_profile_is_implementation_lane() {
  [ "$1" = main ] || [ "$1" = sub ]
}

fixed_2plus1_profile_peer_lane() {
  case "$1" in
    main) printf '%s\n' sub ;;
    sub) printf '%s\n' main ;;
    *) return 2 ;;
  esac
}

fixed_2plus1_profile_lane_path() {
  case "$1" in
    main)
      if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
        printf '%s\n' "${NUINUI_MAIN_WT:?NUINUI_MAIN_WT is required}"
      else
        printf '%s\n' /Users/yosomi/Code/nuinuiCAD
      fi
      ;;
    sub)
      if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
        printf '%s\n' "${NUINUI_SUB_WT:?NUINUI_SUB_WT is required}"
      else
        printf '%s\n' /Users/yosomi/Code/nuinuiCAD-sub
      fi
      ;;
    e2e)
      if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
        printf '%s\n' "${NUINUI_E2E_WT:?NUINUI_E2E_WT is required}"
      else
        printf '%s\n' /Users/yosomi/Code/nuinuiCAD-e2e
      fi
      ;;
    *) return 2 ;;
  esac
}

fixed_2plus1_profile_repository_identity() { printf '%s\n' sayosomi/nuinuiCAD; }
fixed_2plus1_profile_default_branch() { printf '%s\n' main; }

fixed_2plus1_profile_origin_matches() {
  if [ "${NUINUI_SELFTEST:-0}" = 1 ]; then
    return 0
  fi
  git -C "$1" remote get-url origin 2>/dev/null | grep -Fq "$2"
}

fixed_2plus1_profile_idle_checkout_form() {
  case "$1" in
    main) printf '%s\n' branch ;;
    sub) printf '%s\n' detached ;;
    *) return 2 ;;
  esac
}

fixed_2plus1_profile_valid_work_id() {
  printf '%s\n' "$1" | grep -Eq '^SAY-[0-9]+$'
}

fixed_2plus1_profile_work_id_from_branch() {
  printf '%s\n' "$1" | sed -n 's/.*[sS][aA][yY]-\([0-9][0-9]*\).*/SAY-\1/p'
}

fixed_2plus1_profile_validate_issue_branch() {
  fixed_2plus1_profile_valid_work_id "$1" || return 1
  git check-ref-format --branch "$2" >/dev/null 2>&1 || return 1
  [ "$(fixed_2plus1_profile_work_id_from_branch "$2")" = "$1" ]
}

fixed_2plus1_profile_human_test_marker_path() {
  printf '%s/nuinui-slot\n' "$(gd "$1")"
}

fixed_2plus1_profile_human_test_session_path() {
  printf '%s/nuinui-e2e-session\n' "$(gd "$1")"
}

fixed_2plus1_profile_human_test_receipt_path() {
  printf '%s/nuinui-e2e-release-receipt\n' "$(gd "$1")"
}
