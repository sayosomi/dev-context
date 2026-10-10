# Fixed-revision evaluator audit release lifecycle.
# This phase verifies the exact reservation before restoring the canonical idle checkout.

nuinui_audit_release() {
  [ "$#" = 3 ] || return 2
  nuinui_audit_manifest=$1
  nuinui_audit_requested_issue=$2
  nuinui_audit_requested_revision=$(printf '%s' "$3" | tr 'A-F' 'a-f')
  NUINUI_AUDIT_RESOLVED_ISSUE=$nuinui_audit_requested_issue
  NUINUI_AUDIT_RESOLVED_LANE=-
  NUINUI_AUDIT_RESOLVED_GENERATION=
  lane_execution_validate_work_id "$nuinui_audit_requested_issue" || { nuinui_audit_blocked_before_mutation 'Issue must be a valid SAY identifier'; return 1; }
  nuinui_ownership_valid_sha "$nuinui_audit_requested_revision" || { nuinui_audit_blocked_before_mutation 'revision must be a full 40-character commit SHA'; return 1; }

  lane_manifest_validate "$nuinui_audit_manifest" || { nuinui_audit_blocked_before_mutation 'lane manifest is invalid'; return 1; }
  nuinui_audit_matches=
  while IFS= read -r nuinui_audit_candidate_lane || [ -n "$nuinui_audit_candidate_lane" ]; do
    [ -n "$nuinui_audit_candidate_lane" ] || continue
    nuinui_audit_candidate_path=$(lane_manifest_lane_path \
      "$nuinui_audit_manifest" "$nuinui_audit_candidate_lane") || continue
    nuinui_audit_candidate_path=$(lane_execution__canonical_path \
      "$nuinui_audit_candidate_path" 2>/dev/null || true)
    [ -n "$nuinui_audit_candidate_path" ] || continue
    [ "$nuinui_audit_candidate_path" = "$(lane_execution__canonical_path \
      "$(lane_manifest_lane_path "$nuinui_audit_manifest" "$nuinui_audit_candidate_lane" 2>/dev/null || true)" 2>/dev/null || true)" ] || continue
    [ "$(lane_manifest_lane_role "$nuinui_audit_manifest" \
      "$nuinui_audit_candidate_lane" 2>/dev/null || true)" = implementation ] || continue
    nuinui_audit_candidate_git_dir=$(lane_execution__git_dir \
      "$nuinui_audit_candidate_path" 2>/dev/null || true)
    [ -n "$nuinui_audit_candidate_git_dir" ] || continue
    if [ -f "$(ap "$nuinui_audit_candidate_path")" ] ||
      [ -L "$(ap "$nuinui_audit_candidate_path")" ]; then
      [ -z "$nuinui_audit_matches" ] || { nuinui_audit_blocked_before_mutation 'multiple active audit reservations make release ambiguous'; return 1; }
      nuinui_audit_matches=$nuinui_audit_candidate_lane
    fi
  done <<EOF
$(lane_manifest_lanes_by_role "$nuinui_audit_manifest" implementation)
EOF

  if [ -z "$nuinui_audit_matches" ]; then
    nuinui_audit_receipt_lane=
    while IFS= read -r nuinui_audit_candidate_lane || [ -n "$nuinui_audit_candidate_lane" ]; do
      [ -n "$nuinui_audit_candidate_lane" ] || continue
      nuinui_audit_candidate_path=$(lane_manifest_lane_path \
        "$nuinui_audit_manifest" "$nuinui_audit_candidate_lane") || continue
      nuinui_audit_candidate_git_dir=$(lane_execution__git_dir \
        "$nuinui_audit_candidate_path" 2>/dev/null || true)
      [ -n "$nuinui_audit_candidate_git_dir" ] || continue
      nuinui_audit_candidate_receipt=$(arp "$nuinui_audit_candidate_path")
      if [ -f "$nuinui_audit_candidate_receipt" ] || [ -L "$nuinui_audit_candidate_receipt" ]; then
        [ -z "$nuinui_audit_receipt_lane" ] || { nuinui_audit_blocked_before_mutation 'multiple audit release receipts make duplicate release ambiguous'; return 1; }
        nuinui_audit_receipt_lane=$nuinui_audit_candidate_lane
        nuinui_audit_receipt_candidate_path=$nuinui_audit_candidate_path
      fi
    done <<EOF
$(lane_manifest_lanes_by_role "$nuinui_audit_manifest" implementation)
EOF
    [ -n "$nuinui_audit_receipt_lane" ] || { nuinui_audit_blocked_before_mutation 'no matching active audit reservation or release receipt exists'; return 1; }
    nuinui_audit_target "$nuinui_audit_manifest" "$nuinui_audit_receipt_lane" || { nuinui_audit_blocked_before_mutation 'release receipt target is not a declared implementation lane'; return 1; }
    [ ! -e "$nuinui_audit_reservation_file" ] && [ ! -L "$nuinui_audit_reservation_file" ] &&
      [ ! -e "$(kp "$nuinui_audit_repo")" ] && [ ! -L "$(kp "$nuinui_audit_repo")" ] || { nuinui_audit_blocked_before_mutation 'audit or mutation ownership changed during duplicate release read-back'; return 1; }
    nuinui_audit_load_receipt "$nuinui_audit_receipt_file" &&
      nuinui_audit_receipt_matches_target &&
      [ "$nuinui_audit_receipt_issue" = "$nuinui_audit_requested_issue" ] &&
      [ "$nuinui_audit_receipt_revision" = "$nuinui_audit_requested_revision" ] || { nuinui_audit_blocked_before_mutation 'release receipt does not exactly match the requested Issue and revision'; return 1; }
    NUINUI_AUDIT_RESOLVED_LANE=$nuinui_audit_target_lane
    NUINUI_AUDIT_RESOLVED_GENERATION=$nuinui_audit_receipt_generation
    nuinui_audit_receipt_base=$nuinui_audit_receipt_base
    nuinui_audit_current_branch=$(bn "$nuinui_audit_repo")
    nuinui_audit_expected_branch=$nuinui_audit_receipt_branch
    [ "$nuinui_audit_expected_branch" != - ] || nuinui_audit_expected_branch=
    [ "$(hh "$nuinui_audit_repo" 2>/dev/null || true)" = "$nuinui_audit_receipt_base" ] &&
      [ "$nuinui_audit_current_branch" = "$nuinui_audit_expected_branch" ] &&
      [ -z "$(git -C "$nuinui_audit_repo" status --porcelain 2>/dev/null)" ] || { nuinui_audit_blocked_before_mutation 'recorded released checkout is no longer in its canonical clean idle state'; return 1; }
    nuinui_audit_initial_free_proof "$nuinui_audit_manifest" || { nuinui_audit_blocked_before_mutation 'duplicate release read-back did not prove canonical FREE state'; return 1; }
    nuinui_audit_projection_free_evidence "$nuinui_audit_preflight_output" > /dev/null || { nuinui_audit_blocked_before_mutation 'duplicate release did not read back FREE or FREE/STALE'; return 1; }
    nuinui_audit_projection_line=$(nuinui_audit_projection_free_evidence \
      "$nuinui_audit_preflight_output") || return 1
    printf 'AUDIT ALREADY RELEASED\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\npost_ff_base=%s\n%s\nclean=yes\nmutation=no-op\n' \
      "$nuinui_audit_receipt_issue" "$nuinui_audit_receipt_lane" \
      "$nuinui_audit_receipt_revision" "$nuinui_audit_receipt_generation" \
      "$nuinui_audit_receipt_checkout" "$nuinui_audit_receipt_base" \
      "$nuinui_audit_projection_line"
    return 0
  fi

  nuinui_audit_target "$nuinui_audit_manifest" "$nuinui_audit_matches" || { nuinui_audit_blocked_before_mutation 'active reservation target is not a declared implementation lane'; return 1; }
  if [ -e "$nuinui_audit_receipt_file" ] || [ -L "$nuinui_audit_receipt_file" ]; then
    nuinui_audit_load_receipt "$nuinui_audit_receipt_file" &&
      nuinui_audit_receipt_matches_target || { nuinui_audit_blocked_before_mutation 'existing audit receipt is malformed or belongs to another checkout'; return 1; }
  fi
  nuinui_audit_reservation_fields_valid_for_request || { nuinui_audit_blocked_before_mutation 'active audit reservation does not exactly match the requested Issue, lane, and revision'; return 1; }
  nuinui_audit_prepare_result_identity
  [ "$nuinui_audit_state" = ACTIVE ] && nuinui_audit_clean_active_checkout || { nuinui_audit_blocked_with_reservation 'release requires the exact clean detached ACTIVE audit checkout'; return 1; }
  nuinui_audit_lock=$(kp "$nuinui_audit_repo")
  [ ! -e "$nuinui_audit_lock" ] && [ ! -L "$nuinui_audit_lock" ] || { nuinui_audit_blocked_with_reservation 'an unresolved mutation lock prevents audit release'; return 1; }
  nuinui_audit_reservation_nonfree_proof "$nuinui_audit_manifest" >/dev/null || { nuinui_audit_blocked_with_reservation 'active reservation is not proven by canonical admission preflight'; return 1; }
  nuinui_audit_generation=$nuinui_audit_generation
  nuinui_audit_release_generation=$nuinui_audit_generation
  lane_execution__lock "$nuinui_audit_repo" "$nuinui_audit_release_generation" \
    - - "$nuinui_audit_requested_revision" audit-release || { nuinui_audit_blocked_with_reservation 'could not acquire the existing per-lane release mutation lock'; return 1; }
  nuinui_audit_load_reservation "$nuinui_audit_reservation_file" &&
    nuinui_audit_identity_matches_target &&
    [ "$nuinui_audit_state" = ACTIVE ] &&
    [ "$nuinui_audit_issue" = "$nuinui_audit_requested_issue" ] &&
    [ "$nuinui_audit_revision" = "$nuinui_audit_requested_revision" ] &&
    nuinui_audit_clean_active_checkout || { nuinui_audit_blocked_with_reservation 'release mutation-boundary reservation read-back failed'; return 1; }
  nuinui_audit_store_state=RELEASING
  nuinui_audit_store_content=$(printf 'version=1\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\ngit_dir=%s\nrepository=%s\ndefault_branch=%s\nidle_policy=%s\noriginal_branch=%s\npre_ff_head=%s\npost_ff_base=%s\nstate=RELEASING\n' \
    "$nuinui_audit_issue" "$nuinui_audit_lane" "$nuinui_audit_revision" \
    "$nuinui_audit_generation" "$nuinui_audit_stored_checkout" \
    "$nuinui_audit_stored_git_dir" "$nuinui_audit_stored_repository" \
    "$nuinui_audit_stored_default" "$nuinui_audit_stored_idle" \
    "$nuinui_audit_original_branch" "$nuinui_audit_pre_ff_head" \
    "$nuinui_audit_post_ff_base")
  lane_execution__atomic_write "$nuinui_audit_reservation_file" \
    "$nuinui_audit_store_content" || { nuinui_audit_blocked_with_reservation 'unable to durably mark the audit reservation as RELEASING'; return 1; }
  if [ "${NUINUI_SELFTEST:-0}" = 1 ] &&
    [ "${NUINUI_SELFTEST_CRASH_AT:-}" = audit-release-after-marker ]; then
    printf 'BLOCKED: injected interruption after release marker\nmutation_state=UNKNOWN\nrecovery=preserve-audit-reservation\nissue=%s\nlane=%s\ngeneration=%s\n' \
      "$nuinui_audit_requested_issue" "$nuinui_audit_target_lane" "$nuinui_audit_generation"
    return 97
  fi
  if [ "$nuinui_audit_idle" = branch ]; then
    [ "$(git -C "$nuinui_audit_repo" rev-parse \
      "refs/heads/$nuinui_audit_default^{commit}" 2>/dev/null || true)" = \
      "$nuinui_audit_post_ff_base" ] || { nuinui_audit_blocked_with_reservation 'recorded canonical idle branch no longer points at the post-fast-forward base'; return 1; }
    git -C "$nuinui_audit_repo" switch "$nuinui_audit_default" >/dev/null 2>&1 || { nuinui_audit_blocked_with_reservation 'could not restore the recorded canonical idle branch'; return 1; }
  else
    git -C "$nuinui_audit_repo" switch --detach \
      "$nuinui_audit_post_ff_base" >/dev/null 2>&1 || { nuinui_audit_blocked_with_reservation 'could not restore the recorded canonical detached idle form'; return 1; }
  fi
  lane_execution__occupancy_idle_proof "$nuinui_audit_target_lane" \
    "$nuinui_audit_repo" "$nuinui_audit_idle" "$nuinui_audit_default" \
    "$nuinui_audit_post_ff_base" || { nuinui_audit_blocked_with_reservation 'restored checkout does not match the recorded clean idle base'; return 1; }
  nuinui_audit_read_preflight "$nuinui_audit_manifest" audit-release \
    "$nuinui_audit_generation"
  [ "$nuinui_audit_preflight_rc" = 0 ] &&
    nuinui_audit_output_has_inventory "$nuinui_audit_preflight_output" || { nuinui_audit_blocked_with_reservation 'release projection did not prove canonical FREE state'; return 1; }
  nuinui_audit_projection_line=$(nuinui_audit_projection_free_evidence \
    "$nuinui_audit_preflight_output") || { nuinui_audit_blocked_with_reservation 'release projection did not prove FREE or FREE/STALE'; return 1; }

  nuinui_audit_released_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ') || { nuinui_audit_blocked_with_reservation 'unable to allocate release receipt timestamp'; return 1; }
  nuinui_audit_receipt_content=$(printf 'version=1\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\ngit_dir=%s\nrepository=%s\ndefault_branch=%s\nidle_policy=%s\noriginal_branch=%s\npre_ff_head=%s\npost_ff_base=%s\nreleased_at=%s\n' \
    "$nuinui_audit_issue" "$nuinui_audit_lane" "$nuinui_audit_revision" \
    "$nuinui_audit_generation" "$nuinui_audit_stored_checkout" \
    "$nuinui_audit_stored_git_dir" "$nuinui_audit_stored_repository" \
    "$nuinui_audit_stored_default" "$nuinui_audit_stored_idle" \
    "$nuinui_audit_original_branch" "$nuinui_audit_pre_ff_head" \
    "$nuinui_audit_post_ff_base" "$nuinui_audit_released_at")
  lane_execution__atomic_write "$nuinui_audit_receipt_file" \
    "$nuinui_audit_receipt_content" || { nuinui_audit_blocked_with_reservation 'unable to persist the exact audit release receipt'; return 1; }
  nuinui_ownership_validate_audit_receipt "$nuinui_audit_receipt_file" || { nuinui_audit_blocked_with_reservation 'persisted audit release receipt failed strict read-back'; return 1; }
  nuinui_audit_receipt_read_generation=$(nuinui_ownership_field \
    "$nuinui_audit_receipt_file" generation) || { nuinui_audit_blocked_with_reservation 'release receipt generation read-back failed'; return 1; }
  [ "$nuinui_audit_receipt_read_generation" = "$nuinui_audit_generation" ] || { nuinui_audit_blocked_with_reservation 'release receipt generation does not match the reservation'; return 1; }
  nuinui_audit_load_reservation "$nuinui_audit_reservation_file" &&
    [ "$nuinui_audit_generation" = "$nuinui_audit_release_generation" ] &&
    [ "$nuinui_audit_state" = RELEASING ] || { nuinui_audit_blocked_with_reservation 'reservation changed before its protected release point'; return 1; }
  lane_execution__unlock "$nuinui_audit_repo" "$nuinui_audit_release_generation" || { nuinui_audit_blocked_with_reservation 'could not release the audit-release mutation lock'; return 1; }
  rm -f -- "$nuinui_audit_reservation_file" || { nuinui_audit_blocked_with_reservation 'could not remove the exact released reservation after unlocking'; return 1; }
  [ ! -e "$nuinui_audit_reservation_file" ] &&
    [ ! -L "$nuinui_audit_reservation_file" ] || { nuinui_audit_blocked_with_reservation 'released reservation path still exists after removal'; return 1; }
  nuinui_audit_released_branch=$nuinui_audit_original_branch
  [ "$nuinui_audit_released_branch" != - ] || nuinui_audit_released_branch=DETACHED
  printf 'AUDIT RELEASED\nissue=%s\nlane=%s\nrevision=%s\ngeneration=%s\ncheckout=%s\npost_ff_base=%s\nbranch=%s\nhead=%s\nclean=yes\n%s\nstate=FREE\nmutation_state=COMPLETED\n' \
    "$nuinui_audit_issue" "$nuinui_audit_lane" "$nuinui_audit_revision" \
    "$nuinui_audit_generation" "$nuinui_audit_stored_checkout" \
    "$nuinui_audit_post_ff_base" \
    "$nuinui_audit_released_branch" "$nuinui_audit_post_ff_base" \
    "$nuinui_audit_projection_line"
}
