# Project-independent fixed 2+1 implementation lifecycle primitives.
# The short helper names below are retained for the existing standalone CLI
# callers; their lane and repository semantics come from the profile.

fixed_2plus1_profile_guard() {
  fixed_2plus1_profile_contract_ready
}

lr() { fixed_2plus1_profile_lane_path "$1"; }
il() { fixed_2plus1_profile_is_implementation_lane "$1"; }
gr() { [ -d "$1" ] && git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; }
ao() {
  fixed_2plus1_profile_origin_matches "$1" "$2"
}
cn() { [ -z "$(git -C "$1" status --porcelain)" ]; }
bn() { git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null || true; }
hh() { git -C "$1" rev-parse HEAD; }
om() { git -C "$1" rev-parse "origin/$(fixed_2plus1_profile_default_branch)"; }
fm() { git -C "$1" fetch origin "$(fixed_2plus1_profile_default_branch)" >/dev/null 2>&1; }
fp() { git -C "$1" fetch origin --prune >/dev/null 2>&1; }
an() { git -C "$1" merge-base --is-ancestor "$2" "$3"; }
sd() { git -C "$1" switch --detach "$2" >/dev/null; }
gd() { git -C "$1" rev-parse --absolute-git-dir 2>/dev/null; }
ip() { printf '%s/nuinui-implementation-v1\n' "$(gd "$1")"; }
sp() { printf '%s/nuinui-implementation-slot\n' "$(gd "$1")"; }
kp() { printf '%s/nuinui-implementation-lock\n' "$(gd "$1")"; }
rp() { printf '%s/nuinui-implementation-slot.releasing.%s\n' "$(gd "$1")" "$2"; }
rds() {
  find "$(gd "$1")" -maxdepth 1 -type d \
    -name 'nuinui-implementation-slot.releasing.*' -print 2>/dev/null | sort
}
mp() { fixed_2plus1_profile_human_test_marker_path "$1"; }
ep() { fixed_2plus1_profile_human_test_session_path "$1"; }

wa() {
  fixed_2plus1_write_target=$1.tmp.$$
  (umask 077; printf '%b' "$2" >"$fixed_2plus1_write_target") &&
    mv -- "$fixed_2plus1_write_target" "$1"
}

gc() {
  command -v uuidgen >/dev/null 2>&1 && uuidgen | tr A-Z a-z ||
    printf '%s:%s:%s\n' $$ "$(date +%s)" "${RANDOM:-0}" | git hash-object --stdin
}

lo() {
  fixed_2plus1_lock_dir=$(kp "$1")
  mkdir "$fixed_2plus1_lock_dir" 2>/dev/null || return 1
  wa "$fixed_2plus1_lock_dir/state" \
    "version=1\noperation=$2\nissue=$4\nbranch=$5\nbase=$6\ncheckpoint=$7\nclaim=$3\n"
}

ul() {
  fixed_2plus1_unlock_repo=$1
  fixed_2plus1_unlock_claim=$2
  set -- $(nuinui_ownership_parse_lock "$(kp "$fixed_2plus1_unlock_repo")/state") || return 1
  [ "$6" = "$fixed_2plus1_unlock_claim" ] || return 1
  rm "$(kp "$fixed_2plus1_unlock_repo")/state" &&
    rmdir "$(kp "$fixed_2plus1_unlock_repo")"
}

am() {
  git -C "$1" ls-remote origin \
    "refs/heads/$(fixed_2plus1_profile_default_branch)" 2>/dev/null |
    awk 'NR == 1 {print $1}'
}

ab() {
  git -C "$1" ls-remote --heads origin "refs/heads/$2" 2>/dev/null |
    awk 'NR == 1 {print $1}'
}

id() {
  fixed_2plus1_idle_lane=$1
  fixed_2plus1_idle_repo=$2
  fixed_2plus1_idle_head=$3
  cn "$fixed_2plus1_idle_repo" || return 1
  [ "$(hh "$fixed_2plus1_idle_repo")" = "$fixed_2plus1_idle_head" ] || return 1
  case "$(fixed_2plus1_profile_idle_checkout_form "$fixed_2plus1_idle_lane")" in
    branch)
      [ "$(bn "$fixed_2plus1_idle_repo")" = \
        "$(fixed_2plus1_profile_default_branch)" ]
      ;;
    detached) [ -z "$(bn "$fixed_2plus1_idle_repo")" ] ;;
    *) return 1 ;;
  esac
}

