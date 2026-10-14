# Public dispatcher for native Human E2E. Fixture regression mode and live
# production mode are explicit and have separate authority boundaries.

nuinui_e2e_usage() {
  cat >&2 <<'USAGE'
Usage: nuinui-e2e {admit|status|start|cleanup-proof|release|recover|closure|host-check|host-prepare|host-status|host-cleanup|host-recover|host-closure} \
  --self-test --manifest <disposable-LANES.conf> --issue <canonical-identity> \
  --generation <caller-token> --tested-sha <40-lowercase-hex> [--lane <name>] \
  [--fixture <absolute-canonical-external-file> --port <1-65535> \
   [--locale default|ja] [--adapter fixture-no-process|vscode-isolated]]

Accepted Issue identities are exactly:
  sayosomi/nuinuiCAD#N
  https://github.com/sayosomi/nuinuiCAD/issues/N
  GH-sayosomi-nuinuiCAD-N

Usage: nuinui-e2e {admit|status|start|release|recover|closure|host-check|host-prepare|host-status|host-cleanup|host-recover|host-closure} \
  --production --issue <canonical-identity> --generation <caller-token> \
  --tested-sha <40-lowercase-hex> [--lane human-e2e] \
  [--fixture <absolute-canonical-external-file> --port <1-65535> [--locale default|ja]]

Production mode uses only the canonical versioned LANES.conf and always uses
the signed Microsoft VS Code adapter. Host readiness is not product PASS.
USAGE
}

