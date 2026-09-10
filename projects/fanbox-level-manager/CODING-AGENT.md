# fanbox-level-manager Implementation Coding Agent Policy

This document owns the fanbox-level-manager project-specific implementation
and blocking-fix route. Shared role, prompt, Git, and completion rules remain
owned by [`../../shared/CODING-AGENT-WORKFLOW.md`](../../shared/CODING-AGENT-WORKFLOW.md),
[`../../shared/GIT-WORKFLOW.md`](../../shared/GIT-WORKFLOW.md),
[`../../shared/AGENT-PROMPT-STYLE.md`](../../shared/AGENT-PROMPT-STYLE.md), and
[`../../shared/AGENT-PROMPT-PREFLIGHT.md`](../../shared/AGENT-PROMPT-PREFLIGHT.md).

## Executor

Codex Luna xhigh is the default executor for normal source-code
implementation and blocking fixes unless the Human explicitly overrides the
current Task.

ChatGPT owns current-state investigation, repository and architecture
understanding, product and architecture decisions, semantic owner
identification, the implementation contract, prompt completeness and
publication, blocking review, and GitHub management.

Luna owns concrete implementation of the settled contract, narrow
implementation-side diagnosis needed to satisfy that contract, required tests,
the intended commit, and a normal non-force push.

The Human normally owns only unavoidable prompt transport and explicitly
requested local startup boundaries. A Human terminal action does not transfer
source implementation ownership to the Human.

Do not delegate open-ended product design, architecture selection, or scope
expansion to Luna. ChatGPT settles those decisions before publishing the
complete prompt.

## Startup and execution boundary

The normal Luna startup sequence and fail-closed repository proof are owned by
[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md). Luna runs that canonical
handoff after receiving the complete prompt. A failed handoff is terminal for
that startup attempt; Luna makes no repair, retry, or repository mutation.

After `HANDOFF VERIFIED`, Luna implements only the settled contract, runs the
required verification, commits only the intended changes, and pushes the
specified branch normally. ChatGPT independently reviews the pushed state.

This project does not adopt nuinuiCAD documentation/direct-edit exceptions,
exact-fix exceptions, execution lanes, Linear semantics, Manual E2E semantics,
or nuinuiCAD integration mechanics. It also does not add a parallel work
management or ownership store.

## Continuation

Changing the Luna session, changing the ChatGPT chat, or continuing a blocking
fix does not by itself require the Human to reconstruct checker files or
startup transport metadata. The continuing authority is reconstructed from
the current remote and project sources, then ChatGPT publishes the applicable
complete prompt and expected handoff inputs.

Shared policy is referenced above rather than duplicated here. This document
owns only the fanbox executor routing, responsibility boundaries, and the
project-specific prohibition on importing unrelated nuinuiCAD workflow.