nr() { [ -z "$(rds "$1")" ]; }

bo() {
  fixed_2plus1_branch_path=$(CDPATH= cd -- "$1" && pwd -P) || return 1
  git -C "$1" worktree list --porcelain |
    awk -v branch="refs/heads/$2" -v path="$fixed_2plus1_branch_path" '
      /^worktree / {worktree=substr($0, 10)}
      /^branch / && substr($0, 8) == branch && worktree != path {
        print worktree
        exit
      }
    '
}

cl() {
  local lane repo initialization slot lock branch head dirty releasing_count
  local releasing_paths origin_main
  lane=$1
  repo=$2
  initialization=$(ip "$repo")
  slot=$(sp "$repo")
  lock=$(kp "$repo")
  branch=$(bn "$repo")
  head=$(git -C "$repo" rev-parse HEAD 2>/dev/null || true)
  dirty=$(git -C "$repo" status --porcelain 2>/dev/null)
  printf '%s path=%s\n' "$lane" "$repo"
  printf '  branch=%s\n' "${branch:-DETACHED}"
  printf '  head=%s\n' "$head"
  printf '  clean=%s\n' "$([ -z "$dirty" ] && echo yes || echo no)"

  if [ -e "$lock" ]; then
    set -- $(nuinui_ownership_parse_lock "$lock/state")
    if [ "$#" = 6 ]; then
      printf '  state=BLOCKED reason=mutation-in-progress operation=%s claim=%s\n' "$1" "$6"
    else
      echo '  state=BLOCKED reason=invalid-mutation-lock'
    fi
    return 1
  fi

  releasing_paths=$(rds "$repo")
  releasing_count=$(printf '%s\n' "$releasing_paths" | grep -c . || true)
  if [ -e "$slot" ]; then
    [ "$releasing_count" = 0 ] || {
      echo '  state=BLOCKED reason=active-and-releasing-state-coexist'
      return 1
    }
    set -- $(nuinui_ownership_parse_slot "$slot/state") || {
      echo '  state=BLOCKED reason=invalid-active-slot'
      return 1
    }
    [ "$#" = 4 ] || {
      echo '  state=BLOCKED reason=invalid-active-slot'
      return 1
    }
    printf '  owner_issue=%s owner_branch=%s base=%s claim=%s\n' "$1" "$2" "$3" "$4"
    [ "$branch" = "$2" ] && an "$repo" "$3" "$head" 2>/dev/null || {
      echo '  state=BLOCKED reason=claim-checkout-mismatch'
      return 1
    }
    echo '  state=BUSY'
    return 0
  fi

  if [ "$releasing_count" != 0 ]; then
    [ "$releasing_count" = 1 ] || {
      echo '  state=BLOCKED reason=multiple-release-states'
      return 1
    }
    set -- $(nuinui_ownership_parse_releasing "$releasing_paths") || {
      echo '  state=BLOCKED reason=invalid-release-state'
      return 1
    }
    [ "$#" = 5 ] || {
      echo '  state=BLOCKED reason=invalid-release-state'
      return 1
    }
    printf '  state=RELEASE-PENDING claim=%s checkpoint=%s\n' "$4" "$5"
    return 0
  fi

  nuinui_ownership_validate_initialization "$initialization" || {
    echo '  state=BLOCKED reason=durable-ownership-initialization-required'
    return 1
  }
  origin_main=$(am "$repo")
  nuinui_ownership_valid_sha "$origin_main" && id "$lane" "$repo" "$origin_main" || {
    printf '  state=BLOCKED reason=invalid-idle-state origin_main=%s\n' "$origin_main"
    return 1
  }
  printf '  state=FREE origin_main=%s\n' "$origin_main"
}

