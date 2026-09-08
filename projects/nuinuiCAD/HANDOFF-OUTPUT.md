# nuinuiCAD handoff output safety

## Purpose

This document owns only the presentation/capture boundary around the canonical one-shot Luna handoff. It exists to prevent UI or agent output truncation from causing an already-consumed immutable handoff ticket to be retried.

The semantic handoff authority remains [`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md). The canonical `nuinui handoff <ticket>` command, ticket validation, reservation, standalone proof authority, and exact branch-mismatch recovery remain unchanged. This document adds a narrow outer façade that invokes that canonical command exactly once and normalizes what the execution agent sees.

## Canonical agent command

For Luna implementation, integration, blocking-fix, continuation, or chat-rotation handoff, the Execution Envelope must use this command as the first repository operation:

```text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-handoff-once <ticket>
```

The wrapper invokes the sibling canonical `nuinui handoff <ticket>` exactly once. It does not reserve, validate, retry, resume, repair, or reconstruct execution identity itself.

## One-shot no-retry rule

The execution agent must never invoke the same handoff ticket more than once.

This remains true when:

- displayed output is truncated;
- displayed output is incomplete;
- the UI omits trailing lines;
- the agent cannot determine whether later hidden output contained `HANDOFF VERIFIED`;
- the command failed after ticket reservation;
- the agent suspects that re-running the command would reveal more output.

A ticket reservation is one-shot. Output uncertainty does not authorize a retry.

If the wrapper result visible to the agent does not establish success with a first line exactly equal to:

```text
HANDOFF VERIFIED
```

then the agent stops before further repository mutation and reports the visible output. Continuation requires ChatGPT to fresh-audit current authority and issue a new immutable ticket.

Do not convert output uncertainty into manual branch/Base/Claim/Checkpoint reconstruction, ad-hoc Git inspection, checkout repair, or reuse of the consumed ticket.

## Presentation façade contract

`projects/nuinuiCAD/scripts/nuinui-handoff-once` is a non-semantic presentation façade.

It must:

1. accept exactly one canonical short `h1-<24 hex>` ticket;
2. invoke the sibling `nuinui handoff <ticket>` no more than once;
3. capture the complete child output before presenting it to the execution agent;
4. on exit 0 with canonical success evidence, emit `HANDOFF VERIFIED` as the first line and emit only the successful proof block beginning at that marker;
5. suppress earlier recoverable `BLOCKED:` / resume chatter when the canonical façade ultimately succeeded;
6. on nonzero exit, emit the first canonical `BLOCKED:` or `ERROR:` line first and only bounded diagnostic output after it;
7. fail closed if the child exits 0 without a canonical `HANDOFF VERIFIED` marker;
8. never retry the child command internally.

The wrapper is not an alternative handoff authority. Any change to reservation semantics, exact branch-mismatch recovery, durable identity validation, or proof rules belongs in `EXECUTION-HANDOFF.md` and the existing `nuinui` / `nuinui-handoff-check` owners.

## Prompt requirement

Every execution-agent handoff prompt must state, directly and without optional wording:

```text
Run the exact handoff command once. Do not retry the same ticket even if output is truncated, incomplete, or ambiguous. Continue only if the visible first line is exactly HANDOFF VERIFIED. Otherwise stop and report the visible output; ChatGPT will fresh-audit state and issue a new ticket if continuation is still valid.
```

The prompt must not tell the agent to repeat the command to confirm success.

## Regression verification

`projects/nuinuiCAD/scripts/test-nuinui-handoff-once` covers the presentation boundary independently from handoff semantics.

It must prove at least:

- successful exact recovery can contain noisy pre-success output internally while visible output starts with `HANDOFF VERIFIED`;
- the wrapper invokes the child handoff exactly once on success;
- a nonzero canonical failure remains a failure and starts with `BLOCKED:` or `ERROR:`;
- failure does not cause a retry;
- exit 0 without `HANDOFF VERIFIED` fails closed;
- markerless success does not cause a retry.

## Maintenance rule

Keep this document narrow. Do not duplicate ticket issuance, durable claim authority, lane rules, recovery semantics, or integration policy here. If the wrapper no longer needs to exist because the canonical public handoff itself acquires an equivalent bounded presentation contract, consolidate this responsibility back into `EXECUTION-HANDOFF.md` rather than keeping two presentation owners.
