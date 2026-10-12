# nuinuiCAD execution handoff authority

This document owns the implementation-agent startup boundary for nuinuiCAD.
The implementation agent, not the Human or ChatGPT, runs the public handoff
command after receiving the complete prompt.

## Executor selection boundary

The Human selects the Coding Agent product, model, effort, and concrete UI
session outside the implementation prompt and outside this handoff contract.
The prompt may define the implementation-agent role and repository contract,
but it must not require or validate a specific product, model name, or effort
level. A runtime's self-reported model identity is not authorization evidence
and is not a valid reason to reject an otherwise authorized implementation run.

This handoff validates durable repository execution identity and startup safety
only: Issue, lane, claim, branch, Base, checkpoint, checkout state, and
authoritative remote state. It does not validate model identity.

## Transitional Cloudflare mirror shutdown and repair exception — #268 only

The normal public handoff contract below remains required for ordinary
nuinuiCAD implementation. For only the Phase B Worker write-barrier / shutdown
implementation and the approved lossless repair of existing mirror history
and reconciliation required before cutover (Linear-to-GitHub identity mapping,
status drift, Issue / Document comments, and Linear Document reconciliation),
plus corresponding focused tests / configuration authorized by
`sayosomi/dev-context#268`, do not require a new SAY Linear Issue or
`nuinui begin`, this `nuinui handoff`, or `nuinui release`.

Before any edit, the implementation agent uses the existing product checkout
and performs a read-only Git / durable-state proof required by
[`CHECKOUTS.md`](./CHECKOUTS.md): exact repository and registered checkout,
fresh authoritative remote `main`, clean and understood branch / HEAD, no
active implementation claim or audit reservation, no unrelated changes, and
no concurrent product implementation or evaluator audit. If any fact is
missing or ambiguous, stop without mutation. Do not create, delete, initialize,
or rewrite durable metadata for this exception. Continue only with ordinary
sequential Git branch, commit, push, CI, independent blocking review, and safe
PR / merge rules. All other implementation runs use the canonical handoff
below.

## Proposed GitHub-native startup proof — inactive until safety proof

This proposed proof is separate from the active SAY-only handoff below. C1
still prohibits ordinary GitHub-native implementation startup. This section
does not enable that route, change the existing handoff contract, or authorize
the controlled proof run.

The proposed inputs are:

- The canonical GitHub Issue URL or repository-qualified Issue number.
- A freshly verified expected remote main SHA for a new Task, or the exact
  expected remote topic checkpoint for a same-Task continuation.
- The expected topic branch and exact starting checkpoint where relevant.
- The approved contract, acceptance, required verification, and non-goals.

Before any repository mutation, the implementation agent must prove:

- The checkout is the existing /Users/yosomi/Code/nuinuiCAD checkout for
  sayosomi/nuinuiCAD, and its registered-worktree identity is exact.
- The current branch, HEAD, full tracked/untracked status, and remote refs
  match the expected new-Task start or explicitly authorized continuation.
- The agent has freshly fetched and verified authoritative GitHub main and, for
  a continuation, the exact remote topic checkpoint.
- The current GitHub Issue body and material comments still express the
  approved contract. The latest relevant repository policy and normative
  specifications have been re-audited; dependencies and implementation
  readiness remain valid.
- A new Task starts clean, or a same-Task continuation starts clean at the
  exact pushed checkpoint named by the Issue evidence. Dirty state is not
  accepted as a normal recovery checkpoint.
- For a new Task on the declared idle `main` checkout, the existing read-only
  nuinui preflight must report `FREE` / `preflight=PASS` before the controlled
  route starts. For a same-Task native continuation on its expected topic
  branch, do not require the legacy preflight to report `FREE` or `PASS`; a
  clean topic branch without a legacy slot may be `BLOCKED` under that
  classifier. This known classification difference is neither capacity proof
  nor authorization. Instead, apply the independent read-only Git-directory
  metadata and execution-occupancy proof defined in
  [CHECKOUTS.md](./CHECKOUTS.md). Any active legacy claim, mutation lock,
  release-pending tombstone, audit reservation, competing implementation or
  evaluator audit, or missing / malformed / symlinked / inconsistent /
  ambiguous required record remains a hard stop. Do not infer permission from a
  generic `BLOCKED` result, add a second ownership state machine, or change the
  legacy classifier.
- A new Task's exact ChatGPT-approved topic branch is unused and can be
  created from the exact approved base. If the requested local or remote branch
  already exists, stop; ChatGPT must establish and authorize a new exact branch
  before the agent proceeds, and the implementation agent must not choose a
  replacement. A continuation's current Issue checkpoint must name the exact
  Issue, slice, branch, and pushed SHA; the local branch and HEAD and remote
  topic ref must all match that SHA, with clean status. If the local branch is
  absent but the remote checkpoint is exact, create only a local tracking
  branch from that remote ref.

For a new Task, after all checks pass, use the existing checkout, fast-forward
a clean stale main only when ordinary ancestry proves it safe, and create a
fresh topic branch from the verified base. For a continuation, resume only from
the verified pushed topic checkpoint. Do not require a SAY identifier,
nuinui begin, nuinui handoff, nuinui release, or a new durable slot. Do not
introduce a replacement runtime helper as a prerequisite.

