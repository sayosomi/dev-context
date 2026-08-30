fb_parse_machine_rows() {
  fb_rows=$1
  fb_seen=0
  fb_pending=0
  fb_failure=
  fb_parse_error=
  while IFS="$(printf '\t')" read -r fb_name fb_bucket fb_extra; do
    [ -z "$fb_name" ] && continue
    fb_seen=1
    if [ -n "$fb_extra" ] || [ -z "$fb_bucket" ]; then
      fb_parse_error='malformed required check row'
      continue
    fi
    case "$fb_bucket" in
      pending) fb_pending=1 ;;
      pass) ;;
      failure|fail|cancelled|cancel|skipped|skipping|unknown|neutral|*)
        fb_failure="$fb_name	$fb_bucket"
        ;;
    esac
  done < "$fb_rows"
  if [ -n "$fb_parse_error" ]; then
    CHECK_STATE=required-checks-unresolved
    CHECK_DETAIL=$fb_parse_error
  elif [ "$fb_seen" != 1 ]; then
    return 1
  elif [ -n "$fb_failure" ]; then
    CHECK_STATE=fail
    CHECK_DETAIL="required_check=$fb_failure"
  elif [ "$fb_pending" = 1 ]; then
    CHECK_STATE=pending
    CHECK_DETAIL='machine-readable required checks include pending work'
  else
    CHECK_STATE=pass
    CHECK_DETAIL='all machine-readable required checks passed'
  fi
  return 0
}

fb_validate_requirements() {
  fb_input=$1
  fb_output=$2
  : > "$fb_output"
  fb_requirement_count=0
  fb_requirement_error=
  while IFS="$(printf '\t')" read -r fb_kind fb_context fb_app fb_extra; do
    [ -z "$fb_kind" ] && continue
    case "$fb_kind" in
      none)
        [ -z "$fb_context$fb_app$fb_extra" ] || fb_requirement_error='malformed required-check metadata'
        ;;
      required)
        if [ -z "$fb_context" ] || [ -n "$fb_extra" ]; then
          fb_requirement_error='malformed required-check metadata'
          continue
        fi
        case "$fb_app" in
          ''|-) fb_app=- ;;
          *[!0-9]*) fb_requirement_error='malformed required-check metadata'; continue ;;
          0) fb_app=- ;;
        esac
        printf 'required\t%s\t%s\n' "$fb_context" "$fb_app" >> "$fb_output"
        fb_requirement_count=$((fb_requirement_count + 1))
        ;;
      invalid)
        fb_requirement_error='contradictory or incomplete required-check metadata'
        ;;
      *) fb_requirement_error='malformed required-check metadata' ;;
    esac
  done < "$fb_input"
  if [ -n "$fb_requirement_error" ]; then
    CHECK_STATE=required-checks-unresolved
    CHECK_DETAIL=$fb_requirement_error
  fi
}

fb_classify_status() {
  case "$1:$2" in
    queued:none|in_progress:none|queued:''|in_progress:'') echo pending ;;
    completed:success) echo pass ;;
    completed:*) echo fail ;;
    *) echo unresolved ;;
  esac
}

