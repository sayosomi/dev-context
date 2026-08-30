V=1.6.3;P=$0;D=$(CDPATH= cd -- "$(dirname -- "$P")"&&pwd -P);EH=${NUINUI_E2E_STATUS_HELPER:-$D/nuinui-e2e-prepare};GH=${NUINUI_GH_BIN:-gh};PR=sayosomi/nuinuiCAD
if [ "${NUINUI_SELFTEST:-0}" = 1 ];then M=${NUINUI_MAIN_WT:?};S=${NUINUI_SUB_WT:?};E=${NUINUI_E2E_WT:?};C=${NUINUI_DEV_CONTEXT_WT:-};RT=;CT=;else M=/Users/yosomi/Code/nuinuiCAD;S=/Users/yosomi/Code/nuinuiCAD-sub;E=/Users/yosomi/Code/nuinuiCAD-e2e;C=/Users/yosomi/Code/dev-context;RT=sayosomi/nuinuiCAD;CT=sayosomi/dev-context;fi
lr(){ case $1 in main)echo "$M";;sub)echo "$S";;e2e)echo "$E";;*)return 2;;esac;};il(){ case $1 in main|sub);;*)return 2;;esac;};gr(){ [ -d "$1" ]&&git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1;};ao(){ [ -z "$2" ]||git -C "$1" remote get-url origin 2>/dev/null|grep -Fq "$2";};cn(){ [ -z "$(git -C "$1" status --porcelain)" ];};bn(){ git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null||true;};hh(){ git -C "$1" rev-parse HEAD;};om(){ git -C "$1" rev-parse origin/main;};fm(){ git -C "$1" fetch origin main >/dev/null 2>&1;};fp(){ git -C "$1" fetch origin --prune >/dev/null 2>&1;};an(){ git -C "$1" merge-base --is-ancestor "$2" "$3";};sd(){ git -C "$1" switch --detach "$2" >/dev/null;};gd(){ git -C "$1" rev-parse --absolute-git-dir 2>/dev/null;};ip(){ echo "$(gd "$1")/nuinui-implementation-v1";};sp(){ echo "$(gd "$1")/nuinui-implementation-slot";};kp(){ echo "$(gd "$1")/nuinui-implementation-lock";};rp(){ echo "$(gd "$1")/nuinui-implementation-slot.releasing.$2";};rds(){ find "$(gd "$1")" -maxdepth 1 -type d -name 'nuinui-implementation-slot.releasing.*' -print 2>/dev/null|sort;};mp(){ echo "$(gd "$1")/nuinui-slot";};ep(){ echo "$(gd "$1")/nuinui-e2e-session";}
wa(){  t=${1}.tmp.$$;(umask 077;printf '%b' "$2">"$t")&&mv -- "$t" "$1";};gc(){ command -v uuidgen >/dev/null 2>&1&&uuidgen|tr A-Z a-z||printf '%s:%s:%s\n' $$ "$(date +%s)" "${RANDOM:-0}"|git hash-object --stdin;};lo(){  k=$(kp "$1");mkdir "$k" 2>/dev/null||return 1;wa "$k/state" "version=1\noperation=$2\nissue=$4\nbranch=$5\nbase=$6\ncheckpoint=$7\nclaim=$3\n";};ul(){ r=$1;e=$2;set -- $(nuinui_ownership_parse_lock "$(kp "$r")/state")||return 1;[ "$6" = "$e" ]&&rm "$(kp "$r")/state"&&rmdir "$(kp "$r")";};am(){ git -C "$1" ls-remote origin refs/heads/main 2>/dev/null|awk 'NR==1{print $1}';};ab(){ git -C "$1" ls-remote --heads origin "refs/heads/$2" 2>/dev/null|awk 'NR==1{print $1}';};id(){ local r a q; r=$2;a=$3;cn "$r"&&[ "$(hh "$r")" = "$a" ]||return 1;q=$(bn "$r");case $1 in main)[ "$q" = main ];;sub)[ -z "$q" ];;esac;};nr(){ [ -z "$(rds "$1")" ];};bo(){  x=$(CDPATH= cd -- "$1"&&pwd -P);git -C "$1" worktree list --porcelain|awk -v b="refs/heads/$2" -v x="$x" '/^worktree /{p=substr($0,10)}/^branch /&&substr($0,8)==b&&p!=x{print p;exit}';}
cl(){ local l r i s k q h d z n a;l=$1;r=$2;i=$(ip "$r");s=$(sp "$r");k=$(kp "$r");q=$(bn "$r");h=$(git -C "$r" rev-parse HEAD 2>/dev/null||true);d=$(git -C "$r" status --porcelain 2>/dev/null);echo "$l path=$r";echo "  branch=${q:-DETACHED}";echo "  head=$h";echo "  clean=$([ -z "$d" ]&&echo yes||echo no)";if [ -e "$k" ];then set -- $(nuinui_ownership_parse_lock "$k/state");[ $# = 6 ]&&echo "  state=BLOCKED reason=mutation-in-progress operation=$1 claim=$6"||echo '  state=BLOCKED reason=invalid-mutation-lock';return 1;fi;z=$(rds "$r");n=$(echo "$z"|grep -c .||true);if [ -e "$s" ];then [ "$n" = 0 ]||{ echo '  state=BLOCKED reason=active-and-releasing-state-coexist';return 1;};set -- $(nuinui_ownership_parse_slot "$s/state");[ $# = 4 ]||{ echo '  state=BLOCKED reason=invalid-active-slot';return 1;};echo "  owner_issue=$1 owner_branch=$2 base=$3 claim=$4";[ "$q" = "$2" ]&&an "$r" "$3" "$h" 2>/dev/null||{ echo '  state=BLOCKED reason=claim-checkout-mismatch';return 1;};echo '  state=BUSY';return 0;fi;if [ "$n" != 0 ];then [ "$n" = 1 ]||{ echo '  state=BLOCKED reason=multiple-release-states';return 1;};set -- $(nuinui_ownership_parse_releasing "$z");[ $# = 5 ]||{ echo '  state=BLOCKED reason=invalid-release-state';return 1;};echo "  state=RELEASE-PENDING claim=$4 checkpoint=$5";return 0;fi;nuinui_ownership_validate_initialization "$i"||{ echo '  state=BLOCKED reason=durable-ownership-initialization-required';return 1;};a=$(am "$r");nuinui_ownership_valid_sha "$a"&&id "$l" "$r" "$a"||{ echo "  state=BLOCKED reason=invalid-idle-state origin_main=$a";return 1;};echo "  state=FREE origin_main=$a";}
wt(){ a=$(printf "%s\n" "$(CDPATH= cd -- "$M"&&pwd -P)" "$(CDPATH= cd -- "$S"&&pwd -P)" "$(CDPATH= cd -- "$E"&&pwd -P)"|sort)||return 1;t=$(git -C "$M" worktree list --porcelain|sed -n "s/^worktree //p"|sort);echo worktrees:;git -C "$M" worktree list|sed "s/^/  /";[ "$a" = "$t" ];};pf(){  z=0;gr "$M"&&cl main "$M"||z=1;gr "$S"&&cl sub "$S"||z=1;echo "e2e path=$E";gr "$E"||z=1;if [ "$z" = 0 ];then q=$(bn "$E");d=$(git -C "$E" status --porcelain);echo "  branch=${q:-DETACHED}";echo "  head=$(hh "$E")";echo "  clean=$([ -z "$d" ]&&echo yes||echo no) marker=$([ -f "$(mp "$E")" ]&&echo present||echo none)";[ ! -f "$(mp "$E")" ]||sed "s/^/    /" "$(mp "$E")";[ -z "$d" ]||z=1;fi;wt||z=1;[ "$z" = 0 ]&&{ echo 'PREFLIGHT PASS';return 0;};echo 'PREFLIGHT BLOCKED';return 1;}
cv(){ local l i a q r z h; l=$1;i=$2;a=$3;q=$4;il "$l"&&nuinui_ownership_valid_issue "$i"&&nuinui_ownership_valid_sha "$a"&&nuinui_ownership_validate_issue_branch "$i" "$q"||return 2;r=$(lr "$l");gr "$r"&&ao "$r" "$RT"&&cn "$r"||return 1;z=$(bn "$r");case $l in main)[ "$z" = main ];;sub)[ -z "$z" ];;esac||return 1;fm "$r"&&[ "$(om "$r")" = "$a" ]||return 1;git -C "$r" show-ref --verify --quiet "refs/heads/$q"&&return 1;[ -z "$(ab "$r" "$q")" ]||return 1;h=$(hh "$r");[ "$h" = "$a" ]||an "$r" "$h" "$a"||return 1;echo VERIFIED;};vr(){  r=$(lr "$1")||return 2;nuinui_ownership_validate_initialization "$(ip "$r")"&&[ ! -e "$(sp "$r")" ]&&[ ! -e "$(kp "$r")" ]&&nr "$r"||return 1;cv "$@";};li(){  l=$1;il "$l"||return;r=$(lr "$l");gr "$r"&&ao "$r" "$RT"||return 1;i=$(ip "$r");if [ -e "$i" ];then nuinui_ownership_validate_initialization "$i"&&{ echo 'ALREADY INITIALIZED';return 0;};return 1;fi;[ ! -e "$(sp "$r")" ]&&[ ! -e "$(kp "$r")" ]&&nr "$r"||return 1;c=$(gc);lo "$r" init "$c" - - - -||return 1;fm "$r"||return 1;a=$(om "$r");id "$l" "$r" "$a"||return 1;wa "$i" 'version=1\n'&&ul "$r" "$c"||return 1;echo 'LANE INITIALIZED';}
cs(){  l=$1;i=$2;a=$3;q=$4;r=$(lr "$l");cv "$@" >/dev/null||return $?;fm "$r"||return 1;[ "$(om "$r")" = "$a" ]||return 1;h=$(hh "$r");if [ "$h" != "$a" ];then if [ "$l" = main ];then git -C "$r" merge --ff-only origin/main >/dev/null;else sd "$r" "$a";fi||return 1;fi;git -C "$r" switch -c "$q" "$a" >/dev/null||return 1;echo STARTED;};st(){ local l i a q r c s; l=$1;i=$2;a=$3;q=$4;vr "$@" >/dev/null||return $?;r=$(lr "$l");c=$(gc);lo "$r" start "$c" "$i" "$q" "$a" -||return 1;s=$(sp "$r");mkdir "$s"||return 1;wa "$s/state" "version=1\nissue=$i\nbranch=$q\nbase=$a\nclaim=$c\n"||return 1;[ "${NUINUI_SELFTEST_CRASH_AT:-}" = start-after-slot ]&&return 97;cs "$@"||{ id "$l" "$r" "$a"&&! git -C "$r" show-ref --verify --quiet "refs/heads/$q"&&{ rm -rf "$s";ul "$r" "$c" >/dev/null 2>&1;};return 1;};ul "$r" "$c"||return 1;echo "  claim=$c";}
cr(){ local l i a h q c r m z x; l=$1;i=$2;a=$3;h=$4;q=$5;c=$6;r=$(lr "$l");set -- $(nuinui_ownership_parse_slot "$(sp "$r")/state")||return 1;[ "$1" = "$i" ]&&[ "$2" = "$q" ]&&[ "$3" = "$a" ]&&[ "$4" = "$c" ]||return 1;cn "$r"&&[ "$(git -C "$r" rev-parse "refs/heads/$q^{commit}" 2>/dev/null)" = "$h" ]&&[ "$(ab "$r" "$q")" = "$h" ]&&an "$r" "$a" "$h"&&[ -z "$(bo "$r" "$q")" ]||return 1;fm "$r"||return 1;m=$(om "$r");z=$(bn "$r");x=$(hh "$r");if [ "$z" != "$q" ]||[ "$x" != "$h" ];then case $l in main)[ "$z" = main ];;sub)[ -z "$z" ];;esac&&an "$r" "$x" "$m"&&[ "$(ab "$r" "$q")" = "$h" ]&&[ "$(am "$r")" = "$m" ]||return 1;git -C "$r" switch "$q" >/dev/null||return 1;fi;[ "$(hh "$r")" = "$h" ]&&cn "$r"||return 1;echo RESUMED;};rs(){ local l i a h q c r z x; l=$1;i=$2;a=$3;h=$4;q=$5;c=$6;il "$l"&&nuinui_ownership_valid_issue "$i"&&nuinui_ownership_valid_sha "$a"&&nuinui_ownership_valid_sha "$h"&&nuinui_ownership_valid_claim "$c"||return 2;r=$(lr "$l");set -- $(nuinui_ownership_parse_slot "$(sp "$r")/state")||return 1;[ "$1 $2 $3 $4" = "$i $q $a $c" ]&&[ ! -e "$(kp "$r")" ]&&nr "$r"||return 1;z=$(bn "$r");x=$(hh "$r");lo "$r" resume "$c" "$i" "$q" "$a" "$h"||return 1;cr "$l" "$i" "$a" "$h" "$q" "$c"||{ [ "$(bn "$r")" = "$z" ]&&[ "$(hh "$r")" = "$x" ]&&ul "$r" "$c" >/dev/null 2>&1;return 1;};ul "$r" "$c"||return 1;echo "  base=$a";echo "  claim=$c";}
pd(){ printf '%s\n' "$*" >&2; }
pdetail(){ [ -n "$1" ] && printf 'detail=%s\n' "$1" >&2; }
ps(){ "$GH" pr view "$1" -R "$PR" --json id,state,isDraft,baseRefName,baseRefOid,headRefOid,mergeable,autoMergeRequest,url --jq '[.id,.state,(.isDraft|tostring),.baseRefName,.baseRefOid,.headRefOid,.mergeable,(.autoMergeRequest.mergeMethod//"none"),.url]|@tsv'; }

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

