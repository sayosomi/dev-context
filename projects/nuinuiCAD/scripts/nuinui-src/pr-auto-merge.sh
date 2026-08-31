pd(){ printf '%s\n' "$*" >&2; }
pdetail(){ [ -n "$1" ] && printf 'detail=%s\n' "$1" >&2; }
pa(){ local p h m mode s c z b q check_out check_err check_rc actual_main integration integration_status integrated_base compare_base merge_base ahead_by behind_by already_reserved;
p=$1;h=$2;m=$3;mode=$4
echo "$p"|grep -Eq '^[1-9][0-9]*$'&&nuinui_ownership_valid_sha "$h"&&nuinui_ownership_valid_sha "$m"||return 2
s=$(ps "$p" 2>&1);z=$?
if [ "$z" != 0 ];then pd 'ERROR: PR lookup/API failure';[ -n "$s" ]&&pdetail "$s";return 1;fi
set -- $s
if [ "$#" != 9 ];then pd 'ERROR: PR lookup returned invalid data';pdetail "$s";return 1;fi
[ -n "$1" ]||{ pd 'ERROR: PR lookup returned no pull request identity';return 1; }
if [ "$2" != OPEN ];then pd 'BLOCKED: PR is not OPEN';printf 'state=%s\n' "$2" >&2;return 1;fi
if [ "$3" != false ];then pd 'BLOCKED: PR is a draft';return 1;fi
if [ "$4" != main ];then pd 'BLOCKED: PR base branch mismatch';printf 'expected_base=main\nactual_base=%s\n' "$4" >&2;return 1;fi
if [ "$6" != "$h" ];then pd 'BLOCKED: reviewed head mismatch';printf 'expected_head=%s\nactual_head=%s\n' "$h" "$6" >&2;return 1;fi
if [ "$7" != MERGEABLE ];then pd 'BLOCKED: PR mergeability is not acceptable or is ambiguous';printf 'mergeability=%s\n' "$7" >&2;return 1;fi
case "$8" in
  none) already_reserved=0 ;;
  MERGE)
    case "$9" in
      */pull/"$p") ;;
      *) pd 'BLOCKED: PR number mismatch';printf 'expected_pr=%s\nactual_url=%s\n' "$p" "$9" >&2;return 1;;
    esac
    already_reserved=1
    ;;
  *) pd 'BLOCKED: Auto-merge already configured';printf 'method=%s\n' "$8" >&2;return 1 ;;
esac
integrated_base=$5
actual_main=$(cm 2>&1);z=$?
if [ "$z" != 0 ]||! nuinui_ownership_valid_sha "$actual_main";then pd 'ERROR: current main lookup/API failure';[ -n "$actual_main" ]&&pdetail "$actual_main";return 1;fi
if [ "$actual_main" != "$m" ];then pd 'BLOCKED: expected main mismatch';printf 'expected_main=%s\nactual_main=%s\n' "$m" "$actual_main" >&2;return 1;fi
integration=$(ci "$m" "$h" 2>&1);z=$?
if [ "$z" != 0 ];then pd 'ERROR: PR integration lookup/API failure';[ -n "$integration" ]&&pdetail "$integration";return 1;fi
set -- $integration
if [ "$#" != 5 ]||! nuinui_ownership_valid_sha "$2"||! nuinui_ownership_valid_sha "$3";then pd 'ERROR: PR integration lookup returned invalid data';pdetail "$integration";return 1;fi
integration_status=$1;compare_base=$2;merge_base=$3;ahead_by=$4;behind_by=$5
case "$ahead_by" in ''|*[!0-9]*) pd 'ERROR: PR integration lookup returned invalid data';pdetail "$integration";return 1;; esac
case "$behind_by" in ''|*[!0-9]*) pd 'ERROR: PR integration lookup returned invalid data';pdetail "$integration";return 1;; esac
if { [ "$integration_status" != ahead ]&&[ "$integration_status" != identical ]; }||[ "$compare_base" != "$m" ]||[ "$merge_base" != "$m" ]||[ "$behind_by" != 0 ];then
  pd 'BLOCKED: PR is behind current main; integration required'
  printf 'expected_main=%s\nreviewed_head=%s\nintegrated_base=%s\n' "$m" "$h" "$integrated_base" >&2
  return 1
fi
if [ "$already_reserved" = 1 ];then
  [ "$mode" = initial ] || { pd 'BLOCKED: Auto-merge reservation precondition changed before mutation';return 1; }
  printf '%s\n' 'AUTO-MERGE ALREADY RESERVED'
  printf 'pr=%s\n' "$p"
  printf 'head=%s\n' "$h"
  printf 'main=%s\n' "$m"
  printf 'merge_method=MERGE\n'
  printf 'mutation=no-op\n'
  return 3
fi
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
s=$(pa "$p" "$h" "$m" initial 2>"$d");z=$?
if [ "$z" = 3 ];then rm -f "$d";printf '%s\n' "$s";return 0;fi
if [ "$z" != 0 ];then
if [ "$z" = 2 ];then rm -f "$d";return 2;fi
if [ -s "$d" ];then cat "$d" >&2;else pd 'ERROR: Auto-merge precondition check failed without a diagnostic';fi
rm -f "$d";return 1
fi
rm -f "$d"
d=$(mktemp "${TMPDIR:-/tmp}/nuinui-pam.XXXXXX" 2>&1);z=$?
if [ "$z" != 0 ];then pd 'ERROR: unable to capture Auto-merge precondition diagnostics';[ -n "$d" ]&&pdetail "$d";return 1;fi
s=$(pa "$p" "$h" "$m" revalidate 2>"$d");z=$?
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
a=$(pa "$p" "$h" "$m" revalidate 2>"$d");ar=$?
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
if [ "$1" != "$i" ]||[ "$2" != OPEN ]||[ "$3" != false ]||[ "$4" != main ]||[ "$6" != "$h" ]||[ "$8" != MERGE ];then
pd 'BLOCKED: Auto-merge reservation read-back mismatch'
printf 'expected_pr_id=%s\nexpected_state=OPEN\nexpected_draft=false\nexpected_base=main\nexpected_main=%s\nexpected_head=%s\nexpected_merge_method=MERGE\n' "$i" "$m" "$h" >&2
printf 'observed_pr_id=%s\nobserved_state=%s\nobserved_draft=%s\nobserved_base=%s\nobserved_base_oid=%s\nobserved_head=%s\nobserved_merge_method=%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$8" >&2
rm -f "$d";return 1
fi
actual_main=$(cm 2>&1);z=$?
if [ "$z" != 0 ]||! nuinui_ownership_valid_sha "$actual_main";then
  pd 'ERROR: authoritative current main read-back failed'
  [ -n "$actual_main" ]&&pdetail "$actual_main"
  rm -f "$d";return 1
fi
if [ "$actual_main" != "$m" ];then
  pd 'BLOCKED: Auto-merge reservation read-back main mismatch'
  printf 'expected_main=%s\nactual_main=%s\n' "$m" "$actual_main" >&2
  rm -f "$d";return 1
fi
rm -f "$d"
printf '%s\n' 'AUTO-MERGE RESERVED'
printf 'pr=%s\n' "$p"
printf 'head=%s\n' "$h"
printf 'main=%s\n' "$m"
printf 'merge_method=MERGE\n'
}
