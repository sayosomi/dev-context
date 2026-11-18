# nuinuiCAD VS Code Manual E2E environment

## Scope and authority

This document owns the **native VS Code production-host-specific baseline**: isolation, signed app, immutable tested build, profile/fixture, host readiness, generation/session ownership, and safe teardown/recovery.

- [MANUAL-E2E.md](./MANUAL-E2E.md): when Manual E2E is required, declared units/oracles, Human execution/judgment, stop/pause, failure triage and evidence.
- [CHECKOUTS.md](./CHECKOUTS.md#native-human-manual-e2e): manifest-declared Human-test checkout, native lifecycle, identity/ownership, interrupted state and final proof.
- [LOCAL-TOOLS.md](./LOCAL-TOOLS.md): active `nuinui-e2e --production` interface and legacy helper boundary.
- [ISSUES.md](./ISSUES.md#native-github-manual-e2e-checkpoints): canonical GitHub Issue plan, start, progress, Human results, recovery and closure checkpoints.
- [VS-CODE-E2E-LOCALE.md](./VS-CODE-E2E-LOCALE.md): locale-specific test only.
- [VS-CODE-E2E-INPUT-TROUBLESHOOTING.md](./VS-CODE-E2E-INPUT-TROUBLESHOOTING.md): abnormal pointer/mouse state only.

The **Human alone** operates the real GUI and makes PASS/FAIL judgments. Helper admission, immutable-build validation, fixture check and host readiness are setup evidence, not product PASS.

## One-command Human E2E startup

After confirming the current Issue plan, exact tested SHA, reverse map,
stabilization eligibility and checkout ownership, start the registered
human-e2e lane with one command:

~~~
nuinui-e2e ready --production --issue <canonical-GitHub-Issue> --tested-sha <40-lowercase-sha> [--fixture <absolute-external-file>] [--locale default|ja]
~~~

ready allocates a unique generation and free loopback port, uses the reserved
default .nui fixture when --fixture is omitted, validates the signed Microsoft
VS Code app and exact immutable dogfood snapshot, starts the clean Human-test
checkout at the requested SHA, and launches the isolated Extension
Development Host. It prints the tested SHA and snapshot identity at launch,
then reports the generation, fixture, port and locale.

An existing snapshot is selected by its exact tested SHA and Mac
architecture. Its validity comes from the snapshot metadata and full content
hashes; current.json does not select the build. This permits a previously
tested SHA to be used when its exact immutable snapshot exists, even if the
implementation checkout is dirty or on another branch. If the exact snapshot
is absent, the helper may call the existing dogfood:build owner only when the
implementation checkout is clean main at that exact SHA and matches
origin/main. Otherwise startup is BLOCKED before native generation or host
session creation; there is no alternate build route.

On HUMAN E2E READY, the Human establishes each declared initial state, runs
the product actions in VS Code, observes and judges them, and returns concise
result/evidence. Host readiness is setup evidence, never product PASS. Record
relevant observations and transient failure evidence before teardown. Normal
host-closure performs checked owned-host cleanup, checkout release and final
clean/idle proof for the same generation.

If the command reports BLOCKED, exits nonzero, or returns an identity
mismatch, stop and report the actual output. Do not retry with a new generation
or infer success. Use the exact printed generation with host-status,
host-recover or host-closure only under their ownership checks. The Human-test
lane remains clean and detached when idle; startup still verifies its current
idle revision and exact ownership.

Production rejects caller-provided manifests/adapters and
NUINUI_E2E_TEST_* overrides. --self-test is fixture-only, not production
authorization. The individual admit, start, host-check and host-prepare
commands remain available for diagnosis and established recovery workflows;
ready is the normal startup entry point.

## Isolated VS Code and fixture baseline

The production host must not silently inherit the Human's normal VS Code profile, settings, keybindings or installed extensions. The helper owns:

- isolated `--user-data-dir`, initially empty `--extensions-dir`, required `--extensionDevelopmentPath`, disabled workspace-trust prompts and suppressed welcome/release-note surfaces;
- profile settings that prevent built-in word-based, inline, quick and snippet suggestions from confounding nuinuiCAD completion/interaction observations;
- the exact tested immutable extension and Rust evaluator artifacts; do not rebuild or substitute binaries from a different checkout;
- identifiable task-specific `.nui` fixture outside every source checkout/worktree, opened as a file rather than relying on the repository workspace;
- owned host process, root, profile, CDP listener and session metadata bound to one exact native E2E generation.

Those are preparation conditions, not extra Human product test cases. For exact profile flags and fixture materialization, use the versioned helper implementation rather than copying a large inline launcher or changing the Human's everyday VS Code settings.

Before a declared action, confirm the intended fixture and initial state actually exist and the relevant contributed extension/language registration is usable. A source-specific command must be checked on the surface that exposes it, not in an unrelated Canvas-only context. Missing activation, unexpected modal or wrong fixture is setup `BLOCKED`, not an immediate product failure.

## Meaningful VS Code test coverage

[MANUAL-E2E.md](./MANUAL-E2E.md) owns test-unit grouping, screenshot evidence, Objective/Human judgment and implementation-backed mapping. For Webview/Canvas/Output commands, preserve **cold vs warm** surface paths when they materially change execution. If a command must open a surface, the same invocation must also complete the requested focus, selection/navigation or operation. Add active/inactive cases only for genuinely different behavior; do not make a Cartesian matrix of every state.

For theme-sensitive Human visual acceptance, retain one representative **Light and Dark** theme, with theme names in evidence. After a theme-specific fix, repeat the exact failing theme; if shared theme-resolution logic changes, confirm both. Do not repeat nonvisual Objective units across themes.

Combine scenarios/screenshots when one fixture/initial state safely proves them; live Human observation is needed for drag, focus, transition and other dynamic behavior not proved by a static screenshot. Additional screenshots are driven by failure or ambiguity, not a fixed count. User-profile interoperability is a separately declared test, not part of the isolated baseline.

## Host failure, interruption and safe recovery

For unexpected `host-prepare` errors, hangs, process exits or session mismatch:

1. Classify it as host/setup `BLOCKED` until actual-host evidence proves otherwise; never infer a product FAIL from a failed launch.
2. Read `host-status` for the **same** Issue, generation and tested SHA, with responsible checkout/helper metadata. Preserve material start/stop evidence in the canonical Issue.
3. Apply only an authorized exact-generation `host-recover` / `recover` or other helper-owned cleanup procedure whose process/root/marker/session ownership is freshly proved. Ambiguity, live/foreign owners, changed snapshots or malformed receipts remain blocked.
4. Restore required fresh initial state before any rerun and retain failure evidence where still possible.

Do **not** search temporary parents to guess a session root, synthesize a PID, kill/delete foreign processes, edit markers/metadata, recreate the Human-test checkout, bypass recovery with an inline launcher, or turn a helper error into an alternate old SAY workflow. Proven exact duplicate/no-op success needs no redundant confirmation; near matches do not count.

Host/OS permissions and modal prerequisites (e.g. macOS privacy prompt, VS Code trust or missing registration) are environmental `BLOCKED`. Correct only the specific prerequisite; do not require Full Disk Access for all runs. For widespread abnormal Canvas pointer behavior, consult [input troubleshooting](./VS-CODE-E2E-INPUT-TROUBLESHOOTING.md) before concluding product failure.

## Relaunch and checked closure

A changed tested SHA/build, repaired shared runtime, invalidated profile/fixture or lost host requires fresh exact-generation admission/preparation under the canonical helper. An old VS Code process cannot prove a new tested build. Recreate declared cold/initial states for affected units; previously passed unaffected units need not repeat merely for completeness.

Collect material transient evidence before cleanup when required for Human actual-host failure classification. Human stop/pause supersedes further operations without inventing PASS/FAIL. After authorization, `host-closure` binds the exact generation's cleanup receipt to checkout release and independently proves returned idle topology, detached revision and clean state. Incomplete/ambiguous closure prevents reuse until exact recovery is settled.

## Immutable legacy reference

Compatible **already-admitted SAY** operations can still use their original historical preparation and release under [CHECKOUTS.md](./CHECKOUTS.md#compatible-pre-existing-say-nuinui-operations--historical-reference) and [LOCAL-TOOLS.md](./LOCAL-TOOLS.md#legacy-say-compatibility--historical-not-a-new-work-route). The [frozen pre-cleanup VS Code inline launch and SAY guidance](https://github.com/sayosomi/dev-context/blob/910724f722ce9fa2143939a3d6c228470fee837b/projects/nuinuiCAD/VS-CODE-E2E.md) is immutable legacy reference **only**, never a fallback for `nuinui-e2e --production`. `LUNA-E2E-PLAYBOOK.md` likewise remains inactive and must not be loaded in normal Human E2E.