pf() {
  local lane_a lane_b human_lane result
  fixed_2plus1_profile_guard || {
    echo '===== FIXED 2+1 PREFLIGHT RESULT ====='
    echo 'PREFLIGHT BLOCKED'
    return 1
  }
  printf '%s\n' '===== NUINUI PREFLIGHT RESULT ====='
  result=0
  lane_a=$(fixed_2plus1_profile_implementation_lane_a_name)
  lane_b=$(fixed_2plus1_profile_implementation_lane_b_name)
  human_lane=$(fixed_2plus1_profile_human_test_lane_name)
  gr "$(lr "$lane_a")" && cl "$lane_a" "$(lr "$lane_a")" || result=1
  gr "$(lr "$lane_b")" && cl "$lane_b" "$(lr "$lane_b")" || result=1
  fixed_2plus1_profile_human_test_preflight "$human_lane" || result=1
  fixed_2plus1_profile_inventory_guard \
    "$(lr "$lane_a")" "$(lr "$lane_b")" "$(lr "$human_lane")" || result=1
  [ "$result" = 0 ] && { echo 'PREFLIGHT PASS'; return 0; }
  echo 'PREFLIGHT BLOCKED'
  return 1
}

cv() {
  local lane issue base branch repo current_head
  lane=$1
  issue=$2
  base=$3
  branch=$4
  il "$lane" && nuinui_ownership_valid_issue "$issue" &&
    nuinui_ownership_valid_sha "$base" &&
    nuinui_ownership_validate_issue_branch "$issue" "$branch" || return 2
  repo=$(lr "$lane")
  gr "$repo" && ao "$repo" "$(fixed_2plus1_profile_repository_identity)" &&
    cn "$repo" || return 1
  id "$lane" "$repo" "$base" || {
    fm "$repo" || return 1
    [ "$(om "$repo")" = "$base" ] || return 1
    current_head=$(hh "$repo")
    id "$lane" "$repo" "$current_head" || return 1
  }
  fm "$repo" && [ "$(om "$repo")" = "$base" ] || return 1
  git -C "$repo" show-ref --verify --quiet "refs/heads/$branch" && return 1
  [ -z "$(ab "$repo" "$branch")" ] || return 1
  current_head=$(hh "$repo")
  [ "$current_head" = "$base" ] || an "$repo" "$current_head" "$base" || return 1
  echo VERIFIED
}

vr() {
  local repo
  repo=$(lr "$1") || return 2
  nuinui_ownership_validate_initialization "$(ip "$repo")" &&
    [ ! -e "$(sp "$repo")" ] && [ ! -e "$(kp "$repo")" ] && nr "$repo" || return 1
  cv "$@"
}

li() {
  local lane repo marker claim origin_main
  lane=$1
  il "$lane" || return 2
  repo=$(lr "$lane")
  gr "$repo" && ao "$repo" "$(fixed_2plus1_profile_repository_identity)" || return 1
  marker=$(ip "$repo")
  if [ -e "$marker" ]; then
    nuinui_ownership_validate_initialization "$marker" && {
      echo 'ALREADY INITIALIZED'
      return 0
    }
    return 1
  fi
  [ ! -e "$(sp "$repo")" ] && [ ! -e "$(kp "$repo")" ] && nr "$repo" || return 1
  claim=$(gc)
  lo "$repo" init "$claim" - - - - || return 1
  fm "$repo" || return 1
  origin_main=$(om "$repo")
  id "$lane" "$repo" "$origin_main" || return 1
  wa "$marker" 'version=1\n' && ul "$repo" "$claim" || return 1
  echo 'LANE INITIALIZED'
}

cs() {
  local lane issue base branch repo head default_branch
  lane=$1
  issue=$2
  base=$3
  branch=$4
  repo=$(lr "$lane")
  cv "$@" >/dev/null || return $?
  fm "$repo" || return 1
  [ "$(om "$repo")" = "$base" ] || return 1
  head=$(hh "$repo")
  if [ "$head" != "$base" ]; then
    case "$(fixed_2plus1_profile_idle_checkout_form "$lane")" in
      branch) git -C "$repo" merge --ff-only "origin/$(fixed_2plus1_profile_default_branch)" >/dev/null || return 1 ;;
      detached) sd "$repo" "$base" || return 1 ;;
      *) return 1 ;;
    esac
  fi
  git -C "$repo" switch -c "$branch" "$base" >/dev/null || return 1
  echo STARTED
}

st() {
  local lane issue base branch repo claim slot
  lane=$1
  issue=$2
  base=$3
  branch=$4
  vr "$@" >/dev/null || return $?
  repo=$(lr "$lane")
  claim=$(gc)
  lo "$repo" start "$claim" "$issue" "$branch" "$base" - || return 1
  slot=$(sp "$repo")
  mkdir "$slot" || return 1
  wa "$slot/state" "version=1\nissue=$issue\nbranch=$branch\nbase=$base\nclaim=$claim\n" || return 1
  [ "${NUINUI_SELFTEST_CRASH_AT:-}" = start-after-slot ] && return 97
  cs "$@" || {
    if id "$lane" "$repo" "$base" &&
      ! git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
      rm -rf "$slot"
      ul "$repo" "$claim" >/dev/null 2>&1 || true
    fi
    return 1
  }
  ul "$repo" "$claim" || return 1
  printf '  claim=%s\n' "$claim"
}

