#!/bin/sh

# Generic implementation occupancy and expected-inventory API.
#
# Inventory text is data.  This source deliberately uses temporary records and
# exact comparisons; it never evaluates caller-provided lane or occupancy
# values as shell.

lane_execution__inventory_lookup() {
  lane_execution_lookup_file=$1
  lane_execution_lookup_lane=$2
  awk -F '\t' -v lane="$lane_execution_lookup_lane" '
    $1 == lane { value=$2; count++ }
    END { if (count != 1) exit 1; print value }
  ' "$lane_execution_lookup_file"
}

lane_execution__inventory_pairs() {
  lane_execution_inventory_text=$1
  [ -n "$lane_execution_inventory_text" ] || return 1
  printf '%s\n' "$lane_execution_inventory_text" | awk '
    NR != 1 { invalid=1 }
    {
      count=split($0, pair, ",")
      for (i=1; i<=count; i++) {
        if (pair[i] !~ /^[^=,[:space:]]+=[^=,[:space:]]+$/) invalid=1
        else {
          equals=index(pair[i], "=")
          print substr(pair[i], 1, equals - 1) "\t" substr(pair[i], equals + 1)
        }
      }
    }
    END { if (invalid || count == 0) exit 1 }
  '
}

lane_execution_inventory_normalize() {
  [ "$#" = 2 ] || return 2
  lane_execution_inventory_manifest=$1
  lane_execution_inventory_text=$2
  lane_manifest_validate "$lane_execution_inventory_manifest" || return 1

  lane_execution_inventory_pairs_file=$(mktemp "${TMPDIR:-/tmp}/lane-inventory-pairs.XXXXXX") || return 1
  lane_execution_inventory_result=0
  if ! lane_execution__inventory_pairs "$lane_execution_inventory_text" >"$lane_execution_inventory_pairs_file"; then
    rm -f "$lane_execution_inventory_pairs_file"
    return 1
  fi

  lane_execution_inventory_seen_file=$(mktemp "${TMPDIR:-/tmp}/lane-inventory-seen.XXXXXX") || {
    rm -f "$lane_execution_inventory_pairs_file"
    return 1
  }
  : >"$lane_execution_inventory_seen_file"
  while IFS="$(printf '\t')" read -r lane_execution_inventory_lane \
    lane_execution_inventory_value || [ -n "$lane_execution_inventory_lane" ]; do
    if grep -Fqx "$lane_execution_inventory_lane" "$lane_execution_inventory_seen_file"; then
      lane_execution_inventory_result=1
      continue
    fi
    printf '%s\n' "$lane_execution_inventory_lane" >>"$lane_execution_inventory_seen_file"
    lane_manifest_validate_lane_name "$lane_execution_inventory_manifest" \
      "$lane_execution_inventory_lane" >/dev/null 2>&1 || {
      lane_execution_inventory_result=1
      continue
    }
    [ "$(lane_manifest_lane_role "$lane_execution_inventory_manifest" \
      "$lane_execution_inventory_lane" 2>/dev/null || true)" = implementation ] || {
      lane_execution_inventory_result=1
      continue
    }
    case "$lane_execution_inventory_value" in
      FREE) ;;
      *) lane_execution_validate_work_id "$lane_execution_inventory_value" || lane_execution_inventory_result=1 ;;
    esac
  done <"$lane_execution_inventory_pairs_file"

  lane_execution_inventory_output=
  while IFS= read -r lane_execution_inventory_lane || [ -n "$lane_execution_inventory_lane" ]; do
    [ -n "$lane_execution_inventory_lane" ] || continue
    lane_execution_inventory_value=$(lane_execution__inventory_lookup \
      "$lane_execution_inventory_pairs_file" "$lane_execution_inventory_lane" 2>/dev/null || true)
    [ -n "$lane_execution_inventory_value" ] || lane_execution_inventory_result=1
    if [ -n "$lane_execution_inventory_output" ]; then
      lane_execution_inventory_output=$lane_execution_inventory_output,
    fi
    lane_execution_inventory_output=$lane_execution_inventory_output$lane_execution_inventory_lane=$lane_execution_inventory_value
  done <<EOF
$(lane_manifest_lanes_by_role "$lane_execution_inventory_manifest" implementation)
EOF

  lane_execution_inventory_expected_count=$(lane_manifest_lanes_by_role \
    "$lane_execution_inventory_manifest" implementation | grep -c . || true)
  lane_execution_inventory_actual_count=$(grep -c . "$lane_execution_inventory_pairs_file" || true)
  [ "$lane_execution_inventory_actual_count" = "$lane_execution_inventory_expected_count" ] ||
    lane_execution_inventory_result=1

  rm -f "$lane_execution_inventory_pairs_file" "$lane_execution_inventory_seen_file"
  [ "$lane_execution_inventory_result" = 0 ] || return 1
  printf '%s\n' "$lane_execution_inventory_output"
}

