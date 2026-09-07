# Immutable Git-object ticket resolution for the canonical Luna handoff.
#
# This source owns only the short-token parser, dev-context remote proof,
# ticket commit validation, and one-shot reservation.  handoff.sh remains the
# owner of standalone proof and exact branch-mismatch recovery.

nuinui_handoff_ticket_resolve_and_reserve() {
  [ "$#" = 1 ] || {
    printf 'ERROR: handoff expects exactly one short ticket\n'
    printf 'Usage: nuinui handoff <h1-24-hex-ticket>\n'
    return 2
  }
  nuinui_handoff_ticket_token=$1
  printf '%s\n' "$nuinui_handoff_ticket_token" | grep -Eq '^h1-[0-9a-f]{24}$' || {
    printf 'ERROR: invalid handoff ticket; expected h1- followed by 24 lowercase hexadecimal characters\n'
    return 2
  }

  [ -n "${C:-}" ] && gr "$C" && ao "$C" "${CT:-sayosomi/dev-context}" || {
    printf 'BLOCKED: canonical dev-context repository identity is unavailable\n'
    return 1
  }
  nuinui_handoff_ticket_common_dir=$(context_git_common_abs "$C" 2>/dev/null) || {
    printf 'BLOCKED: canonical dev-context Git directory is unavailable\n'
    return 1
  }
  [ -d "$nuinui_handoff_ticket_common_dir" ] &&
    [ ! -L "$nuinui_handoff_ticket_common_dir" ] || {
    printf 'BLOCKED: canonical dev-context Git directory is invalid\n'
    return 1
  }

  nuinui_handoff_ticket_ref=refs/heads/nuinui-handoff-ticket/$nuinui_handoff_ticket_token
  nuinui_handoff_ticket_remote_raw=$(git -C "$C" ls-remote --exit-code --heads \
    origin "$nuinui_handoff_ticket_ref" 2>/dev/null) || {
    printf 'BLOCKED: handoff ticket ref is missing\n'
    return 1
  }
  set -- $nuinui_handoff_ticket_remote_raw
  [ "$#" = 2 ] && [ "$2" = "$nuinui_handoff_ticket_ref" ] &&
    printf '%s\n' "$1" | grep -Eq '^[0-9a-f]{40}$' || {
    printf 'BLOCKED: handoff ticket ref resolution is ambiguous\n'
    return 1
  }
  nuinui_handoff_ticket_sha=$1
  nuinui_handoff_ticket_suffix=${nuinui_handoff_ticket_token#h1-}
  case "$nuinui_handoff_ticket_sha" in
    "$nuinui_handoff_ticket_suffix"*) ;;
    *)
      printf 'BLOCKED: handoff ticket ref target does not match its token\n'
      return 1
      ;;
  esac

  git -C "$C" fetch --no-tags origin "$nuinui_handoff_ticket_ref" \
    >/dev/null 2>&1 || {
    printf 'BLOCKED: handoff ticket object could not be fetched\n'
    return 1
  }
  [ "$(git -C "$C" cat-file -t "$nuinui_handoff_ticket_sha" 2>/dev/null)" = commit ] || {
    printf 'BLOCKED: handoff ticket target is not a commit\n'
    return 1
  }
  [ "$(git -C "$C" rev-parse "$nuinui_handoff_ticket_sha" 2>/dev/null)" = \
    "$nuinui_handoff_ticket_sha" ] || {
    printf 'BLOCKED: fetched handoff ticket object changed identity\n'
    return 1
  }
  nuinui_handoff_ticket_remote_after=$(git -C "$C" ls-remote --exit-code --heads \
    origin "$nuinui_handoff_ticket_ref" 2>/dev/null) || {
    printf 'BLOCKED: handoff ticket ref disappeared during resolution\n'
    return 1
  }
  [ "$nuinui_handoff_ticket_remote_after" = "$nuinui_handoff_ticket_remote_raw" ] || {
    printf 'BLOCKED: handoff ticket ref changed during resolution\n'
    return 1
  }

  nuinui_handoff_ticket_parents=$(git -C "$C" rev-list --parents -n 1 \
    "$nuinui_handoff_ticket_sha" 2>/dev/null) || {
    printf 'BLOCKED: handoff ticket parent metadata is unavailable\n'
    return 1
  }
  set -- $nuinui_handoff_ticket_parents
  [ "$#" = 2 ] || {
    printf 'BLOCKED: handoff ticket must have exactly one parent\n'
    return 1
  }
  nuinui_handoff_ticket_parent=$2
  [ "$(git -C "$C" rev-parse "$nuinui_handoff_ticket_sha^{tree}" 2>/dev/null)" = \
    "$(git -C "$C" rev-parse "$nuinui_handoff_ticket_parent^{tree}" 2>/dev/null)" ] || {
    printf 'BLOCKED: handoff ticket must have an identical tree to its parent\n'
    return 1
  }

  nuinui_handoff_ticket_fields=$(git -C "$C" cat-file commit \
    "$nuinui_handoff_ticket_sha" 2>/dev/null | awk '
      BEGIN {
        in_body = 0
        body_line = 0
        invalid = 0
        expected[1] = "repository"
        expected[2] = "lane"
        expected[3] = "issue"
        expected[4] = "claim"
        expected[5] = "checkpoint"
        expected[6] = "main"
        expected[7] = "topic"
        expected[8] = "nonce"
      }
      {
        if (!in_body) {
          if ($0 == "") in_body = 1
          next
        }
        body_line++
        if (body_line == 1) {
          if ($0 != "nuinui-handoff-ticket-v1") invalid = 1
          next
        }
        equals = index($0, "=")
        key = substr($0, 1, equals - 1)
        value = substr($0, equals + 1)
        if (equals <= 1 || value == "" || index(value, "=") != 0 ||
            body_line > 9 || key != expected[body_line - 1]) {
          invalid = 1
          next
        }
        value_by_line[body_line - 1] = value
      }
      END {
        if (!in_body || body_line != 9 || invalid) exit 1
        for (i = 1; i <= 8; i++) print value_by_line[i]
      }
    ') || {
    printf 'BLOCKED: handoff ticket message is not the canonical field set\n'
    return 1
  }
  set -- $nuinui_handoff_ticket_fields
  [ "$#" = 8 ] || {
    printf 'BLOCKED: handoff ticket message field count is invalid\n'
    return 1
  }
  nuinui_handoff_ticket_repository=$1
  nuinui_handoff_ticket_lane=$2
  nuinui_handoff_ticket_issue=$3
  nuinui_handoff_ticket_claim=$4
  nuinui_handoff_ticket_checkpoint=$5
  nuinui_handoff_ticket_main=$6
  nuinui_handoff_ticket_topic=$7
  nuinui_handoff_ticket_nonce=$8

  [ "$nuinui_handoff_ticket_repository" = sayosomi/nuinuiCAD ] || {
    printf 'BLOCKED: handoff ticket repository is invalid\n'
    return 1
  }
  il "$nuinui_handoff_ticket_lane" || {
    printf 'BLOCKED: handoff ticket lane is not a declared implementation lane\n'
    return 1
  }
  nuinui_ownership_valid_issue "$nuinui_handoff_ticket_issue" || {
    printf 'BLOCKED: handoff ticket Issue is invalid\n'
    return 1
  }
  nuinui_ownership_valid_claim "$nuinui_handoff_ticket_claim" || {
    printf 'BLOCKED: handoff ticket claim is invalid\n'
    return 1
  }
  nuinui_ownership_valid_sha "$nuinui_handoff_ticket_checkpoint" || {
    printf 'BLOCKED: handoff ticket checkpoint is invalid\n'
    return 1
  }
  nuinui_ownership_valid_sha "$nuinui_handoff_ticket_main" || {
    printf 'BLOCKED: handoff ticket main is invalid\n'
    return 1
  }
  case "$nuinui_handoff_ticket_topic" in
    absent|exact) ;;
    *)
      printf 'BLOCKED: handoff ticket topic is invalid\n'
      return 1
      ;;
  esac
  printf '%s\n' "$nuinui_handoff_ticket_nonce" | grep -Eq '^[0-9a-f]{16}$' || {
    printf 'BLOCKED: handoff ticket nonce is invalid\n'
    return 1
  }

  nuinui_handoff_ticket_store=$nuinui_handoff_ticket_common_dir/nuinui-handoff-ticket-v1
  if [ -L "$nuinui_handoff_ticket_store" ]; then
    printf 'BLOCKED: handoff ticket reservation store is a symbolic link\n'
    return 1
  fi
  if [ ! -e "$nuinui_handoff_ticket_store" ]; then
    mkdir "$nuinui_handoff_ticket_store" 2>/dev/null || {
      [ -d "$nuinui_handoff_ticket_store" ] &&
        [ ! -L "$nuinui_handoff_ticket_store" ] || {
        printf 'BLOCKED: handoff ticket reservation store is unavailable\n'
        return 1
      }
    }
  fi
  [ -d "$nuinui_handoff_ticket_store" ] || {
    printf 'BLOCKED: handoff ticket reservation store is invalid\n'
    return 1
  }
  nuinui_handoff_ticket_reservation=$nuinui_handoff_ticket_store/$nuinui_handoff_ticket_token
  if mkdir "$nuinui_handoff_ticket_reservation" 2>/dev/null; then
    wa "$nuinui_handoff_ticket_reservation/state" \
      "version=1\ntoken=$nuinui_handoff_ticket_token\nticket=$nuinui_handoff_ticket_sha\n" || {
      printf 'BLOCKED: handoff ticket reservation could not be recorded\n'
      return 1
    }
  else
    printf 'BLOCKED: handoff ticket is already reserved or used\n'
    return 1
  fi

  nuinui_handoff_lane=$nuinui_handoff_ticket_lane
  nuinui_handoff_issue=$nuinui_handoff_ticket_issue
  nuinui_handoff_claim=$nuinui_handoff_ticket_claim
  nuinui_handoff_checkpoint=$nuinui_handoff_ticket_checkpoint
  nuinui_handoff_main=$nuinui_handoff_ticket_main
  nuinui_handoff_topic=$nuinui_handoff_ticket_topic
}