rt() {
  local repo branch head topic topic_rc remote_head remote_ref
  repo=$1
  branch=$2
  head=$3
  topic=$(git -C "$repo" ls-remote --exit-code --heads origin "refs/heads/$branch" 2>/dev/null)
  topic_rc=$?
  case "$topic_rc" in
    0)
      remote_head=$(printf '%s\n' "$topic" | awk 'NR == 1 {print $1}')
      remote_ref=$(printf '%s\n' "$topic" | awk 'NR == 1 {print $2}')
      [ "$remote_head" = "$head" ] && [ "$remote_ref" = "refs/heads/$branch" ] &&
        [ -z "$(printf '%s\n' "$topic" | awk 'NR > 1 {print}')" ] || return 1
      echo pushed
      ;;
    2) [ -z "$topic" ] && echo absent || return 1 ;;
    *) return 1 ;;
  esac
}

cr() {
  local lane issue base head branch claim repo mode main_branch
  lane=$1
  issue=$2
  base=$3
  head=$4
  branch=$5
  claim=$6
  repo=$(lr "$lane")
  set -- $(nuinui_ownership_parse_slot "$(sp "$repo")/state") || return 1
  [ "$1 $2 $3 $4" = "$issue $branch $base $claim" ] || return 1
  cn "$repo" &&
    [ "$(git -C "$repo" rev-parse "refs/heads/$branch^{commit}" 2>/dev/null)" = "$head" ] &&
    an "$repo" "$base" "$head" && [ -z "$(bo "$repo" "$branch")" ] || return 1
  mode=$(rt "$repo" "$branch" "$head") || return 1
  [ "$mode" != absent ] || [ "$head" = "$base" ] || return 1
  fm "$repo" || return 1
  main_branch=$(om "$repo")
  current_branch=$(bn "$repo")
  current_head=$(hh "$repo")
  if [ "$current_branch" != "$branch" ] || [ "$current_head" != "$head" ]; then
    fixed_2plus1_profile_idle_checkout_form "$lane" >/dev/null || return 1
    id "$lane" "$repo" "$main_branch" || return 1
    [ "$current_head" = "$main_branch" ] || an "$repo" "$current_head" "$main_branch" || return 1
    [ "$(rt "$repo" "$branch" "$head")" = "$mode" ] || return 1
    git -C "$repo" switch "$branch" >/dev/null || return 1
  fi
  [ "$(hh "$repo")" = "$head" ] && cn "$repo" || return 1
  echo RESUMED
}

rs() {
  local lane issue base head branch claim repo old_branch old_head
  lane=$1
  issue=$2
  base=$3
  head=$4
  branch=$5
  claim=$6
  il "$lane" && nuinui_ownership_valid_issue "$issue" &&
    nuinui_ownership_valid_sha "$base" && nuinui_ownership_valid_sha "$head" &&
    nuinui_ownership_valid_claim "$claim" || return 2
  repo=$(lr "$lane")
  set -- $(nuinui_ownership_parse_slot "$(sp "$repo")/state") || return 1
  [ "$1 $2 $3 $4" = "$issue $branch $base $claim" ] &&
    [ ! -e "$(kp "$repo")" ] && nr "$repo" || return 1
  old_branch=$(bn "$repo")
  old_head=$(hh "$repo")
  lo "$repo" resume "$claim" "$issue" "$branch" "$base" "$head" || return 1
  cr "$lane" "$issue" "$base" "$head" "$branch" "$claim" || {
    [ "$(bn "$repo")" = "$old_branch" ] && [ "$(hh "$repo")" = "$old_head" ] &&
      ul "$repo" "$claim" >/dev/null 2>&1 || true
    return 1
  }
  ul "$repo" "$claim" || return 1
  printf '  base=%s\n  claim=%s\n' "$base" "$claim"
}

