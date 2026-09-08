#!/bin/sh
set -eu

VERSION=1.0.0
CANONICAL_NUINUI=/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui
ISOLATION_CLAUSE='Do not inspect, modify, merge, rebase, cherry-pick, or otherwise manipulate another active implementation lane.'
OUTPUT_REQUIREMENT='Final success and BLOCKED/stopped reports must include a fresh Output time in the form Output time: YYYY-MM-DD HH:MM JST; do not reuse Prompt time.'

usage() {
  echo 'Usage: nuinui-prompt-check <prompt-file> <expected-context-file>' >&2
  exit 2
}

if [ "${1:-}" = version ]; then
  printf '%s\n' "$VERSION"
  exit 0
fi

blocked() {
  printf 'PROMPT PREFLIGHT BLOCKED\n'
  printf 'reason=%s\n' "$1"
  exit 1
}

require_regular_file() {
  [ -f "$1" ] && [ ! -L "$1" ] || blocked "$2"
}

require_exact_line() {
  prompt_check_expected_line=$1
  prompt_check_line_count=$(grep -Fxc -- "$prompt_check_expected_line" "$prompt_file" 2>/dev/null || true)
  [ "$prompt_check_line_count" = 1 ] ||
    blocked "prompt must contain exactly one canonical line: $prompt_check_expected_line"
}

require_context_line() {
  prompt_check_label=$1
  prompt_check_value=$2
  [ "$prompt_check_value" = - ] && return 0
  prompt_check_prefix="$prompt_check_label: "
  prompt_check_line_count=$(awk -v prefix="$prompt_check_prefix" \
    'index($0, prefix) == 1 {count++} END {print count + 0}' "$prompt_file")
  prompt_check_exact_count=$(grep -Fxc -- "$prompt_check_prefix$prompt_check_value" \
    "$prompt_file" 2>/dev/null || true)
  [ "$prompt_check_line_count" = 1 ] && [ "$prompt_check_exact_count" = 1 ] ||
    blocked "prompt field does not exactly match expected $prompt_check_label"
}

validate_context_field() {
  prompt_check_field=$1
  prompt_check_value=$2
  case "$prompt_check_field" in
    lane)
      [ "$prompt_check_value" = - ] ||
        printf '%s\n' "$prompt_check_value" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*$' ||
        blocked 'expected lane is invalid'
      ;;
    issue)
      [ "$prompt_check_value" = - ] ||
        printf '%s\n' "$prompt_check_value" | grep -Eq '^SAY-[0-9]+$' ||
        blocked 'expected Issue is invalid'
      ;;
    branch)
      [ "$prompt_check_value" = - ] ||
        printf '%s\n' "$prompt_check_value" | grep -Eq '^[A-Za-z0-9._/-]+$' ||
        blocked 'expected branch is invalid'
      ;;
    base|checkpoint)
      [ "$prompt_check_value" = - ] ||
        printf '%s\n' "$prompt_check_value" | grep -Eq '^[0-9a-fA-F]{40}$' ||
        blocked "expected $prompt_check_field is invalid"
      ;;
    claim)
      [ "$prompt_check_value" = - ] ||
        printf '%s\n' "$prompt_check_value" | grep -Eq '^[0-9A-Za-z][0-9A-Za-z._-]{7,127}$' ||
        blocked 'expected claim is invalid'
      ;;
    topic)
      [ "$prompt_check_value" = - ] ||
        case "$prompt_check_value" in
          absent|exact) ;;
          *) blocked 'expected topic mode is invalid' ;;
        esac
      ;;
  esac
}

validate_active_inventory() {
  [ "$active_implementation_lanes" = - ] && return 0
  [ "$lane" != - ] || blocked 'active implementation inventory requires an expected lane'
  prompt_check_current_lane_seen=0
  prompt_check_other_lane_seen=0
  prompt_check_old_ifs=$IFS
  IFS=,
  for prompt_check_active_lane in $active_implementation_lanes; do
    printf '%s\n' "$prompt_check_active_lane" | grep -Eq \
      '^[A-Za-z0-9][A-Za-z0-9._-]*$' || blocked 'active implementation inventory is invalid'
    if [ "$prompt_check_active_lane" = "$lane" ]; then
      prompt_check_current_lane_seen=1
    else
      prompt_check_other_lane_seen=1
    fi
  done
  IFS=$prompt_check_old_ifs
  [ "$prompt_check_current_lane_seen" = 1 ] ||
    blocked 'expected lane is absent from the authoritative active inventory'
  if [ "$prompt_check_other_lane_seen" = 1 ]; then
    require_exact_line "$ISOLATION_CLAUSE"
  fi
}

