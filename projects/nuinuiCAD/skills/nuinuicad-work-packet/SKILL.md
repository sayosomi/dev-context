---
name: nuinuicad-work-packet
description: Create, refresh, or validate compact nuinuiCAD handoff packets for ChatGPT, Luna, implementation agents, or Human E2E while preserving authority, unknowns, checkpoints, and executable next steps. Use for handoff/checkpoint context only; never send, resume, select issues, write external state, merge, or decide implementation.
---

# nuinuiCAD work packet

## Purpose and boundary

Use this skill only to **generate**, **refresh**, or **validate** a packet carrying a current handoff. A packet is a temporary context carrier, not a source of truth. Read current authority and cite it; do not copy policy prose into the packet. The skill must not select an Issue, send or resume a task, update Linear/GitHub, merge, mutate a lane/worktree, or make an implementation decision.

## Required reads

Read progressively, stopping when the needed authority is known:

1. `projects/nuinuiCAD/README.md` and the applicable `shared/DEVELOPMENT.md`.
2. `projects/nuinuiCAD/CODEX-ONLY-INTERIM.md` when it is Active, plus the current README route in normal operation. Record the current rule; never deactivate or reproduce it.
3. The role owner: `CHAT-COORDINATOR.md`, `CHAT-WORKFLOW.md`, `IMPLEMENTATION-SLICING.md`, `MANUAL-E2E.md`, and `LOCAL-TOOLS.md` only as relevant to the recipient and operation.
4. The current repository/lane state and fresh Issue/PR/CI evidence when the packet claims them. An old chat summary is never authority.

If authority, freshness, or ownership conflicts, stop and report the conflict rather than guessing.

## Inputs

The caller supplies (or the skill marks `Unverified`): Issue/key and objective, acceptance authority references, recipient (`ChatGPT/Coordinator`, `Codex/Luna/implementation`, or `Human`), operation (`generate`, `refresh`, or `validate`), current work class and executor/model, exact repository/base/head/branch/PR, scope and non-goals, completed verification/evidence, blockers/ambiguity, and any required Human action. Refresh uses only newly verified facts and preserves unresolved fields explicitly.

## Output format

Emit one packet with this stable schema. Do not omit an unknown field; use `Unverified`, `Unknown`, or `Not applicable`.

```text
Work packet — <issue/key> — <recipient>
Authority: <objective/acceptance and policy/owner references; links or paths, not copied policy>
Work class / executor / model: <values>
State: repository=<exact>; base=<SHA>; head=<SHA>; branch=<name>; PR=<number/URL or N/A>; freshness=<timestamp/source>
Scope and owner: <in-scope, non-goals, owner documents>
Evidence: <completed verification and exact commands/artifacts>
Blocker / ambiguity: <explicit unknowns and conflicts>
Next atomic operation: <one uniquely identified read-only or approved operation>
Terminal condition / model-decision checkpoint: <stop condition and who decides what>
Human action (only if required): <why, value-filled command, or Manual E2E steps; expected observation>
```

## Recipient-specific contract

- **Codex/Luna/implementation agent:** optimize context efficiency. Replace policy bodies with authority references and center contract, base/head, scope, verification, blocker, next atomic operation, and stop condition. State measured reduction against the paired unstructured baseline; the Luna resume fixture must meet at least 40% reduction.
- **ChatGPT/Coordinator:** no fixed token ceiling. Remove repeated history but retain judgment-relevant background, ambiguity, authority, and routing facts needed to choose the next owner.
- **Human:** token reduction is not acceptance. Preserve why the action is needed, enough context to approve it, exact value-filled commands, and directly executable Manual E2E steps. Do not turn an unknown live result into PASS/FAIL.

The format is not a shortest-possible handoff. It is context-efficient for Codex-family agents and loss-resistant for Human collaboration. Coordinator rotation and Human E2E have no fixed token upper bound; acceptance is clear authority, explicit unknowns, one next operation, a clear stop/checkpoint, and an executable Human action when needed.

## Evidence and tools

Use an existing connector or CLI only to read the relevant current source: Linear for contract/checkpoint, Git/GitHub for exact repository/branch/PR/CI facts, and the existing `nuinui` owner for local state. `nuinui context-check` may validate dev-context Markdown/router/CLI-doc references; `nuinui transition-audit` is only a read-only interim audit; `nuinui verify` is only a pre-start verification when its contract applies. Never use mutation commands to fill a packet. If a connector/tool is unavailable, say so and leave the field unverified.

For Human commands, first apply `shared/skills/human-terminal-instructions/SKILL.md`: values must be filled, paths explicit, expected output and stop condition stated. A packet never invokes send/resume or external writes itself.

## Validation and stopping

For `validate`, check schema completeness, authority references, exactness of claimed state, recipient contract, unique next operation, explicit stop checkpoint, and absence of write/selection/merge instructions. Use the fixtures and measurement in `references/evals.md`. Stop immediately on stale or conflicting evidence, missing authority, ambiguous ownership, an unsafe/destructive command, or a request outside generate/refresh/validate. Return the packet and the unresolved issue; do not repair external state.
