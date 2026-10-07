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

The default Sol run is a bounded multi-family run. Unless the Human or current Work contract explicitly chooses a tighter bound, stop when any one of these limits is reached:

- **3 independently retained defect families**;
- **40 distinct compiler-accepted programs**;
- **80 production persistent-Rust requests**;
- an environment, platform, checkout, or other execution-boundary restriction.

Each retained family must independently meet the full evidence threshold above before it counts toward the family cap.

After retaining a family, Sol does not automatically return. It classifies the remaining owned matrix by contamination from the known defect:

- **uncontaminated** — continue exploring normally;
- **possibly contaminated** — defer the cell and record why its result would not be trustworthy;
- **blocked by the retained family** — defer the cell and record the dependency on that family.

Continue only where evidence remains trustworthy at the same fixed revision. Return immediately before the normal cap when family isolation fails, the finding exposes a semantic/product-contract ambiguity that requires ChatGPT or Human judgment, the retained defect broadly contaminates the remaining owned domain, or the execution boundary itself becomes invalid.

At the normal run stop, return all retained families together with explicit residual dispositions to ChatGPT for semantic/product triage. Do not insert Astra merely because the Work is exploratory. After ChatGPT confirms the findings, concrete implementation and deterministic regression coverage return to Luna under the normal implementation workflow.

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

Use GPT-6 Astra only when at least one of the following explicit conditions exists after a substantive Sol pass:

1. **Deliberate high-assurance independent second pass** — Sol has cleanly disposed the selected high-value domain, but ChatGPT explicitly decides that the domain's risk or value justifies paying for an independent stronger pass. This is optional assurance, not a default audit-closure requirement.
2. **Substantive Sol exhaustion with unresolved residuals** — Sol has consumed the intended semantic exploration budget for the run, such as the accepted-program/request budget or an equivalent substantive bounded effort, and high-value rows remain untested, unresolved, or inconclusive because Sol could not close them within that effort.
3. **Finding isolation failure** — Sol has a plausible or reproducible observation but cannot converge on reduction, discriminating controls, family grouping, or the first useful compiler/evaluator/transport boundary.

A retained-family / finding-count stop, repair -> resume checkpoint, or Work-level administrative cap is **not** by itself condition 2. If Sol is still converging — retaining independent families with useful reductions, controls, semantic authority, and first incorrect boundaries — repair the retained Bug, re-anchor to a fresh fixed revision, and continue with Sol. Use a successor residual Work item when tracking boundaries require it; do not use Astra merely because the preceding Sol Work reached its authored family-count stop.

After Sol cleanly disposes every owned residual as pass, retained Bug, or bounded non-actionable/inconclusive evidence, closure normally proceeds without Astra. Use condition 1 only when independent second-pass assurance is itself justified; do not make Astra a ceremonial final pass.

Astra receives the bounded residual or escalation scope, not an automatic full restart of the entire campaign. A full independent replay is appropriate only when ChatGPT explicitly decides that whole-domain second-pass assurance is itself the objective.

Do not select Astra up front merely because a matrix is large, combinatorial, historically associated with Astra, or inherited from an earlier Astra campaign. Those properties shape the Sol budget and possible escalation; they do not bypass the Sol-first rule.

## Work shaping for benign correctness exploration

Shape each evaluator-audit run so its actual purpose and boundary are explicit from the start. This is intended to reduce ambiguity between nuinuiCAD product-correctness research and cybersecurity work; it is not a mechanism for bypassing platform safeguards.

- One run covers one bounded correctness domain. Do not ask for repo-wide unknown-defect hunting. Unknown-defect discovery remains allowed inside the selected semantic domain.
- State the owned local target and correctness purpose explicitly, for example local nuinuiCAD compiler/evaluator/language-service behavior at one fixed audit revision.
- Express the exploration in terms of semantic or behavioral invariants to verify, such as source-order invariance, equivalent-program consistency, cross-feature consistency, revision isolation, or reference/identity preservation.
- Constrain execution to the Human-authorized local checkout or forensic-worktree path, nuinuiCAD compiler/evaluator/test runners, and temporary local artifacts allowed by [`CHECKOUTS.md`](./CHECKOUTS.md). External targets, network scanning, credentials, privilege escalation, exploit development, and other security objectives are out of scope.
- Define a bounded stopping condition before each run. The default Sol bound is completion of the selected feature-family matrix or the first of: 3 independently retained families, 40 distinct compiler-accepted programs, 80 production persistent-Rust requests, or an execution-boundary restriction. A Work may explicitly choose a tighter bound.
- For each retained mismatch, stop investigation of that family at reproducible evidence, nearby controls, reduction, and the first useful incorrect boundary needed for ChatGPT triage. Then classify the remaining matrix as uncontaminated, possibly contaminated, or blocked by the retained family. Continue only uncontaminated cells; defer and record the others. Return early if the family cannot be isolated, a contract decision is required, contamination is broad enough to undermine the remaining domain, or the execution boundary fails.
- Use terminology that accurately describes the task, such as semantic conformance, property/metamorphic correctness, cross-feature consistency, or regression exploration when those are the real goals. Do not cosmetically rename a security task or add wording whose purpose is to evade classification.
- If a platform restriction blocks a run, stop and report it rather than weakening or obscuring the task boundary.

## Work and finding handoff

Track evaluator exploration as explicit Research/Improvement Work with a bounded semantic search domain under the current work-management authority ([`LINEAR.md`](./LINEAR.md) and [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)). Keep the audit revision fixed for each run; if the revision or required semantic scope changes, stop and return the decision to ChatGPT.

For a Sol first pass:

- a retained qualifying defect is recorded as one family and consumes one slot of the default 3-family cap; it does not by itself force an immediate return;
- after each retained family, Sol performs the contamination classification above and continues only with uncontaminated owned cells;
- Sol returns all retained families together when the selected matrix closes, the 3-family cap is reached, the 40-program or 80-request budget is reached, or an immediate-return condition applies;
- ChatGPT decides whether each returned family is a concrete Bug, a contract/spec ambiguity, an existing family, or non-actionable evidence;
- confirmed Bugs are implemented by Luna;
- unresolved residuals remain explicit rather than disappearing when the run budget ends;
- after repair, resume on a fresh fixed authoritative-main revision with fresh runtime evidence; a multi-family run never continues on the old revision after a fix is merged;
- a family-count or administrative stop while Sol is still converging normally leads to repair -> fresh-revision Sol continuation or a Sol successor residual Work item;
- Astra is invoked only under one of the three escalation conditions above.

For an Astra escalation:

- preserve the same evidence threshold and read-only boundary;
- state which escalation condition applies and which Sol residual/evidence defines the starting scope;
- do not implement fixes;
- return the retained evidence or high-assurance negative result to ChatGPT for disposition.

## Platform boundary

Describe this work accurately as local nuinuiCAD evaluator correctness and semantic-conformance testing. Do not add instructions intended to evade or bypass platform safeguards. If a platform restriction blocks a Sol or Astra run, stop and report the restriction.
