# nuinuiCAD Implementation Coding Agent Policy

## Current and legacy routes

This document owns nuinuiCAD implementation Coding Agent selection, its project role boundary and tier-specific causal repair authority, the two direct-execution exceptions, and the autonomous-conformance Issue opt-in. Detailed checkout, handoff, slicing, integration and E2E mechanics remain with their existing owners.

- **Native GitHub D1:** consume the single Human `nuinui-checkout-check` PASS and perform only the prescribed mutation-boundary recheck; use the activated Git-only checkout/startup route in [`CHECKOUTS.md`](./CHECKOUTS.md) and [`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md). Current contract and material checkpoints live in GitHub Issue body/comments; execution evidence in commits/PR/checks. Do not use legacy SAY identifiers, Linear checkpoints or `nuinui begin/handoff/release` for native Issues.
- **Compatible pre-existing SAY:** retain the legacy admitted claim, Base, Integration Watermark, Linear minimum checkpoints and canonical `nuinui handoff` only until that lifecycle is retired. [`CHECKOUTS.md`](./CHECKOUTS.md), [`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md) and [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) own the details.
- **Shared contracts:** [Coding Agent workflow](../../shared/CODING-AGENT-WORKFLOW.md), [prompt style](../../shared/AGENT-PROMPT-STYLE.md), [prompt preflight](../../shared/AGENT-PROMPT-PREFLIGHT.md). Read current execution role/checkout from [`LANES.conf`](./LANES.conf); do not infer lane topology from historical names or the agent's initial `pwd`.
- **D2-C fixed-SHA read-only audit** remains under [`ASTRA-AUDIT.md`](./ASTRA-AUDIT.md). Audit executor escalation, reservation, budgets and final proof are separate from source implementation.

## Implementation agent selection and roles

**Lower-tier Coding Agents (Luna, etc.) are the default.** A Human may explicitly choose an **upper-tier Coding Agent (Astra, Sol Xhigh, etc.)** for ordinary implementation or blocking fixes, including compatible pre-existing SAY execution. Upper-tier selection does **not** authorize autonomous conformance; that scope separately requires the exact Issue-body opt-in below.

The Human chooses the actual product/model/effort and UI session outside the implementation prompt. ChatGPT may recommend a tier and a new session by default; narrow same-branch, same-slice continuation may reuse a session. No product/model/effort or self-reported model family is a prompt-level admission identity.

- **ChatGPT:** fetch fresh remote/current Issue authority; settle product/architecture and acceptance, semantic owner, scope, slice, lane, checkpoints and prompt; decide failure classification, review, integration and merge.
- **Selected implementation Coding Agent:** implement the authorized source slice, test, diagnose in-scope failures, commit/push, and resolve approved integration conflicts. No open-ended product design, unrelated cleanup, unapproved dependencies or architecture decisions.
- **Human:** select actual agent, approve genuine decisions, perform eligible deterministic terminal operations and Human-only Manual E2E. Terminal assistance is not a second source-code implementation executor.

Web ChatGPT may not directly edit nuinuiCAD product source through GitHub. Ordinary source implementation/repair uses an existing manifest-declared `role=implementation` checkout.

## GitHub-native D1 causal repair authority — Human-selected upper tier only

This rule applies **only while the Human has explicitly selected an upper-tier implementation Coding Agent** in the actual UI for the current GitHub-native D1 Task. The lower-tier default (Luna, etc.) retains the existing strict Issue-specific writable file/owner limits and escalation; neither a prompt nor an agent self-report proves upper-tier selection. Switching the executor/tier mid-Task requires ChatGPT/Human to recheck the intended tier-specific Issue scope **before any additional mutation**. This rule does not broaden compatible SAY or convert D2-C read-only audit work into implementation.

The Issue must still bound the **semantic mission and observable acceptance**, independent semantic oracle, relevant producing owners/interfaces, required verification, exclusions, and safety limits. For the Human-selected upper tier only, anticipated file/symbol paths are **guidance, not an exhaustive mutation allowlist**. Once a defect has been independently reproduced against Base and its earliest incorrect producing owner identified, the agent may make the **smallest causally necessary first-owner correction** and directly affected source, tests, fixtures and expected values across previously unlisted paths, without a new per-file Human scope approval. The newly reached files/owners and causal reasons must be reported. Retain exact Base FAIL, neighboring controls, corrected PASS, and required contract-preserving regression, parity and full-suite verification.

An unrelated historical test path qualifies only when the authorized correctness repair itself made an existing assertion/fixture stale **and** the corrected expectation is established independently from the semantic oracle. Never skip, relax, waive or weaken a check, or add a compensating production bypass, to make a failure disappear.

