# nuinuiCAD Evaluator Audit Policy

## Authority and scope

This is the sole nuinuiCAD project-policy owner for open-ended evaluator correctness and semantic-conformance exploration. The work covered here is local nuinuiCAD compiler/evaluator/language-service correctness research. It is not a source-implementation role.

The default first-pass executor is GPT-6.1 Sol at High reasoning. GPT-6 Astra is reserved for explicit escalation after a Sol pass. This policy defines both roles and the handoff for findings. Project checkout constraints are owned by [`CHECKOUTS.md`](./CHECKOUTS.md). Current Work selection and tracking continue to follow the project's existing work-management policy.

## Role split

| Owner | Responsibility |
| --- | --- |
| ChatGPT | Select Work and set the bounded exploration scope; make semantic and product decisions; triage findings; author or update Issues and implementation contracts; decide whether Astra escalation is warranted; review results and implementation. |
| GPT-6.1 Sol High | Default first-pass executor for bounded evaluator semantic-conformance, differential, property/metamorphic, reduction, control, and first-boundary exploration. |
| GPT-6 Astra in Codex | Escalation executor for an explicitly bounded residual or independent high-assurance second pass after Sol. Astra is not the default first-pass executor. |
| Luna | Own source implementation and blocking fixes, deterministic regression tests, normal verification, integration, and implementation Git work. Luna remains the normal and only implementation Coding Agent. |

Neither Sol nor Astra implements fixes.

## Default Sol first pass

All new bounded evaluator exploration starts with GPT-6.1 Sol at High reasoning unless the Human explicitly overrides the model for a particular run.

Sol uses the same evidence threshold previously required for evaluator audits:

- fixed audit revision;
- tracked product source read-only;
- temporary harnesses, reducers, logs, outputs, and evidence outside tracked source;
- valid-source authority from the current normative contract;
- a minimal useful reproducer;
- independent reproduction;
- nearby passing controls that isolate the boundary;
- expected semantics and actual results;
- the first useful incorrect compiler, evaluator, or transport boundary that can be established;
- real production Node -> persistent Rust stdio evidence when evaluator parity is involved;
- grouping of equivalent symptoms by one independent defect family.

TypeScript/Rust agreement does not exonerate a shared compiler/lowering defect.

When Sol retains an independent defect family that meets this threshold, return it directly to ChatGPT for semantic/product triage. Do not insert Astra merely because the Work is exploratory. After ChatGPT confirms the finding, concrete implementation and deterministic regression coverage return to Luna under the normal implementation workflow.

## Audit session continuity

A fixed audit revision defines one execution run. A change of fixed revision after a retained defect is repaired starts a new run, but does not by itself require a new Sol chat/session.

Optimize for the smallest useful active context rather than mechanically maximizing or minimizing session lifetime.

For the same evaluator-audit Work:

- reuse the existing Sol High session across nearby repair -> resume cycles while its accumulated context remains compact and materially relevant to the remaining audit;
- when accumulated history becomes materially larger than the context needed for the remaining work, rotate to a new Sol session using a compact checkpoint reconstructed from current external authority;
- on every resumed run, explicitly re-anchor to the new exact fixed revision and re-verify the checkout/read-only boundary;
- create a fresh temporary evidence directory for each run;
- do not treat runtime evidence from an earlier revision as current-revision evidence;
- carry prior final dispositions forward only as Work history or targeted smoke-control context, not as substitute evidence for newly changed behavior.

Do not create a new Sol session merely because:

- a concrete Bug was repaired and merged;
- the fixed audit revision changed;
- the same bounded Work is resuming after a normal repair cycle.

Prefer a new session when:

- prior audit reports, reproducers, or abandoned search paths now dominate the context while only a small residual remains;
- the current session has become confused, long, or context-degraded;
- the Human or ChatGPT deliberately chooses rotation;
- the executor model or role changes;
- an independent second pass is itself part of the assurance objective.

An Astra independent second pass should normally use a separate session so that the pass remains meaningfully independent.