dl() {
  local lane head branch repo current_branch current_head delete_branch form default_branch
  lane=$1
  head=$2
  branch=$3
  repo=$(lr "$lane")
  cn "$repo" || return 1
  current_branch=$(bn "$repo")
  current_head=$(hh "$repo")
  delete_branch=
  [ "$current_branch" = "$branch" ] && [ "$current_head" = "$head" ] && delete_branch=$branch
  form=$(fixed_2plus1_profile_idle_checkout_form "$lane")
  default_branch=$(fixed_2plus1_profile_default_branch)
  case "$form" in
    branch)
      [ "$current_branch" = "$branch" ] || [ "$current_branch" = "$default_branch" ] || return 1
      git -C "$repo" switch "$default_branch" >/dev/null &&
        git -C "$repo" merge --ff-only "origin/$default_branch" >/dev/null || return 1
      ;;
    detached)
      [ "$current_branch" = "$branch" ] || [ -z "$current_branch" ] || return 1
      [ "$current_head" = "$head" ] || an "$repo" "$current_head" "origin/$default_branch" || return 1
      sd "$repo" "origin/$default_branch" || return 1
      ;;
    *) return 1 ;;
  esac
  if [ -n "$delete_branch" ]; then
    [ "$(git -C "$repo" rev-parse "refs/heads/$delete_branch^{commit}" 2>/dev/null)" = "$head" ] &&
      [ -z "$(bo "$repo" "$delete_branch")" ] &&
      git -C "$repo" update-ref -d "refs/heads/$delete_branch" "$head" || return 1
  fi
  echo RELEASED
}

rr() { printf '%s/nuinui-implementation-release-receipt\n' "$(gd "$1")"; }

write_release_receipt() {
  local repo lane issue branch base head claim receipt
  repo=$1
  lane=$2
  issue=$3
  branch=$4
  base=$5
  head=$6
  claim=$7
  receipt=$(rr "$repo")
  wa "$receipt" \
    "version=1\nlane=$lane\nissue=$issue\nbranch=$branch\nbase=$base\ncheckpoint=$head\nclaim=$claim\n" || return 1
  set -- $(nuinui_ownership_parse_release_receipt "$receipt") || return 1
  [ "$1 $2 $3 $4 $5 $6" = "$lane $issue $branch $base $head $claim" ]
}

