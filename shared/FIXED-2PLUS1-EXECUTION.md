# Fixed 2+1 Execution Model

This document is the normative owner for the reusable execution mechanics shared by projects that adopt the fixed 2+1 profile.

## Capacity and states

The model has exactly two implementation lanes, lane A and lane B, and exactly one Human-test lane. Each lane admits at most one task. The model is intentionally not a worker pool, scheduler, queue, or configurable lane-count system.

An implementation lane is `FREE` only when its durable initialization is valid, its checkout is clean and in the profile-defined idle form, its HEAD equals the authoritative default-branch tip, and no lock, active slot, or release-pending state exists. It is `BUSY` when a valid ownership slot identifies the task and generation and the checkout remains consistent with that slot. It is `RELEASE-PENDING` when the active slot has been moved into one valid claim-specific release tombstone. It is `BLOCKED` for malformed, conflicting, stale, ambiguous, or unverifiable state.

The Human-test lane follows the same one-task capacity rule. Its project adapter may add process or session policy, but the shared lifecycle fixes one exact tested reference at a time and fails closed when the checkout, marker, session, or receipt cannot be proven consistent.

## Durable generation ownership

Each implementation generation has a durable ownership slot containing the lane's task identity, topic branch, fixed Base checkpoint, and generation claim. The claim is an opaque, unique mutation identity; it is never inferred from a branch name or reconstructed from external task status.

The Base is captured at admission and remains fixed for that generation. `begin` validates the complete two-lane admission condition and starts a new generation. `start` is the lower-level primitive. `resume` requires the caller to provide the exact lane, task, Base, checkpoint, branch, and claim and matches all of them against the durable slot and repository state.

The exact checkpoint is the caller-supplied commit being resumed or released. It must be a valid full commit identity and must satisfy the operation's ancestry and remote-readback proofs. A newer default-branch tip does not silently refresh the generation's Base.

## Mutation safety and release

A mutation lock is created before a lifecycle operation changes checkout or branch state. Its operation, task, branch, Base, checkpoint, and claim are strict durable evidence. A lock, malformed lock, or conflicting lock state blocks ordinary lifecycle commands until the narrow supported recovery path can prove the exact operation.

Release first validates the active slot and exact checkpoint/claim. It then moves the slot to a claim-specific release tombstone before checkout cleanup. The tombstone records the release checkpoint and remains if completion cannot be proven. A completed release writes a durable receipt containing the generation identity, removes the tombstone and lock, and leaves the implementation lane in its profile-defined idle form. Duplicate release is a read-only no-op only when the receipt, current idle state, and authoritative default branch provide the complete exact proof.

Recovery is narrow and evidence-driven. It never expires, guesses, rewrites, resets, stashes, force-switches, force-pushes, or broadly deletes state. Any missing, malformed, conflicting, or ambiguous proof is `BLOCKED`.

## Profile boundary

The shared core owns lane admission, peer resolution, default-branch reads, durable ownership schema, claims, Base/checkpoint checks, locks, tombstones, receipts, and canonical idle validation. A project profile owns the three public lane names, checkout paths, repository identity, default branch, idle checkout forms, Work-ID syntax and branch relationship, and project-specific Human-test hooks/presentation.

The shared core contains no project identity, checkout path, Work-ID syntax, lane alias, default-branch assumption, or project-specific meaning for Human testing. The generated standalone runtime is assembled from these development sources in a deterministic order; it does not dynamically source shared files.

This shared model does not change dev-context self-development. The dev-context repository remains single-track under the root [`DEVELOPMENT.md`](../DEVELOPMENT.md).
