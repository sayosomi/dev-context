# nuinuiCAD implementation slicing policy

## Scope and current routes

This document owns **implementation slice boundaries**, safe checkpoints, integration timing, and
post-integration drift decisions. Work/Issue decomposition belongs to
[`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md); checkout admission to
[`CHECKOUTS.md`](./CHECKOUTS.md) and [`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md); agent selection to
[`CODING-AGENT.md`](./CODING-AGENT.md); PR/review/CI/merge to [`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md).

- **GitHub-native D1 (active):** use the existing single product implementation checkout and Git-only
  lifecycle. The canonical `sayosomi/nuinuiCAD#N` Issue body owns scope/acceptance; Issue comments own
  material decisions and exact pushed checkpoints. No SAY identifier, Linear checkpoint, or legacy
  `nuinui begin/handoff/release` applies.
- **Compatible pre-existing SAY only:** already-admitted legacy generations retain their declared lane,
  durable claim, minimum Linear checkpoints, and eligible `nuinui integrate-clean` assistance. The last
  section adds these rules; they never grant a native D1 route.
- **D2-C evaluator audit:** fixed-SHA and read-only under its separate admission; no concurrent product
  implementation or conversion of audit findings into source-edit permission. See
  [`ASTRA-AUDIT.md`](./ASTRA-AUDIT.md) and [`CHECKOUTS.md`](./CHECKOUTS.md).
- **Human Manual E2E:** remains Human-only. Native general activation and eventual legacy-helper
  retirement belong to [dev-context #286](https://github.com/sayosomi/dev-context/issues/286), not this
  policy.

One Issue may require several **sequential slices/PRs**. Same Issue does not mean same branch, PR,
session, or uninterrupted track. Work decomposition (new leaf Issue) and implementation slicing (PR
boundaries within one Issue) are separate decisions.

## Plan the natural slice

**One slice uses one authorized implementation checkout/lane and one fixed Base checkpoint through its
next safe checkpoint.** Do not predeclare every future PR. Before execution, inspect the *whole current
acceptance* against the latest repository and record:

- current acceptance cluster, primary semantic owner/API/data-flow boundary, and intended observable
  result;
- prerequisite/downstream dependencies, shared owners, lifecycle/integration boundaries, and competing
  work;
- whether each candidate slice is independently verifiable and intermediate merge leaves coherent
  repository state;
- selected checkout/lane, fixed Base SHA, topic branch, next safe checkpoint, and required verification.

A useful boundary sequence, only when it matches real ownership, is semantic/type foundation →
host-neutral planner/transformation → adapter/protocol/runtime → host lifecycle wiring →
interactive/production-host acceptance.

**Do not force a split** when an intermediate merge would break the product, duplicate a source of
truth/owner, require artificial temporary APIs or compatibility layers, interrupt an indivisible
cross-boundary transaction, lack its own verification oracle, or increase overhead without improving
review, diagnosis, or rollback. PR size, Issue count, and lane utilization are not goals.

For D1, keep one active product implementation track. For already-admitted SAY work with another BUSY
lane, use the legacy parallel-admission rules below; a FREE lane alone is not authorization.

The ordinary lower-tier Coding Agent default, Human-explicit upper-tier choice, and the **separate exact
Issue-body autonomous-conformance opt-in** belong to [`CODING-AGENT.md`](./CODING-AGENT.md). An opted-in
agent may investigate and repair multiple in-scope defect families under its closed matrix and
numeric distinct-input exploration budget; neither family count nor accumulated verification invocations
alone requires stopping or splitting. Exhausting that discovery budget stops new inputs, not required
re-execution of authorized cases or regression/full-suite verification. Do not broaden the Issue oracle,
owners, or budget through slicing.

For a Human-selected **upper-tier GitHub-native D1 implementation executor only**, a previously unlisted
first-incorrect producer or causally stale regression fixture may be repaired across file paths without
per-file approval, provided the authorized semantic mission, owner/interface contract, oracle and
verification remain unchanged. Evidence-based re-identification of the actual first-incorrect producer
within that unchanged semantic mission is not itself semantic ownership redesign; a material change to
the owner/interface contract still requires re-evaluation. Record new file/owner paths and causal
evidence. This does not change the fixed Base, closed exploration ceiling, checkpoints, integration, review, CI or E2E gates.
Lower-tier agents keep their strict Issue-specific writable paths; changing tier mid-Task requires
rechecking the intended scope before further mutation. See [`CODING-AGENT.md`](./CODING-AGENT.md).

## Safe checkpoints

### Implementation checkpoint

The current work is committed/pushed to its authorized remote topic branch so another chat or agent
session can resume without reconstructing unsaved work. Record the canonical Issue, slice/owner, Base
SHA, branch, **exact pushed head**, completed and remaining acceptance, verification/failure classes, and
next safe action.

For interrupted native work, independently match the current Issue, exact remote topic SHA, local
branch/HEAD/clean status, and recorded pushed checkpoint before resuming; never infer a push from lost
output or blindly replay a mutation. See [`CHECKOUTS.md`](./CHECKOUTS.md) and
[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md).

Pause/handoff at a pushed checkpoint. A checkpoint alone does **not** incorporate newer `main` or release
a legacy lane. GitHub-native checkpoints go to current GitHub Issue comments; legacy SAY also retains its
separately required minimum Linear record.

### Merge checkpoint

An intermediate slice may merge only if it forms a reviewable semantic change, completes focused
verification, is pushed, leaves the intended base coherent, and permits remaining acceptance without an
implicit dependency on unmerged work. Protected PR/CI and exact pushed-HEAD blocking review remain
mandatory under [`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md).

### Integration checkpoint

The ordinary point for incorporating current `main` is **after** implementation and focused verification
have been pushed, **before** blocking review/merge. Never routine-merge/rebase `main`, cherry-pick
unrelated work, or absorb another lane's unfinished branch mid-slice.

```text
fixed Base -> implement / focused verify -> push checkpoint
-> inspect Base..current main and current contract
-> integrate only as needed at the safe checkpoint
-> required verification -> Integration Watermark
-> independent exact pushed-HEAD blocking review -> protected PR/merge
```

ChatGPT audits Base/current-main semantic drift and the current contract. The assigned implementation
Coding Agent handles integration requiring source reasoning, conflict resolution, code changes, or
verifier diagnosis. Only compatible pre-existing SAY work may instead use
Human `nuinui integrate-clean` only under the legacy conditions below.

If a remote advance **materially invalidates** scope, semantics, owner, or prerequisite before this
checkpoint, preserve current work remotely and stop for contract/slice re-evaluation rather than merging
mid-slice. An unrelated advance does not change the fixed Base.

### Integration Watermark, Review Head, and later drift

Routine integration normally happens **once per slice**. After integrating a particular `main` SHA and
completing required verification, record it as the **Integration Watermark**. A subsequent blocking fix
does not erase that watermark or automatically restart routine integration:

```text
watermark -> blocking review -> in-scope blocking fix
-> focused / required verification -> pushed exact-head re-review
```

If `main` advances after the watermark, inspect `Integration Watermark..current main` and classify
**Post-integration Drift**:

- **NON-INTERFERING:** no material change to this slice's semantic owner, shared API/primitive,
  prerequisite, contract, mergeability, or review premise. Do **not** reintegrate just to follow `main`.
- **RELEVANT:** material change to an owner/shared primitive/prerequisite/contract, or the review
  premise can no longer be maintained unambiguously. Require exception integration or contract/slice
  re-evaluation.
- **MERGE-GATE:** actual conflict/unmergeable state, or the repository's current merge requirement
  explicitly demands a branch update. Perform the necessary integration and checks.

For a `RELEVANT` or `MERGE-GATE` exception, integrate, rerun required verification, update the watermark
to the integrated `main` SHA, and perform blocking review appropriate to the changed premise. Do not
exception-integrate merely to be current. Repeated exceptions caused by overlapping active legacy lanes
indicate contention: reassess scheduling and prefer sequential merge, not repeated refresh.

A blocking review PASS identifies the exact topic SHA as **Review Head**. Before PR/auto-merge/merge,
freshly check `main`, later drift, mergeability, required CI, and authorization. `NON-INTERFERING` drift
alone neither invalidates Review Head nor forces integration; a fresh actual merge-gate requirement still
applies. New source fixes or integration that changes the pushed head require the relevant independent
review and CI gates. See [`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md).

## Re-evaluate boundaries when evidence changes

Re-evaluate the slice/owner map at the start of each slice and when:

1. A shared owner/adapter changes the material API, contract or data-flow boundary, or a repair
   requires a materially new semantic mission, owner/interface contract or architecture (not merely
   an unlisted first-incorrect file inside the unchanged authorized mission).
2. A pause/resume exposes changed prerequisites, dependencies, or an uncertain checkpoint; a material
   remote `main` change invalidates the premise.
3. Failure classes or semantic changes require acceptance outside the agreed oracle, blocking fixes
   require material semantic owner/architecture expansion, or Human Manual E2E reveals a new failure class.
4. Post-integration drift becomes `RELEVANT` / `MERGE-GATE`, or an active legacy parallel lane expands
   and defeats its `LOW` interference premise.

File/line/commit counts, elapsed time, and `NON-INTERFERING` `main` advances alone are **not** triggers.
For the Human-selected upper-tier D1 implementation executor, crossing anticipated file paths to fix
an independently demonstrated first-incorrect producer or causally stale historical test is also
**not by itself** a slice/owner reauthorization trigger. Re-evaluate material semantic expansion, not
file-path drift; retain causal evidence and all relevant regression controls. For lower-tier agents,
existing explicit writable file limits and escalation still apply.
A routine same-generation resume does not automatically require a fresh Base, claim, or integration.

Choose one outcome:

- **A — Same Issue, same slice:** inseparable acceptance or unsafe intermediate merge; keep the
  authorized branch/lane and fixed Base until integration.
- **B — Same Issue, next PR:** current slice merges coherently and remaining acceptance still belongs to
  this Issue; preserve the Issue, then start the next slice from freshly verified `main` on a fresh
  branch. Do not construct accidental stacked PRs.
- **C — New/extracted leaf Issue:** truly independent scope, owner, observable acceptance, and safe
  merge/verification boundary; follow [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md), not PR size.
- **D — Blocker/contract reset:** missing prerequisite, unsettled product/UX/scope decision, or unsafe
  boundary; push a safe checkpoint and stop. Do not hide missing semantics through slicing.

Intermediate PRs do not complete an Issue. For GitHub-native work, record each slice and remaining
acceptance in Issue comments; re-read current Issue and latest `main` before the next slice.
Use `Refs #N` for intermediate or still-incomplete acceptance, and `Closes #N` only
when full acceptance—including
required Human Manual E2E—is verified. Exact PR linking, review, CI, merge, and completion gates belong
to [`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md) and [`ISSUES.md`](./ISSUES.md).

## Verification and Human E2E failure

At the first integration through a changed boundary, verify at least one **observable end-to-end
result**, not just an internal helper: e.g. adapter output/resulting source, resolved runtime-consumed
values, serializer round-trip, or host-visible query result. Run appropriate broad integration
verification at that checkpoint rather than automatically deferring it to final Issue completion.

A confirmed Human Manual E2E implementation failure is **never fixed in the Human-test checkout**.
Classify implementation/environment/capability/oracle, identify failure class and semantic owner, decide
same Issue versus independent leaf, and return any implementation fix to an authorized implementation
Coding Agent after proper checkout admission. For legacy parallel work, also satisfy parallel admission.
Verify/review/merge the fix; rerun affected E2E units from their declared initial state at the **new
exact tested commit**. Previously passed, unaffected units need not repeat unless shared owner/contract/lifecycle
premises changed. Stabilization/re-entry and Human-only outcome judgment remain with
[`MANUAL-E2E.md`](./MANUAL-E2E.md).

## Compatible pre-existing SAY only

**This section does not apply to a new GitHub-native Issue.** Existing admitted SAY generations keep
their manifest-declared lane, durable claim/Base, minimum Linear records, and `nuinui` lifecycle until
separate retirement under [#286](https://github.com/sayosomi/dev-context/issues/286). Current
`LANES.conf` and [`CHECKOUTS.md`](./CHECKOUTS.md) own actual capacity/physical state;
[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md) owns durable handoff.

### Lane selection and cross-lane dependencies

Before a new legacy implementation start, ChatGPT reconciles fresh remote state, actual Linear occupancy,
and the Coordinator's [parallel admission gate](./CHAT-COORDINATOR.md). Route an admitted start through
the single `nuinui begin` operation described in [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md); that helper
performs its full declared-lane audit rather than requiring a second Human preflight.

- If all implementation lanes are BUSY, do not start another implementation. The Human-test lane is never
  implementation capacity.
- If another implementation lane is BUSY, admit a legacy Task only with **LOW** interference: distinct
  primary owners and no material overlap in shared APIs, prerequisites, or integration surfaces. `MEDIUM`
  / `HIGH` or uncertain independence means no parallel start; leave FREE unused.
- If the other lane's scope materially expands before actual start, re-evaluate admission. Do not create
  extra lane/worktree capacity or assign lanes merely to keep them busy.
- Independent lanes keep separate fixed Bases. Never import another lane's unfinished branch/mid-slice
  commit or sync just because it advanced. If a real prerequisite emerges, push/pause the dependent lane,
  merge the prerequisite, then rebuild dependent work at its next integration/restart checkpoint. No
  stacked PR by default.

After a successful legacy begin, the selected Coding Agent executes the **exact**
`nuinui handoff <SAY-N> <expected-main-sha>` in its checkout. Continue only on
`HANDOFF VERIFIED`; failure stops without
agent-side retry/repair or redundant Human proof. A chat/agent-session rotation, same-generation blocking
fix, integration, or unrelated `main` advance alone does not require another begin/claim/preflight.
Follow [`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md).

### Deterministic Human integration exception

At the first/routine Integration checkpoint, Human `nuinui integrate-clean` is eligible **only when**
ChatGPT freshly audits Base/current-main drift and contract and confirms a conflict-free, merge-only
operation with settled exact verification. It requires exact pushed implementation checkpoint, same
durable generation, fresh `main`, known verification plan, and no source edit, conflict, integration fix,
ambiguous diagnosis, or new Manual E2E request. **No prior watermark or Review Head is required for this
first use.** Successful `INTEGRATION PUSHED` records merged main SHA as the watermark and proceeds to
pushed-state blocking review.

For a **post-review merge-gate refresh**, require the already-reviewed exact Review Head and existing
watermark; ChatGPT must freshly classify drift `NON-INTERFERING` and establish that current-base
CI/branch freshness is the *only* merge-gate demand. After successful helper push, update the watermark,
perform focused independent blocking review of parents/effective diff/verification/remote state, and
obtain fresh required PR CI.

A stale or mechanical precondition failure may remain on this deterministic route only after ChatGPT
uniquely re-evaluates it from fresh evidence, with no source reasoning. Conflict, relevant/ambiguous
drift, code change, failed verification requiring diagnosis, or ambiguous repository state goes to the
**assigned implementation Coding Agent**, never an ad-hoc Human integration/debug loop. The helper is
terminal assistance, not a second source executor. [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) and
[`CHECKOUTS.md`](./CHECKOUTS.md) own execution details.

### Legacy checkpoint and release records

At lane start/pause/next PR, preserve the minimum external `Implementation checkpoint` fields required by
[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md), **including durable Claim**, lane, Issue, branch, immutable
Base, exact pushed checkpoint, completed/remaining acceptance, current/next slice, and next safe action.
Do not maintain a competing shortened template here. Record Integration Watermark, Review Head and
Post-integration Drift as needed so a rotation does not repeat integration.

A same-Issue next PR may use a newly admitted lane/branch and freshly verified Base after the prior slice
merges; do not silently reuse the previous branch or release an active generation solely because an
intermediate PR merged. Keep minimum Linear status/checkpoint semantics and actual lane release/recovery
with [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md), [`CHECKOUTS.md`](./CHECKOUTS.md), and
[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md). Do not apply these records or helper steps to GitHub-native D1.
