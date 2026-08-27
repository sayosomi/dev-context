# Work-packet forward evaluations

These are behavioral fixtures, not a second source of truth. Evaluate the skill by giving each fixture's facts and checking the emitted packet against the acceptance criteria.

## Measurement

For the Codex/Luna fixture, the paired **unstructured baseline** is the exact prose in the fixture (same facts, recipient, and evidence). Count all Unicode characters in the baseline and packet body, including labels and authority paths, with `len(text)` in Python; exclude the fixture title and fenced-code delimiters. Report `reduction = 1 - packet_chars / baseline_chars`. This is a comparable proxy for tokens, not a tokenizer claim. The Luna resume fixture passes only at `>= 40%` reduction. No fixed token ceiling applies to Coordinator or Human fixtures.

## Fixture 1 — Coordinator rotation

Facts: `SAY-201`; objective and acceptance are in the current Linear contract; current route is Active interim; no fresh lane SHA was supplied; `CHAT-COORDINATOR.md` requires a checkpoint before routing.

Expected: cite the contract, workflow, and interim authorities; mark lane/head/verification unverified; preserve the ambiguity; identify one next operation (obtain a fresh checkpoint); state that routing waits for it. No token minimum and no guessed owner or status.

## Fixture 2 — Luna resume

Facts: `SAY-202`; implementation slice; executor Luna; branch `codex/say-202`; base `09612fd`; head `abc1234`; tests `nuinui self-test` passed; remote freshness and PR are unverified; scope and non-goals are in the current Linear contract.

Unstructured baseline (the paired input to count):

```text
SAY-202 is an implementation slice for Luna on branch codex/say-202. The base is 09612fd and the current head is abc1234. nuinui self-test passed. The scope and non-goals are in the current Linear contract. The remote freshness and PR are not known yet. Luna should read the interim policy and implementation slicing guidance, check the branch and PR, then continue implementation if everything is fine. If there is a problem, investigate it and decide whether to merge or ask the coordinator. Remember that the active interim policy controls the executor and Git batch, that the repository and lane rules are authoritative, and that a checkpoint should preserve completed work, remaining work, evidence, and the next operation. Do not rely on this chat summary as authority, but reread all prior context and the entire contract before acting. If the branch is behind, determine whether a rebase is appropriate; if a pull request is missing, decide whether to create one; if CI is pending, wait and report. Keep the coordinator informed throughout the resume. The previous handoff also repeated the full operating model, all role boundaries, the complete list of non-goals, and the historical test transcript even though those are available in the linked owner documents. It repeated the branch, base, head, and self-test result in several paragraphs and included speculative options for implementation, issue updates, merge, and CI handling. This repetition is deliberately part of the unstructured comparison baseline.
```

Expected: a compact agent packet centered on contract/base/head/scope/evidence/blocker/next/stop, with policy as references. Next operation is a read-only fresh remote/PR check; stop if it differs. Do not resume, implement, or merge. Report the paired baseline and reduction; target is at least 40%.

## Fixture 3 — Human E2E

Facts: `SAY-203`; tested commit `abc1234`; Manual E2E oracle is the current Issue plan; Human must run the exact command `nuinui e2e --fixture SAY-203 --commit abc1234` in the fixed e2e lane; expected observation is the oracle's named UI state; current result is unknown.

Expected: preserve why the run is needed, authority/oracle reference, exact command and lane, expected observation, and a clear stop/report checkpoint. Do not optimize for character reduction, invent PASS/FAIL, or ask Human to fill placeholders.

## Acceptance checklist

All fixtures must have clear authority, explicit unknowns, one next atomic operation, a clear terminal/model checkpoint, and no send/resume/Issue-selection/external-write/merge/implementation instruction. Fixture 2 additionally meets the measured `>=40%` reduction. Fixture 3 is accepted on executable clarity and context retention, not size.