Session reuse and rotation are efficiency choices only. They do not weaken fixed-revision isolation, evidence thresholds, stop rules, or checkout safety.

## Astra escalation

Use GPT-6 Astra only when at least one of the following explicit conditions exists after a Sol pass:

1. **High-assurance independent second pass** — Sol found no defect in a high-value domain and closing the audit warrants an independent stronger pass.
2. **Budget exhaustion or unresolved residuals** — Sol reaches the bounded run limit with high-value rows still untested, unresolved, or inconclusive.
3. **Finding isolation failure** — Sol has a plausible or reproducible observation but cannot converge on reduction, discriminating controls, family grouping, or the first useful compiler/evaluator/transport boundary.

Astra receives the bounded residual or escalation scope, not an automatic full restart of the entire campaign. A full independent replay is appropriate only when ChatGPT explicitly decides that whole-domain second-pass assurance is itself the objective.

Do not select Astra up front merely because a matrix is large, combinatorial, or historically associated with Astra. Those properties shape the Sol budget and possible escalation; they do not bypass the Sol-first rule.

## Work shaping for benign correctness exploration

Shape each evaluator-audit run so its actual purpose and boundary are explicit from the start. This is intended to reduce ambiguity between nuinuiCAD product-correctness research and cybersecurity work; it is not a mechanism for bypassing platform safeguards.

- One run covers one bounded correctness domain. Do not ask for repo-wide unknown-defect hunting. Unknown-defect discovery remains allowed inside the selected semantic domain.
- State the owned local target and correctness purpose explicitly, for example local nuinuiCAD compiler/evaluator/language-service behavior at one fixed audit revision.
- Express the exploration in terms of semantic or behavioral invariants to verify, such as source-order invariance, equivalent-program consistency, cross-feature consistency, revision isolation, or reference/identity preservation.
- Constrain execution to the Human-authorized local checkout or forensic-worktree path, nuinuiCAD compiler/evaluator/test runners, and temporary local artifacts allowed by [`CHECKOUTS.md`](./CHECKOUTS.md). External targets, network scanning, credentials, privilege escalation, exploit development, and other security objectives are out of scope.
- Define a bounded stopping condition before each run, such as completion of a selected feature-family matrix, a maximum accepted-program/request budget, or a fixed number of independent retained findings.
- For each retained mismatch, stop at reproducible evidence, nearby controls, reduction, and the first useful incorrect boundary needed for ChatGPT triage. A Work with explicit residual rows may resume after the concrete Bug is repaired.
- Use terminology that accurately describes the task, such as semantic conformance, property/metamorphic correctness, cross-feature consistency, or regression exploration when those are the real goals. Do not cosmetically rename a security task or add wording whose purpose is to evade classification.
- If a platform restriction blocks a run, stop and report it rather than weakening or obscuring the task boundary.

## Work and finding handoff

Track evaluator exploration as explicit Research/Improvement Work with a bounded semantic search domain under the current work-management authority ([`LINEAR.md`](./LINEAR.md) and [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)). Keep the audit revision fixed for each run; if the revision or required semantic scope changes, stop and return the decision to ChatGPT.

For a Sol first pass:

- a retained qualifying defect returns directly to ChatGPT;
- ChatGPT decides whether it is a concrete Bug, a contract/spec ambiguity, an existing family, or non-actionable evidence;
- confirmed Bugs are implemented by Luna;
- unresolved residuals remain explicit rather than disappearing when the run budget ends;
- Astra is invoked only under one of the three escalation conditions above.

For an Astra escalation:

- preserve the same evidence threshold and read-only boundary;
- state which escalation condition applies and which Sol residual/evidence defines the starting scope;
- do not implement fixes;
- return the retained evidence or high-assurance negative result to ChatGPT for disposition.

## Platform boundary

Describe this work accurately as local nuinuiCAD evaluator correctness and semantic-conformance testing. Do not add instructions intended to evade or bypass platform safeguards. If a platform restriction blocks a Sol or Astra run, stop and report the restriction.
