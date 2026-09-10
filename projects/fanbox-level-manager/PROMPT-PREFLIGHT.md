# fanbox-level-manager Prompt Preflight

## Ownership boundary

This document and [`scripts/fanbox-prompt-check`](./scripts/fanbox-prompt-check) own the machine-checkable execution-envelope gate for fanbox-level-manager implementation prompts.

Shared prompt language and presentation remain owned by [`shared/AGENT-PROMPT-STYLE.md`](../../shared/AGENT-PROMPT-STYLE.md). Shared publication-gate policy remains owned by [`shared/AGENT-PROMPT-PREFLIGHT.md`](../../shared/AGENT-PROMPT-PREFLIGHT.md). Implementation-agent role, completeness, scope, verification, and completion-report requirements remain owned by [`shared/CODING-AGENT-WORKFLOW.md`](../../shared/CODING-AGENT-WORKFLOW.md).

The checker validates only the settled execution envelope. It does not decide product architecture, Issue semantics, implementation correctness, file-change scope, or business logic.

## Publication boundary

The prompt file, expected-context file, and verification-oracle file are
internal publication-validation plumbing owned by ChatGPT and the project
preflight process. They are not Human-managed transport artifacts in the
normal ChatGPT -> Human -> Luna flow.

The normal publication boundary is:

```text
ChatGPT prepares complete prompt
-> project prompt preflight passes
-> ChatGPT prints the complete prompt directly in chat
-> Human copies that prompt to Luna
```

The Human does not reconstruct these files merely to transport a prompt.
Canonical Luna handoff requirements are owned by
[`CODING-AGENT.md`](./CODING-AGENT.md) and
[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md), not by
`fanbox-prompt-check`.

## Checker command

Run the checked-in executable with a prompt file and its expected context file:

```text
projects/fanbox-level-manager/scripts/fanbox-prompt-check <prompt-file> <expected-context-file>
```

The checker performs pure local validation. It does not invoke Git, GitHub, network, handoff, or repository mutation operations.

## Expected context

The expected-context file is exactly six lines in this order. It has no extra, missing, empty, reordered, or unknown fields.

```text
fanbox-prompt-preflight-context-v1
repository=sayosomi/fanbox-level-manager
role=implementation
branch=<branch>
base=<40-hex-SHA>
verification_oracle=<absolute-readable-regular-file>
```

The branch is a non-empty, syntactically safe Git branch-shaped value. The base is exactly 40 hexadecimal characters. The verification oracle is an absolute path to a readable regular non-symbolic file.

## Required prompt envelope

The prompt contains exactly one matching line for each expected field:

```text
Repository: sayosomi/fanbox-level-manager
Role: implementation
Branch: <expected branch>
Base: <expected base>
```

It contains exactly one line matching:

```text
Prompt time: YYYY-MM-DD HH:MM JST
```

It contains this exact reporting requirement:

```text
Final success and BLOCKED/stopped reports must include a fresh Output time in the form Output time: YYYY-MM-DD HH:MM JST; do not reuse Prompt time.
```

It contains these exact Git-safety requirements:

```text
Run git fetch origin --prune before changing files.
Require a clean intended checkout before changing files.
Stop as BLOCKED if the expected remote state does not match after fetch.
Do not use reset, rebase, merge, stash, or force-push to recover from a mismatch.
```

It contains this exact commit/push requirement:

```text
Commit only the intended changes and push the specified branch normally.
```

It contains this exact completion-report requirement:

```text
Completion report must include branch, base SHA, final HEAD, changed files, verification results, acceptance coverage, scope deviation, and blockers or residual risks.
```

## Verification oracle

The prompt contains exactly one `Verification block: begin` line and exactly one `Verification block: end` line. The bytes between those marker lines must match the `verification_oracle` file byte-for-byte. Missing, duplicated, nested, reordered, or altered markers or body bytes fail validation.

## Exclusions

This checker does not validate semantic or product behavior, architecture, Issue meaning, implementation correctness, changed-file scope, or business logic. It does not require or infer nuinuiCAD lane, claim, checkpoint, handoff-ticket, handoff-command, topic-remote, active-lane, declared-lane, or Linear metadata. No nuinuiCAD execution-field semantics apply to this project.

Japanese and other non-ASCII product literals are allowed. Product-language and style review remains with the shared prompt-style owner.

After this one-time first-checker bootstrap is merged, the normal publication rule applies: every fanbox-level-manager implementation-agent prompt must pass this checker and produce `PROMPT PREFLIGHT PASS` before publication.
