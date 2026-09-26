# nuinuiCAD Astra Evaluator Audit Policy

## Authority and scope

This is the sole nuinuiCAD project-policy owner for GPT-6 Astra's evaluator exploration role. The work covered here is local nuinuiCAD evaluator correctness and semantic-conformance testing. It is not a source-implementation role.

This policy defines Astra's role and the handoff for its findings. Project checkout constraints are owned by [`CHECKOUTS.md`](./CHECKOUTS.md). Current Work selection and tracking continue to follow the project's existing work-management policy.

## Role split

| Owner | Responsibility |
| --- | --- |
| ChatGPT | Select Work and set the bounded exploration scope; make semantic and product decisions; triage findings; author or update Issues and implementation contracts; review results and implementation. |
| GPT-6 Astra in Codex | Perform open-ended exploration only when its value comes from searching a large space: evaluator semantic conformance, TypeScript-reference versus production-Rust differential execution, metamorphic/property exploration, generation of many valid combinations, mismatch reduction, controls, and root-cause boundary isolation across compiler, evaluator, and transport layers. |
| Luna | Own source implementation and blocking fixes, deterministic regression tests, normal verification, integration, and implementation Git work. Luna remains the normal and only implementation Coding Agent. |

## When Astra is appropriate

Use Astra only when broad, open-ended search is the main value of the Work and the search domain can be bounded before the run. Examples include exploring combinations that are uneconomical to enumerate by hand, comparing the TypeScript reference evaluator with the production Rust evaluator, checking metamorphic properties, reducing mismatches, and isolating the boundary where behavior diverges.

ChatGPT sets the exploration question, semantic boundaries, audit revision, relevant controls, and evidence expected from the run. Astra reports observations and reproducible evidence; it does not decide product semantics or choose implementation behavior.

Astra is not a general implementation executor. Do not route known Bug implementation, blocking fixes, deterministic regression-test work, routine verification, Issue authoring, product or architecture decisions, PR work, or merge/integration work to Astra. Do not let an exploration Work silently expand into source implementation.

## Work shaping for benign correctness exploration

Shape each Astra run so its actual purpose and boundary are explicit from the start. This is intended to reduce ambiguity between nuinuiCAD product-correctness research and cybersecurity work; it is not a mechanism for bypassing platform safeguards.

- One Astra Work item covers one bounded correctness domain. Do not ask for repo-wide unknown-defect hunting. Unknown-defect discovery remains allowed inside the selected semantic domain.
- State the owned local target and correctness purpose explicitly, for example local nuinuiCAD compiler/evaluator/language-service behavior at one fixed audit revision.
- Express the exploration in terms of semantic or behavioral invariants to verify, such as source-order invariance, equivalent-program consistency, cross-feature consistency, revision isolation, or reference/identity preservation.
- Constrain execution to the Human-authorized local checkout or forensic-worktree path, nuinuiCAD compiler/evaluator/test runners, and temporary local artifacts allowed by [`CHECKOUTS.md`](./CHECKOUTS.md). External targets, network scanning, credentials, privilege escalation, exploit development, and other security objectives are out of scope.
- Define a bounded stopping condition before the run, such as completion of the selected feature-family matrix, a maximum planned case budget, or a fixed number of independent retained findings.
- For each retained mismatch, stop at reproducible evidence, nearby controls, reduction, and the first useful incorrect boundary, then return the finding to ChatGPT under the normal handoff below.
- Use terminology that accurately describes the task, such as semantic conformance, property/metamorphic correctness, cross-feature consistency, or regression exploration when those are the real goals. Do not cosmetically rename a security task or add wording whose purpose is to evade classification.
- If a platform restriction still blocks the run, stop and report it rather than weakening or obscuring the task boundary.

## Work and finding handoff

Track an Astra run as explicit Research/Improvement Work with a bounded semantic search domain under the current work-management authority ([`LINEAR.md`](./LINEAR.md) and [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)). Keep the audit revision fixed for the run; if the revision or required semantic scope changes, stop and return the decision to ChatGPT.

When Astra confirms an independent defect family, Astra stops after producing the evidence, reduced reproduction, controls, and root-cause boundary needed for triage. ChatGPT evaluates the semantics, creates or updates the concrete Bug contract, and reviews the finding. Implementation and deterministic regression coverage then return to Luna under the normal implementation workflow.

## Platform boundary

Describe the work accurately as local nuinuiCAD evaluator correctness and semantic-conformance testing. Do not add instructions intended to evade or bypass platform safeguards. If a platform restriction blocks an Astra run, stop and report the restriction.