pa(){ local p h m s c z b q check_out check_err check_rc;
p=$1;h=$2;m=$3
echo "$p"|grep -Eq '^[1-9][0-9]*$'&&nuinui_ownership_valid_sha "$h"&&nuinui_ownership_valid_sha "$m"||return 2
s=$(ps "$p" 2>&1);z=$?
if [ "$z" != 0 ];then pd 'ERROR: PR lookup/API failure';[ -n "$s" ]&&pdetail "$s";return 1;fi
set -- $s
if [ "$#" != 9 ];then pd 'ERROR: PR lookup returned invalid data';pdetail "$s";return 1;fi
[ -n "$1" ]||{ pd 'ERROR: PR lookup returned no pull request identity';return 1; }
if [ "$2" != OPEN ];then pd 'BLOCKED: PR is not OPEN';printf 'state=%s\n' "$2" >&2;return 1;fi
if [ "$3" != false ];then pd 'BLOCKED: PR is a draft';return 1;fi
if [ "$4" != main ];then pd 'BLOCKED: PR base branch mismatch';printf 'expected_base=main\nactual_base=%s\n' "$4" >&2;return 1;fi
if [ "$5" != "$m" ];then pd 'BLOCKED: expected main mismatch';printf 'expected_main=%s\nactual_base_oid=%s\n' "$m" "$5" >&2;return 1;fi
if [ "$6" != "$h" ];then pd 'BLOCKED: reviewed head mismatch';printf 'expected_head=%s\nactual_head=%s\n' "$h" "$6" >&2;return 1;fi
if [ "$7" != MERGEABLE ];then pd 'BLOCKED: PR mergeability is not acceptable or is ambiguous';printf 'mergeability=%s\n' "$7" >&2;return 1;fi
if [ "$8" != none ];then pd 'BLOCKED: Auto-merge already configured';printf 'method=%s\n' "$8" >&2;return 1;fi
check_out=$(mktemp /tmp/nuinui-pr-checks.XXXXXX 2>&1);z=$?
if [ "$z" != 0 ];then
  pd 'ERROR: unable to capture required-check output'
  [ -n "$check_out" ] && pdetail "$check_out"
  return 1
fi
check_err=$(mktemp /tmp/nuinui-pr-checks.XXXXXX 2>&1);check_rc=$?
if [ "$check_rc" != 0 ];then
  rm -f "$check_out"
  pd 'ERROR: unable to capture required-check diagnostics'
  [ -n "$check_err" ] && pdetail "$check_err"
  return 1
fi
"$GH" pr checks "$p" -R "$PR" --required --json name,bucket --jq '.[]|[.name,.bucket]|@tsv' >"$check_out" 2>"$check_err"
z=$?
case $z in
  0|1|8) ;;
  *)
    pd 'ERROR: required-check lookup/API failure'
    [ -s "$check_err" ] && pdetail "$(cat "$check_err")"
    rm -f "$check_out" "$check_err"
    return 1
    ;;
