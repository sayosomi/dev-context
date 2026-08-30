integration_clean_slot_identity() {
  local repo expected_issue expected_claim expected_topic
  local slot issue branch base claim current_branch current_head
  repo=$1
  expected_issue=$2
  expected_claim=$3
  expected_topic=$4

  INTEGRATION_CLEAN_BRANCH=
  INTEGRATION_CLEAN_BASE=

  slot="$(sp "$repo")/state"
  [ -f "$slot" ] || return 1
  set -- $(nuinui_ownership_parse_slot "$slot") || return 1
  [ "$#" = 4 ] || return 1
  issue=$1
  branch=$2
  base=$3
  claim=$4

  [ "$issue" = "$expected_issue" ] || return 1
  [ "$claim" = "$expected_claim" ] || return 1
  [ ! -e "$(kp "$repo")" ] || return 1
  [ -z "$(rds "$repo")" ] || return 1

  current_branch=$(bn "$repo")
  [ "$current_branch" = "$branch" ] || return 1
  current_head=$(hh "$repo" 2>/dev/null) || return 1
  [ "$current_head" = "$expected_topic" ] || return 1
  an "$repo" "$base" "$current_head" || return 1

  INTEGRATION_CLEAN_BRANCH=$branch
  INTEGRATION_CLEAN_BASE=$base
}

integration_clean_remote_main() {
  am "$1"
}

integration_clean_remote_topic() {
  ab "$1" "$2"
}

integration_clean_restore_precommit() {
  local repo lane issue claim topic branch base remote_topic restore_rc
  repo=$1
  lane=$2
  issue=$3
  claim=$4
  topic=$5
  branch=$6
  base=$7
  restore_rc=0

  if git -C "$repo" rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
    git -C "$repo" merge --abort >/dev/null 2>&1 || restore_rc=1
  fi

  if [ "$restore_rc" = 0 ]; then
    [ "$(hh "$repo" 2>/dev/null || true)" = "$topic" ] || restore_rc=1
    [ "$(bn "$repo")" = "$branch" ] || restore_rc=1
  fi

  if [ "$restore_rc" = 0 ]; then
    git -C "$repo" checkout-index -a -f >/dev/null 2>&1 || restore_rc=1
  fi

  if [ "$restore_rc" = 0 ]; then
    [ -z "$(git -C "$repo" status --porcelain 2>/dev/null)" ] || restore_rc=1
    integration_clean_slot_identity "$repo" "$issue" "$claim" "$topic" || restore_rc=1
    [ "$INTEGRATION_CLEAN_BRANCH" = "$branch" ] || restore_rc=1
    [ "$INTEGRATION_CLEAN_BASE" = "$base" ] || restore_rc=1
  fi

  remote_topic=$(integration_clean_remote_topic "$repo" "$branch" 2>/dev/null || true)
  [ "$remote_topic" = "$topic" ] || restore_rc=1

  [ "$restore_rc" = 0 ]
}

integration_clean_fail_precommit() {
  local class reason detail_file repo lane issue claim topic branch base
  class=$1
  reason=$2
  detail_file=$3
  repo=$4
  lane=$5
  issue=$6
  claim=$7
  topic=$8
  branch=$9
  shift 9
  base=$1

  if integration_clean_restore_precommit "$repo" "$lane" "$issue" "$claim" "$topic" "$branch" "$base"; then
    printf '%s: %s\n' "$class" "$reason"
    if [ -n "$detail_file" ] && [ -s "$detail_file" ]; then
      printf 'detail:\n'
      cat "$detail_file"
    fi
    return 1
  fi

  printf 'ERROR: integration pre-commit rollback could not be proven\n'
  printf 'lane=%s\nissue=%s\nbranch=%s\nexpected_topic=%s\nclaim=%s\n' \
    "$lane" "$issue" "$branch" "$topic" "$claim"
  printf 'actual_head=%s\nactual_branch=%s\n' \
    "$(hh "$repo" 2>/dev/null || printf '-')" "$(bn "$repo")"
  printf 'actual_remote_topic=%s\n' \
    "$(integration_clean_remote_topic "$repo" "$branch" 2>/dev/null || printf '-')"
  printf 'clean=%s\n' \
    "$([ -z "$(git -C "$repo" status --porcelain 2>/dev/null)" ] && printf yes || printf no)"
  if [ -n "$detail_file" ] && [ -s "$detail_file" ]; then
    printf 'detail:\n'
    cat "$detail_file"
  fi
  return 1
}

