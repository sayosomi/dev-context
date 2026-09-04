# Work-packet forward evaluations

These are behavioral fixtures, not a second source of truth. Evaluate the skill by giving each fixture's facts and checking the emitted packet against the acceptance criteria.

## Measurement

For the Coding Agent fixture, the paired **unstructured baseline** is the exact prose in the fixture (same facts, recipient, and evidence). Count all Unicode characters in the baseline and packet body, including labels and authority paths, with `len(text)` in Python; exclude the fixture title and fenced-code delimiters. Report `reduction = 1 - packet_chars / baseline_chars`. This is a comparable proxy for tokens, not a tokenizer claim. The forward fixture passes only at `>= 40%` reduction. No fixed token ceiling applies to Coordinator or Human fixtures.

## Fixture 1 — Coordinator rotation

Facts: `WORK-201`; objective and acceptance are in the current Work contract; the current project route is active; no fresh execution checkpoint was supplied; the coordinator workflow requires a checkpoint before routing.

Expected: cite the contract, workflow, and current-route authorities; mark execution state and verification unverified; preserve the ambiguity; identify one next operation (obtain a fresh checkpoint); state that routing waits for it. No token minimum and no guessed owner or status.

## Fixture 2 — Coding Agent resume

Facts: `WORK-202`; implementation slice; executor Coding Agent; branch `codex/work-202`; base `09612fd`; head `abc1234`; the project validation command passed; remote freshness and review request are unverified; scope and non-goals are in the current Work contract.

Unstructured baseline (the paired input to count):

```text
WORK-202 is an implementation slice for a Coding Agent on branch codex/work-202. The base is 09612fd and the current head is abc1234. The project validation command passed. The scope and non-goals are in the current Work contract. The remote freshness and review request are not known yet. The agent should read the current project authority and implementation guidance, check the branch and review request, then continue implementation if everything is fine. If there is a problem, investigate it and decide whether to merge or ask the coordinator. Remember that the active project route controls the executor and batch, that repository rules are authoritative, and that a checkpoint should preserve completed work, remaining work, evidence, and the next operation. Do not rely on this chat summary as authority, but reread all prior context and the entire contract before acting. If the branch is behind, determine whether a rebase is appropriate; if a review request is missing, decide whether to create one; if validation is pending, wait and report. Keep the coordinator informed throughout the resume. The previous handoff also repeated the full operating model, all role boundaries, the complete list of non-goals, and the historical test transcript even though those are available in the linked owner documents. It repeated the branch, base, head, and validation result in several paragraphs and included speculative options for implementation, work updates, merge, and review handling. This repetition is deliberately part of the unstructured comparison baseline.
```

Expected: a compact Coding Agent packet centered on contract, base/head, scope, evidence, blocker, next, and stop, with policy as references. The next operation is one read-only fresh remote/review check; stop if it differs. Do not resume, implement, or merge. Report the paired baseline and reduction; target is at least 40%.

## Fixture 3 — Human validation

Facts: `WORK-203`; tested commit `abc1234`; the validation oracle is the current Work plan; a Human must run the exact command `project-tool verify --work WORK-203 --commit abc1234` in the fixed test environment; expected observation is the oracle's named UI state; current result is unknown.

Expected: preserve why the run is needed, authority/oracle reference, exact command and environment, expected observation, and a clear stop/report checkpoint. Do not optimize for character reduction, invent `PASS` / `FAIL`, or ask the Human to fill placeholders.

## Acceptance checklist

All fixtures must have clear authority, explicit unknowns, one next atomic operation, a clear terminal/model checkpoint, and no work-selection, send/resume, external-write, merge, or implementation instruction. Fixture 2 additionally meets the measured `>=40%` reduction. Fixture 3 is accepted on executable clarity and context retention, not size.
