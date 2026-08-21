# nuinuiCAD Luna Manual E2E playbook

## Purpose

This document collects reusable operational techniques for running nuinuiCAD Manual E2E with Codex Luna xhigh reliably.

It is a **playbook**, not the acceptance-contract authority.

- Test classification, `Judgment`, `Executor`, PASS / FAIL / BLOCKED semantics, and Sol High result ownership are defined by [Manual E2E execution rules](./MANUAL-E2E.md).
- The standard VS Code isolated-host baseline is defined by [Project Context](./README.md).
- This playbook explains how to apply those rules in practice, especially around local VS Code operation, prompt construction, evidence capture, freshness, and common failure modes.

If this playbook conflicts with `MANUAL-E2E.md`, the current Issue contract, or the Project Context baseline, follow those authorities and refresh this playbook afterward.

## Core operating model

Luna is the operator, not the test designer.

For an assigned objective unit, keep the loop narrow:

```text
prepare exact state
-> operate
-> observe
-> compare with the predeclared oracle
-> capture evidence
-> report PASS / FAIL / BLOCKED
```

Do not ask Luna to decide product semantics, redesign a test, investigate architecture, repair implementation, or convert a Human judgment into an objective substitute.

## 1. Pin a stable tested state without fighting a moving `main`

Always fetch before execution and verify the intended remote state.

For a quiet repository, testing an exact current `origin/main` commit is sufficient.

For nuinuiCAD, unrelated work may merge while a Manual E2E prompt is being prepared or executed. Requiring:

```text
origin/main == <prompt SHA>
```

can then cause repeated false `BLOCKED` results even when the tested implementation has not changed.

When this is likely, create a dedicated stable remote E2E ref pointing at the reviewed commit, for example:

```text
origin/sayosomi/<issue>-manual-e2e-freeze
```

Luna should verify both:

```bash
EXPECTED="<tested commit>"
E2E_REF="origin/sayosomi/<issue>-manual-e2e-freeze"

test "$(git rev-parse "$E2E_REF")" = "$EXPECTED"
git merge-base --is-ancestor "$EXPECTED" origin/main
```

Normal advancement of `origin/main` is allowed. Record the current `origin/main` SHA in the result.

After Luna returns, Sol High must fresh-check latest `main` again and review drift from the frozen tested commit.

- unrelated drift that cannot affect the tested oracle does not invalidate the E2E result;
- drift that materially touches the tested behavior requires a new reviewed test state and rerun of affected units;
- if the tested commit is no longer an ancestor of `main`, treat that as remote-state staleness / rewrite, not a product failure.

Do not silently move a frozen ref after completed evidence has been recorded. Prefer preserving the evidence anchor and creating a new versioned ref when a new tested state is required.

## 2. Protect both standard checkouts

Before using a checkout, inspect both standard locations:

```text
/Users/yosomi/Code/nuinuiCAD
/Users/yosomi/Code/nuinuiCAD-sub
```

At minimum record:

```bash
git status --short
git branch --show-current
git rev-parse HEAD
```

Use only a clean checkout that is not occupied by unrelated active work.

If a clean idle checkout must test a historical/frozen commit, a detached checkout is acceptable:

```bash
git switch --detach "$EXPECTED"
test "$(git rev-parse HEAD)" = "$EXPECTED"
test -z "$(git status --porcelain)"
```

Never reset, stash, discard, overwrite, or force-switch unrelated user work to make room for Manual E2E.

If Luna detached a checkout only for the test, restore its original ref afterward with a normal non-destructive switch when safe.

## 3. Treat extension registration as an environment preflight

A VS Code UI test is meaningless if the development extension was never registered in the isolated host.

Before executing product oracles, verify the environment itself.

For a `.nui` fixture:

1. activate the fixture;
2. confirm the language mode is `nui` / nuinuiCAD, not Plain Text;
3. confirm the required contributed nuinuiCAD command(s) exist in Command Palette;
4. when useful, confirm the development extension appears in Running Extensions.

If this preflight fails:

```text
result = BLOCKED
reason = development extension registration / test environment unavailable
```

Do **not** mark the product unit FAIL.

Collect environment evidence instead, especially the newest relevant files under the fresh profile's `logs` directory. Useful evidence includes extension-host, window, or main logs mentioning:

- `nuinuiCAD`;
- `extensionDevelopmentPath`;
- extension scanning / activation;
- load errors or warnings.

Do not change implementation code to make the environment pass during a Manual E2E run.

## 4. Use the repository-compatible isolated VS Code launch shape

Use the current canonical launch baseline in `README.md`.

Important practical points:

- build the VS Code bundle before launch;
- build and explicitly provide the Rust `evaluation_stdio` binary;
- use a fresh `--user-data-dir` every run;
- use an empty `--extensions-dir`;
- disable VS Code built-in completion in the fresh profile;
- use `--disable-workspace-trust` so first-run trust state cannot block the dev host;
- suppress welcome / session welcome / release notes;
- open the task fixture directly rather than depending on opening the repository workspace folder;
- after rebuild, branch/commit switch, or blocking fix, close the old host and launch a fresh one.

Do not improvise with the normal user profile unless the test explicitly targets profile / extension interoperability.

## 5. Make fixtures easy to identify objectively

A good Luna fixture contains machine-visible identity markers that make the oracle unambiguous.

For multi-document tests, do not rely only on similar geometry. Give A and B distinct names such as:

```text
PrintA / SvgA / PieceA
PrintB / SvgB / PieceB
```

Then require evidence that reports those exact identities through selectors, tab titles, source text, Inspector text, accessible labels, or other stable UI text.

For state-preservation tests, establish the state before leaving the surface and record before/after evidence.

Examples:

- selected geometry identity before and after reveal;
- Preview selector text before and after cross-surface navigation;
- exact source span before and after an edit;
- A/B tabs present before source close and only A-owned sessions absent afterward.

Avoid oracles such as `the right document opened` when the prompt does not define how A and B are distinguished.

## 6. Prefer objective evidence over narration

A Luna result should make it possible for Sol High to validate the oracle without trusting phrases like `looks correct`.

Prefer combinations of:

- screenshots;
- accessibility state / accessible names;
- exact visible strings;
- active tab title;
- selector value;
- exact source text;
- before/after state;
- count evidence when duplicate prevention is part of the oracle.

Screenshots are useful but not sufficient when the relevant identity can also be captured as text.

For visual-but-objective tests, state exactly what visual fact is being checked. For example:

```text
PASS if the same selection marker remains on the same identified geometry.
```

Do not let Luna infer aesthetic quality from the screenshot.

## 7. Order tests to preserve useful evidence

Place destructive or lifecycle-ending operations last when possible.

Examples:

- close-source lifecycle tests after navigation / selection tests;
- delete/dispose tests after state-preservation checks;
- irreversible or state-resetting operations after independent read-only checks.

The prompt should say whether a failure invalidates later units.

If a failed unit does not make later state ambiguous, continue independent units so one failure does not hide unrelated evidence.

## 8. Keep the Luna prompt self-contained and narrow

For a fresh Luna session, include all execution-critical information directly in the prompt:

- repository and checkout identity;
- expected tested commit / stable ref;
- remote verification commands;
- checkout safety rules;
- exact build and launch block;
- exact fixture contents;
- selected test units only;
- initial state, action, oracle, evidence for each unit;
- stop / continue conditions;
- exact result format.

Do not make Luna rediscover the test plan from Linear, GitHub, previous chat history, or repository architecture.

For an already-running Luna session, a delta prompt may be smaller only when the retained context is explicit and still fresh. When in doubt, use a self-contained prompt.

Useful prompt language is direct:

```text
Do not modify implementation code.
Do not fix a failure.
Do not redesign or expand the test plan.
Do not perform Human-assigned units.
Return BLOCKED if the required state cannot be established objectively.
```

## 9. Do not weaken an oracle to fit Luna capability

If Luna can perform the operation but cannot reliably establish or observe the required state, the correct result may be `BLOCKED`.