integration_clean_command() {
  local lane issue claim expected_topic expected_main verifier manifest repo
  local slot issue_actual branch base claim_actual actual_main actual_topic
  local root merge_output verifier_output status_before status_after actual_manifest
  local prospective_tree after_tree precommit_main precommit_topic commit_output commit_rc
  local head parents parent1 parent2 commit_tree push_output push_rc post_topic file_set

  lane=$1
  issue=$2
  claim=$3
  expected_topic=$4
  expected_main=$5
  verifier=$6
  manifest=$7

  case "$lane" in
    main|sub) ;;
    *)
      echo 'ERROR: lane must be main or sub'
      return 2
      ;;
  esac
  nuinui_ownership_valid_issue "$issue" || {
    echo 'ERROR: Issue must look like SAY-123'
    return 2
  }
  nuinui_ownership_valid_claim "$claim" || {
    echo 'ERROR: expected claim is invalid'
    return 2
  }
  nuinui_ownership_valid_sha "$expected_topic" || {
    echo 'ERROR: expected topic head must be a full 40-character commit SHA'
    return 2
  }
  nuinui_ownership_valid_sha "$expected_main" || {
    echo 'ERROR: expected main must be a full 40-character commit SHA'
    return 2
  }
  case "$verifier" in
    /*) ;;
    *)
      echo 'ERROR: verification script must be an absolute path'
      return 2
      ;;
  esac
  [ -f "$verifier" ] && [ -x "$verifier" ] && [ ! -L "$verifier" ] || {
    echo 'ERROR: verification script must be an executable regular file'
    return 2
  }
  if [ "$manifest" != - ]; then
    case "$manifest" in
      /*) ;;
      *)
        echo 'ERROR: expected-files manifest must be - or an absolute path'
        return 2
        ;;
    esac
    [ -f "$manifest" ] && [ -r "$manifest" ] && [ ! -L "$manifest" ] || {
      echo 'ERROR: expected-files manifest must be a readable regular file'
      return 2
    }
  fi

  repo=$(lr "$lane") || {
    echo 'ERROR: unable to resolve lane checkout'
    return 1
  }

  integration_clean_slot_identity "$repo" "$issue" "$claim" "$expected_topic" || {
    echo 'BLOCKED: durable lane identity does not match integrate-clean request'
    printf 'lane=%s\nissue=%s\nexpected_topic=%s\nclaim=%s\n' \
      "$lane" "$issue" "$expected_topic" "$claim"
    return 1
  }
  branch=$INTEGRATION_CLEAN_BRANCH
  base=$INTEGRATION_CLEAN_BASE

  lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" "$claim" "$expected_topic" || {
    echo 'BLOCKED: active lane checkpoint could not be proven clean and exact'
    printf 'lane=%s\nissue=%s\nbranch=%s\nexpected_topic=%s\nclaim=%s\n' \
      "$lane" "$issue" "$branch" "$expected_topic" "$claim"
    return 1
  }

  actual_main=$(integration_clean_remote_main "$repo" 2>/dev/null || true)
  if [ "$actual_main" != "$expected_main" ]; then
    echo 'BLOCKED: expected main mismatch'
    printf 'expected_main=%s\nactual_main=%s\n' "$expected_main" "${actual_main:--}"
    return 1
  fi
  actual_topic=$(integration_clean_remote_topic "$repo" "$branch" 2>/dev/null || true)
  if [ "$actual_topic" != "$expected_topic" ]; then
    echo 'BLOCKED: remote topic mismatch'
    printf 'expected_topic=%s\nactual_topic=%s\n' "$expected_topic" "${actual_topic:--}"
    return 1
  fi

  git -C "$repo" fetch --no-tags origin main >/dev/null 2>&1 || {
    echo 'ERROR: failed to fetch current main'
    return 1
  }
  [ "$(om "$repo" 2>/dev/null || true)" = "$expected_main" ] || {
    echo 'BLOCKED: fetched origin/main does not match expected main'
    printf 'expected_main=%s\nactual_origin_main=%s\n' \
      "$expected_main" "$(om "$repo" 2>/dev/null || printf '-')"
    return 1
  }

  integration_clean_slot_identity "$repo" "$issue" "$claim" "$expected_topic" || {
    echo 'BLOCKED: lane identity changed before merge'
    return 1
  }
  [ "$INTEGRATION_CLEAN_BRANCH" = "$branch" ] &&
    [ "$INTEGRATION_CLEAN_BASE" = "$base" ] || {
      echo 'BLOCKED: durable lane identity changed before merge'
      return 1
    }
  [ "$(integration_clean_remote_main "$repo" 2>/dev/null || true)" = "$expected_main" ] || {
    echo 'BLOCKED: remote main changed before merge'
    return 1
  }
  [ "$(integration_clean_remote_topic "$repo" "$branch" 2>/dev/null || true)" = "$expected_topic" ] || {
    echo 'BLOCKED: remote topic changed before merge'
    return 1
  }
  if git -C "$repo" merge-base --is-ancestor "$expected_main" "$expected_topic" >/dev/null 2>&1; then
    echo 'BLOCKED: topic already contains expected main'
    return 1
  fi

  root=$(mktemp -d "${TMPDIR:-/tmp}/nuinui-integrate-clean.XXXXXX") || {
    echo 'ERROR: unable to create integrate-clean temporary directory'
    return 1
  }
  merge_output=$root/merge.out
  verifier_output=$root/verifier.out
  status_before=$root/status.before
  status_after=$root/status.after
  actual_manifest=$root/files.actual
  commit_output=$root/commit.out
  push_output=$root/push.out

  if ! git -C "$repo" merge --no-commit --no-ff "$expected_main" >"$merge_output" 2>&1; then
    integration_clean_fail_precommit BLOCKED 'merge conflict or no-commit merge failure' \
      "$merge_output" "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  fi

  [ "$(hh "$repo" 2>/dev/null || true)" = "$expected_topic" ] || {
    integration_clean_fail_precommit ERROR 'HEAD changed during no-commit merge' \
      "$merge_output" "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  }
  integration_clean_slot_identity "$repo" "$issue" "$claim" "$expected_topic" || {
    integration_clean_fail_precommit ERROR 'durable lane identity changed during merge' \
      "$merge_output" "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  }

  prospective_tree=$(git -C "$repo" write-tree 2>/dev/null) || {
    integration_clean_fail_precommit ERROR 'unable to materialize prospective merge tree' \
      '' "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  }
  nuinui_ownership_valid_sha "$prospective_tree" || {
    integration_clean_fail_precommit ERROR 'prospective merge tree identity is invalid' \
      '' "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  }

  file_set=NOT_REQUESTED
  if [ "$manifest" != - ]; then
    git -C "$repo" diff --name-only -z "$expected_main" "$prospective_tree" >"$actual_manifest" 2>/dev/null || {
      integration_clean_fail_precommit ERROR 'unable to compute prospective effective file set' \
        '' "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
      commit_rc=$?
      rm -rf "$root"
      return "$commit_rc"
    }
    if ! cmp -s "$actual_manifest" "$manifest"; then
      integration_clean_fail_precommit BLOCKED 'expected effective file set mismatch' \
        '' "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
      commit_rc=$?
      rm -rf "$root"
      return "$commit_rc"
    fi
    file_set=VERIFIED
  fi

  git -C "$repo" status --porcelain=v1 -z --untracked-files=all >"$status_before" 2>/dev/null || {
    integration_clean_fail_precommit ERROR 'unable to capture pre-verification merge state' \
      '' "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  }

  if ! (cd "$repo" && "$verifier") >"$verifier_output" 2>&1; then
    integration_clean_fail_precommit BLOCKED 'required verification failed' \
      "$verifier_output" "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  fi

  after_tree=$(git -C "$repo" write-tree 2>/dev/null || true)
  git -C "$repo" status --porcelain=v1 -z --untracked-files=all >"$status_after" 2>/dev/null || {
    integration_clean_fail_precommit ERROR 'unable to capture post-verification merge state' \
      '' "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  }
  if [ "$after_tree" != "$prospective_tree" ] || ! cmp -s "$status_before" "$status_after"; then
    integration_clean_fail_precommit BLOCKED 'verification altered prospective tracked merge state' \
      "$verifier_output" "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  fi

  integration_clean_slot_identity "$repo" "$issue" "$claim" "$expected_topic" || {
    integration_clean_fail_precommit ERROR 'durable lane identity changed during verification' \
      '' "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  }
  precommit_main=$(integration_clean_remote_main "$repo" 2>/dev/null || true)
  precommit_topic=$(integration_clean_remote_topic "$repo" "$branch" 2>/dev/null || true)
  if [ "$precommit_main" != "$expected_main" ]; then
    printf 'expected_main=%s\nactual_main=%s\n' "$expected_main" "${precommit_main:--}" >"$merge_output"
    integration_clean_fail_precommit BLOCKED 'remote main moved during verification' \
      "$merge_output" "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  fi
  if [ "$precommit_topic" != "$expected_topic" ]; then
    printf 'expected_topic=%s\nactual_topic=%s\n' "$expected_topic" "${precommit_topic:--}" >"$merge_output"
    integration_clean_fail_precommit BLOCKED 'remote topic moved during verification' \
      "$merge_output" "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
    commit_rc=$?
    rm -rf "$root"
    return "$commit_rc"
  fi

  commit_rc=0
  git -C "$repo" commit --no-edit >"$commit_output" 2>&1 || commit_rc=$?
  head=$(hh "$repo" 2>/dev/null || true)
  if [ "$commit_rc" != 0 ]; then
    if [ "$head" = "$expected_topic" ]; then
      integration_clean_fail_precommit ERROR 'merge commit failed before advancing HEAD' \
        "$commit_output" "$repo" "$lane" "$issue" "$claim" "$expected_topic" "$branch" "$base"
      commit_rc=$?
      rm -rf "$root"
      return "$commit_rc"
    fi
    echo 'ERROR: merge commit reported failure after HEAD changed'
    printf 'lane=%s\nissue=%s\nbranch=%s\nprior_topic=%s\nactual_head=%s\nexpected_main=%s\nclaim=%s\n' \
      "$lane" "$issue" "$branch" "$expected_topic" "${head:--}" "$expected_main" "$claim"
    [ -s "$commit_output" ] && {
      printf 'detail:\n'
      cat "$commit_output"
    }
    rm -rf "$root"
    return 1
  fi

  nuinui_ownership_valid_sha "$head" || {
    echo 'ERROR: merge commit HEAD is invalid'
    rm -rf "$root"
    return 1
  }
  set -- $(git -C "$repo" rev-list --parents -n 1 "$head" 2>/dev/null) || {
    echo 'ERROR: unable to read merge commit parents'
    rm -rf "$root"
    return 1
  }
  if [ "$#" != 3 ]; then
    echo 'ERROR: integrate-clean created a non-two-parent commit'
    printf 'head=%s\n' "$head"
    rm -rf "$root"
    return 1
  fi
  parent1=$2
  parent2=$3
  if [ "$parent1" != "$expected_topic" ] || [ "$parent2" != "$expected_main" ]; then
    echo 'ERROR: merge commit parent mismatch'
    printf 'head=%s\nexpected_parent1=%s\nactual_parent1=%s\nexpected_parent2=%s\nactual_parent2=%s\n' \
      "$head" "$expected_topic" "$parent1" "$expected_main" "$parent2"
    rm -rf "$root"
    return 1
  fi
  commit_tree=$(git -C "$repo" rev-parse "$head^{tree}" 2>/dev/null || true)
  if [ "$commit_tree" != "$prospective_tree" ]; then
    echo 'ERROR: merge commit tree differs from verified prospective tree'
    printf 'expected_tree=%s\nactual_tree=%s\n' "$prospective_tree" "${commit_tree:--}"
    rm -rf "$root"
    return 1
  fi
  if ! lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" "$claim" "$head"; then
    echo 'ERROR: post-commit durable lane state could not be proven'
    printf 'head=%s\nclaim=%s\n' "$head" "$claim"
    rm -rf "$root"
    return 1
  fi

  push_rc=0
  git -C "$repo" push origin "HEAD:refs/heads/$branch" >"$push_output" 2>&1 || push_rc=$?
  if [ "$push_rc" != 0 ]; then
    post_topic=$(integration_clean_remote_topic "$repo" "$branch" 2>/dev/null || true)
    echo 'ERROR: integration push failed after verified merge commit'
    printf 'lane=%s\nissue=%s\nbranch=%s\nprior_topic=%s\nhead=%s\nexpected_main=%s\nclaim=%s\n' \
      "$lane" "$issue" "$branch" "$expected_topic" "$head" "$expected_main" "$claim"
    printf 'actual_remote_topic=%s\nclean=%s\n' \
      "${post_topic:--}" \
      "$([ -z "$(git -C "$repo" status --porcelain 2>/dev/null)" ] && printf yes || printf no)"
    [ -s "$push_output" ] && {
      printf 'detail:\n'
      cat "$push_output"
    }
    rm -rf "$root"
    return 1
  fi

  post_topic=$(integration_clean_remote_topic "$repo" "$branch" 2>/dev/null || true)
  if [ "$post_topic" != "$head" ]; then
    echo 'ERROR: integration push read-back mismatch'
    printf 'expected_remote_topic=%s\nactual_remote_topic=%s\n' "$head" "${post_topic:--}"
    rm -rf "$root"
    return 1
  fi
  if ! lifecycle_prove_busy_retry "$lane" "$issue" "$branch" "$base" "$claim" "$head"; then
    echo 'ERROR: pushed integration lane state could not be proven'
    printf 'head=%s\nclaim=%s\n' "$head" "$claim"
    rm -rf "$root"
    return 1
  fi

  printf 'INTEGRATION PUSHED\n'
  printf 'lane=%s\nissue=%s\nbranch=%s\nprior_topic=%s\nhead=%s\nintegration_watermark=%s\nclaim=%s\ntopic_remote=%s\nverification=PASS\nfile_set=%s\nclean=yes\n' \
    "$lane" "$issue" "$branch" "$expected_topic" "$head" "$expected_main" "$claim" "$head" "$file_set"
  rm -rf "$root"
}
