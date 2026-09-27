# voiceger-accent-adapter Implementation Coding Agent Policy

This document owns the voiceger-accent-adapter project-specific implementation and blocking-fix route.

Shared implementation role, prompt completeness, Git safety, commit / push, review, and completion-report mechanics remain owned by:

- [Shared Implementation Coding Agent Workflow](../../shared/CODING-AGENT-WORKFLOW.md)
- [Shared Git Workflow](../../shared/GIT-WORKFLOW.md)
- [Shared Agent Prompt Style](../../shared/AGENT-PROMPT-STYLE.md)

Do not duplicate those shared mechanics here.

## Responsibility boundary

ChatGPT owns:

- fresh current-state investigation;
- repository and architecture understanding;
- product and design decisions;
- semantic-owner and change-boundary identification;
- the executable implementation contract;
- acceptance and verification selection;
- blocking review of pushed state;
- GitHub Issue / PR continuation.

The implementation Coding Agent owns:

- concrete implementation of the settled contract;
- narrow implementation-side diagnosis needed to satisfy that contract;
- required tests and verification;
- the intended commit;
- a normal non-force push to the specified branch.

Do not delegate open-ended product design, architecture selection, dependency strategy, or scope expansion to the implementation Coding Agent.

This project does not define a project-wide default Coding Agent product or reasoning effort. Use an explicit current-Task choice when provided; otherwise follow the shared workflow without assuming one.

## Startup and Git boundary

Use the shared Git freshness and safety rules.

Before implementation, the Coding Agent must refresh remote state and verify the expected base supplied by ChatGPT. On mismatch, dirty checkout, unexpected branch ownership, or other ambiguous repository state, stop instead of repairing with reset, stash, rebase, merge, force-switch, or force-push.

Normal work uses the primary repository checkout. Do not create a new worktree merely to start another sequential Task or topic branch. Parallel worktrees require an actual simultaneous implementation need.

## Voiceger upstream boundary

Voiceger is a separate upstream dependency and is not an implementation surface of an ordinary voiceger-accent-adapter Task.

Do not:

- modify files in the local Voiceger checkout;
- vendor or copy Voiceger source into this repository;
- modify Voiceger models, reference audio, or other upstream assets;
- treat a local upstream workaround as an adapter implementation.

An upstream Voiceger change is allowed only when the current Task explicitly authorizes that separate upstream scope.

If satisfying the settled adapter contract requires an unauthorized upstream change, report `BLOCKED` with the exact dependency instead of broadening scope.

## Verification boundary

Use the product repository's current `AGENTS.md`, README, tests, and task contract for exact verification commands.

Normal unit tests are the default repository verification layer and should not require loading the real Voiceger models.

Real Voiceger integration tests are a separate opt-in layer. Run them when the current Task or acceptance criteria require runtime synthesis validation, or when the changed behavior crosses the real Voiceger integration boundary and unit-level evidence is insufficient.

Do not copy a specific Voiceger compatibility SHA, local environment path, or integration command into this durable policy. Read those values from the current product repository so they can evolve without duplicating authority.

Generated manual-test artifacts, temporary WAV files, JSON, logs, scratch paths, and repository hygiene remain governed by the current product repository `AGENTS.md`.

## Scope discipline

Implement only the settled current Task.

Do not silently add:

- unrelated API behavior;
- new pronunciation semantics;
- additional language support;
- dependency changes;
- UI architecture changes;
- Voiceger upstream changes;
- cleanup or refactors not needed for the contract.

If a material new product, architecture, dependency, or compatibility decision becomes necessary, stop and return it to ChatGPT for contract resolution.

## Project separation

Do not import nuinuiCAD-specific Linear workflow, declared lanes, Astra execution policy, Manual E2E policy, or nuinuiCAD checkout semantics.

This project currently has no dedicated execution-handoff helper or prompt-publication checker. Do not invent one during ordinary implementation.
