# Shared Agent Prompt Preflight

This document owns reusable mechanics for an explicitly project-owned,
machine-checkable implementation-prompt publication gate. It is opt-in. It
does not make publication checking, expected-context files, handoff identity,
Git mutation policy, lane lifecycle, or semantic implementation correctness a
universal shared prerequisite.

## Routing rule

A project uses this document only when its own README or implementation
policy names a project-specific checker, its inputs, and its success evidence.
That project owner defines the checker contract and remains responsible for
keeping the checker routed. A project that does not explicitly opt in
publishes a complete prompt directly after the shared semantic completeness,
scope, verification, Git safety, and prompt-style checks.

## Reusable publication-check mechanics

When a project opts in:

- the checker runs before the prompt is published;
- the checker fails closed on missing or malformed inputs;
- a failed checker stops publication and does not authorize a handoff;
- the checker validates only its documented execution envelope, not product
  design, architecture, Issue meaning, or implementation correctness;
- the project-specific owner keeps the checker, fixtures, generated artifacts,
  and focused tests together.

The project may use a strict line-oriented expected-context file or another
deterministic input format, but that choice belongs to the project owner. The
shared workflow does not reconstruct omitted values from Git history, a
checkout, a prompt, or a handoff command.

## Existing explicit opt-in

fanbox-level-manager explicitly opts in through its own
[`PROMPT-PREFLIGHT.md`](../projects/fanbox-level-manager/PROMPT-PREFLIGHT.md)
and `scripts/fanbox-prompt-check`. That project-specific contract and its
tests remain independent of nuinuiCAD's implementation-agent startup gate.

## Maintenance rule

Keep this document focused on reusable publication-check mechanics. Do not add
project-specific fields, universal prompt prerequisites, handoff-ticket
semantics, durable execution identity, or runtime safety proof here.
