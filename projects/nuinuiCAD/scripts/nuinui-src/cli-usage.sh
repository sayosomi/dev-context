# Public CLI version, command membership, and usage output.
# K is consumed by usage and the existing context-check implementation.

V=1.15.0
K='preflight verify lane-init begin begin-command start resume handoff exact-fix release release-command recover integrate-clean integrate-clean-command audit-begin audit-release e2e-start e2e-start-command e2e-start-local-main e2e-release context-audit context-sync context-dev-audit context-dev-transition context-dev-next doctor transition-audit context-check self-test last-result'

nuinui_usage() {
  echo "nuinui $V"
  echo "Commands: $K"
  echo 'Usage: nuinui handoff <SAY-N> <expected-main-sha>'
  echo 'Usage: nuinui exact-fix --issue <SAY-N> --expected-topic <40-sha> --expected-main <40-sha> --patch <absolute-patch-file> --verify <absolute-verifier-file> --message <commit-message> --file <repo-relative-path> [--file <repo-relative-path> ...]'
  echo 'Usage: nuinui begin-command --lane <implementation-lane> --issue <SAY-123> --base <expected-base-sha> --branch <branch> [--forensic-worktree <absolute-path>]'
  echo 'Usage: nuinui release-command --lane <implementation-lane> --issue <SAY-123> --claim <claim>'
  echo 'Usage: nuinui e2e-start-command --issue <SAY-123> --tested-ref <full-sha> --executor <human|luna> --fixture <absolute-fixture-path> [--lane <human-test-lane>] [--locale <default|ja>] [--port <port>]'
  echo 'Usage: nuinui integrate-clean-command --lane <implementation-lane> --issue <SAY-123> --claim <claim> --topic-head <full-sha> --main <full-sha> --verification-script <absolute-executable-path> [--manifest <absolute-readable-file-path>]'
  echo 'Usage: nuinui context-dev-next --old-branch <expected-old-branch> --old-head <expected-old-head> --main <expected-main> --new-branch <new-branch>'
  echo 'Usage: nuinui audit-begin --issue <SAY-N> --lane <declared-lane> --revision <full-sha>'
  echo 'Usage: nuinui audit-release --issue <SAY-N> --revision <full-sha>'
}
