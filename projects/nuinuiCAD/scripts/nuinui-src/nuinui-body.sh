V=1.6.7;P=$0;D=$(CDPATH= cd -- "$(dirname -- "$P")"&&pwd -P);EH=${NUINUI_E2E_STATUS_HELPER:-$D/nuinui-e2e-prepare}
if [ "${NUINUI_SELFTEST:-0}" = 1 ];then M=${NUINUI_MAIN_WT:?};S=${NUINUI_SUB_WT:?};E=${NUINUI_E2E_WT:?};C=${NUINUI_DEV_CONTEXT_WT:-};RT=;CT=;else M=/Users/yosomi/Code/nuinuiCAD;S=/Users/yosomi/Code/nuinuiCAD-sub;E=/Users/yosomi/Code/nuinuiCAD-e2e;C=/Users/yosomi/Code/dev-context;RT=sayosomi/nuinuiCAD;CT=sayosomi/dev-context;fi
if [ "${NUINUI_SELFTEST:-0}" = 1 ];then CD=${NUINUI_DEV_CONTEXT_DEV_WT:-};[ -z "${NUINUI_SELFTEST_EXPECTED_ORIGIN:-}" ]||CT=$NUINUI_SELFTEST_EXPECTED_ORIGIN;else CD=/Users/yosomi/Code/dev-context-dev;fi
lr(){ case $1 in main)echo "$M";;sub)echo "$S";;e2e)echo "$E";;*)return 2;;esac;};il(){ case $1 in main|sub);;*)return 2;;esac;};gr(){ [ -d "$1" ]&&git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1;};ao(){ [ -z "$2" ]||git -C "$1" remote get-url origin 2>/dev/null|grep -Fq "$2";};cn(){ [ -z "$(git -C "$1" status --porcelain)" ];};bn(){ git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null||true;};hh(){ git -C "$1" rev-parse HEAD;};om(){ git -C "$1" rev-parse origin/main;};fm(){ git -C "$1" fetch origin main >/dev/null 2>&1;};fp(){ git -C "$1" fetch origin --prune >/dev/null 2>&1;};an(){ git -C "$1" merge-base --is-ancestor "$2" "$3";};sd(){ git -C "$1" switch --detach "$2" >/dev/null;};gd(){ git -C "$1" rev-parse --absolute-git-dir 2>/dev/null;};ip(){ echo "$(gd "$1")/nuinui-implementation-v1";};sp(){ echo "$(gd "$1")/nuinui-implementation-slot";};kp(){ echo "$(gd "$1")/nuinui-implementation-lock";};rp(){ echo "$(gd "$1")/nuinui-implementation-slot.releasing.$2";};rds(){ find "$(gd "$1")" -maxdepth 1 -type d -name 'nuinui-implementation-slot.releasing.*' -print 2>/dev/null|sort;};mp(){ echo "$(gd "$1")/nuinui-slot";};ep(){ echo "$(gd "$1")/nuinui-e2e-session";}
wa(){  t=${1}.tmp.$$;(umask 077;printf '%b' "$2">"$t")&&mv -- "$t" "$1";};gc(){ command -v uuidgen >/dev/null 2>&1&&uuidgen|tr A-Z a-z||printf '%s:%s:%s\n' $$ "$(date +%s)" "${RANDOM:-0}"|git hash-object --stdin;};lo(){  k=$(kp "$1");mkdir "$k" 2>/dev/null||return 1;wa "$k/state" "version=1\noperation=$2\nissue=$4\nbranch=$5\nbase=$6\ncheckpoint=$7\nclaim=$3\n";};ul(){ r=$1;e=$2;set -- $(nuinui_ownership_parse_lock "$(kp "$r")/state")||return 1;[ "$6" = "$e" ]&&rm "$(kp "$r")/state"&&rmdir "$(kp "$r")";};am(){ git -C "$1" ls-remote origin refs/heads/main 2>/dev/null|awk 'NR==1{print $1}';};ab(){ git -C "$1" ls-remote --heads origin "refs/heads/$2" 2>/dev/null|awk 'NR==1{print $1}';};id(){ local r a q; r=$2;a=$3;cn "$r"&&[ "$(hh "$r")" = "$a" ]||return 1;q=$(bn "$r");case $1 in main)[ "$q" = main ];;sub)[ -z "$q" ];;esac;};nr(){ [ -z "$(rds "$1")" ];};bo(){  x=$(CDPATH= cd -- "$1"&&pwd -P);git -C "$1" worktree list --porcelain|awk -v b="refs/heads/$2" -v x="$x" '/^worktree /{p=substr($0,10)}/^branch /&&substr($0,8)==b&&p!=x{print p;exit}';}
release_restore_checkout() {
  local l r i q a c h b x m n n2 m2 t
  l=$1
  r=$2
  q=$3
  a=$4
  h=$5

  [ -e "$(sp "$r")/state" ] || return 1
  set -- $(nuinui_ownership_parse_slot "$(sp "$r")/state") || return 1
  i=$1
  c=$4
  [ "$1 $2 $3 $4" = "$i $q $a $c" ] || return 1
  set -- $(nuinui_ownership_parse_lock "$(kp "$r")/state") || return 1
  [ "$1 $2 $3 $4 $5 $6" = "release $i $q $a $h $c" ] || return 1
  nr "$r" || return 1

  b=$(bn "$r")
  x=$(hh "$r" 2>/dev/null) || return 1
  if [ "$b" = "$q" ] && [ "$x" = "$h" ]; then
    [ -z "$(git -C "$r" status --porcelain 2>/dev/null)" ] || return 1
    [ -z "$(bo "$r" "$q")" ] || return 1
    return 0
  fi

  [ -z "$(git -C "$r" status --porcelain 2>/dev/null)" ] || return 1
  case "$l" in
    main) [ "$b" = main ] || return 1 ;;
    sub) [ -z "$b" ] || return 1 ;;
    *) return 1 ;;
  esac
  nuinui_ownership_valid_sha "$x" || return 1

  fp "$r" || return 1
  m=$(om "$r" 2>/dev/null) || return 1
  nuinui_ownership_valid_sha "$m" || return 1
  an "$r" "$x" "$m" || return 1
  an "$r" "$h" "$m" || return 1
  [ "$a" = "$h" ] || an "$r" "$a" "$h" || return 1
  t=$(git -C "$r" rev-parse "refs/heads/$q^{commit}" 2>/dev/null) || return 1
  [ "$t" = "$h" ] || return 1
  [ -z "$(bo "$r" "$q")" ] || return 1
  n=$(rt "$r" "$q" "$h") || return 1

  fp "$r" || return 1
  m2=$(om "$r" 2>/dev/null) || return 1
  [ "$m2" = "$m" ] || return 1
  n2=$(rt "$r" "$q" "$h") || return 1
  [ "$n2" = "$n" ] || return 1
  b=$(bn "$r")
  x=$(hh "$r" 2>/dev/null) || return 1
  [ -z "$(git -C "$r" status --porcelain 2>/dev/null)" ] || return 1
  case "$l" in
    main) [ "$b" = main ] || return 1 ;;
    sub) [ -z "$b" ] || return 1 ;;
    *) return 1 ;;
  esac
  an "$r" "$x" "$m2" || return 1
  an "$r" "$h" "$m2" || return 1
  t=$(git -C "$r" rev-parse "refs/heads/$q^{commit}" 2>/dev/null) || return 1
  [ "$t" = "$h" ] || return 1
  [ -z "$(bo "$r" "$q")" ] || return 1

  git -C "$r" switch "$q" >/dev/null || return 1
  [ "$(bn "$r")" = "$q" ] && [ "$(hh "$r")" = "$h" ] && cn "$r" || return 1
}
cl(){ local l r i s k q h d z n a;l=$1;r=$2;i=$(ip "$r");s=$(sp "$r");k=$(kp "$r");q=$(bn "$r");h=$(git -C "$r" rev-parse HEAD 2>/dev/null||true);d=$(git -C "$r" status --porcelain 2>/dev/null);echo "$l path=$r";echo "  branch=${q:-DETACHED}";echo "  head=$h";echo "  clean=$([ -z "$d" ]&&echo yes||echo no)";if [ -e "$k" ];then set -- $(nuinui_ownership_parse_lock "$k/state");[ $# = 6 ]&&echo "  state=BLOCKED reason=mutation-in-progress operation=$1 claim=$6"||echo '  state=BLOCKED reason=invalid-mutation-lock';return 1;fi;z=$(rds "$r");n=$(echo "$z"|grep -c .||true);if [ -e "$s" ];then [ "$n" = 0 ]||{ echo '  state=BLOCKED reason=active-and-releasing-state-coexist';return 1;};set -- $(nuinui_ownership_parse_slot "$s/state");[ $# = 4 ]||{ echo '  state=BLOCKED reason=invalid-active-slot';return 1;};echo "  owner_issue=$1 owner_branch=$2 base=$3 claim=$4";[ "$q" = "$2" ]&&an "$r" "$3" "$h" 2>/dev/null||{ echo '  state=BLOCKED reason=claim-checkout-mismatch';return 1;};echo '  state=BUSY';return 0;fi;if [ "$n" != 0 ];then [ "$n" = 1 ]||{ echo '  state=BLOCKED reason=multiple-release-states';return 1;};set -- $(nuinui_ownership_parse_releasing "$z");[ $# = 5 ]||{ echo '  state=BLOCKED reason=invalid-release-state';return 1;};echo "  state=RELEASE-PENDING claim=$4 checkpoint=$5";return 0;fi;nuinui_ownership_validate_initialization "$i"||{ echo '  state=BLOCKED reason=durable-ownership-initialization-required';return 1;};a=$(am "$r");nuinui_ownership_valid_sha "$a"&&id "$l" "$r" "$a"||{ echo "  state=BLOCKED reason=invalid-idle-state origin_main=$a";return 1;};echo "  state=FREE origin_main=$a";}
wt(){ a=$(printf "%s\n" "$(CDPATH= cd -- "$M"&&pwd -P)" "$(CDPATH= cd -- "$S"&&pwd -P)" "$(CDPATH= cd -- "$E"&&pwd -P)"|sort)||return 1;t=$(git -C "$M" worktree list --porcelain|sed -n "s/^worktree //p"|sort);echo worktrees:;git -C "$M" worktree list|sed "s/^/  /";[ "$a" = "$t" ];};pf(){  z=0;gr "$M"&&cl main "$M"||z=1;gr "$S"&&cl sub "$S"||z=1;echo "e2e path=$E";gr "$E"||z=1;if [ "$z" = 0 ];then q=$(bn "$E");d=$(git -C "$E" status --porcelain);echo "  branch=${q:-DETACHED}";echo "  head=$(hh "$E")";echo "  clean=$([ -z "$d" ]&&echo yes||echo no) marker=$([ -f "$(mp "$E")" ]&&echo present||echo none)";[ ! -f "$(mp "$E")" ]||sed "s/^/    /" "$(mp "$E")";[ -z "$d" ]||z=1;fi;wt||z=1;[ "$z" = 0 ]&&{ echo 'PREFLIGHT PASS';return 0;};echo 'PREFLIGHT BLOCKED';return 1;}
cv(){ local l i a q r z h; l=$1;i=$2;a=$3;q=$4;il "$l"&&nuinui_ownership_valid_issue "$i"&&nuinui_ownership_valid_sha "$a"&&nuinui_ownership_validate_issue_branch "$i" "$q"||return 2;r=$(lr "$l");gr "$r"&&ao "$r" "$RT"&&cn "$r"||return 1;z=$(bn "$r");case $l in main)[ "$z" = main ];;sub)[ -z "$z" ];;esac||return 1;fm "$r"&&[ "$(om "$r")" = "$a" ]||return 1;git -C "$r" show-ref --verify --quiet "refs/heads/$q"&&return 1;[ -z "$(ab "$r" "$q")" ]||return 1;h=$(hh "$r");[ "$h" = "$a" ]||an "$r" "$h" "$a"||return 1;echo VERIFIED;};vr(){  r=$(lr "$1")||return 2;nuinui_ownership_validate_initialization "$(ip "$r")"&&[ ! -e "$(sp "$r")" ]&&[ ! -e "$(kp "$r")" ]&&nr "$r"||return 1;cv "$@";};li(){  l=$1;il "$l"||return;r=$(lr "$l");gr "$r"&&ao "$r" "$RT"||return 1;i=$(ip "$r");if [ -e "$i" ];then nuinui_ownership_validate_initialization "$i"&&{ echo 'ALREADY INITIALIZED';return 0;};return 1;fi;[ ! -e "$(sp "$r")" ]&&[ ! -e "$(kp "$r")" ]&&nr "$r"||return 1;c=$(gc);lo "$r" init "$c" - - - -||return 1;fm "$r"||return 1;a=$(om "$r");id "$l" "$r" "$a"||return 1;wa "$i" 'version=1\n'&&ul "$r" "$c"||return 1;echo 'LANE INITIALIZED';}
cs(){  l=$1;i=$2;a=$3;q=$4;r=$(lr "$l");cv "$@" >/dev/null||return $?;fm "$r"||return 1;[ "$(om "$r")" = "$a" ]||return 1;h=$(hh "$r");if [ "$h" != "$a" ];then if [ "$l" = main ];then git -C "$r" merge --ff-only origin/main >/dev/null;else sd "$r" "$a";fi||return 1;fi;git -C "$r" switch -c "$q" "$a" >/dev/null||return 1;echo STARTED;};st(){ local l i a q r c s; l=$1;i=$2;a=$3;q=$4;vr "$@" >/dev/null||return $?;r=$(lr "$l");c=$(gc);lo "$r" start "$c" "$i" "$q" "$a" -||return 1;s=$(sp "$r");mkdir "$s"||return 1;wa "$s/state" "version=1\nissue=$i\nbranch=$q\nbase=$a\nclaim=$c\n"||return 1;[ "${NUINUI_SELFTEST_CRASH_AT:-}" = start-after-slot ]&&return 97;cs "$@"||{ id "$l" "$r" "$a"&&! git -C "$r" show-ref --verify --quiet "refs/heads/$q"&&{ rm -rf "$s";ul "$r" "$c" >/dev/null 2>&1;};return 1;};ul "$r" "$c"||return 1;echo "  claim=$c";}
rt(){ local r q h t s remote_head remote_ref; r=$1;q=$2;h=$3;t=$(git -C "$r" ls-remote --exit-code --heads origin "refs/heads/$q" 2>/dev/null);s=$?;case $s in 0)remote_head=$(printf '%s\n' "$t"|awk 'NR==1{print $1}');remote_ref=$(printf '%s\n' "$t"|awk 'NR==1{print $2}');[ "$remote_head" = "$h" ]&&[ "$remote_ref" = "refs/heads/$q" ]&&[ -z "$(printf '%s\n' "$t"|awk 'NR>1{print}')" ]||return 1;echo pushed;;2)[ -z "$t" ]&&echo absent||return 1;;*)return 1;;esac;};
cr(){ local l i a h q c r mode m z x; l=$1;i=$2;a=$3;h=$4;q=$5;c=$6;r=$(lr "$l");set -- $(nuinui_ownership_parse_slot "$(sp "$r")/state")||return 1;[ "$1" = "$i" ]&&[ "$2" = "$q" ]&&[ "$3" = "$a" ]&&[ "$4" = "$c" ]||return 1;cn "$r"&&[ "$(git -C "$r" rev-parse "refs/heads/$q^{commit}" 2>/dev/null)" = "$h" ]&&an "$r" "$a" "$h"&&[ -z "$(bo "$r" "$q")" ]||return 1;mode=$(rt "$r" "$q" "$h")||return 1;if [ "$mode" = absent ];then [ "$h" = "$a" ]||return 1;fi;fm "$r"||return 1;m=$(om "$r");z=$(bn "$r");x=$(hh "$r");if [ "$z" != "$q" ]||[ "$x" != "$h" ];then case $l in main)[ "$z" = main ];;sub)[ -z "$z" ];;esac&&an "$r" "$x" "$m"&&[ "$(am "$r")" = "$m" ]&&[ "$(rt "$r" "$q" "$h")" = "$mode" ]||return 1;git -C "$r" switch "$q" >/dev/null||return 1;fi;[ "$(hh "$r")" = "$h" ]&&cn "$r"||return 1;echo RESUMED;};
rs(){ local l i a h q c r z x; l=$1;i=$2;a=$3;h=$4;q=$5;c=$6;il "$l"&&nuinui_ownership_valid_issue "$i"&&nuinui_ownership_valid_sha "$a"&&nuinui_ownership_valid_sha "$h"&&nuinui_ownership_valid_claim "$c"||return 2;r=$(lr "$l");set -- $(nuinui_ownership_parse_slot "$(sp "$r")/state")||return 1;[ "$1 $2 $3 $4" = "$i $q $a $c" ]&&[ ! -e "$(kp "$r")" ]&&nr "$r"||return 1;z=$(bn "$r");x=$(hh "$r");lo "$r" resume "$c" "$i" "$q" "$a" "$h"||return 1;cr "$l" "$i" "$a" "$h" "$q" "$c"||{ [ "$(bn "$r")" = "$z" ]&&[ "$(hh "$r")" = "$x" ]&&ul "$r" "$c" >/dev/null 2>&1;return 1;};ul "$r" "$c"||return 1;echo "  base=$a";echo "  claim=$c";}
dl(){ local l h q r z x d; l=$1;h=$2;q=$3;r=$(lr "$l");cn "$r"||return 1;z=$(bn "$r");x=$(hh "$r");d=;[ "$z" = "$q" ]&&[ "$x" = "$h" ]&&d=$q;if [ "$l" = main ];then [ "$z" = "$q" ]||[ "$z" = main ]||return 1;git -C "$r" switch main >/dev/null&&git -C "$r" merge --ff-only origin/main >/dev/null||return 1;else [ "$z" = "$q" ]||[ -z "$z" ]||return 1;[ "$x" = "$h" ]||git -C "$r" merge-base --is-ancestor "$x" origin/main||return 1;sd "$r" origin/main||return 1;fi;if [ -n "$d" ];then [ "$(git -C "$r" rev-parse "refs/heads/$d^{commit}" 2>/dev/null)" = "$h" ]&&[ -z "$(bo "$r" "$d")" ]&&git -C "$r" update-ref -d "refs/heads/$d" "$h"||return 1;fi;echo RELEASED;}
rl(){ local l h c r s i q a t; l=$1;h=$2;c=$3;il "$l"&&nuinui_ownership_valid_sha "$h"&&nuinui_ownership_valid_claim "$c"||return 2;r=$(lr "$l");s=$(sp "$r");set -- $(nuinui_ownership_parse_slot "$s/state")||return 1;i=$1;q=$2;a=$3;[ "$4" = "$c" ]&&[ "$(git -C "$r" rev-parse "refs/heads/$q^{commit}" 2>/dev/null)" = "$h" ]&&[ ! -e "$(kp "$r")" ]&&nr "$r"||return 1;lo "$r" release "$c" "$i" "$q" "$a" "$h"||return 1;release_restore_checkout "$l" "$r" "$q" "$a" "$h"||{ ul "$r" "$c";return 1;};fp "$r"&&git -C "$r" merge-base --is-ancestor "$h" origin/main||{ ul "$r" "$c";return 1;};wa "$s/checkpoint" "$h\n"||return 1;t=$(rp "$r" "$c");mv "$s" "$t"||return 1;[ "${NUINUI_SELFTEST_CRASH_AT:-}" = release-after-rename ]&&return 97;dl "$l" "$h" "$q"||return 1;rm "$t/checkpoint" "$t/state"&&rmdir "$t"&&ul "$r" "$c"||return 1;[ "${NUINUI_SELFTEST_STALE_RESULT:-}" = release ]&&return 98;echo "  claim=$c";}
rc(){ local l c r k s z n o i q a h m t; l=$1;c=$2;il "$l"&&nuinui_ownership_valid_claim "$c"||return 2;r=$(lr "$l");k=$(kp "$r");s=$(sp "$r");z=$(rds "$r");n=$(echo "$z"|grep -c .||true);if [ ! -e "$k" ];then [ "$n" = 1 ]&&set -- $(nuinui_ownership_parse_releasing "$z")&&[ "$4" = "$c" ]||return 1;lo "$r" release "$c" "$1" "$2" "$3" "$5"||return 1;fi;set -- $(nuinui_ownership_parse_lock "$k/state")||return 1;o=$1;i=$2;q=$3;a=$4;h=$5;[ "$6" = "$c" ]||return 1;case $o in init)fm "$r"||return 1;m=$(om "$r");id "$l" "$r" "$m"||return 1;[ -e "$(ip "$r")" ]||wa "$(ip "$r")" 'version=1\n';nuinui_ownership_validate_initialization "$(ip "$r")"&&ul "$r" "$c";;start)set -- $(nuinui_ownership_parse_slot "$s/state")||return 1;[ "$1 $2 $3 $4" = "$i $q $a $c" ]||return 1;if [ "$(bn "$r")" = "$q" ]&&[ "$(hh "$r")" = "$a" ]&&cn "$r";then ul "$r" "$c";else cs "$l" "$i" "$a" "$q" >/dev/null&&ul "$r" "$c";fi;;resume)cr "$l" "$i" "$a" "$h" "$q" "$c" >/dev/null&&ul "$r" "$c";;release)if [ "$n" = 0 ]&&[ -e "$s" ];then set -- $(nuinui_ownership_parse_slot "$s/state")||return 1;[ "$1 $2 $3 $4" = "$i $q $a $c" ]||return 1;if [ -f "$s/checkpoint" ];then [ "$(cat "$s/checkpoint")" = "$h" ]||return 1;else wa "$s/checkpoint" "$h\n"||return 1;fi;t=$(rp "$r" "$c");mv "$s" "$t"||return 1;elif [ "$n" = 1 ];then t=$z;else return 1;fi;set -- $(nuinui_ownership_parse_releasing "$t")||return 1;[ "$1 $2 $3 $4 $5" = "$i $q $a $c $h" ]||return 1;fp "$r"&&git -C "$r" merge-base --is-ancestor "$h" origin/main&&dl "$l" "$h" "$q" >/dev/null||return 1;rm "$t/checkpoint" "$t/state"&&rmdir "$t"&&ul "$r" "$c";;esac||return 1;echo "RECOVERED operation=$o";}
