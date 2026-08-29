#!/bin/sh

# Canonical durable ownership metadata semantics.  This fragment is assembled
# before each standalone consumer; it is never sourced at runtime.

nuinui_ownership_valid_issue() {
  printf '%s\n' "$1" | grep -Eq '^SAY-[0-9]+$'
}

nuinui_ownership_valid_sha() {
  printf '%s\n' "$1" | grep -Eq '^[0-9a-fA-F]{40}$'
}

nuinui_ownership_valid_claim() {
  printf '%s\n' "$1" | grep -Eq '^[0-9A-Za-z][0-9A-Za-z._-]{7,127}$'
}

nuinui_ownership_issue_from_branch() {
  printf '%s\n' "$1" | sed -n 's/.*[sS][aA][yY]-\([0-9][0-9]*\).*/SAY-\1/p'
}

nuinui_ownership_valid_branch() {
  git check-ref-format --branch "$1" >/dev/null 2>&1
}

nuinui_ownership_validate_issue_branch() {
  nuinui_ownership_valid_issue "$1" || return 1
  nuinui_ownership_valid_branch "$2" || return 1
  [ "$(nuinui_ownership_issue_from_branch "$2")" = "$1" ]
}

nuinui_ownership_read_fields() {
  [ -f "$1" ] || return 1
  nuinui_ownership_metadata_file=$1
  nuinui_ownership_expected_keys=$2
  awk -v keys="$nuinui_ownership_expected_keys" '
    BEGIN {
      count=split(keys, expected, ",")
      for (i=1; i<=count; i++) allowed[expected[i]]=1
    }
    {
      equals=index($0, "=")
      if (equals <= 1) {
        invalid=1
        next
      }
      key=substr($0, 1, equals-1)
      value=substr($0, equals+1)
      if (!(key in allowed) || (key in seen) || value == "") {
        invalid=1
        next
      }
      seen[key]=1
      values[key]=value
    }
    END {
      for (i=1; i<=count; i++) if (!(expected[i] in seen)) invalid=1
      if (invalid) exit 1
      for (i=1; i<=count; i++) {
        printf "%s", values[expected[i]]
        if (i < count) printf " "
        else printf "\n"
      }
    }
  ' "$nuinui_ownership_metadata_file"
}

nuinui_ownership_field() {
  [ -f "$1" ] || return 1
  nuinui_ownership_metadata_file=$1
  nuinui_ownership_wanted_key=$2
  awk -v wanted="$nuinui_ownership_wanted_key" '
    {
      equals=index($0, "=")
      if (equals <= 1) {
        invalid=1
        next
      }
      key=substr($0, 1, equals-1)
      value=substr($0, equals+1)
      if (key == wanted) {
        if (value == "" || found) invalid=1
        found=1
        result=value
      }
    }
    END {
      if (invalid || !found) exit 1
      print result
    }
  ' "$nuinui_ownership_metadata_file"
}

nuinui_ownership_validate_exact_file() {
  nuinui_ownership_read_fields "$1" "$2" >/dev/null
}

nuinui_ownership_validate_initialization() {
  nuinui_ownership_initialize_version=$(nuinui_ownership_read_fields "$1" version) || return 1
  [ "$nuinui_ownership_initialize_version" = 1 ]
}

nuinui_ownership_parse_slot() {
  set -- $(nuinui_ownership_read_fields "$1" version,issue,branch,base,claim) || return 1
  [ "$#" = 5 ] || return 1
  [ "$1" = 1 ] || return 1
  nuinui_ownership_validate_issue_branch "$2" "$3" || return 1
  nuinui_ownership_valid_sha "$4" || return 1
  nuinui_ownership_valid_claim "$5" || return 1
  printf '%s %s %s %s\n' "$2" "$3" "$4" "$5"
}

nuinui_ownership_parse_lock() {
  set -- $(nuinui_ownership_read_fields "$1" version,operation,issue,branch,base,checkpoint,claim) || return 1
  [ "$#" = 7 ] || return 1
  [ "$1" = 1 ] || return 1
  case "$2" in
    init|start|resume|release) ;;
    *) return 1 ;;
  esac
  case "$3:$4" in
    -:-) ;;
    -:*|*:-) return 1 ;;
    *)
      nuinui_ownership_validate_issue_branch "$3" "$4" || return 1
      ;;
  esac
  [ "$5" = - ] || nuinui_ownership_valid_sha "$5" || return 1
  [ "$6" = - ] || nuinui_ownership_valid_sha "$6" || return 1
  nuinui_ownership_valid_claim "$7" || return 1
  printf '%s %s %s %s %s %s\n' "$2" "$3" "$4" "$5" "$6" "$7"
}

nuinui_ownership_parse_releasing() {
  nuinui_ownership_releasing_dir=$1
  [ -d "$nuinui_ownership_releasing_dir" ] || return 1
  set -- $(nuinui_ownership_parse_slot "$nuinui_ownership_releasing_dir/state") || return 1
  [ -f "$nuinui_ownership_releasing_dir/checkpoint" ] || return 1
  nuinui_ownership_releasing_checkpoint=$(cat "$nuinui_ownership_releasing_dir/checkpoint") || return 1
  nuinui_ownership_valid_sha "$nuinui_ownership_releasing_checkpoint" || return 1
  [ "${nuinui_ownership_releasing_dir##*/}" = "nuinui-implementation-slot.releasing.$4" ] || return 1
  printf '%s %s %s %s %s\n' "$1" "$2" "$3" "$4" "$nuinui_ownership_releasing_checkpoint"
}
