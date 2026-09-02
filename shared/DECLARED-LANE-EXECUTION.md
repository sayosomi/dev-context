# Declared-lane execution model

This is the sole normative shared owner for local execution lanes. Project
documents may describe their current manifest and workflow, but they must not
define a second topology or state machine.

## Topology and capacity

`LANES.conf` is the authoritative topology for a project. It is plain data,
never shell: it is parsed by the generic manifest owner and is never sourced,
evaluated, or executed. Each declared entry has a stable lane name, a role,
an absolute checkout path, and an idle policy. The repository identity and
default branch are also declared there.

The two supported roles are `implementation` and `human-test`. Capacity is
the number of declared entries of each role. Implementation inventory is
reported in manifest declaration order; lane names such as `main`, `sub`, or
`e2e` have no special meaning. A topology edit is a configuration change and
must affect the next invocation without changing executable source or
regenerating a helper.

The registered-worktree inventory consists of all declared lane paths and
their repository worktrees. A Human-authorized forensic worktree may be
supplied as exactly one absolute, canonical, registered extra path for one
`preflight`, `begin`, or `start` invocation. It is a one-shot inventory
exception, is not a declared lane, and never adds execution capacity.

## Runtime states

`FREE` means the declared checkout is clean and satisfies its idle policy,
with no active ownership, lock, or release-pending state. `BUSY` means a
valid implementation slot owns an Issue generation. `RELEASE-PENDING` means
release mutation has moved the slot into its durable tombstone. `BLOCKED`
means the required state cannot be proven or an ambiguity was found. A
missing or malformed manifest, unknown lane, wrong role, unreadable checkout,
or inconsistent worktree is never interpreted optimistically as `FREE`.

## Durable v1 ownership

The generic ownership owner preserves the existing v1 metadata format. Each
initialized implementation checkout has an exact `version=1`
`nuinui-implementation-v1` marker. A live generation is represented by a
strict `nuinui-implementation-slot/state` containing Issue, branch, Base, and
claim. A mutation lock records operation, Issue, branch, Base, checkpoint, and
claim. Release uses a `nuinui-implementation-slot.releasing.<claim>` tombstone
and its checkpoint file, then writes the strict
`nuinui-implementation-release-receipt`. These records are durable identity,
not inferred from branch names or checkout paths.

## Mutation boundaries

`verify` proves initialization, a `FREE` target, expected Base, branch
collision absence, and clean/idle checkout. `lane-init` admits only a
declared implementation lane and proves its canonical idle checkout before
writing an idempotent v1 marker. `begin` and `start` validate complete
declaration-order inventory, acquire the lock before mutation, and retain
ambiguous durable state when a checkout mutation might have occurred.

`resume` requires exact lane, Issue, Base, checkpoint, branch, and claim
identity. A failure before checkout mutation may remove only its own lock when
the original checkout state is re-proven; possible checkout mutation remains
for explicit recovery. `release` requires exact claim and merged checkpoint,
fresh authoritative default-branch ancestry, branch/ref proof, clean checkout,
and safe idle restoration. Release writes the tombstone before checkout
cleanup and receipt completion; partial failure retains recoverable state.
`recover` is claim- and operation-specific, never a general repair command.
It performs no reset, stash, force switch, or guessed cleanup.

Duplicate operations are read-only. In particular, duplicate release is
accepted only after the complete receipt, initialization marker, tombstone
absence, lock absence, checkout idle proof, Base-to-checkpoint ancestry, and
checkpoint-to-fresh-authoritative-default ancestry are all re-proven.

## Human-test execution

Human-test commands accept an explicit declared Human-test lane. Short forms
are compatibility syntax only when exactly one Human-test lane is declared:
zero lanes block, and two or more lanes require explicit identity. Persisted
session metadata records the exact lane where session identity is required.
Marker and receipt files are physically scoped to the selected lane's Git
directory and are interpreted only through that selected declared-lane
context. Lane identity is never reconstructed from a marker or receipt
filename, a path, declaration order, or a literal global E2E lane name.

The project Human-test policy remains separate from topology. It owns exact
Issue/tested-ref marker and session semantics, process ownership, receipts,
cleanup ordering, and any explicit local-main source-lane policy. Human
remains the Manual E2E executor unless a project policy explicitly says
otherwise.

## Fail-closed data and recovery rules

All lane-sensitive commands validate the manifest before mutation. Values are
looked up through the data-only parser. Shell syntax, command substitutions,
symlinks, malformed fields, unsupported versions, unreadable files, wrong
roles, stale remote data, and races are rejected before mutation or retained
as ambiguous recovery state. Standalone helpers derive the manifest from
their own versioned project `scripts` directory; normal production invocation
does not accept an ambient manifest redirect.

Generic executable sources are assembled into standalone helpers in explicit
deterministic order. A generated helper does not dynamically source
development files at runtime, and topology changes do not require source
edits or helper regeneration.