release_restore_checkout() {
  local lane repo issue topic base claim head before_branch before_head
  local topic_head mode branch_head current_branch current_head default_branch
  local main_head main_head2 remote_state remote_state2 target_head target_head2
  lane=$1
  repo=$2
  topic=$3
  base=$4
  head=$5
  release_restore_checkout_mutated=no
  set -- $(nuinui_ownership_parse_slot "$(sp "$repo")/state") || return 1
  issue=$1
  claim=$4
  [ "$1 $2 $3 $4" = "$issue $topic $base $claim" ] || return 1
  set -- $(nuinui_ownership_parse_lock "$(kp "$repo")/state") || return 1
  [ "$1 $2 $3 $4 $5 $6" = "release $issue $topic $base $head $claim" ] || return 1
  nr "$repo" || return 1
  before_branch=$(bn "$repo")
  before_head=$(hh "$repo") || return 1
  if [ "$before_branch" = "$topic" ] && [ "$before_head" = "$head" ]; then
    cn "$repo" && [ -z "$(bo "$repo" "$topic")" ] || return 1
    return 0
  fi
  cn "$repo" || return 1
  nuinui_ownership_valid_sha "$before_head" || return 1
  topic_head=$(git -C "$repo" rev-parse --verify --quiet "refs/heads/$topic^{commit}" 2>/dev/null || true)
  mode=
  if [ -n "$before_branch" ] && [ "$before_branch" != "$topic" ] && [ "$before_head" = "$head" ]; then
    branch_head=$(git -C "$repo" rev-parse "refs/heads/$before_branch^{commit}" 2>/dev/null || true)
    if [ "$branch_head" = "$head" ]; then
      if [ "$topic_head" = "$head" ]; then
        mode=switch
      elif [ -z "$topic_head" ] && [ "$before_branch" != "$(fixed_2plus1_profile_default_branch)" ]; then
        mode=rename
      fi
    fi
  fi
  if [ -z "$mode" ]; then
    id "$lane" "$repo" "$before_head" || return 1
    [ "$topic_head" = "$head" ] || return 1
    mode=canonical
  fi
  fp "$repo" || return 1
  main_head=$(om "$repo") || return 1
  nuinui_ownership_valid_sha "$main_head" || return 1
  an "$repo" "$before_head" "$main_head" || return 1
  an "$repo" "$head" "$main_head" || return 1
  [ "$base" = "$head" ] || an "$repo" "$base" "$head" || return 1
  case "$mode" in
    switch|canonical) [ "$topic_head" = "$head" ] || return 1 ;;
    rename) [ -z "$topic_head" ] || return 1 ;;
    *) return 1 ;;
  esac
  [ -z "$(bo "$repo" "$topic")" ] || return 1
  remote_state=$(rt "$repo" "$topic" "$head") || return 1
  fp "$repo" || return 1
  main_head2=$(om "$repo") || return 1
  [ "$main_head2" = "$main_head" ] || return 1
  remote_state2=$(rt "$repo" "$topic" "$head") || return 1
  [ "$remote_state2" = "$remote_state" ] || return 1
  current_branch=$(bn "$repo")
  current_head=$(hh "$repo") || return 1
  [ "$current_branch" = "$before_branch" ] && [ "$current_head" = "$before_head" ] || return 1
  cn "$repo" && an "$repo" "$current_head" "$main_head2" &&
    an "$repo" "$head" "$main_head2" || return 1
  case "$mode" in
    switch|rename)
      [ -n "$current_branch" ] && [ "$current_branch" != "$topic" ] || return 1
      [ "$current_head" = "$head" ] || return 1
      branch_head=$(git -C "$repo" rev-parse "refs/heads/$current_branch^{commit}" 2>/dev/null || true)
      [ "$branch_head" = "$current_head" ] || return 1
      ;;
    canonical) id "$lane" "$repo" "$current_head" || return 1 ;;
    *) return 1 ;;
  esac
  target_head=$(git -C "$repo" rev-parse --verify --quiet "refs/heads/$topic^{commit}" 2>/dev/null || true)
  case "$mode" in
    switch|canonical) [ "$target_head" = "$head" ] || return 1 ;;
    rename) [ -z "$target_head" ] || return 1 ;;
  esac
  [ -z "$(bo "$repo" "$topic")" ] || return 1
  case "$mode" in
    switch)
      release_restore_checkout_mutated=potential
      git -C "$repo" switch "$topic" >/dev/null || return 1
      release_restore_checkout_mutated=yes
      ;;
    rename)
      release_restore_checkout_mutated=potential
      git -C "$repo" branch -m "$topic" >/dev/null || return 1
      release_restore_checkout_mutated=yes
      ;;
    canonical) return 0 ;;
    *) return 1 ;;
  esac
  [ "$(bn "$repo")" = "$topic" ] && [ "$(hh "$repo")" = "$head" ] && cn "$repo" || return 1
  set -- $(nuinui_ownership_parse_slot "$(sp "$repo")/state") || return 1
  [ "$1 $2 $3 $4" = "$issue $topic $base $claim" ] || return 1
  set -- $(nuinui_ownership_parse_lock "$(kp "$repo")/state") || return 1
  [ "$1 $2 $3 $4 $5 $6" = "release $issue $topic $base $head $claim" ] || return 1
  nr "$repo"
}

rl() {
  local lane head claim repo slot issue topic base tombstone
  release_restore_checkout_mutated=no
  lane=$1
  head=$2
  claim=$3
  il "$lane" && nuinui_ownership_valid_sha "$head" &&
    nuinui_ownership_valid_claim "$claim" || return 2
  repo=$(lr "$lane")
  slot=$(sp "$repo")
  set -- $(nuinui_ownership_parse_slot "$slot/state") || return 1
  issue=$1
  topic=$2
  base=$3
  [ "$4" = "$claim" ] && [ ! -e "$(kp "$repo")" ] && nr "$repo" || return 1
  lo "$repo" release "$claim" "$issue" "$topic" "$base" "$head" || return 1
  if ! release_restore_checkout "$lane" "$repo" "$topic" "$base" "$head"; then
    [ "$release_restore_checkout_mutated" = no ] && ul "$repo" "$claim"
    return 1
  fi
  if ! fp "$repo" || ! git -C "$repo" merge-base --is-ancestor "$head" \
    "origin/$(fixed_2plus1_profile_default_branch)"; then
    [ "$release_restore_checkout_mutated" = no ] && ul "$repo" "$claim"
    return 1
  fi
  wa "$slot/checkpoint" "$head\n" || {
    [ "$release_restore_checkout_mutated" = no ] && ul "$repo" "$claim"
    return 1
  }
  tombstone=$(rp "$repo" "$claim")
  mv "$slot" "$tombstone" || return 1
  [ "${NUINUI_SELFTEST_CRASH_AT:-}" = release-after-rename ] && return 97
  dl "$lane" "$head" "$topic" || return 1
  write_release_receipt "$repo" "$lane" "$issue" "$topic" "$base" "$head" "$claim" || return 1
  rm "$tombstone/checkpoint" "$tombstone/state" && rmdir "$tombstone" &&
    ul "$repo" "$claim" || return 1
  [ "${NUINUI_SELFTEST_STALE_RESULT:-}" = release ] && return 98
  printf '  claim=%s\n' "$claim"
}