A truly new feature/mission, unresolved semantic oracle or product decision, material semantic-owner/interface/API/architecture/dependency redesign, Human-only GUI/host proof, unsafe/unowned checkout, unexpected drift, exceeding a closed exploration ceiling, or actual process/resource risk still requires a safe checkpoint and **BLOCKED**. Merely crossing an anticipated file-path boundary within the unchanged authorized semantic mission is not a stop condition for the eligible upper tier. All ordinary D1 Human LOCAL CHECK, volatile ownership recheck, non-force Git, independent exact-HEAD review, protected PR/CI, and Human Manual E2E gates remain mandatory. Upper-tier selection **alone** never authorizes autonomous conformance discovery; that mode still needs the separate exact Issue-body opt-in below.

## Execution safety and evidence

Use [`CHECKOUTS.md`](./CHECKOUTS.md) and [`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md) for canonical exact admission/startup. After the Human's one-command PASS, verify only changed/volatile remote `main` and topic refs, branch/HEAD/clean state, and conflicting ownership immediately before mutation; do not rebuild the full inventory. Re-read the current Issue scope and comments. A dirty/untracked file, wrong branch, lock/release state, remote drift, ownership conflict or ambiguity is a stop. Preserve state; no reset, stash, rebase, force, overwrite, deleting user work, new checkout/worktree or legacy-metadata repair. Never merge/rebase main mid-slice; integrate only at the checkpoint in [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md).

Keep changes within the settled semantic mission and agreed verification, applying the tier-specific path/owner boundary above; commit intended files only, normal non-force push, and report branch, Base SHA, exact pushed HEAD, changes, commands/results, acceptance, blockers and residual risks. Retain independent pushed-HEAD blocking review, protected PR/CI and required Human Manual E2E gates. On ambiguous scope, oracle, dependencies or safety, preserve only a safe checkpoint and return to ChatGPT/Human.

For compatible pre-existing SAY, target the assigned checkout irrespective of initial `pwd` and execute the **exact** supplied `nuinui handoff <SAY-N> <expected-main-sha>` as its first identity operation. A failed handoff stops; do not redundantly rebuild helper-owned proof or blindly retry. This command is never a native GitHub startup step.

## Autonomous conformance discovery and repair — explicit Issue-body opt-in

Autonomous conformance is a separately authorized D1 **implementation** mode, not the D2-C audit, a different lane, or a new approval/metadata mechanism. An upper-tier agent can be selected without invoking this mode. The following settled oracle, matrix, budgets and stop conditions remain authoritative.


The current implementation Issue body must contain the explicit field
`Autonomous conformance discovery and repair: authorized` and define every
item below before the mode can start. This is plain Issue-body text, not a new
label or metadata authority. Do not infer authorization from words such as
“audit,” “debug,” “test,” or “conformance,” from a linked read-only audit, or
from historical audit findings.

- **Settled semantic oracle:** cite the current normative nui1 contract and
  state the exact expected semantics needed to judge the cases. If expected
  behavior is ambiguous or requires a product/spec decision, do not opt in.
- **Closed exploration matrix:** enumerate the allowed inputs, transformations,
  endpoints, and other dimensions precisely enough to establish when every
  cell is complete. Do not authorize repo-wide or otherwise open-ended search.
- **Semantic owners and boundaries:** identify the primary compiler,
  evaluator, transport, or language-service owners in scope, plus any relevant
  reference and production paths. Do not delegate new owner or architecture
  choices to the Coding Agent.
- **Bounded distinct exploration:** provide a numeric ceiling on distinct
  compiler-accepted exploratory programs, or an equally explicit countable
  exploration-unit ceiling appropriate to the closed matrix. A distinct new
  exploratory input consumes capacity once; reruns of the same input and
  existing or unrelated suite fixtures run for verification do not consume
  additional exploratory capacity. The ceiling constrains *new exploration*,
  not the number of times authorized cases may be verified. There is no
  automatic defect-family-count stop.
- **Verification is not a cumulative count budget:** do not require hard
  numerical ceilings for canonical compiler invocation attempts, production
  persistent-Rust stdio requests, or repeats of focused regression, parity,
  build, CI, and full-suite verification. These executions may be counted and
  reported for diagnostics and cost awareness, but their totals alone must
  never stop required retesting, independent review, or completion. Human-run
  and agent-run verification obey the same scope and safety contract; changing
  the executor does not bypass or expand the exploration boundary.
- **Execution guardrails:** retain per-test and per-process timeouts, bounded
  individual harness runs, resource and memory safety, detection of
  non-progressing or repeating failures, and explicit process cleanup. On
  actual hangs, resource exhaustion, or other safety failures, preserve a
  safe pushed checkpoint and stop for diagnosis. Prefer existing runner
  controls; do not add a new quota or ledger, promise endless execution, or
  waive platform limits. D2-C read-only evaluator audits retain their own
  separate per-run accepted-program and Rust-request budgets unchanged.
- **Acceptance and verification:** define expected results, required controls,
  reproduction and regression evidence, and the criteria for matrix
  completion. State which production/reference parity checks apply.
- **Exclusions and stop conditions:** name out-of-scope semantics, owners,
  surfaces, resources, and decisions. Require a safe checkpoint if the oracle,
  matrix, owner, checkout, or contract becomes ambiguous, if work would exceed
  the authorized exploration-unit ceiling, or if a process hangs, resources
  are exhausted, required execution cannot progress safely, or a
  product/architecture decision is needed.

One Human-selected implementation Coding Agent owns the complete in-scope
loop for the Issue: generate discriminating compiler-valid cases and calculate
expected results; run the applicable reference/production checks; independently
reproduce and reduce each suspected defect with nearby passing controls; locate
the useful incorrect boundary; add deterministic regressions; make the smallest
owner-correct fix; and reverify the affected cells against the corrected
candidate. Continue across multiple distinct defect families until the closed
matrix is complete or a real stop condition applies. Exhausting the distinct
exploration ceiling stops *new exploratory inputs*, not required re-execution
of already authorized cases or necessary regression and full-suite checks.
If completing the matrix would require new exploration beyond that ceiling,
preserve a safe pushed checkpoint and return the contract decision to ChatGPT.
A defect-family count or accumulated compiler/Rust/test invocation count
alone never stops verification. Do not report cells contaminated by a known
defect as evidence; rerun affected cells on the corrected candidate.
One Issue may cover multiple in-scope defects; do not automatically create a
separate Bug Issue for each family.

Keep edits and tests within the Issue's authorized semantic mission,
owners/interfaces and verification boundary. Only a Human-selected upper-tier
GitHub-native D1 executor may also follow the first-owner and causally stale
regression path exception above; a newly discovered file/producer within the
unchanged mission is not by itself a material scope expansion. Lower-tier
agents retain strict Issue-specific writable boundaries. Do not change the
product specification speculatively, redesign architecture, broaden the matrix,
use external resources, or claim a Human-only GUI result. If the semantic
mission/owner/interface contract materially changes, preserve a safe checkpoint
and return the decision to ChatGPT. Record each distinct family, test seed,
expected and actual result, exact candidate revision, completed and residual
matrix cells, source changes, verification, and Git checkpoints in the existing
Issue/PR surfaces.

This mode remains an implementation Task: use the ordinary D1 Git-only
admission, single registered implementation checkout, GitHub-native branch and
checkpoint lifecycle, independent pushed-HEAD review, protected PR/CI, and
Human Manual E2E requirements. It does not use D2-C audit admission,
fixed-SHA read-only execution, audit reservations, or audit final-checkout
closeout. Manual E2E remains Human-only. Human chooses the actual
implementation-agent product, model, and effort in the Codex UI outside the
prompt. Do not name, prescribe, or verify those selections in the prompt.

## ChatGPT direct-execution exceptions

### Documentation / policy direct execution exception

Repository-owned documentation / specification / policy workはsource-code implementationとは別のexecution classとする。

次の条件をすべて満たすdocumentation/policy Taskは、implementation Coding Agentを使わずChatGPTがremote repository上で直接実行してよい。

- 変更対象が`docs/**`、`AGENTS.md`、repository/project `README.md`、`ARCHITECTURE.md`、CHANGELOG等のrepository-owned documentation / specification / policy fileに限定される;
- source code、test code、fixtures、build設定、CI、runtime behavior、generated artifactを変更しない;
- target file、current problem、change purpose、intended change summaryをユーザーへ事前提示し、ユーザーの明示的な許可を得ている;
- 文面修正だけでなく、新しいproduct / UX / architecture / engineering / operational ruleを決定する変更も、この明示的なplanのscope内であれば対象にできる;
- latest remote repository、current management/spec state、関連するpolicy ownerを確認してから編集する;
- verificationがdocumentation/policy consistencyを確認するread-only / focused checkで足り、source-code implementation-side test-debug loopを必要としない;
- scopeがdocumentation / specification / policy workからsource-code implementationへmaterially拡大しない。

この例外ではimplementation lane、Base checkpoint、implementation-agent sessionを要求しない。ChatGPTが編集、必要なfocused verification、blocking review、commit / push / mergeまで担当してよい。Native GitHub Workのcontract / material checkpointはGitHub Issue body/commentsへ、execution evidenceはGitHub commits / PRs / checksから確認する。Linearへ記録できるのは、compatible pre-existing SAY taskがすでにadmittedされたlifecycle自身から要求するminimum checkpointだけである。

ユーザーの許可なしに新しいrepository policy / product ruleをChatGPT判断だけで直接commitしてはならない。許可済みplanの意味上のscopeを越える場合はwrite前にplanを更新して再承認を得る。

途中でsource code / test / generated outputの変更、broad implementation-side debugging、または許可済みplanを越える変更が必要になった場合は例外を解除し、通常のimplementation Coding Agent lifecycleへ戻す。

### Narrow CI/tooling direct execution exception

CI / repository tooling / automation workのうち、product implementationから独立した**狭く一意なCI/tooling-only変更**は、source-code implementationとは別のexecution classとする。

次の条件をすべて満たすTaskは、implementation Coding Agentを使わずChatGPTが直接実行してよい。

- targetがCI workflow / CI config、repository-only automation / tooling、またはrepository checkの狭い配線変更に限定される;
- product source implementation、runtime semantics、DSL semantics、fixtures、generated artifacts、product build output / packaging semanticsを変更しない;
- latest remote repositoryからintended changeが一意に決まり、implementation scopeが狭い;
- target file、current problem、change purpose、intended change summaryをユーザーへ事前提示し、ユーザーの明示的な許可を得ている;
- verificationがread-onlyまたはfocusedなCI/tooling checkで完結し、broad test-debug loopを必要としない;
- Manual E2Eを必要としない;
- conflict resolution、integration-heavy work、またはambiguous failure diagnosisを必要としない。

典型例は、既存CI jobへrepository内にすでに存在するcheck commandを1 step追加するだけで、上記条件をすべて満たす変更である。

この例外ではdeclared execution lane、Base checkpoint、implementation-agent sessionをclaimしない。ChatGPTがbranch、edit、focused verification、blocking review、commit / push、PR、mergeを担当してよい。Work記録はcurrent authorityに従い、native GitHub WorkではGitHub Issue / repository evidenceを使う。minimum Linear compatibility checkpointはcompatible pre-existing SAY taskに限る。

write直前にlatest remote SHAとtarget file freshnessを再確認する。freshness driftによってintended change、scope、またはverification routeが一意でなくなった場合はwriteせず再評価する。

途中でproduct source / runtime behavior / DSL semantics側の変更、broad debugging、conflict resolution、integration-heavy work、またはその他の除外scopeが必要になった場合はdirect executionを停止し、通常のimplementation Coding Agent + declared implementation lane lifecycleへ戻す。

このexceptionは旧 `only_chatgpt` execution model全体を復活させるものではない。

## Human assistance and legacy integration

**Single obvious source fix:** a Human may run one specifically authorized textual `exact-fix` invocation only under the eligibility, scope and safety checks in [`CHECKOUTS.md`](./CHECKOUTS.md) and [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md). No general source implementation, design, debug loop, conflict resolution or ambiguous repair is authorized.

**Deterministic conflict-free legacy integration:** after fresh Base/current-main drift and contract audit, eligible conflict-free merge-only integration with settled verification may use Human `nuinui integrate-clean`. Relevant semantic drift, conflicts, verifier diagnosis, source changes, integration repair or uncertain state return to the assigned Coding Agent. Existing Review Head/Integration Watermark and required CI/blocking review remain in force. See [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md), [`CHECKOUTS.md`](./CHECKOUTS.md), and [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md).

Simple deterministic terminal commands are Human assistance under [`CHECKOUTS.md`](./CHECKOUTS.md) and [shared Agent Skills](../../shared/AGENT-SKILLS.md), not transfer of source ownership. Confirmed Manual E2E implementation failures are fixed on a free implementation lane, **not** in the Human-test checkout, and rerun on a new exact tested commit under [`MANUAL-E2E.md`](./MANUAL-E2E.md).

## Continuity

Current native Work uses GitHub Issue body for scope, Issue comments for decisions/pushed continuation checkpoints and commits/PR/checks for implementation facts. Compatible pre-existing SAY alone retains minimum legacy Linear checkpoint records. Reconstruct current remote/Issue authority across chats; do not manufacture lengthy handoff transcripts.

Canonical owners: [`CHECKOUTS.md`](./CHECKOUTS.md) (checkout, admissions and exceptions), [`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md) (startup), [`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) (slicing and integration), [`AGENT-SKILLS.md`](./AGENT-SKILLS.md) (skills), [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) (helpers) and [`MANUAL-E2E.md`](./MANUAL-E2E.md) (Human testing).
