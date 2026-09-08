# Shared Agent Prompt Preflight

This document owns the fail-closed, machine-checkable publication gate for implementation-agent prompts. It does not own prompt language or formatting, implementation scope, Git mutation policy, lane lifecycle, handoff identity, or semantic correctness of an implementation plan.

## Ownership boundary

Use the owners in this order:

- [`AGENT-PROMPT-STYLE.md`](./AGENT-PROMPT-STYLE.md) owns language, formatting, and directness.
- This document owns hard execution-envelope checks before an implementation prompt is published.
- Project execution-handoff policy owns ticket identity, the public handoff command, one-shot reservation, and runtime proof. For nuinuiCAD, that owner is [`projects/nuinuiCAD/EXECUTION-HANDOFF.md`](../projects/nuinuiCAD/EXECUTION-HANDOFF.md).
- [`CODING-AGENT-WORKFLOW.md`](./CODING-AGENT-WORKFLOW.md) owns implementation-agent role completeness, scope, verification, and completion reporting.

Prompt preflight does not replace Human/LLM review of architecture, implementation scope, product decisions, or semantic correctness.

## Publication rule

Do not present an implementation-agent prompt until the project prompt checker returns `PROMPT PREFLIGHT PASS`.

The coordinator first completes the role-specific contract and fresh handoff-ticket audit, then writes the prompt and its expected context, then runs the project checker. A blocked result stops publication. The checker is a second, deterministic envelope gate; it is not permission to invent missing scope or to repair a failed handoff.

### First-checker bootstrap exception

A project that does not yet have an applicable project-specific prompt checker may use a one-time bootstrap exception only for the implementation Task that establishes its first checker. This is a fail-closed bootstrap path, not a generic publication bypass.

Before publishing that bootstrap implementation prompt, the coordinator must satisfy all of the following:

- fresh authoritative repository inspection confirms that no applicable project-specific prompt checker exists;
- the Human explicitly approves both the checker-bootstrap change and the implementation route used for that bootstrap;
- the Task scope is limited to adding the first checker, its narrowly required tests or generated helper, and the project routing needed to make that checker authoritative;
- no unrelated product, repository-governance, or workflow change is included in the bootstrap Task;
- the bootstrap prompt satisfies every shared implementation-agent contract requirement that does not depend on the missing checker, including exact repository, branch and base, required prompt/output timestamp semantics, exact verification input, settled scope, Git safety, commit/push requirements, stop conditions, and completion reporting;
- immediately before publication, the coordinator rechecks that an applicable checker still does not exist; if one is found, the exception is invalid and the normal checker gate applies instead.

The exception ends when the first checker is merged into the authoritative project routing. It cannot be reused for later checker changes, fixes, replacements, or ordinary implementation work. After bootstrap, every implementation-agent prompt for that project must pass the applicable project-specific checker and produce `PROMPT PREFLIGHT PASS` before publication.

Do not infer project execution semantics from this exception. In particular, nuinuiCAD-specific lane, claim, checkpoint, handoff-ticket, one-shot reservation, or cross-lane requirements do not become requirements for projects that do not independently own them.

## nuinuiCAD checker interface

The nuinuiCAD implementation is:

```text
projects/nuinuiCAD/scripts/nuinui-prompt-check <prompt-file> <expected-context-file>
```

Both inputs are local regular files. The checker performs no GitHub operation, does not invoke `nuinui handoff`, does not reserve a ticket, and does not consume a production one-shot ticket.

The expected-context file is a strict line-oriented machine-readable file. Fields must appear exactly in this order:

```text
prompt-preflight-context-v1
repository=sayosomi/nuinuiCAD
role=implementation
phase=implementation|integration|blocking-fix
ticket=h1-<24 lowercase hexadecimal characters>
ticket_state=valid|malformed|reserved|expired
command=/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui handoff <ticket>
lane=<lane>|-
issue=<SAY-N>|-
branch=<branch>|-
base=<full SHA>|-
claim=<claim>|-
checkpoint=<full SHA>|-
topic=absent|exact|-
active_implementation_lanes=<comma-separated lane names>|-
verification_oracle=<absolute readable file>|-
```

`-` means that the generation context intentionally does not expose that optional field in the prompt. When a value is supplied, the prompt must contain exactly one matching visible field. The checker does not reconstruct omitted values from the ticket, a checkout, Git history, or architecture knowledge.

`ticket_state=valid` is the production-context value. The other values are explicit regression fixtures for malformed, reserved, expired, or otherwise non-executable representations. They are rejected before any handoff path is called.

When `verification_oracle` is not `-`, the prompt must contain exactly one pair of `Verification block: begin` and `Verification block: end` lines, and the enclosed block must match the oracle byte-for-byte. The oracle is an explicit test/generation input, not an authority inferred by the checker.

## Hard checks

For the current nuinuiCAD implementation-agent contract, the checker rejects:

- invalid shared-style forms that are mechanically checkable: non-ASCII/non-printable text, polite request phrasing, and decorative Markdown;
- a missing or malformed `Prompt time: YYYY-MM-DD HH:MM JST` line;
- a missing exact requirement that final successful and `BLOCKED`/stopped reports use a fresh `Output time: YYYY-MM-DD HH:MM JST` and do not reuse `Prompt time`;
- an invalid ticket token or a non-valid fixture ticket state;
- any command other than the exact canonical public façade command with the declared ticket;
- an unavailable, non-executable, or noncanonical `nuinui` public façade surface;
- an invalid role or phase;
- supplied lane, Issue, branch, Base, claim, checkpoint, or topic values that do not exactly match the visible prompt envelope;
- a supplied verification oracle that is missing, altered, or absent from the prompt;
- actionable merge, rebase, cherry-pick, reset, stash, or cross-lane manipulation instructions in the implementation phase;
- a missing exact isolation clause when the authoritative active-lane inventory contains another implementation lane.

The checker does not validate the implementation plan, source design, product behavior, or technical correctness of the requested slice.

## Maintenance rule

Keep this document focused on publication-time execution-envelope validation. Do not move role, Git, lane, handoff, verification-oracle ownership, or semantic implementation authority into [`AGENT-PROMPT-STYLE.md`](./AGENT-PROMPT-STYLE.md) or into the generated checker artifact.