rc() {
  local lane claim repo lock slot releasing state_count operation issue topic base head
  local claim_dir
  lane=$1
  claim=$2
  il "$lane" && nuinui_ownership_valid_claim "$claim" || return 2
  repo=$(lr "$lane")
  lock=$(kp "$repo")
  slot=$(sp "$repo")
  releasing=$(rds "$repo")
  state_count=$(printf '%s\n' "$releasing" | grep -c . || true)
  if [ ! -e "$lock" ]; then
    [ "$state_count" = 1 ] && set -- $(nuinui_ownership_parse_releasing "$releasing") &&
      [ "$4" = "$claim" ] || return 1
    lo "$repo" release "$claim" "$1" "$2" "$3" "$5" || return 1
  fi
  set -- $(nuinui_ownership_parse_lock "$lock/state") || return 1
  operation=$1
  issue=$2
  topic=$3
  base=$4
  head=$5
  [ "$6" = "$claim" ] || return 1
  case "$operation" in
    init)
      fm "$repo" || return 1
      origin_main=$(om "$repo")
      id "$lane" "$repo" "$origin_main" || return 1
      [ -e "$(ip "$repo")" ] || wa "$(ip "$repo")" 'version=1\n'
      nuinui_ownership_validate_initialization "$(ip "$repo")" && ul "$repo" "$claim"
      ;;
    start)
      set -- $(nuinui_ownership_parse_slot "$slot/state") || return 1
      [ "$1 $2 $3 $4" = "$issue $topic $base $claim" ] || return 1
      if [ "$(bn "$repo")" = "$topic" ] && [ "$(hh "$repo")" = "$base" ] && cn "$repo"; then
        ul "$repo" "$claim"
      else
        cs "$lane" "$issue" "$base" "$topic" >/dev/null && ul "$repo" "$claim"
      fi
      ;;
    resume) cr "$lane" "$issue" "$base" "$head" "$topic" "$claim" >/dev/null && ul "$repo" "$claim" ;;
    release)
      if [ "$state_count" = 0 ] && [ -e "$slot" ]; then
        set -- $(nuinui_ownership_parse_slot "$slot/state") || return 1
        [ "$1 $2 $3 $4" = "$issue $topic $base $claim" ] || return 1
        if [ -f "$slot/checkpoint" ]; then
          [ "$(cat "$slot/checkpoint")" = "$head" ] || return 1
        else
          wa "$slot/checkpoint" "$head\n" || return 1
        fi
        claim_dir=$(rp "$repo" "$claim")
        mv "$slot" "$claim_dir" || return 1
      elif [ "$state_count" = 1 ]; then
        claim_dir=$releasing
      else
        return 1
      fi
      set -- $(nuinui_ownership_parse_releasing "$claim_dir") || return 1
      [ "$1 $2 $3 $4 $5" = "$issue $topic $base $claim $head" ] || return 1
      fp "$repo" && git -C "$repo" merge-base --is-ancestor "$head" \
        "origin/$(fixed_2plus1_profile_default_branch)" &&
        dl "$lane" "$head" "$topic" >/dev/null || return 1
      write_release_receipt "$repo" "$lane" "$issue" "$topic" "$base" "$head" "$claim" || return 1
      rm "$claim_dir/checkpoint" "$claim_dir/state" && rmdir "$claim_dir" && ul "$repo" "$claim"
      ;;
    *) return 1 ;;
  esac || return 1
  printf 'RECOVERED operation=%s\n' "$operation"
}