validate_forbidden_implementation_instructions() {
  [ "$phase" = implementation ] || return 0
  awk -v isolation="$ISOLATION_CLAUSE" '
    {
      lower = tolower($0)
      if ($0 == isolation) next
      protective = (lower ~ /(do not|must not|never|prohibited|forbidden)/)
      if (!protective && lower ~ /(merge|rebase|cherry-pick)/) {
        exit 1
      }
      if (!protective && lower ~ /(inspect|modify|checkout|switch|reset|stash)/ &&
          lower ~ /(another|other|cross-lane)/ && lower ~ /lane/) {
        exit 1
      }
    }
  ' "$prompt_file" || blocked 'implementation prompt contains a forbidden merge, rebase, or cross-lane manipulation instruction'
}

validate_verification_oracle() {
  [ "$verification_oracle" = - ] && return 0
  case "$verification_oracle" in
    /*) ;;
    *) blocked 'verification oracle must be an absolute path' ;;
  esac
  require_regular_file "$verification_oracle" 'verification oracle is unavailable'
  prompt_check_verification_body=$(mktemp "${TMPDIR:-/tmp}/nuinui-prompt-check.XXXXXX") ||
    blocked 'verification block temporary file could not be created'
  prompt_check_cleanup_verification() {
    result=$?
    trap - EXIT HUP INT TERM
    rm -f "$prompt_check_verification_body"
    exit "$result"
  }
  trap prompt_check_cleanup_verification EXIT HUP INT TERM
  awk '
    BEGIN { state = 0; begin_count = 0; end_count = 0; invalid = 0 }
    $0 == "Verification block: begin" {
      if (state != 0) invalid = 1
      state = 1
      begin_count++
      next
    }
    $0 == "Verification block: end" {
      if (state != 1) invalid = 1
      state = 2
      end_count++
      next
    }
    state == 1 { print }
    END {
      if (state != 2 || begin_count != 1 || end_count != 1 || invalid) exit 1
    }
  ' "$prompt_file" > "$prompt_check_verification_body" ||
    blocked 'prompt verification block markers are missing or malformed'
  cmp -s "$prompt_check_verification_body" "$verification_oracle" ||
    blocked 'prompt verification block does not match the expected oracle byte-for-byte'
  trap - EXIT HUP INT TERM
  rm -f "$prompt_check_verification_body"
}

[ "$#" = 2 ] || usage
prompt_file=$1
context_file=$2
require_regular_file "$prompt_file" 'prompt file is unavailable'
require_regular_file "$context_file" 'expected context file is unavailable'

repository=
role=
phase=
ticket=
ticket_state=
command=
lane=
issue=
branch=
base=
claim=
checkpoint=
topic=
active_implementation_lanes=
verification_oracle=
context_field=0
while IFS= read -r context_line || [ -n "$context_line" ]; do
  if [ "$context_field" = 0 ]; then
    [ "$context_line" = prompt-preflight-context-v1 ] ||
      blocked 'expected context header is invalid'
    context_field=1
    continue
  fi
  context_key=${context_line%%=*}
  context_value=${context_line#*=}
  [ "$context_key" != "$context_line" ] && [ -n "$context_key" ] && [ -n "$context_value" ] ||
    blocked 'expected context contains a malformed field'
  case "$context_field:$context_key" in
    1:repository) repository=$context_value ;;
    2:role) role=$context_value ;;
    3:phase) phase=$context_value ;;
    4:ticket) ticket=$context_value ;;
    5:ticket_state) ticket_state=$context_value ;;
    6:command) command=$context_value ;;
    7:lane) lane=$context_value ;;
    8:issue) issue=$context_value ;;
    9:branch) branch=$context_value ;;
    10:base) base=$context_value ;;
    11:claim) claim=$context_value ;;
    12:checkpoint) checkpoint=$context_value ;;
    13:topic) topic=$context_value ;;
    14:active_implementation_lanes) active_implementation_lanes=$context_value ;;
    15:verification_oracle) verification_oracle=$context_value ;;
    *) blocked 'expected context field order or name is invalid' ;;
  esac
  context_field=$((context_field + 1))
done < "$context_file"
[ "$context_field" = 16 ] || blocked 'expected context field set is incomplete'

[ "$repository" = sayosomi/nuinuiCAD ] || blocked 'expected repository is invalid'
[ "$role" = implementation ] || blocked 'role is not an allowed implementation-agent role'
case "$phase" in
  implementation|integration|blocking-fix) ;;
  *) blocked 'phase is not an allowed implementation phase' ;;
esac
printf '%s\n' "$ticket" | grep -Eq '^h1-[0-9a-f]{24}$' ||
  blocked 'declared handoff ticket has invalid syntax'
[ "$ticket_state" = valid ] || blocked 'declared handoff ticket fixture is not executable'

[ "$command" = "$CANONICAL_NUINUI handoff $ticket" ] ||
  blocked 'execution command is not the canonical public façade command for the declared ticket'
require_regular_file "$CANONICAL_NUINUI" 'canonical public nuinui façade is unavailable'
[ -x "$CANONICAL_NUINUI" ] || blocked 'canonical public nuinui façade is not executable'
grep -Fq 'Usage: nuinui handoff <h1-24-hex-ticket>' "$CANONICAL_NUINUI" ||
  blocked 'canonical public nuinui façade does not expose the expected handoff surface'
grep -Fq 'handoff)' "$CANONICAL_NUINUI" ||
  blocked 'canonical public nuinui façade handoff dispatch is unavailable'

validate_context_field lane "$lane"
validate_context_field issue "$issue"
validate_context_field branch "$branch"
validate_context_field base "$base"
validate_context_field claim "$claim"
validate_context_field checkpoint "$checkpoint"
validate_context_field topic "$topic"

require_exact_line "Role: $role"
require_exact_line "Phase: $phase"
require_exact_line "Handoff ticket: $ticket"
require_exact_line "$command"
prompt_check_slice_count=$(awk 'index($0, "Slice: ") == 1 && length($0) > 7 {count++} END {print count + 0}' "$prompt_file")
[ "$prompt_check_slice_count" = 1 ] || blocked 'prompt must contain exactly one non-empty Slice field'
require_context_line 'Lane' "$lane"
require_context_line 'Issue' "$issue"
require_context_line 'Branch' "$branch"
require_context_line 'Base' "$base"
require_context_line 'Claim' "$claim"
require_context_line 'Checkpoint' "$checkpoint"
require_context_line 'Topic remote mode' "$topic"

LC_ALL=C grep -n '[^ -~]' "$prompt_file" >/dev/null 2>&1 &&
  blocked 'prompt contains non-ASCII or non-printable text incompatible with the shared style contract'
grep -Eiq '(^|[[:space:]])(please|could you|would you)([[:space:]]|[,.!?]|$)' "$prompt_file" &&
  blocked 'prompt contains polite request phrasing incompatible with the shared style contract'
grep -Eq '^(#{1,6}[[:space:]]|>[[:space:]]|```|[*_-]{3,}[[:space:]]*$)' "$prompt_file" &&
  blocked 'prompt contains decorative Markdown incompatible with the shared style contract'
grep -Eq '^Prompt time: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} JST$' "$prompt_file" ||
  blocked 'required Prompt time field is missing or not in the stable JST form'
require_exact_line "$OUTPUT_REQUIREMENT"

validate_active_inventory
validate_forbidden_implementation_instructions
validate_verification_oracle

printf 'PROMPT PREFLIGHT PASS\n'
printf 'role=%s\n' "$role"
printf 'phase=%s\n' "$phase"
printf 'ticket=%s\n' "$ticket"
printf 'command=%s\n' "$command"