Examples:

- a selection must be preserved but Luna cannot establish an objectively identifiable selection;
- a transient popup exists but accessibility / screenshot evidence cannot distinguish the required candidate;
- an interaction requires a physical device or judgment Luna cannot reproduce.

After a capability `BLOCKED`, Sol High may reclassify:

```text
Judgment: Objective
Executor: Human
Reason: Luna capability
```

when appropriate.

Do not replace the original oracle with an easier one simply to keep `Executor: Luna`.

## 10. Separate environment failure from product failure

Common `BLOCKED` patterns:

- prompt SHA became stale because unrelated `main` work merged;
- stable ref does not resolve to the expected commit;
- no clean safe checkout is available;
- development extension is not registered;
- fixture opens as Plain Text;
- required command is absent because the extension did not load;
- VS Code executable or Rust evaluation binary is unavailable;
- required initial UI state cannot be established or observed reliably;
- instructions or oracle are ambiguous.

Typical true `FAIL` pattern:

```text
The environment preflight passed.
The specified operation was executed.
The required state was objectively observable.
The observation contradicted the predeclared oracle.
```

Only that latter class should enter the implementation-failure loop.

## 11. Known pitfall: moving-main false blockers

Symptom:

```text
Luna fetches and immediately reports BLOCKED because origin/main is newer than the prompt SHA.
```

If the new commits are unrelated, repeatedly regenerating a prompt against the newest `main` can race forever.

Preferred response:

1. Sol High reviews the new drift;
2. choose a reviewed tested commit;
3. create a stable E2E ref;
4. test that exact ref;
5. after the run, review latest-main drift once more before accepting the result.

The goal is stable evidence plus a separate freshness judgment, not pretending the repository stops moving while the UI test runs.

## 12. Known pitfall: isolated host opens but extension is absent

Symptom:

- VS Code launches successfully;
- `.nui` remains Plain Text;
- nuinuiCAD commands are absent;
- Running Extensions does not show the development extension.

Treat this as environment `BLOCKED`.

For nuinuiCAD, use the current README canonical launch shape, especially:

- explicit Rust binary;
- fresh profile;
- empty extension directory;
- `--disable-workspace-trust`;
- first-run UI suppression;
- fixture-only open;
- exact `--extensionDevelopmentPath`.

Then run the extension-registration preflight before product units.

## 13. Result format should expose enough state for Sol High review

A useful result header records:

```text
Tested commit:
Stable E2E ref:
Checkout used:
origin/main at execution:
Repository status before test:
VS Code executable:
VS Code version:
E2E_ROOT:
Extension registration preflight:
Repository implementation files modified: YES | NO
```

For each unit record:

```text
Unit <id>: PASS | FAIL | BLOCKED
Expected:
Observed:
Evidence:
Reproduction steps if FAIL:
Blocker if BLOCKED:
```

For grouped identity tests, record every subcase explicitly instead of summarizing the group as `works`.

## 14. Sol High acceptance checklist after Luna returns

Before accepting a Luna `PASS`, Sol High should confirm:

1. the tested commit / stable ref is the intended state;
2. the environment preflight passed;
3. repository implementation files were not modified during E2E;
4. every required Luna unit has concrete evidence matching its oracle;
5. Human-assigned units, if any, remain outstanding until the user passes them;
6. latest `origin/main` drift from the tested state has been reviewed;
7. any drift touching the tested semantics has been handled before marking aggregate Manual E2E `Passed`;
8. Done-before Ready contract freshness check is still performed separately.

## Maintenance rule

Add to this playbook when a Manual E2E run exposes a reusable operating lesson.

Good additions are durable patterns such as:

- a launch condition needed for reliable extension registration;
- a better evidence technique;
- a repeated Luna capability boundary;
- a freshness strategy that avoids false blockers;
- a prompt structure that materially improves repeatability.

Do not turn this file into a history of individual Issues or paste completed task prompts verbatim. Preserve the reusable rule and let Git / Linear history retain the incident details.