lane_execution_inventory_from_audit() {
  [ "$#" = 2 ] || return 2
  lane_execution_inventory_manifest=$1
  lane_execution_inventory_audit=$2
  lane_manifest_validate "$lane_execution_inventory_manifest" || return 1
  lane_execution_inventory_records_file=$(mktemp "${TMPDIR:-/tmp}/lane-audit-records.XXXXXX") || return 1
  if ! printf '%s\n' "$lane_execution_inventory_audit" | awk '
    function finish(    i, field, value) {
      if (current_role != "implementation") return
      if (current_state == "FREE" && current_owner == "") {
        print current_lane "\tFREE"
      } else if (current_state == "BUSY" && current_owner != "") {
        print current_lane "\t" current_owner
      } else {
        invalid=1
      }
    }
    /^lane name=/ {
      finish()
      current_lane=""
      current_role=""
      current_state=""
      current_owner=""
      count=split($0, fields, " ")
      if (count < 3 || fields[2] !~ /^name=/ || fields[3] !~ /^role=/) {
        invalid=1
        next
      }
      current_lane=substr(fields[2], 6)
      current_role=substr(fields[3], 6)
      next
    }
    /^  state=/ {
      state_line=substr($0, 9)
      split(state_line, state_fields, " ")
      if (current_state != "") invalid=1
      current_state=state_fields[1]
      next
    }
    /^  owner_issue=/ {
      owner_line=substr($0, 15)
      split(owner_line, owner_fields, " ")
      if (current_owner != "" || owner_fields[1] == "") invalid=1
      current_owner=owner_fields[1]
      next
    }
    END {
      finish()
      if (invalid) exit 1
    }
  ' >"$lane_execution_inventory_records_file"; then
    rm -f "$lane_execution_inventory_records_file"
    return 1
  fi

  lane_execution_inventory_records=
  while IFS="$(printf '\t')" read -r lane_execution_inventory_record_lane \
    lane_execution_inventory_record_value ||
    [ -n "$lane_execution_inventory_record_lane" ]; do
    if [ -n "$lane_execution_inventory_records" ]; then
      lane_execution_inventory_records=$lane_execution_inventory_records,
    fi
    lane_execution_inventory_records=$lane_execution_inventory_records$lane_execution_inventory_record_lane=$lane_execution_inventory_record_value
  done <"$lane_execution_inventory_records_file"
  rm -f "$lane_execution_inventory_records_file"
  lane_execution_inventory_normalize "$lane_execution_inventory_manifest" \
    "$lane_execution_inventory_records"
}

lane_execution_inventory_compare() {
  [ "$#" = 3 ] || [ "$#" = 4 ] || return 2
  lane_execution_inventory_manifest=$1
  lane_execution_inventory_expected=$2
  lane_execution_inventory_actual=$3
  lane_execution_inventory_skip=${4-}
  lane_execution_inventory_expected=$(lane_execution_inventory_normalize \
    "$lane_execution_inventory_manifest" "$lane_execution_inventory_expected") || return 1
  lane_execution_inventory_actual=$(lane_execution_inventory_normalize \
    "$lane_execution_inventory_manifest" "$lane_execution_inventory_actual") || return 1
  lane_execution_inventory_result=0
  while IFS= read -r lane_execution_inventory_lane || [ -n "$lane_execution_inventory_lane" ]; do
    [ -n "$lane_execution_inventory_lane" ] || continue
    [ "$lane_execution_inventory_lane" = "$lane_execution_inventory_skip" ] && continue
    lane_execution_inventory_expected_value=$(lane_execution__inventory_value \
      "$lane_execution_inventory_expected" "$lane_execution_inventory_lane") || {
      lane_execution_inventory_result=1
      continue
    }
    lane_execution_inventory_actual_value=$(lane_execution__inventory_value \
      "$lane_execution_inventory_actual" "$lane_execution_inventory_lane" 2>/dev/null || true)
    if [ -z "$lane_execution_inventory_actual_value" ]; then
      printf 'lane=%s expected=%s actual=UNAVAILABLE\n' \
        "$lane_execution_inventory_lane" "$lane_execution_inventory_expected_value"
      lane_execution_inventory_result=1
    elif [ "$lane_execution_inventory_expected_value" != "$lane_execution_inventory_actual_value" ]; then
      printf 'lane=%s expected=%s actual=%s\n' "$lane_execution_inventory_lane" \
        "$lane_execution_inventory_expected_value" "$lane_execution_inventory_actual_value"
      lane_execution_inventory_result=1
    fi
  done <<EOF
$(lane_manifest_lanes_by_role "$lane_execution_inventory_manifest" implementation)
EOF
  return "$lane_execution_inventory_result"
}

lane_execution__inventory_value() {
  lane_execution_inventory_value_text=$1
  lane_execution_inventory_value_lane=$2
  printf '%s\n' "$lane_execution_inventory_value_text" | awk -v lane="$lane_execution_inventory_value_lane" -F ',' '
    {
      for (i=1; i<=NF; i++) {
        equals=index($i, "=")
        if (equals > 1 && substr($i, 1, equals - 1) == lane) {
          value=substr($i, equals + 1)
          count++
        }
      }
    }
    END { if (count != 1) exit 1; print value }
  '
}