esac
if fb_parse_machine_rows "$check_out"; then
  rm -f "$check_out" "$check_err"
else
  fb "$h"
  rm -f "$check_out" "$check_err"
fi
case "$CHECK_STATE" in
  pending)
    echo "$s"
    return 0
    ;;
  pass)
    pd 'BLOCKED: all required checks are already complete'
    printf 'check_state=pass\n' >&2
    [ -z "$CHECK_DETAIL" ] || pdetail "$CHECK_DETAIL"
    return 1
    ;;
  fail)
    pd 'BLOCKED: required check is not pass or pending'
    printf 'check_state=fail\n' >&2
    [ -z "$CHECK_DETAIL" ] || pdetail "$CHECK_DETAIL"
    return 1
    ;;
  none-required)
    pd 'BLOCKED: no required checks are configured or active'
    printf 'check_state=none-required\n' >&2
    [ -z "$CHECK_DETAIL" ] || pdetail "$CHECK_DETAIL"
    return 1
    ;;
  required-checks-unresolved)
    pd 'BLOCKED: required-check evidence could not be resolved'
    printf 'check_state=required-checks-unresolved\n' >&2
    [ -z "$CHECK_DETAIL" ] || pdetail "$CHECK_DETAIL"
    return 1
    ;;
  api-error|*)
    pd 'ERROR: required-check lookup/API failure'
    printf 'check_state=api-error\n' >&2
    [ -z "$CHECK_DETAIL" ] || pdetail "$CHECK_DETAIL"
    return 1
    ;;
