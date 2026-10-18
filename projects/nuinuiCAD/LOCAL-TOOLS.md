# nuinuiCAD local tools

## Purpose and authority

This document identifies the **active local helpers**, their safe command boundaries, and how to find older SAY-only behavior. It does not redefine implementation admission, checkout ownership, Human Manual E2E judgment, or helper internals.

- [Project router](./README.md): choose the relevant owner rather than loading every document.
- [Root DEVELOPMENT.md](../../DEVELOPMENT.md): dev-context self-development, standard clone, persistent development worktree, approval, PR, and post-merge sync.
- [CHECKOUTS.md](./CHECKOUTS.md): nuinuiCAD checkout topology, native Human E2E ownership/recovery, and compatible admitted SAY state.
- [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md): GitHub-native implementation startup; legacy SAY handoff only for an existing admitted generation.
- [VS-CODE-E2E.md](./VS-CODE-E2E.md) and [MANUAL-E2E.md](./MANUAL-E2E.md): isolated host preparation and Human-only GUI execution/judgment.

Authoritative tool/source state is the latest GitHub `sayosomi/dev-context` `main`. The standard clone `/Users/yosomi/Code/dev-context` is a production/cache/toolbox checkout, **not** a place to edit tracked files. Local development edits use the persistent `/Users/yosomi/Code/dev-context-dev` worktree, or the approved GitHub-direct route. Neither checkout is an extra nuinuiCAD product lane. Do not infer the current state from a previous chat or a local clone alone.

## Active: native D1 checkout admission (`nuinui-checkout-check`)

After syncing the standard dev-context clone to the authoritative merged
artifact, ChatGPT supplies exactly one of these forms with the current Issue,
main or checkpoint SHA, and topic branch:

~~~text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-checkout-check new --issue sayosomi/nuinuiCAD#N --main <fresh-40-character-main-sha> --branch <unused-topic> --human-clear
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-checkout-check continue --issue sayosomi/nuinuiCAD#N --branch <exact-topic> --checkpoint <pushed-40-character-sha> --human-clear
~~~

`--human-clear` is the Human's affirmative confirmation that no otherwise
unobservable implementation, evaluator or Human E2E owner is active. Do not
supply it when occupancy cannot be established. The check is read-only and
does not fetch, create a branch, write checkout metadata, or change a slot.
`LOCAL CHECK PASS` means local admission conditions matched at check time;
only ChatGPT verifies Issue/audit authority, and the Agent rechecks volatile
conditions immediately before mutation. A `BLOCKED` result is final for
that invocation; never run the retired `nuinui preflight` as a fallback.
The short responsibility router is [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md)
and the state owner is [CHECKOUTS.md](./CHECKOUTS.md).



`projects/nuinuiCAD/scripts/nuinui-context` is the active standalone context-only executable. It does not own product implementation, evaluator audit reservations, or E2E. Its separate generated artifact and installed executable identities must be verified for each guarded operation. The expected artifact is the **`nuinui-context` blob on freshly verified authoritative `main`**, never the legacy `nuinui` blob.

Supported commands (the public CLI and `context-check` both rely on this command surface):

~~~text
nuinui-context context-audit <expected-main> <expected-artifact-blob>
nuinui-context context-sync <expected-main> <expected-artifact-blob>
nuinui-context context-dev-audit <expected-branch> <expected-head>
nuinui-context context-dev-transition <expected-old-branch> <expected-old-head> <expected-main> <new-branch>
nuinui-context context-dev-next --old-branch <expected-old-branch> --old-head <expected-old-head> --main <expected-main> --new-branch <new-branch>
nuinui-context context-check
nuinui-context last-result
~~~

**Standard-clone sync:** after GitHub merge/read-back, pass exact expected `main` and artifact blob to `context-audit` (read-only), then `context-sync` (guarded fetch and fast-forward only). A behind standard clone is acceptable to audit. Sync requires an unambiguous clean `main` checkout and matching target artifact; a dirty, wrong-branch, wrong-repository, or non-fast-forward state blocks. Independently distinguish the Git artifact, installed executable, and expected target; do not claim the Human's local sync succeeded until the Human returns its actual result.

