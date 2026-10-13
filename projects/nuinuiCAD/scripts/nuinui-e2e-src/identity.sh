# Strict identity conversion for the inactive GitHub-native E2E candidate.

nuinui_e2e_identity_number() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_identity_input=$1
  case "$nuinui_e2e_identity_input" in
    sayosomi/nuinuiCAD#*)
      nuinui_e2e_identity_number=${nuinui_e2e_identity_input#sayosomi/nuinuiCAD#}
      [ "$nuinui_e2e_identity_input" = \
        "sayosomi/nuinuiCAD#$nuinui_e2e_identity_number" ] || return 1
      ;;
    https://github.com/sayosomi/nuinuiCAD/issues/*)
      nuinui_e2e_identity_number=${nuinui_e2e_identity_input#https://github.com/sayosomi/nuinuiCAD/issues/}
      [ "$nuinui_e2e_identity_input" = \
        "https://github.com/sayosomi/nuinuiCAD/issues/$nuinui_e2e_identity_number" ] || return 1
      ;;
    GH-sayosomi-nuinuiCAD-*)
      nuinui_e2e_identity_number=${nuinui_e2e_identity_input#GH-sayosomi-nuinuiCAD-}
      [ "$nuinui_e2e_identity_input" = \
        "GH-sayosomi-nuinuiCAD-$nuinui_e2e_identity_number" ] || return 1
      ;;
    *) return 1 ;;
  esac
  case "$nuinui_e2e_identity_number" in
    ''|0|0*|*[!0-9]*) return 1 ;;
  esac
  printf '%s\n' "$nuinui_e2e_identity_number"
}

nuinui_e2e_identity_issue() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_identity_number=$(nuinui_e2e_identity_number "$1") || return 1
  printf 'sayosomi/nuinuiCAD#%s\n' "$nuinui_e2e_identity_number"
}

nuinui_e2e_identity_url() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_identity_number=$(nuinui_e2e_identity_number "$1") || return 1
  printf 'https://github.com/sayosomi/nuinuiCAD/issues/%s\n' \
    "$nuinui_e2e_identity_number"
}

nuinui_e2e_identity_token() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_identity_number=$(nuinui_e2e_identity_number "$1") || return 1
  printf 'GH-sayosomi-nuinuiCAD-%s\n' "$nuinui_e2e_identity_number"
}

nuinui_e2e_identity_resolve() {
  [ "$#" = 1 ] || return 2
  nuinui_e2e_identity_number=$(nuinui_e2e_identity_number "$1") || return 1
  printf 'sayosomi/nuinuiCAD#%s\n' "$nuinui_e2e_identity_number"
  printf 'https://github.com/sayosomi/nuinuiCAD/issues/%s\n' \
    "$nuinui_e2e_identity_number"
  printf 'GH-sayosomi-nuinuiCAD-%s\n' "$nuinui_e2e_identity_number"
}

nuinui_e2e_valid_sha() {
  [ "$#" = 1 ] || return 2
  printf '%s\n' "$1" | grep -Eq '^[0-9a-f]{40}$'
}

nuinui_e2e_valid_generation() {
  [ "$#" = 1 ] || return 2
  case "$1" in
    ''|.*|*..*|*[!A-Za-z0-9._-]*) return 1 ;;
  esac
  [ "${#1}" -ge 8 ] && [ "${#1}" -le 128 ]
}

nuinui_e2e_valid_digest() {
  [ "$#" = 1 ] || return 2
  printf '%s\n' "$1" | grep -Eq '^[0-9a-f]{64}$'
}