esac
}
pam(){ local p h m s i o z d a ar;
p=$1;h=$2;m=$3
d=$(mktemp "${TMPDIR:-/tmp}/nuinui-pam.XXXXXX" 2>&1);z=$?
if [ "$z" != 0 ];then pd 'ERROR: unable to capture Auto-merge precondition diagnostics';[ -n "$d" ]&&pdetail "$d";return 1;fi
s=$(pa "$p" "$h" "$m" 2>"$d");z=$?
if [ "$z" != 0 ];then
if [ "$z" = 2 ];then rm -f "$d";return 2;fi
if [ -s "$d" ];then cat "$d" >&2;else pd 'ERROR: Auto-merge precondition check failed without a diagnostic';fi
rm -f "$d";return 1
fi
rm -f "$d"
d=$(mktemp "${TMPDIR:-/tmp}/nuinui-pam.XXXXXX" 2>&1);z=$?
if [ "$z" != 0 ];then pd 'ERROR: unable to capture Auto-merge precondition diagnostics';[ -n "$d" ]&&pdetail "$d";return 1;fi
s=$(pa "$p" "$h" "$m" 2>"$d");z=$?
if [ "$z" != 0 ];then
pd 'BLOCKED: Auto-merge reservation precondition changed before mutation'
if [ "$z" = 2 ];then pd 'ERROR: Auto-merge precondition validator rejected the command arguments';elif [ -s "$d" ];then cat "$d" >&2;else pd 'ERROR: current precondition reason could not be determined';fi
rm -f "$d";return 1
fi
rm -f "$d"
set -- $s;i=$1
o=$("$GH" api graphql -f query='mutation($id:ID!,$h:GitObjectID!){enablePullRequestAutoMerge(input:{pullRequestId:$id,mergeMethod:MERGE,expectedHeadOid:$h}){clientMutationId}}' -f id="$i" -f h="$h" 2>&1);z=$?
if [ "$z" != 0 ];then
d=$(mktemp "${TMPDIR:-/tmp}/nuinui-pam.XXXXXX" 2>&1);ar=$?
if [ "$ar" = 0 ];then
a=$(pa "$p" "$h" "$m" 2>"$d");ar=$?
if [ "$ar" != 0 ]&&grep -q '^BLOCKED:' "$d";then cat "$d" >&2;rm -f "$d";return 1;fi
else
a=;pd 'ERROR: unable to capture fresh Auto-merge failure diagnosis';[ -n "$d" ]&&pdetail "$d"
fi
pd 'ERROR: Auto-merge reservation mutation failed';[ -n "$o" ]&&pdetail "$o"
if [ -s "$d" ];then pd 'fresh_diagnosis:';cat "$d" >&2;fi
rm -f "$d";return 1
fi
d=$(mktemp "${TMPDIR:-/tmp}/nuinui-pam.XXXXXX" 2>&1);z=$?
if [ "$z" != 0 ];then pd 'ERROR: unable to capture Auto-merge read-back diagnostics';[ -n "$d" ]&&pdetail "$d";return 1;fi
s=$(ps "$p" 2>"$d");z=$?
if [ "$z" != 0 ];then pd 'ERROR: Auto-merge reservation state could not be verified';[ -s "$d" ]&&{ pd 'read_back_detail:';cat "$d" >&2;};rm -f "$d";return 1;fi
set -- $s
if [ "$#" != 9 ];then pd 'ERROR: Auto-merge reservation read-back returned invalid PR data';pdetail "$s";rm -f "$d";return 1;fi
if [ "$1" != "$i" ]||[ "$2" != OPEN ]||[ "$3" != false ]||[ "$4" != main ]||[ "$5" != "$m" ]||[ "$6" != "$h" ]||[ "$8" != MERGE ];then
pd 'BLOCKED: Auto-merge reservation read-back mismatch'
printf 'expected_pr_id=%s\nexpected_state=OPEN\nexpected_draft=false\nexpected_base=main\nexpected_main=%s\nexpected_head=%s\nexpected_merge_method=MERGE\n' "$i" "$m" "$h" >&2
printf 'observed_pr_id=%s\nobserved_state=%s\nobserved_draft=%s\nobserved_base=%s\nobserved_base_oid=%s\nobserved_head=%s\nobserved_merge_method=%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$8" >&2
rm -f "$d";return 1
fi
rm -f "$d";echo 'AUTO-MERGE RESERVED'
}
dl(){ local l h q r z x d; l=$1;h=$2;q=$3;r=$(lr "$l");cn "$r"||return 1;z=$(bn "$r");x=$(hh "$r");d=;[ "$z" = "$q" ]&&[ "$x" = "$h" ]&&d=$q;if [ "$l" = main ];then [ "$z" = "$q" ]||[ "$z" = main ]||return 1;git -C "$r" switch main >/dev/null&&git -C "$r" merge --ff-only origin/main >/dev/null||return 1;else [ "$z" = "$q" ]||[ -z "$z" ]||return 1;[ "$x" = "$h" ]||git -C "$r" merge-base --is-ancestor "$x" origin/main||return 1;sd "$r" origin/main||return 1;fi;if [ -n "$d" ];then [ "$(git -C "$r" rev-parse "refs/heads/$d^{commit}" 2>/dev/null)" = "$h" ]&&[ -z "$(bo "$r" "$d")" ]&&git -C "$r" update-ref -d "refs/heads/$d" "$h"||return 1;fi;echo RELEASED;}
rl(){ local l h c r s i q a t; l=$1;h=$2;c=$3;il "$l"&&nuinui_ownership_valid_sha "$h"&&nuinui_ownership_valid_claim "$c"||return 2;r=$(lr "$l");s=$(sp "$r");set -- $(nuinui_ownership_parse_slot "$s/state")||return 1;i=$1;q=$2;a=$3;[ "$4" = "$c" ]&&[ "$(git -C "$r" rev-parse "refs/heads/$q^{commit}" 2>/dev/null)" = "$h" ]&&[ ! -e "$(kp "$r")" ]&&nr "$r"||return 1;lo "$r" release "$c" "$i" "$q" "$a" "$h"||return 1;fp "$r"&&git -C "$r" merge-base --is-ancestor "$h" origin/main||{ ul "$r" "$c";return 1;};wa "$s/checkpoint" "$h\n"||return 1;t=$(rp "$r" "$c");mv "$s" "$t"||return 1;[ "${NUINUI_SELFTEST_CRASH_AT:-}" = release-after-rename ]&&return 97;dl "$l" "$h" "$q"||return 1;rm "$t/checkpoint" "$t/state"&&rmdir "$t"&&ul "$r" "$c"||return 1;[ "${NUINUI_SELFTEST_STALE_RESULT:-}" = release ]&&return 98;echo "  claim=$c";}
rc(){ local l c r k s z n o i q a h m t; l=$1;c=$2;il "$l"&&nuinui_ownership_valid_claim "$c"||return 2;r=$(lr "$l");k=$(kp "$r");s=$(sp "$r");z=$(rds "$r");n=$(echo "$z"|grep -c .||true);if [ ! -e "$k" ];then [ "$n" = 1 ]&&set -- $(nuinui_ownership_parse_releasing "$z")&&[ "$4" = "$c" ]||return 1;lo "$r" release "$c" "$1" "$2" "$3" "$5"||return 1;fi;set -- $(nuinui_ownership_parse_lock "$k/state")||return 1;o=$1;i=$2;q=$3;a=$4;h=$5;[ "$6" = "$c" ]||return 1;case $o in init)fm "$r"||return 1;m=$(om "$r");id "$l" "$r" "$m"||return 1;[ -e "$(ip "$r")" ]||wa "$(ip "$r")" 'version=1\n';nuinui_ownership_validate_initialization "$(ip "$r")"&&ul "$r" "$c";;start)set -- $(nuinui_ownership_parse_slot "$s/state")||return 1;[ "$1 $2 $3 $4" = "$i $q $a $c" ]||return 1;if [ "$(bn "$r")" = "$q" ]&&[ "$(hh "$r")" = "$a" ]&&cn "$r";then ul "$r" "$c";else cs "$l" "$i" "$a" "$q" >/dev/null&&ul "$r" "$c";fi;;resume)cr "$l" "$i" "$a" "$h" "$q" "$c" >/dev/null&&ul "$r" "$c";;release)if [ "$n" = 0 ]&&[ -e "$s" ];then set -- $(nuinui_ownership_parse_slot "$s/state")||return 1;[ "$1 $2 $3 $4" = "$i $q $a $c" ]||return 1;if [ -f "$s/checkpoint" ];then [ "$(cat "$s/checkpoint")" = "$h" ]||return 1;else wa "$s/checkpoint" "$h\n"||return 1;fi;t=$(rp "$r" "$c");mv "$s" "$t"||return 1;elif [ "$n" = 1 ];then t=$z;else return 1;fi;set -- $(nuinui_ownership_parse_releasing "$t")||return 1;[ "$1 $2 $3 $4 $5" = "$i $q $a $c $h" ]||return 1;fp "$r"&&git -C "$r" merge-base --is-ancestor "$h" origin/main&&dl "$l" "$h" "$q" >/dev/null||return 1;rm "$t/checkpoint" "$t/state"&&rmdir "$t"&&ul "$r" "$c";;esac||return 1;echo "RECOVERED operation=$o";}
es(){  i=$1;f=$2;r=$E;nuinui_ownership_valid_issue "$i"&&gr "$r"&&ao "$r" "$RT"&&cn "$r"&&[ -z "$(bn "$r")" ]&&[ ! -e "$(mp "$r")" ]&&[ ! -e "$(ep "$r")" ]||return 1;fp "$r"||return 1;m=$(om "$r");x=$(hh "$r");[ "$x" = "$m" ]||{ an "$r" "$x" "$m"&&sd "$r" "$m";}||return 1;h=$(git -C "$r" rev-parse "$f^{commit}" 2>/dev/null)||return 1;sd "$r" "$h"&&printf 'issue=%s\nref=%s\n' "$i" "$h">"$(mp "$r")"||return 1;echo 'E2E STARTED';};el(){ i=$1;f=$2;nuinui_ownership_valid_issue "$i"&&nuinui_ownership_valid_sha "$f"&&fm "$M"&&[ "$(git -C "$M" branch --show-current)" = codex/interim-sequential ]&&cn "$M"&&[ "$(hh "$M")" = "$f" ]&&an "$M" "$(om "$M")" "$f"||return 1;es "$i" "$f";};ee(){  r=$E;k=$(mp "$r");[ -f "$k" ]&&[ ! -e "$(ep "$r")" ]&&cn "$r"&&[ -z "$(bn "$r")" ]||return 1;i=$(sed -n 's/^issue=//p' "$k");h=$(sed -n 's/^ref=//p' "$k");nuinui_ownership_valid_issue "$i"&&nuinui_ownership_valid_sha "$h"&&[ "$(hh "$r")" = "$h" ]||return 1;fp "$r"&&sd "$r" origin/main&&rm "$k"||return 1;echo 'E2E RELEASED';}
sy(){ gr "$C"&&ao "$C" "$CT"&&cn "$C"&&[ "$(bn "$C")" = main ]&&fp "$C"||return 1;an "$C" "$(hh "$C")" "$(om "$C")"&&git -C "$C" merge --ff-only origin/main >/dev/null||return 1;echo 'CONTEXT SYNCED';};dc(){ [ -d "$C" ]||{ echo 'dev-context=not-installed';return;};gr "$C"||return 1;echo "dev-context=$C branch=$(bn "$C") head=$(hh "$C") clean=$([ cn "$C" ]&&echo yes||echo no)";cn "$C";};doctor(){ [ $# = 0 ]||[ "$1" = --full ]||return 2;z=0;pf||z=1;[ "${1:-}" != --full ]||{ [ -x "$EH" ]&&NUINUI_E2E_PREPARE_WT="$E" "$EH" status||z=1;};dc||z=1;[ "$z" = 0 ];};cc(){ [ -d "$C" ]||return 1;z=0;find "$C" -type f -name '*.md'|while read -r f;do grep -oE '\]\([^)]+\)' "$f" 2>/dev/null|sed -E 's/^\]\(([^)#]+).*$/\1/'|while read -r x;do case $x in ''|'#'*|http://*|https://*|mailto:*)continue;;/*)t=$x;;*)t=$(dirname "$f")/$x;;esac;[ -e "$t" ]||exit 17;done||exit 17;grep -q 'ONLY-CHATGPT\.md' "$f"&&exit 17||:;done||z=1;for x in $K;do grep -q "\`nuinui $x" "$C/projects/nuinuiCAD/LOCAL-TOOLS.md"||z=1;done;echo "nuinui $V";[ "$z" = 0 ]&&{ echo 'CONTEXT CHECK PASS';return;};echo 'CONTEXT CHECK BLOCKED';return 1;};ta(){ p=$C/projects/nuinuiCAD/CODEX-ONLY-INTERIM.md;echo 'TRANSITION AUDIT (read-only)';grep -q 'Status: \*\*Active\*\*' "$p" 2>/dev/null||return 1;m=$(am "$M");nuinui_ownership_valid_sha "$m"&&[ "$(om "$M" 2>/dev/null)" = "$m" ]&&[ "$(bn "$M")" = codex/interim-sequential ]&&cn "$M"||return 1;h=$(hh "$M");an "$M" "$h" "$m" 2>/dev/null||[ -z "$(git -C "$M" cherry "$m" "$h"|grep '^+'||true)" ]||return 1;wt&&[ ! -e "$(mp "$E")" ]&&[ ! -e "$(ep "$E")" ]&&[ -x "$EH" ]&&NUINUI_E2E_PREPARE_WT="$E" "$EH" status||return 1;echo 'TRANSITION AUDIT PREPARED';}
T(){ local R O a f o c h;R=$(mktemp -d "${TMPDIR:-/tmp}/nui.XXXXXX")||return 1;trap 'rm -rf "$R"' EXIT;O=$R/o;M=$R/m;S=$R/s;E=$R/e;RT=;export GIT_AUTHOR_NAME=a GIT_AUTHOR_EMAIL=a@b GIT_COMMITTER_NAME=a GIT_COMMITTER_EMAIL=a@b;git init -q --bare "$O";git init -q -b main "$M";echo a>$M/a;git -C "$M" add a;git -C "$M" commit -qm a;git -C "$M" remote add origin "$O";git -C "$M" push -qu origin main;git -C "$M" worktree add -q --detach "$S" origin/main;git -C "$M" worktree add -q --detach "$E" origin/main;a=$(om "$M");pf >/dev/null 2>&1&&return 1;li main >/dev/null&&li sub >/dev/null||return 1;f=$R/x;printf 'version=2\n'>$f;nuinui_ownership_validate_initialization "$f"&&return 1;o=$(st main SAY-9 "$a" x/say-9-a)||return 1;c=$(echo "$o"|sed -n 's/^  claim=//p');echo b>>$M/a;git -C "$M" add a;git -C "$M" commit -qm b;h=$(hh "$M");rl main "$h" "$c" >/dev/null 2>&1&&return 1;git -C "$M" push -q origin HEAD:main;rl main "$h" "$c" >/dev/null||return 1;echo 'SELFTEST PASS';}