nuinui_e2e_cli_resolve_program() {
  nuinui_e2e_cli_program=$0
  case "$nuinui_e2e_cli_program" in
    */*) ;;
    *) nuinui_e2e_cli_program=$(command -v -- "$nuinui_e2e_cli_program" 2>/dev/null || true) ;;
  esac
  [ -n "$nuinui_e2e_cli_program" ] || return 1
  nuinui_e2e_cli_program_path=$(realpath "$nuinui_e2e_cli_program" 2>/dev/null) || return 1
}

nuinui_e2e_cli_main() {
  [ "$#" -ge 1 ] || { nuinui_e2e_usage; return 2; }
  nuinui_e2e_self_test=no
  nuinui_e2e_production=no
  nuinui_e2e_test_failpoint=
  nuinui_e2e_command=$1
  shift
  nuinui_e2e_cli_manifest=
  nuinui_e2e_cli_issue=
  nuinui_e2e_cli_lane=
  nuinui_e2e_cli_generation=
  nuinui_e2e_cli_tested=
  nuinui_e2e_cli_fixture=
  nuinui_e2e_cli_port=
  nuinui_e2e_cli_locale=default
  nuinui_e2e_cli_adapter=fixture-no-process
  nuinui_e2e_cli_self_test=no
  nuinui_e2e_cli_production=no
  nuinui_e2e_cli_seen_self_test=no
  nuinui_e2e_cli_seen_production=no
  nuinui_e2e_cli_seen_manifest=no
  nuinui_e2e_cli_seen_issue=no
  nuinui_e2e_cli_seen_lane=no
  nuinui_e2e_cli_seen_generation=no
  nuinui_e2e_cli_seen_tested=no
  nuinui_e2e_cli_seen_fixture=no
  nuinui_e2e_cli_seen_port=no
  nuinui_e2e_cli_seen_locale=no
  nuinui_e2e_cli_seen_adapter=no
  while [ "$#" -gt 0 ]; do
    nuinui_e2e_cli_option=$1
    shift
    case "$nuinui_e2e_cli_option" in
      --self-test)
        [ "$nuinui_e2e_cli_seen_self_test" = no ] || {
          echo 'ERROR: duplicate --self-test option' >&2
          return 2
        }
        nuinui_e2e_cli_seen_self_test=yes
        nuinui_e2e_cli_self_test=yes
        ;;
      --production)
        [ "$nuinui_e2e_cli_seen_production" = no ] || {
          echo 'ERROR: duplicate --production option' >&2
          return 2
        }
        nuinui_e2e_cli_seen_production=yes
        nuinui_e2e_cli_production=yes
        ;;
      --manifest|--issue|--lane|--generation|--tested-sha|--fixture|--port|--locale|--adapter)
        [ "$#" -gt 0 ] || { echo "ERROR: $nuinui_e2e_cli_option requires a value" >&2; return 2; }
        nuinui_e2e_cli_value=$1
        shift
        [ -n "$nuinui_e2e_cli_value" ] &&
          case "$nuinui_e2e_cli_value" in -*|--*) false ;; *) true ;; esac || {
            echo "ERROR: $nuinui_e2e_cli_option requires a non-option value" >&2
            return 2
          }
        case "$nuinui_e2e_cli_option" in
          --manifest)
            [ "$nuinui_e2e_cli_seen_manifest" = no ] || { echo 'ERROR: duplicate --manifest option' >&2; return 2; }
            nuinui_e2e_cli_seen_manifest=yes
            nuinui_e2e_cli_manifest=$nuinui_e2e_cli_value
            ;;
          --issue)
            [ "$nuinui_e2e_cli_seen_issue" = no ] || { echo 'ERROR: duplicate --issue option' >&2; return 2; }
            nuinui_e2e_cli_seen_issue=yes
            nuinui_e2e_cli_issue=$nuinui_e2e_cli_value
            ;;
          --lane)
            [ "$nuinui_e2e_cli_seen_lane" = no ] || { echo 'ERROR: duplicate --lane option' >&2; return 2; }
            nuinui_e2e_cli_seen_lane=yes
            nuinui_e2e_cli_lane=$nuinui_e2e_cli_value
            ;;
          --generation)
            [ "$nuinui_e2e_cli_seen_generation" = no ] || { echo 'ERROR: duplicate --generation option' >&2; return 2; }
            nuinui_e2e_cli_seen_generation=yes
            nuinui_e2e_cli_generation=$nuinui_e2e_cli_value
            ;;
          --tested-sha)
            [ "$nuinui_e2e_cli_seen_tested" = no ] || { echo 'ERROR: duplicate --tested-sha option' >&2; return 2; }
            nuinui_e2e_cli_seen_tested=yes
            nuinui_e2e_cli_tested=$nuinui_e2e_cli_value
            ;;
          --fixture)
            [ "$nuinui_e2e_cli_seen_fixture" = no ] || { echo 'ERROR: duplicate --fixture option' >&2; return 2; }
            nuinui_e2e_cli_seen_fixture=yes
            nuinui_e2e_cli_fixture=$nuinui_e2e_cli_value
            ;;
          --port)
            [ "$nuinui_e2e_cli_seen_port" = no ] || { echo 'ERROR: duplicate --port option' >&2; return 2; }
            nuinui_e2e_cli_seen_port=yes
            nuinui_e2e_cli_port=$nuinui_e2e_cli_value
            ;;
          --locale)
            [ "$nuinui_e2e_cli_seen_locale" = no ] || { echo 'ERROR: duplicate --locale option' >&2; return 2; }
            nuinui_e2e_cli_seen_locale=yes
            nuinui_e2e_cli_locale=$nuinui_e2e_cli_value
            ;;
          --adapter)
            [ "$nuinui_e2e_cli_seen_adapter" = no ] || { echo 'ERROR: duplicate --adapter option' >&2; return 2; }
            nuinui_e2e_cli_seen_adapter=yes
            nuinui_e2e_cli_adapter=$nuinui_e2e_cli_value
            ;;
        esac
        ;;
      -h|--help|help)
        nuinui_e2e_usage
        return 0
        ;;
      *)
        echo "ERROR: unknown option or command argument: $nuinui_e2e_cli_option" >&2
        return 2
        ;;
    esac
  done
  [ "$nuinui_e2e_cli_self_test" = no ] || [ "$nuinui_e2e_cli_production" = no ] || {
    echo 'ERROR: choose exactly one of --self-test or --production' >&2
    return 2
  }
  [ "$nuinui_e2e_cli_self_test" = yes ] || [ "$nuinui_e2e_cli_production" = yes ] || {
    echo 'BLOCKED: explicit --production or --self-test is required' >&2
    return 1
  }
  [ "$nuinui_e2e_cli_seen_issue" = yes ] || { echo 'ERROR: --issue is required' >&2; return 2; }
  [ "$nuinui_e2e_cli_seen_generation" = yes ] || { echo 'ERROR: --generation is required' >&2; return 2; }
  [ "$nuinui_e2e_cli_seen_tested" = yes ] || { echo 'ERROR: --tested-sha is required' >&2; return 2; }

  if [ "$nuinui_e2e_cli_production" = yes ]; then
    [ "$nuinui_e2e_cli_seen_manifest" = no ] || {
      echo 'ERROR: --manifest is unavailable in production mode; the canonical versioned LANES.conf is selected automatically' >&2
      return 2
    }
    [ "$nuinui_e2e_cli_seen_adapter" = no ] || {
      echo 'ERROR: --adapter is unavailable in production mode; vscode-isolated is mandatory' >&2
      return 2
    }
    case "$nuinui_e2e_command" in
      cleanup-proof)
        echo 'BLOCKED: fixture-only cleanup-proof cannot be used in production mode' >&2
        return 1
        ;;
      host-check|host-prepare)
        [ "$nuinui_e2e_cli_seen_fixture" = yes ] || { echo 'ERROR: --fixture is required for this host command' >&2; return 2; }
        [ "$nuinui_e2e_cli_seen_port" = yes ] || { echo 'ERROR: --port is required for this host command' >&2; return 2; }
        case "$nuinui_e2e_cli_locale" in default|ja) ;; *) echo 'ERROR: --locale must be default or ja' >&2; return 2 ;; esac
        ;;
      *)
        [ "$nuinui_e2e_cli_seen_fixture" = no ] &&
          [ "$nuinui_e2e_cli_seen_port" = no ] &&
          [ "$nuinui_e2e_cli_seen_locale" = no ] || {
            echo 'ERROR: --fixture, --port, and --locale are only valid for host-check and host-prepare' >&2
            return 2
          }
        ;;
    esac
    [ -z "$(env | sed -n '/^NUINUI_E2E_TEST_/p' | sed -n '1p')" ] || {
      echo 'BLOCKED: self-test environment overrides are forbidden in production mode' >&2
      return 1
    }
    nuinui_e2e_cli_resolve_program || {
      echo 'BLOCKED: production executable path cannot be independently resolved' >&2
      return 1
    }
    nuinui_e2e_production=yes
    nuinui_e2e_self_test=no
    nuinui_e2e_cli_manifest=/Users/yosomi/Code/dev-context/projects/nuinuiCAD/LANES.conf
    nuinui_e2e_cli_adapter=vscode-isolated
  else
    [ "$nuinui_e2e_cli_seen_manifest" = yes ] || { echo 'ERROR: --manifest is required in self-test mode' >&2; return 2; }
    nuinui_e2e_self_test=yes
    nuinui_e2e_production=no
    nuinui_e2e_test_failpoint=${NUINUI_E2E_TEST_FAILPOINT:-}
  fi

  case "$nuinui_e2e_command" in
    host-check|host-prepare)
      [ "$nuinui_e2e_cli_seen_fixture" = yes ] || { echo 'ERROR: --fixture is required for this command' >&2; return 2; }
      [ "$nuinui_e2e_cli_seen_port" = yes ] || { echo 'ERROR: --port is required for this command' >&2; return 2; }
      case "$nuinui_e2e_cli_locale" in default|ja) ;; *) echo 'ERROR: --locale must be default or ja' >&2; return 2 ;; esac
      case "$nuinui_e2e_cli_adapter" in fixture-no-process|vscode-isolated) ;; *) echo 'ERROR: --adapter must be fixture-no-process or vscode-isolated' >&2; return 2 ;; esac
      ;;
    *)
      [ "$nuinui_e2e_cli_seen_fixture" = no ] &&
        [ "$nuinui_e2e_cli_seen_port" = no ] &&
        [ "$nuinui_e2e_cli_seen_locale" = no ] || {
          echo 'ERROR: --fixture, --port, and --locale are only valid for host-check and host-prepare' >&2
          return 2
        }
      [ "$nuinui_e2e_cli_seen_adapter" = no ] || {
        echo 'ERROR: --adapter is only valid for host-check and host-prepare' >&2
        return 2
      }
      ;;
  esac
  nuinui_e2e_operation=$nuinui_e2e_command
  nuinui_e2e_manifest_arg=$nuinui_e2e_cli_manifest
  nuinui_e2e_lane_arg=$nuinui_e2e_cli_lane
  nuinui_e2e_issue_arg=$nuinui_e2e_cli_issue
  nuinui_e2e_expected_generation=$nuinui_e2e_cli_generation
  nuinui_e2e_expected_tested=$nuinui_e2e_cli_tested
  nuinui_e2e_host_adapter_arg=$nuinui_e2e_cli_adapter
  case "$nuinui_e2e_command" in
    admit)
      [ "$nuinui_e2e_cli_seen_tested" = yes ] || return 2
      nuinui_e2e_admit "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    status)
      nuinui_e2e_status "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    start)
      nuinui_e2e_start "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" \
        "$nuinui_e2e_cli_issue" "$nuinui_e2e_cli_tested"
      ;;
    cleanup-proof)
      nuinui_e2e_cleanup_proof "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    release)
      nuinui_e2e_release "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    recover)
      nuinui_e2e_recover "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    closure)
      nuinui_e2e_closure "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    host-check)
      nuinui_e2e_host_check "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" \
        "$nuinui_e2e_cli_issue" "$nuinui_e2e_cli_fixture" \
        "$nuinui_e2e_cli_port" "$nuinui_e2e_cli_locale"
      ;;
    host-prepare)
      nuinui_e2e_host_prepare "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" \
        "$nuinui_e2e_cli_issue" "$nuinui_e2e_cli_fixture" \
        "$nuinui_e2e_cli_port" "$nuinui_e2e_cli_locale"
      ;;
    host-status)
      nuinui_e2e_host_status "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    host-cleanup)
      nuinui_e2e_host_cleanup "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    host-recover)
      nuinui_e2e_host_recover "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    host-closure)
      nuinui_e2e_host_closure "$nuinui_e2e_cli_manifest" "$nuinui_e2e_cli_lane" "$nuinui_e2e_cli_issue"
      ;;
    *)
      echo 'BLOCKED: unsupported candidate operation; live E2E preparation and execution are not implemented' >&2
      nuinui_e2e_usage
      return 2
      ;;
  esac
}

if [ "${NUINUI_E2E_LIBRARY_ONLY:-0}" != 1 ]; then
  nuinui_e2e_cli_main "$@"
fi