**Sequential dev-context tasks:** `context-dev-next` is the normal named handoff for the existing registered worktree. ChatGPT fixes the old branch/HEAD, authoritative new base, and new branch; the helper proves the expected state and performs the ordinary guarded transition. `context-dev-audit` and `context-dev-transition` remain for diagnosis/underlying explicit use. A verified immediate duplicate result (`DEV-CONTEXT ALREADY TRANSITIONED`, `mutation=no-op`) is terminal success, not a reason to rerun checks or ask for another Human handback. A progressed, dirty, stale, or ambiguous state blocks rather than being guessed, reset, stashed, or force-switched.

`context-check` performs the existing Markdown-link, documented-command, repository/worktree, and installed-executable consistency checks; it is not a new general preflight for each operation. Read-only commands do not overwrite the latest tracked mutation result.

## Active: native GitHub Human E2E (`nuinui-e2e --production`)

`projects/nuinuiCAD/scripts/nuinui-e2e` is the active native helper after the [#286 activation checkpoint](https://github.com/sayosomi/dev-context/issues/286). It operates only on the existing registered `human-e2e` checkout under the canonical production manifest and signed Microsoft VS Code isolated-host adapter. **New GitHub-native work never uses legacy `nuinui e2e-start` or `nuinui-e2e-prepare`.**

Common public form (each invocation supplies one explicit operation and its own exact identity):

~~~text
nuinui-e2e <operation> --production --issue <canonical-GitHub-Issue> --generation <token> --tested-sha <40-lowercase-sha> [--lane human-e2e]
~~~

Operations:

| Phase | Commands |
| --- | --- |
| Admission/state | `admit`, `status` |
| Tested checkout | `start` |
| VS Code host | `host-check`, `host-prepare`, `host-status` |
| Normal completion | `host-closure` (checked host cleanup → checkout release → final closure) |
| Targeted diagnosis/recovery | `host-cleanup`, `host-recover`, `release`, `recover`, `closure` |

`host-check` and `host-prepare` additionally require `--fixture <absolute-external-file> --port <1-65535>`; optional locale is `--locale default|ja`. Use the existing helper's usage and [VS-CODE-E2E.md](./VS-CODE-E2E.md) for the host contract, not a manually reconstructed multi-stage shell script. `admit` is read-only; `start` fixes the exact SHA and generation. A ready host is not product PASS: the **Human alone** operates and judges the actual VS Code GUI.

Production rejects caller-supplied fixture manifests/adapters, `NUINUI_E2E_TEST_*` overrides, unregistered or unexpected worktrees, dirty/wrong checkout state, and mismatched installed artifacts. The native marker governs the active generation; sessions, process ownership, immutable tested artifacts, and cleanup/release receipts must match it. The Human-test checkout cannot be replaced, registered again, or used for product source fixes. Use `host-closure` for normal completion; an interruption or mismatch requires exact-generation diagnosis and applicable `host-recover`/`recover`, never speculative cleanup or a new generation. The complete safety and recovery contract belongs to [CHECKOUTS.md](./CHECKOUTS.md#native-human-manual-e2e).

## Command results and fail-closed recovery

The executable that actually ran owns its result and its recovery boundary:

| Executable | Durable result directory in the resolved dev-context Git directory |
| --- | --- |
| `nuinui-context` | `nuinui-context-command-result-v1` |
| Legacy `nuinui` | `nuinui-command-result-v1` |

`nuinui-context last-result` and `nuinui last-result` each read **only their own store**. The context `context-dev-next` façade shares its underlying `context-dev-transition` result identity; it does not create an additional store. A result record is evidence, **not** permission to override checkout ownership, native E2E markers, session authority, claims, locks, or receipts. Read-only diagnostics do not replace a tracked mutation result.

If a mutation was interrupted, its output is missing, or ownership/artifact identity is unclear, inspect the appropriate `last-result` and the actual checkout/owner evidence before any independently reviewed exact recovery. `INCOMPLETE`, malformed/stale evidence, and near-matches block. Do not blindly retry, switch helpers as fallback, infer an owner, clear metadata, delete foreign processes, reset/stash/force, or treat another helper's result as proof. A genuine exact duplicate/no-op success does not justify extra repetitive checks.

## Legacy SAY compatibility — historical, not a new-work route

The versioned `nuinui` and `nuinui-e2e-prepare` executables, generators, source and tests remain checked in for historical reference and **compatible already-admitted** SAY operations. Their `preflight`, `begin`, `start`, `handoff`, `release`, `audit-begin/audit-release`, `integrate-clean`, `exact-fix`, old context commands, and E2E start/prepare/cleanup/recovery are **not** the GitHub-native D1, D2-C, or Human E2E startup path. Do not create new SAY/Linear Work, use legacy preflight to admit native implementation or audits, or re-enable the retired `pr-auto-merge` command.

Already admitted unresolved SAY claims, reservations, locks/tombstones, E2E markers, sessions and receipts continue to block conflicting admission. Recover such work **only** after proving its exact legacy Issue, generation, owner, branch/Base/checkpoint/claim, checkout, and relevant artifacts with the original compatible helper; preserve the existing recovery and fail-closed semantics. The corresponding legacy `last-result` evidence remains separate.

For precise original commands, argument order, ownership schemas, recovery and historical implementation evidence consult:

- [Frozen pre-reduction LOCAL-TOOLS.md (complete legacy command catalogue, source architecture, promotion evidence)](https://github.com/sayosomi/dev-context/blob/e5d51cfb1b7356b20f5d00def72b0028046c5e32/projects/nuinuiCAD/LOCAL-TOOLS.md).
- [Frozen pre-reduction CHECKOUTS.md (complete SAY-only recovery and exclusions)](https://github.com/sayosomi/dev-context/blob/78dbbdc42322d69f202f6694523f4437891085cd/projects/nuinuiCAD/CHECKOUTS.md).
- Current [CHECKOUTS.md legacy compatibility boundary](./CHECKOUTS.md#compatible-pre-existing-say-nuinui-operations--historical-reference) and [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md) for routing.

Pre-activation `nuinui context-audit/context-sync` bootstrap and `git pull --ff-only` fallback are **historical**, not automatic recovery routes for `nuinui-context`. Historical activation/canary evidence is preserved in [#268](https://github.com/sayosomi/dev-context/issues/268); current native activation and legacy retirement are recorded in [#286](https://github.com/sayosomi/dev-context/issues/286). Neither checkpoint must be repeated after ordinary documentation edits.

## Helper development and fallback

Checked-in production helpers are generated artifacts, not dynamic runtime source loading. Their existing `generate-nuinui`, `generate-nuinui-context`, `generate-nuinui-e2e`, and `generate-nuinui-e2e-prepare` scripts plus the associated `*-src/` directories own assembly; do not patch a production generated executable without its source/generator process. Maintain tested candidate identity, exact Git blob and installed-executable identity, isolated supported success/failure regression, reviewed promotion, and authoritative read-back. Never test a candidate's mutating commands on an occupied live product lane.

The **32,768-byte** source-size architecture limit and its actual source discovery/exceptions are enforced by `projects/nuinuiCAD/scripts/test-nuinui-source-budget`; avoid duplicating that test's evolving path inventory here. Earlier artifact SHA/version and promotion test logs are historical snapshots in the frozen document, **not** current installed-helper identities.

If an active helper is missing, stale, broken, or returns `BLOCKED`, stop; do not silently use old `nuinui`, handcraft an alternative native E2E lifecycle, or weaken admission. Diagnose through the responsible owner and, only when explicitly authorized, use the existing [CHECKOUTS.md](./CHECKOUTS.md) and [Human terminal instructions](../../shared/skills/human-terminal-instructions/SKILL.md) for a bounded exact recovery/repair command. A reusable helper change requires separate review and approval, not an ad-hoc workaround.
