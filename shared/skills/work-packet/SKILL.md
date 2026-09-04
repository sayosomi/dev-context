---
name: work-packet
description: Generate, refresh, or validate authority-safe temporary handoff packets for ChatGPT/coordinator-style recipients, Coding Agents/implementation recipients, and Humans while preserving verified facts, explicit unknowns, and safe stop points.
---

# Work packet

## Purpose and boundary

Use this skill only to **generate**, **refresh**, or **validate** a work packet. A packet is a temporary context carrier, not a source of truth. It references current authority and carries the smallest useful current handoff; it does not replace the authority it cites.

The shared skill owns only project-independent packet semantics. It must remain read-only with respect to the external state it describes and must not use mutation to make a packet complete.

The packet must:

- read and reference current authority rather than copy durable policy prose;
- preserve explicit unknowns and conflicts instead of guessing;
- use only currently verified facts when refreshing;
- retain one uniquely identified next atomic operation;
- retain a clear terminal condition or model-decision checkpoint.

The skill must not:

- select work or invent an objective, acceptance criterion, owner, or state;
- send or resume execution;
- update repository, work-management, review, deployment, or local execution state;
- commit, push, merge, or create a review request / PR;
- mutate an execution checkout or working context;
- make product, architecture, or implementation decisions;
- repair external state merely to make a packet complete.

## Required reads

Read progressively, stopping when the needed authority is known:

1. The current project's entrypoint and repository instructions.
2. The current Work, objective, and acceptance authority.
3. Relevant role or workflow owners needed by the recipient and operation.
4. Fresh repository, work-management, review/CI, deployment, or local-execution evidence only when the packet claims those facts.

An old chat summary, prior packet, or copied handoff is not current authority. If authority, freshness, ownership, or state conflicts, stop and preserve the conflict explicitly.

## Inputs and applicability

The caller supplies, or the packet marks as `Unknown`, `Unverified`, or `Not applicable`:

- Work key / identifier and objective;
- objective / acceptance authority references;
- recipient;
- operation: `generate`, `refresh`, or `validate`;
- work class / executor / model when applicable;
- exact execution state when applicable;
- scope and explicit non-goals;
- semantic owner and owner references;
- completed evidence / verification;
- blockers, conflicts, ambiguities, or unknowns;
- required Human action when applicable.

Execution state is applicability-aware. Repository, base, head, branch, review, deployment, session, checkpoint, or other identifiers may be relevant, but none is universally required. Include every materially relevant field even when its current value is unknown. Mark a known non-applicable field as `Not applicable`; do not silently omit it.

`refresh` uses only newly verified facts. It may update a claimed value when the current authority or evidence verifies it, but it preserves unresolved fields and conflicts rather than backfilling them from history or guessing.

## Stable output schema

Emit one packet with this stable shape. Keep the field names and order stable; use explicit values such as `Unknown`, `Unverified`, or `Not applicable` where needed.

```text
Work packet — <work/key> — <recipient>
Authority: <objective/acceptance and policy/owner references>
Work class / executor / model: <applicable values or explicit unknown/inapplicable state>
State: <applicable exact execution state plus freshness/source>
Scope and owner: <in-scope work, explicit non-goals, semantic-owner references>
Evidence: <completed verification and exact evidence/artifacts>
Blocker / ambiguity: <explicit unknowns, blockers, and conflicts>
Next atomic operation: <one uniquely identified read-only or already-authorized operation>
Terminal condition / model-decision checkpoint: <when to stop and who decides what>
Human action: <only when required; why, executable action, expected observation, and stop/report checkpoint>
```

The `State` field is flexible for non-repository work. When repository state is relevant, carry exact repository, base, head, branch, PR/review, and other applicable values plus their freshness/source; when those concepts do not apply, say so explicitly.

The `Next atomic operation` field names exactly one operation. Do not combine alternatives, open-ended investigation, or an unowned decision into that field. The terminal field states when the recipient stops and which authority or person decides the next material choice.

## Recipient-specific behavior

### Coding Agent / implementation recipient

- Optimize context efficiency by replacing repeated policy prose with current authority references.
- Center the settled executable contract, exact applicable state, scope and non-goals, evidence, blocker, next operation, and stop condition.
- Do not lose contract-critical information merely to shorten the packet.
- Do not require every normal generated packet to report a character or token reduction measurement.

The `>=40%` reduction requirement belongs only to the generic forward-evaluation fixture in `references/evals.md`.

### ChatGPT / coordinator-style recipient

- Remove repeated history while preserving judgment-relevant background, authority, ambiguity, routing facts, and the next decision boundary.
- Do not guess the next owner when current authority does not establish it.
- Preserve unresolved choices for the authority or Human that must decide them.

### Human recipient

- Token reduction is not an acceptance criterion.
- Preserve why the action is needed and enough context to understand or approve it.
- Preserve explicit unknowns and never invent a live `PASS` or `FAIL` result.
- Provide exact executable commands or steps when applicable, with expected observation and a clear stop/report checkpoint.

Whenever a Human-facing packet contains terminal commands or shell scripts, first read and route command construction and safety through [`human-terminal-instructions`](../human-terminal-instructions/SKILL.md). Do not duplicate that skill's shell, worktree-targeting, or command-safety policy here.

## Evidence and tools

The skill may use available connectors, repository tools, CLIs, or other read-only sources to verify facts relevant to the packet. Read each claimed fact from the actual current authority for that fact. Do not prescribe one repository, work-management, review, or execution tool as universally required.

If a required source or tool is unavailable, mark the affected value `Unverified` and keep the limitation in `Blocker / ambiguity`. Do not use a mutation command merely to populate a packet. A packet never performs send, resume, selection, external write, merge, implementation, or state-repair work.

## Validation and stopping

For `validate`, check:

- schema completeness, including materially relevant unknown or inapplicable fields;
- authority references and the freshness/source of claimed state;
- recipient-specific behavior;
- one uniquely identified next atomic operation;
- a clear terminal condition or model-decision checkpoint;
- absence of work selection, send/resume, implementation, merge, PR creation, or external-write instructions;
- safe, authorized, and applicable Human actions when present.

Use the fixtures and measurement in `references/evals.md`. Stop immediately on stale or conflicting evidence, missing authority, ambiguous ownership, an unsafe or unauthorized operation, or a request outside `generate`, `refresh`, and `validate`. Return the packet and the unresolved issue; do not repair external state.