Any dirty or untracked checkout, repository or branch mismatch, changed main
or topic checkpoint, active legacy ownership, audit reservation, conflicting
execution, or unresolved policy / contract drift is a hard stop. The agent
preserves state and returns the blocker; it does not retry, repair, reset,
stash, rebase, force-switch, force-push, create another worktree, or infer a
checkpoint from branch naming.

Before the first controlled proof run, the Human must separately approve a
one-run exception naming the proof Issue, exact checkout / base / topic,
approved contract, verification, non-goals, and bounded scope. ChatGPT must
re-audit and reconcile all current startup-blocking owners as enumerated in
[CHECKOUTS.md](./CHECKOUTS.md), not silently override project ISSUES.md,
CHAT-WORKFLOW.md, or
another active owner. This approval cannot be inferred from an ordinary
implementation request or this D1 documentation change. Passing the proof also
does not authorize arbitrary Issues; a separate authoritative activation
checkpoint is required for general use.

The active SAY-only public contract, durable identity resolution, retained
startup proof, and failure behavior below remain unchanged.

## Public contract

```text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui handoff <SAY-N> <expected-main-sha>
```

The Issue and expected authoritative nuinuiCAD `main` SHA are the only public
handoff inputs. The command does not accept or require a prompt file,
expected-context file, lane, claim, branch, Base, checkpoint, topic mode,
ticket, nonce, or caller-managed token.

The expected-main argument is the race-sensitive coordinator expectation used
by the retained exact authoritative-main proof. It does not identify the
execution generation.

## Durable identity resolution

The façade enumerates manifest-declared `role=implementation` lanes using the
existing manifest API and reads each lane's existing durable implementation
slot using `nuinui_ownership_parse_slot`. It must establish exactly one valid
active slot whose durable `issue` equals the requested Issue.

From that one slot and its current checkout it derives:

- lane and checkout repository;
- durable Issue, branch, Base, and claim;
- current local HEAD as the checkpoint.

No second ownership parser or execution-state model is allowed. A missing
match, duplicate matching Issue, malformed slot, invalid checkout, or any
other ambiguous identity is `BLOCKED` or `ERROR`. Resolution is read-only.

## Deterministic remote topic mode

The façade queries exact authoritative remote state with:

```text
git ls-remote --exit-code --heads origin refs/heads/<durable-branch>
```

It derives the internal proof mode as follows:

- remote topic absent: accept `absent` only when local HEAD equals durable
  Base;
- remote topic present: accept `exact` only when remote HEAD equals local
  HEAD;
- network errors, ambiguous refs, mismatches, or absent topic with HEAD
  different from Base: `BLOCKED` or `ERROR`.

The façade never pushes, switches, resumes, repairs, reserves, or otherwise
mutates repository state during handoff. The topic mode is not caller input.

## Retained startup proof

After resolving identity and topic mode, the façade calls the standalone
`projects/nuinuiCAD/scripts/nuinui-handoff-check` proof with those resolved
values. That helper remains the authority for clean state, claimed branch,
durable claim, Base ancestry, checkpoint / HEAD, mutation lock,
release-pending state, exact remote topic, exact authoritative remote main,
and race-sensitive rechecks. It returns `HANDOFF VERIFIED` only after all
startup facts remain stable.

The standalone helper's internal arguments are not a second public contract.
Its focused tests remain because the proof is retained as the single safety
authority.

## Failure behavior

Any handoff failure is terminal for the implementation-agent startup. The
agent performs no repository mutation and returns control to ChatGPT or the
orchestrator. The canonical façade has no automatic branch-mismatch resume,
retry, recovery decision tree, ticket reservation, or replacement-ticket
path.

The implementation agent does not run a second handoff command to diagnose a
failure. The orchestrator must fresh-audit current authority before any later
continuation.

## Human / ChatGPT ordering

The normal implementation sequence is:

```text
Human asks ChatGPT to implement
-> ChatGPT performs current-state and contract work
-> Human runs one short local startup mutation only when genuinely required
-> ChatGPT outputs the complete implementation-agent prompt directly in chat
-> Human copies it to the implementation agent
-> implementation agent runs canonical nuinui handoff
-> HANDOFF VERIFIED
-> implementation / test / commit / push
-> result returns to ChatGPT
```

The Human does not run implementation-agent handoff verification and does not
manage prompt files, expected-context files, ticket refs, ticket tokens,
claims, or checkpoints as transport artifacts. Lane lifecycle still owns
durable claims and checkpoints locally; they are discovered by the handoff,
not transcribed into the public command.

## Versioned owners

- public façade source: `scripts/nuinui-src/handoff.sh`;
- standalone proof source: `scripts/nuinui-handoff-check-src/handoff-body.sh`;
- generated public helper: `scripts/nuinui`;
- generated standalone proof: `scripts/nuinui-handoff-check`;
- focused tests: `scripts/test-nuinui-handoff` and
  `scripts/test-nuinui-handoff-check`.

The public helper is regenerated by `scripts/generate-nuinui`; generated
artifacts are never hand-edited.

## Maintenance rule

Keep this document focused on implementation-agent identity resolution and the
single retained startup proof. Lane mutation, release, integration, and
implementation slicing remain owned by their existing documents.
