# nuinuiCAD Project Context

Repository: `sayosomi/nuinuiCAD`

このREADMEはChatGPT Projectの固定入口 / router。現在のSHA、branch、Task進捗、実装計画はここに置かず、現行のownerへ案内する。**毎回すべてのリンク先を読まない。**
作業に必要な文書だけを読み込む。

## Current routes

- **GitHub-native implementation (D1, active):** New `sayosomi/nuinuiCAD#N` Work uses the single-checkout
  Git-only route in [CHECKOUTS.md](./CHECKOUTS.md) and [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md). The
  global activation is already recorded in historical
  [dev-context #268](https://github.com/sayosomi/dev-context/issues/268); it does not require per-Task
  activation. Never send a native Issue through the legacy SAY-only `nuinui begin/handoff/release` lifecycle.
- **Implementation Coding Agent:** [CODING-AGENT.md](./CODING-AGENT.md) owns the lower-tier default (e.g.
  Luna), Human-explicit upper-tier selection (e.g. Astra / Sol Xhigh), roles, and narrow ChatGPT
  direct-execution exceptions. Agent tier selection is **not** the separate explicit Issue-body opt-in for
  bounded autonomous conformance discovery/repair. Opted-in implementation still obeys D1, independent review,
  PR/CI, and Human Manual E2E.
- **Evaluator audit (D2-C, active):** [ASTRA-AUDIT.md](./ASTRA-AUDIT.md) owns the read-only audit role,
  findings and escalation. [CHECKOUTS.md](./CHECKOUTS.md) and [ISSUES.md](./ISSUES.md) own fixed-SHA
  admission, sequential exclusion, operational checkpoints and independent final checkout proof. An audit does
  not authorize product source edits. The historical D2-B pilot is not a future audit SHA.
- **Standalone context operations (active):** Use `nuinui-context`, as documented in
  [LOCAL-TOOLS.md](./LOCAL-TOOLS.md), for independent context audit/sync, development worktree operations and
  their result read-back. Check the Git artifact and installed executable identities separately; do not
  substitute the legacy `nuinui` artifact.
- **Native Human Manual E2E (active since #286 checkpoint):** The registered Human-test checkout supported a real signed VS Code GUI test that detected a product defect and completed checked host/checkout closure ([#1373 evidence](https://github.com/sayosomi/nuinuiCAD/issues/1373#issuecomment-6210238535)); later independent local checkout verification passed ([#1379 proof](https://github.com/sayosomi/nuinuiCAD/issues/1379#issuecomment-6228687181)). Product FAIL does not mean E2E infrastructure FAIL. General tool use was activated by reviewed [PR #316](https://github.com/sayosomi/dev-context/pull/316) and the explicit [#286 checkpoint](https://github.com/sayosomi/dev-context/issues/286#issuecomment-6229806159), **not** by a product-fix rerun. Every new run requires fresh exact admission and Human-only judgment; see [CHECKOUTS.md](./CHECKOUTS.md), [VS-CODE-E2E.md](./VS-CODE-E2E.md) and [MANUAL-E2E.md](./MANUAL-E2E.md).
- **Legacy `nuinui` (reference retention):** Do not start new SAY/Linear Work or route GitHub-native tasks through old product commands. Preserve the old executable, generator, source, tests and durable SAY history as historical reference instead of deleting them. Existing in-flight legacy ownership and required exact recovery remain protected until final exclusion under [#286](https://github.com/sayosomi/dev-context/issues/286). See [CHECKOUTS.md](./CHECKOUTS.md), [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md) and [LOCAL-TOOLS.md](./LOCAL-TOOLS.md) for transitional compatibility.

The historical cutover and Cloudflare Phase B exception are recorded in
[#268](https://github.com/sayosomi/dev-context/issues/268); remaining native E2E activation and legacy
product-lifecycle retirement from active use are tracked solely in [#286](https://github.com/sayosomi/dev-context/issues/286).
Those histories are not normal startup procedures.

## Sources of truth

- **Current Work contract / acceptance:** canonical GitHub Issue body. Material decisions and operational
  checkpoints: Issue comments. Execution evidence: GitHub branches, commits, PRs, checks and authoritative
  merge read-back. See [ISSUES.md](./ISSUES.md).
- **Actual code and engineering policy:** latest remote `sayosomi/nuinuiCAD` and its current
  [AGENTS.md](https://github.com/sayosomi/nuinuiCAD/blob/main/AGENTS.md). Current architecture:
  `ARCHITECTURE.md`; normative nui1 language: `docs/nui1/spec.md`; implemented DSL: `docs/dsl.md`, all in the
  product repository.
- **Execution capacity:** the actual declared `role=implementation` and `role=human-test` checkouts in
  [LANES.conf](./LANES.conf), not chat count, worker count or historic lane names. Current lane safety and
  isolation belong to [CHECKOUTS.md](./CHECKOUTS.md) and
  [shared declared-lane policy](../../shared/DECLARED-LANE-EXECUTION.md). Do not invent another checkout,
  modify the Human-test checkout as an implementation lane, or skip required Manual E2E.
- **Historical references only:** existing Linear Issues/Documents/mirrors and Notion retain their provenance.
  No new Linear Work, Documents, reverse sync or mirror reconciliation is part of ordinary GitHub-native
  development. Native Work does not inherit SAY claim/Linear checkpoint mechanics.

If management documents or past chats conflict with actual implemented behavior, inspect the latest product
repository. A chat rotation never changes Work status, lane occupancy, Base or branch by itself.

## Loading by task

**Always for development:** this router, [shared development workflow](../../shared/DEVELOPMENT.md) and the
current product `AGENTS.md`. For changes to `dev-context` itself, follow root
[DEVELOPMENT.md](../../DEVELOPMENT.md) and [ISSUES.md](../../ISSUES.md) instead of importing product checkout
rules.

| Task / condition | Read only the relevant owner(s) |
| --- | --- |
| Chat role selection, rotation, external-state recovery | [CHAT-WORKFLOW.md](./CHAT-WORKFLOW.md) and the role-specific [Coordinator](./CHAT-COORDINATOR.md), [Authoring](./CHAT-AUTHORING.md), [Implementation](./CHAT-IMPLEMENTATION.md) or [E2E](./CHAT-E2E.md) chat document |
| New Work, Issue readiness, contract/decision re-audit | [ISSUES.md](./ISSUES.md), [CONTRACT-DECISIONS.md](./CONTRACT-DECISIONS.md), [CONTRACT-REAUDIT.md](./CONTRACT-REAUDIT.md) as applicable; current Issue and repository |
| Native implementation start, recovery, checkout/branch/occupancy | [CHECKOUTS.md](./CHECKOUTS.md), [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md), [CHAT-IMPLEMENTATION.md](./CHAT-IMPLEMENTATION.md) |
| Implementation-agent selection, blocking fix, autonomous conformance opt-in, direct execution | [CODING-AGENT.md](./CODING-AGENT.md); [shared coding workflow](../../shared/CODING-AGENT-WORKFLOW.md), [prompt style](../../shared/AGENT-PROMPT-STYLE.md) and [prompt preflight](../../shared/AGENT-PROMPT-PREFLIGHT.md) when constructing an agent prompt |
| Agent skill selection | [Shared Agent Skills](../../shared/AGENT-SKILLS.md) and [nuinuiCAD Agent Skills](./AGENT-SKILLS.md), when applicable |
| Slicing, Base/integration checkpoints, sequential PR, scope expansion | [IMPLEMENTATION-SLICING.md](./IMPLEMENTATION-SLICING.md) |
| GitHub PR linking, independent review, CI, merge and auto-merge | [LINEAR-GITHUB.md](./LINEAR-GITHUB.md) |
| D2-C read-only evaluator audit | [ASTRA-AUDIT.md](./ASTRA-AUDIT.md), [CHECKOUTS.md](./CHECKOUTS.md), [ISSUES.md](./ISSUES.md) |
| Human Manual E2E | [MANUAL-E2E.md](./MANUAL-E2E.md), [CHECKOUTS.md](./CHECKOUTS.md), [CHAT-E2E.md](./CHAT-E2E.md), [LOCAL-TOOLS.md](./LOCAL-TOOLS.md); for VS Code host, [VS-CODE-E2E.md](./VS-CODE-E2E.md). Load [VS-CODE-E2E-LOCALE.md](./VS-CODE-E2E-LOCALE.md) only for locale-specific verification |
| Local helpers, context sync, command/result recovery | [LOCAL-TOOLS.md](./LOCAL-TOOLS.md); [CHECKOUTS.md](./CHECKOUTS.md) for Human exact-fix or legacy release/ownership |
| Compatible already-admitted SAY task | [LINEAR.md](./LINEAR.md), applicable [LINEAR-ISSUES.md](./LINEAR-ISSUES.md), [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md) and [LOCAL-TOOLS.md](./LOCAL-TOOLS.md); never for a new native Issue |
| CI incident / lane-based reproduction | [CI-INCIDENTS.md](./CI-INCIDENTS.md) only with a strong CI-incident signal |
| User-facing command addition/change | [COMMAND-CONTRACTS.md](./COMMAND-CONTRACTS.md) |
| Historical Linear Projects/Documents/capacity or preserved GitHub mirrors | [LINEAR-PROJECTS.md](./LINEAR-PROJECTS.md), [LINEAR-DOCUMENTS.md](./LINEAR-DOCUMENTS.md), [LINEAR-CAPACITY.md](./LINEAR-CAPACITY.md), [GITHUB-ISSUES-SYNC.md](./GITHUB-ISSUES-SYNC.md) only for relevant history; mirror contract/ops only for historical investigation |
| Inactive contingency or archived workflow | [CODEX-ONLY-INTERIM.md](./CODEX-ONLY-INTERIM.md) only if Human considers reactivation; [LUNA-E2E-PLAYBOOK.md](./LUNA-E2E-PLAYBOOK.md) only for explicit Human reactivation; [NOTION-LEGACY.md](./NOTION-LEGACY.md) only for archive history |

Shared [Agent Prompt Style](../../shared/AGENT-PROMPT-STYLE.md) controls prompt formatting;
[shared Coding Agent Workflow](../../shared/CODING-AGENT-WORKFLOW.md) controls prompt completeness. For
ordinary implementation, load relevant owners based on the actual phase rather than all rows in advance.

## Maintenance

Do not add procedural rules here. Keep this file a concise owner/router and update its conditional links only
when a canonical owner or loading condition changes.