fb() {
  local h fb_dir fb_branch_out fb_branch_err fb_rules_out fb_rules_err
  local fb_runs_out fb_runs_err fb_checks_out fb_checks_err fb_detail
  h=$1
  CHECK_STATE=
  CHECK_DETAIL=
  fb_dir=$(mktemp -d /tmp/nuinui-checks.XXXXXX) || {
    CHECK_STATE=api-error
    CHECK_DETAIL='unable to allocate check-discovery workspace'
    return 0
  }
  fb_branch_out=$fb_dir/branch.out
  fb_branch_err=$fb_dir/branch.err
  if "$GH" api "repos/$PR/branches/main" --jq 'if (.protection.required_status_checks? // null) == null then "none" elif ((.protection.required_status_checks.contexts // [])|length == 0) and ((.protection.required_status_checks.checks // [])|length == 0) then "none" elif ((.protection.required_status_checks.contexts // [])|sort) == ((.protection.required_status_checks.checks // [])|map(.context)|sort) and all((.protection.required_status_checks.checks // [])[]; (.app_id|type)=="number" and .app_id > 0) then .protection.required_status_checks.checks[]|["required",.context,(.app_id|tostring)]|@tsv else "invalid" end' >"$fb_branch_out" 2>"$fb_branch_err"; then
    :
  else
    fb_detail=$(cat "$fb_branch_err" 2>/dev/null)
    CHECK_STATE=api-error
    CHECK_DETAIL='branch-protection lookup failed'
    [ -z "$fb_detail" ] || CHECK_DETAIL="$CHECK_DETAIL: $fb_detail"
    rm -rf "$fb_dir"
    return 0
  fi
  fb_rules_out=$fb_dir/rules.out
  fb_rules_err=$fb_dir/rules.err
  if "$GH" api "repos/$PR/rules/branches/main" --jq '[.[]? | select(.type=="required_status_checks") | .parameters.required_status_checks[]? | ["required",.context,((.integration_id // 0)|tostring)]|@tsv] | if length == 0 then "none" else .[] end' >"$fb_rules_out" 2>"$fb_rules_err"; then
    :
  else
    fb_detail=$(cat "$fb_rules_err" 2>/dev/null)
    CHECK_STATE=api-error
    CHECK_DETAIL='ruleset lookup failed'
    [ -z "$fb_detail" ] || CHECK_DETAIL="$CHECK_DETAIL: $fb_detail"
    rm -rf "$fb_dir"
    return 0
  fi
  cat "$fb_branch_out" "$fb_rules_out" > "$fb_dir/requirements.raw"
  fb_validate_requirements "$fb_dir/requirements.raw" "$fb_dir/requirements"
  if [ "$CHECK_STATE" = required-checks-unresolved ]; then
    rm -rf "$fb_dir"
    return 0
  fi

  fb_runs_out=$fb_dir/runs.out
  fb_runs_err=$fb_dir/runs.err
  if "$GH" api -X GET "repos/$PR/actions/runs" -f head_sha="$h" -f event=pull_request -f per_page=100 --jq 'if (.total_count // 0) > 100 then "truncated" elif ([.workflow_runs[]? | select(.event=="pull_request")]|length) == 0 then "none" else .workflow_runs[] | select(.event=="pull_request") | [.id,.name,.status,(.conclusion // "none"),(.check_suite_id // 0),(.head_sha // ""),.event]|@tsv end' >"$fb_runs_out" 2>"$fb_runs_err"; then
    :
  else
    fb_detail=$(cat "$fb_runs_err" 2>/dev/null)
    CHECK_STATE=api-error
    CHECK_DETAIL='Actions workflow lookup failed'
    [ -z "$fb_detail" ] || CHECK_DETAIL="$CHECK_DETAIL: $fb_detail"
    rm -rf "$fb_dir"
    return 0
  fi
  if grep -qx truncated "$fb_runs_out"; then
    CHECK_STATE=required-checks-unresolved
    CHECK_DETAIL='exact-head Actions workflow evidence is truncated'
    rm -rf "$fb_dir"
    return 0
  fi

  fb_checks_out=$fb_dir/checks.out
  fb_checks_err=$fb_dir/checks.err
  if "$GH" api "repos/$PR/commits/$h/check-runs" --jq 'if (.total_count // 0) > 100 then "truncated" elif ([.check_runs[]?]|length) == 0 then "none" else .check_runs[] | [.name,((.app.id // 0)|tostring),.status,(.conclusion // "none"),(.head_sha // "")]|@tsv end' >"$fb_checks_out" 2>"$fb_checks_err"; then
    :
  else
    fb_detail=$(cat "$fb_checks_err" 2>/dev/null)
    CHECK_STATE=api-error
    CHECK_DETAIL='check-run lookup failed'
    [ -z "$fb_detail" ] || CHECK_DETAIL="$CHECK_DETAIL: $fb_detail"
    rm -rf "$fb_dir"
    return 0
  fi
  if grep -qx truncated "$fb_checks_out"; then
    CHECK_STATE=required-checks-unresolved
    CHECK_DETAIL='exact-head check-run evidence is truncated'
    rm -rf "$fb_dir"
    return 0
  fi

  fb_bad_evidence=
  fb_run_count=0
  fb_pending=0
  fb_failure=0
  fb_all_pass=1
  : > "$fb_dir/suites"
  while IFS="$(printf '\t')" read -r fb_run_id fb_run_name fb_run_status fb_run_conclusion fb_suite_id fb_run_head fb_run_event fb_extra; do
    [ -z "$fb_run_id" ] && continue
    [ "$fb_run_id" = none ] && continue
    if [ -n "$fb_extra" ] || [ "$fb_run_head" != "$h" ] || [ "$fb_run_event" != pull_request ] || ! printf '%s\n' "$fb_suite_id" | grep -Eq '^[1-9][0-9]*$'; then
      fb_bad_evidence='workflow run is not safely correlated to exact head'
      continue
    fi
    fb_run_count=$((fb_run_count + 1))
    fb_suite_out=$fb_dir/suite.out
    fb_suite_err=$fb_dir/suite.err
    if "$GH" api "repos/$PR/check-suites/$fb_suite_id" --jq '[.head_sha,((.app.id // 0)|tostring),.status,(.conclusion // "none")]|@tsv' >"$fb_suite_out" 2>"$fb_suite_err"; then
      :
    else
      fb_detail=$(cat "$fb_suite_err" 2>/dev/null)
      CHECK_STATE=api-error
      CHECK_DETAIL='check-suite lookup failed'
      [ -z "$fb_detail" ] || CHECK_DETAIL="$CHECK_DETAIL: $fb_detail"
      rm -rf "$fb_dir"
      return 0
    fi
    IFS="$(printf '\t')" read -r fb_suite_head fb_suite_app fb_suite_status fb_suite_conclusion fb_suite_extra < "$fb_suite_out"
    if [ -n "$fb_suite_extra" ] || [ "$fb_suite_head" != "$h" ] || ! printf '%s\n' "$fb_suite_app" | grep -Eq '^[0-9]+$'; then
      fb_bad_evidence='check-suite does not prove the exact PR head'
      continue
    fi
    printf '%s\t%s\n' "$fb_run_id" "$fb_suite_app" >> "$fb_dir/suites"
    fb_run_state=$(fb_classify_status "$fb_run_status" "$fb_run_conclusion")
    fb_suite_state=$(fb_classify_status "$fb_suite_status" "$fb_suite_conclusion")
    case "$fb_run_state:$fb_suite_state" in
      pending:pending|pass:pass|fail:fail) ;;
      *)
        fb_bad_evidence='workflow run and check-suite status disagree'
        fb_all_pass=0
        continue
        ;;
    esac
    if [ "$fb_run_status" = completed ] && [ "$fb_suite_status" = completed ] && [ "$fb_run_conclusion" != "$fb_suite_conclusion" ]; then
      fb_bad_evidence='workflow run and check-suite conclusions disagree'
      fb_all_pass=0
      continue
    fi
    case "$fb_suite_status:$fb_suite_conclusion" in
      queued:none|in_progress:none|queued:''|in_progress:'') fb_pending=1; fb_all_pass=0 ;;
      completed:success) ;;
      completed:*) fb_failure=1; fb_all_pass=0 ;;
      *) fb_bad_evidence='check-suite has an unresolved status/conclusion'; fb_all_pass=0 ;;
    esac
  done < "$fb_runs_out"
  if [ "$fb_run_count" = 0 ] && ! grep -qx none "$fb_runs_out"; then
    if [ -z "$fb_bad_evidence" ]; then
      fb_bad_evidence='exact-head workflow evidence could not be parsed'
    fi
  fi

  if [ "$fb_requirement_count" -gt 0 ]; then
    fb_requirement_pending=0
    fb_requirement_failure=0
    fb_requirement_unresolved=
    while IFS="$(printf '\t')" read -r fb_kind fb_context fb_app fb_extra; do
      fb_match_count=0
      fb_match_state=
      while IFS="$(printf '\t')" read -r fb_check_name fb_check_app fb_check_status fb_check_conclusion fb_check_head fb_check_extra; do
        if [ -z "$fb_check_name" ] || [ "$fb_check_name" = none ]; then
          continue
        fi
        if [ -n "$fb_check_extra" ] || [ "$fb_check_head" != "$h" ]; then
          fb_requirement_unresolved="check-run head mismatch for $fb_context"
          continue
        fi
        [ "$fb_check_name" = "$fb_context" ] || continue
        case "$fb_app" in -|'') : ;; *) [ "$fb_check_app" = "$fb_app" ] || continue ;; esac
        fb_match_count=$((fb_match_count + 1))
        fb_match_state=$(fb_classify_status "$fb_check_status" "$fb_check_conclusion")
      done < "$fb_checks_out"
      if [ "$fb_match_count" = 0 ]; then
        while IFS="$(printf '\t')" read -r fb_run_id fb_run_name fb_run_status fb_run_conclusion fb_suite_id fb_run_head fb_run_event fb_extra; do
          if [ -z "$fb_run_id" ] || [ "$fb_run_id" = none ]; then
            continue
          fi
          [ "$fb_run_name" = "$fb_context" ] || continue
          [ "$fb_run_head" = "$h" ] || continue
          case "$fb_app" in
            -|'') ;;
            *)
              if ! awk -F '\t' -v id="$fb_run_id" -v app="$fb_app" '$1==id && $2==app {found=1} END {exit found ? 0 : 1}' "$fb_dir/suites"; then
                continue
              fi
              ;;
          esac
          fb_match_count=$((fb_match_count + 1))
          fb_match_state=$(fb_classify_status "$fb_run_status" "$fb_run_conclusion")
        done < "$fb_runs_out"
      fi
      if [ "$fb_match_count" != 1 ]; then
        if [ -z "$fb_requirement_unresolved" ]; then
          fb_requirement_unresolved="required context cannot be correlated: $fb_context"
        fi
      else
        case "$fb_match_state" in
          pending) fb_requirement_pending=1 ;;
          fail) fb_requirement_failure=1 ;;
          pass) ;;
          *) if [ -z "$fb_requirement_unresolved" ]; then fb_requirement_unresolved="required context has unresolved evidence: $fb_context"; fi ;;
        esac
      fi
    done < "$fb_dir/requirements"
    if [ -n "$fb_bad_evidence" ] || [ -n "$fb_requirement_unresolved" ]; then
      CHECK_STATE=required-checks-unresolved
      if [ -n "$fb_bad_evidence" ]; then CHECK_DETAIL=$fb_bad_evidence; else CHECK_DETAIL=$fb_requirement_unresolved; fi
    elif [ "$fb_requirement_failure" = 1 ]; then
      CHECK_STATE=fail
      CHECK_DETAIL='a proven required context failed'
    elif [ "$fb_requirement_pending" = 1 ]; then
      CHECK_STATE=pending
      CHECK_DETAIL='a proven required context is still pending'
    else
      CHECK_STATE=pass
      CHECK_DETAIL='all configured required contexts passed'
    fi
  elif grep -qx none "$fb_runs_out"; then
    CHECK_STATE=none-required
    CHECK_DETAIL='no required-check configuration or exact-head pull_request Actions workflow'
  elif [ -n "$fb_bad_evidence" ]; then
    CHECK_STATE=required-checks-unresolved
    CHECK_DETAIL=$fb_bad_evidence
  elif [ "$fb_failure" = 1 ]; then
    CHECK_STATE=fail
    CHECK_DETAIL='an exact-head pull_request Actions workflow failed'
  elif [ "$fb_pending" = 1 ]; then
    CHECK_STATE=pending
    CHECK_DETAIL='an exact-head pull_request Actions workflow is still pending'
  elif [ "$fb_all_pass" = 1 ]; then
    CHECK_STATE=pass
    CHECK_DETAIL='all exact-head pull_request Actions workflows passed'
  else
    CHECK_STATE=required-checks-unresolved
    CHECK_DETAIL='exact-head pull_request Actions workflow evidence is incomplete'
  fi
  rm -rf "$fb_dir"
}
