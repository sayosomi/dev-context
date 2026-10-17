# nuinuiCAD Project Context

Repository: `sayosomi/nuinuiCAD`

このREADMEはChatGPT Projectから参照する**固定入口 / router**。

Current taskのSHA、branch、進捗、個別implementation planはここに書かない。詳細policyはowner documentへ置き、このREADMEは「何をいつ読むか」を中心に保つ。

## Normal GitHub-native Git-only implementation route

Ordinary future GitHub-native implementation Tasks use the existing single-checkout Git-only route in [`CHECKOUTS.md`](./CHECKOUTS.md) and
[`EXECUTION-HANDOFF.md`](./EXECUTION-HANDOFF.md). General activation becomes
effective only after the coordinated D1 policy PR is independently reviewed,
merged, read back on authoritative dev-context `main`, and recorded as the
activation checkpoint in [dev-context #268](https://github.com/sayosomi/dev-context/issues/268).
Until all four conditions are met, do not start a GitHub-native implementation.
Afterward, no separate per-Task approval or activation mechanism is required.
Ordinary implementation uses a lower-tier Coding Agent (e.g. Luna) by default;
a Human-explicit selection may use an upper-tier agent (e.g. Astra or Sol Xhigh).
The bounded autonomous conformance mode **separately** requires the exact
Issue-body opt-in in [`CODING-AGENT.md`](./CODING-AGENT.md); it is not another
D1 approval or activation.
The opted-in Issue still uses the D1 checkout, checkpoint, review, PR/CI, and
Human Manual E2E rules below and in [`CHECKOUTS.md`](./CHECKOUTS.md).

## Evaluator audit route — D2-C activation gated

New GitHub-native evaluator audits use the reservation-free fixed-SHA route
only after the D2-C policy PR is independently reviewed and merged, read back
on authoritative dev-context `main`, and followed by a separate explicit
activation checkpoint in [dev-context #268](https://github.com/sayosomi/dev-context/issues/268).
Until then, do not start a new reservation-free audit. Read
[`ASTRA-AUDIT.md`](./ASTRA-AUDIT.md) for executor roles and evidence, and
[`CHECKOUTS.md`](./CHECKOUTS.md) plus [`ISSUES.md`](./ISSUES.md) for admission,
operational checkpoints, independent final checkout verification, and safe
return. This route remains read-only and cannot authorize source changes; a
separate implementation Issue must opt in to the implementation-side mode.

The completed [D2-B pilot on #1194](https://github.com/sayosomi/nuinuiCAD/issues/1194)
is historical operational proof at the revision recorded in its
[independently verified final checkout checkpoint](https://github.com/sayosomi/nuinuiCAD/issues/1194#issuecomment-6128846922).
That SHA is not a fixed revision for future audits. General use still requires
the separate D2-C activation checkpoint in #268.

## Standalone dev-context context operations — active

The standalone `nuinui-context` route is the current authority for independent
context audit / sync, dev-worktree audit / transition, checks, and its own
result read-back. The route was explicitly activated under historical dev-context
[#268](https://github.com/sayosomi/dev-context/issues/268#issuecomment-6137262760)
and independently verified under [#286](https://github.com/sayosomi/dev-context/issues/286).
Use [`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) for current operation and recovery details. Derive its
expected Git artifact from fresh authoritative `main` and verify the installed
executable identity separately. Policy wording changes do not restart the
accepted activation or canary gates; current operations still verify the
executable and Git artifact identities separately.
Keep legacy `nuinui` lifecycle, audit reservation, and E2E operations and
their result store available for compatible SAY work. See
[`LOCAL-TOOLS.md`](./LOCAL-TOOLS.md) for rollout and recovery boundaries and
[dev-context `DEVELOPMENT.md`](../../DEVELOPMENT.md) for sequential worktree
transition rules.

Native GitHub Manual E2E lifecycle and the registered Human-test lane are owned
by [`CHECKOUTS.md`](./CHECKOUTS.md). The Human-test checkout is physically
registered under dev-context #286, and the already approved bounded real-host
pilot remains permitted under fresh production admission. Its first attempt
was blocked before GUI, recovered, and fully released; the host-root defect
was fixed by PR [#290](https://github.com/sayosomi/dev-context/pull/290) and
synchronized. No Human GUI outcome or Manual E2E PASS is established. General
native activation remains pending a genuine Human-operated macOS VS Code
Manual E2E PASS, independently verified checkout closure, and a separate
explicit checkpoint. That general activation gate does not prohibit the
already approved bounded pilot. Host setup constraints are in
[`VS-CODE-E2E.md`](./VS-CODE-E2E.md); Human execution and judgment remain in
[`MANUAL-E2E.md`](./MANUAL-E2E.md).

## Compatible legacy SAY implementation flow

The flow below applies only to pre-existing SAY tasks already admitted to the
current `nuinui begin` / `handoff` / `release` lifecycle. Keep it for those
compatible tasks until a separate retirement checkpoint. Never route a new
GitHub-native Issue through the SAY-only helper.

```text
Human asks ChatGPT to implement
-> ChatGPT performs current-state / contract work
-> Human runs one short local startup mutation only when genuinely required
-> ChatGPT outputs the complete implementation-agent prompt directly in chat
-> Human selects the implementation-agent product / model / effort outside the prompt
-> Human copies the prompt to the selected implementation agent
-> implementation agent runs canonical nuinui handoff
-> HANDOFF VERIFIED
-> implementation / test / commit / push
-> result returns to ChatGPT
```

The Human does not run implementation-agent handoff verification or manage
prompt files, expected-context files, ticket refs, ticket tokens, claims, or
checkpoints as transport artifacts.

For a single self-contained textual repair, ChatGPT may explicitly authorize the
one-shot Human exact-fix exception defined in CHECKOUTS.md and routed by
CODING-AGENT.md. The helper resolves the active generation itself and records
recovery evidence through the existing last-result surface; it is not a
replacement for the normal implementation-agent route.

## Always load for development work

開発作業では最初に次を読む。

- [Shared Development Workflow](../../shared/DEVELOPMENT.md)
- repositoryのcurrent [`AGENTS.md`](https://github.com/sayosomi/nuinuiCAD/blob/main/AGENTS.md)

実装済みの事実、owner、API、surface、architecture、DSLについて判断するときは必ずlatest remote `sayosomi/nuinuiCAD` repositoryを確認する。dev-context、Linear、過去chat、local copyをactual implementationのsource of truthにしない。

## Project-specific policy map

| Topic | Owner |
| --- | --- |
| Human-authorized exact source-fix exception | CHECKOUTS.md + LOCAL-TOOLS.md |
| inactive contingency workflow for ChatGPT availability / token constraints | [Codex-only interim workflow](./CODEX-ONLY-INTERIM.md) — **Inactive; load only when reactivation is being considered** |
| Chat common lifecycle / role routing / rotation / external-state recovery | [Chat workflow](./CHAT-WORKFLOW.md) |
| Coordinator status / Work selection / routing handoff | [Coordinator chat](./CHAT-COORDINATOR.md) |
| Issue Authoring / contract investigation chat behavior | [Issue Authoring chat](./CHAT-AUTHORING.md) |
| Implementation chat start / resume / continuation handoff | [Implementation chat](./CHAT-IMPLEMENTATION.md) |
| E2E chat lifecycle | [E2E chat](./CHAT-E2E.md) |
| declared execution lanes / checkout occupancy / checkpoint isolation | [Execution lane policy](./CHECKOUTS.md) + [Declared-lane Execution Model](../../shared/DECLARED-LANE-EXECUTION.md) |
| local versioned helper / local dev-context sync / tool promotion | [Local tools](./LOCAL-TOOLS.md) |
| implementation-agent prompt language / formatting | [Shared Agent Prompt Style](../../shared/AGENT-PROMPT-STYLE.md) |
| implementation-agent prompt completeness / style | [Shared Implementation Coding Agent Workflow](../../shared/CODING-AGENT-WORKFLOW.md) + [Shared Agent Prompt Style](../../shared/AGENT-PROMPT-STYLE.md) |
| implementation-agent handoff identity / startup safety | [Execution handoff authority](./EXECUTION-HANDOFF.md) |
| GitHub-native Git-only startup, recovery, slicing, and safe return | [CHECKOUTS.md](./CHECKOUTS.md), [EXECUTION-HANDOFF.md](./EXECUTION-HANDOFF.md), [CHAT-IMPLEMENTATION.md](./CHAT-IMPLEMENTATION.md), [CODING-AGENT.md](./CODING-AGENT.md), [IMPLEMENTATION-SLICING.md](./IMPLEMENTATION-SLICING.md) |
| implementation / blocking-fix Coding Agent workflow | [Shared Implementation Coding Agent Workflow](../../shared/CODING-AGENT-WORKFLOW.md) + [nuinuiCAD Implementation Coding Agent Policy](./CODING-AGENT.md) |
| read-only evaluator correctness / semantic-conformance audits and finding handoff | [Evaluator Audit Policy — Sol first / Astra escalation](./ASTRA-AUDIT.md) |
| per-Issue autonomous conformance discovery and repair | [Implementation Coding Agent Policy](./CODING-AGENT.md) + [Implementation slicing policy](./IMPLEMENTATION-SLICING.md); D1 admission in [CHECKOUTS.md](./CHECKOUTS.md) |
| implementation slicing / integration checkpoint / sequential PR | [Implementation slicing policy](./IMPLEMENTATION-SLICING.md) |
| implementation / review skill selection | [Shared Agent Skills](../../shared/AGENT-SKILLS.md) + [nuinuiCAD Agent Skills](./AGENT-SKILLS.md) |
| Current Work authoring / contract / readiness / completion | [GitHub Issues policy](./ISSUES.md) |
| GitHub PR linking / review / merge policy | [GitHub PR policy](./LINEAR-GITHUB.md) |
| Historical Linear reference and legacy SAY execution checkpoints | [Linear policy router](./LINEAR.md) |
| Historical Linear Issue status / Ready Queue / lane checkpoints | [Linear Issue workflow](./LINEAR-ISSUES.md) — compatible pre-existing SAY execution only |
| Historical Linear Project / Project labels | [Linear Project policy](./LINEAR-PROJECTS.md) |
| Historical Linear Documents and provenance | [Linear Document policy](./LINEAR-DOCUMENTS.md) |
| shared CI incident / declared-lane reproduction | [Shared CI incident escalation](./CI-INCIDENTS.md) |
| Manual E2E Judgment / Human Executor / PASS-FAIL-BLOCKED | [Manual E2E execution rules](./MANUAL-E2E.md) |
| VS Code isolated Manual E2E host | [VS Code Manual E2E environment](./VS-CODE-E2E.md) |
| VS Code locale-specific / translated-UI Manual E2E | [VS Code locale Manual E2E](./VS-CODE-E2E-LOCALE.md) — **load only when display-language / locale-specific verification is required** |
| Luna Manual E2E prompt / evidence / pitfalls | [Luna Manual E2E playbook](./LUNA-E2E-PLAYBOOK.md) — **Inactive; do not load/use unless Human explicitly reactivates Luna E2E** |
| implementation contract judgment | [Implementation contract decision rule](./CONTRACT-DECISIONS.md) |
| user-facing command contract | [Command contract policy](./COMMAND-CONTRACTS.md) |
| explicit contract re-audit | [Contract re-audit policy](./CONTRACT-REAUDIT.md) |
| Historical Linear Free plan capacity | [Linear Free plan capacity policy](./LINEAR-CAPACITY.md) |
| Historical GitHub Issue mirror mapping / preservation | [GitHub Issues sync](./GITHUB-ISSUES-SYNC.md) |
| legacy Notion | [Legacy Notion archive](./NOTION-LEGACY.md) |

## Declared execution lanes

nuinuiCADのlocal executionはversioned [`LANES.conf`](./LANES.conf)に宣言されたlaneだけを使う。generic execution semanticsは [`DECLARED-LANE-EXECUTION.md`](../../shared/DECLARED-LANE-EXECUTION.md)、project-specific checkout policyは [`CHECKOUTS.md`](./CHECKOUTS.md) がownerする。

The checked-in manifest currently declares one implementation lane and one Human-test lane; both declared checkout paths are registered. Lane names and paths are data and do not define capacity.

- `main` implementation lane (`idle=branch`): `/Users/yosomi/Code/nuinuiCAD`
- `human-e2e` Human-test lane (`idle=detached`): `/Users/yosomi/Code/nuinuiCAD-e2e`

Hard rule:

- implementation capacity is the count of declared `role=implementation` lanes;
- Human-test capacity is the count of declared `role=human-test` lanes;
- The `human-e2e` Human-test lane is declared and registered. Its existing bounded-pilot authorization under #286 remains usable with fresh exact production admission; general native Manual E2E activation remains pending a genuine Human GUI PASS, independent checkout closure, and an explicit activation checkpoint. Do not treat the general gate as a ban on the approved pilot. Required Manual E2E cannot be skipped or marked PASS without Human judgment, and no additional lane or checkout registration is authorized;
- Manual E2EのExecutorはHumanのみ。implementation Coding AgentをE2E executionに使わない;
- Human-authorized forensic worktreeは[`CHECKOUTS.md`](./CHECKOUTS.md)の明示的なone-shot inventory exceptionで認識される場合に限り1つだけ存在でき、lane capacityを追加しない;
- active implementation sliceはBase checkpoint SHAを固定し、integration checkpointまで他lane / remote mainの変更を取り込まない;
- E2Eでimplementation failureが出たらFREEなdeclared implementation laneへfixを戻し、Human-test checkoutでは修正しない。

## Repository-owned sources of truth

- actual code / implemented behavior: latest `sayosomi/nuinuiCAD` repository
- repository engineering policy: `AGENTS.md`
- current architecture / navigation index: `ARCHITECTURE.md`
- normative nui1 language contract: `docs/nui1/spec.md`
- implemented user-facing DSL documentation: `docs/dsl.md`

実装事実について管理文書・過去chat・work-management systemとrepositoryが矛盾する場合はlatest repositoryをauthoritativeとする。

## Work / specification management

After the coordinated C1 policy change has merged and authoritative `main`
read-back has succeeded, GitHub Issues are the primary Work and current-contract
authority. New native Work uses `sayosomi/nuinuiCAD#N`; the Issue body owns
current scope and acceptance, comments retain material decisions and evidence,
and GitHub branches, commits, PRs, and checks establish execution facts. See
[`ISSUES.md`](./ISSUES.md) for authoring, readiness, freshness, and completion.

New GitHub-native Work may be authored after the C1 cutover. Its implementation
uses the Git-only route only after the separate general D1 activation checkpoint
described above. Pre-existing SAY tasks already admitted to the current
`nuinui` lifecycle may retain only the minimum Linear execution/status
checkpoints that lifecycle requires until a separate retirement checkpoint.
These checkpoints do not change the GitHub Issue contract or execution evidence.
No new Linear Work or Documents, bulk Linear updates, or reverse sync are part of
the normal route.

Existing Linear Documents and Linear/GitHub mirrors remain historical evidence;
their identity and links are retained. Repository-owned normative
specifications keep their current owners. Notion remains a legacy archive, not
a new Work or specification owner.

For existing SAY execution only, inspect the applicable historical Linear
checkpoint and the latest repository state. Do not treat Linear as the source
for new Work, current GitHub Issue contracts, or implemented behavior.

C1 GitHub Issues Work authority and the general D1 Git-only implementation
route are active. The completed #1374 pilot remains one-off operational proof
under its expressly waived policy-amendment prerequisite. D1 is one global
policy checkpoint, not a per-Task approval step. Compatible pre-existing SAY
work keeps its legacy lifecycle. Reservation-free evaluator audits have their
separate D2-C activation boundary; Human Manual E2E policy and legacy
runtime-helper retirement remain separate.

## Parallel execution rule

Parallelismはunbounded worker / reservation modelではなく、物理laneで表現する。

```text
each declared implementation lane -> at most one current implementation Issue
each declared Human-test lane    -> at most one current Manual E2E Issue
```

implementation lanesは互いの途中変更を取り込まない。

一方のPRが先にmainへmergeされても、もう一方はactive slice途中でmerge-main / rebase-mainしない。Integration checkpointの実行は[`IMPLEMENTATION-SLICING.md`](./IMPLEMENTATION-SLICING.md) / [`CODING-AGENT.md`](./CODING-AGENT.md)に従い、eligibleなdeterministic merge-only workはHuman `nuinui integrate-clean`を使い、integration reasoning / conflict / fixが必要な場合はimplementation Coding Agentが担当する。

同じlaneで次Taskへ進むときは、前Taskをmergeまたはremote保存済みsafe checkpointでreleaseした後、新Task startとしてlatest remote stateからnew Base checkpointを固定する。

## Loading rule

毎回すべてのlinked documentを読む必要はない。

1. **Always:** このREADMEを読む。`CODEX-ONLY-INTERIM.md`はInactiveな間は通常loadしない。Humanが明示的に再有効化を検討・指示した場合だけ読み、Active化された場合はlisted override topicで同documentを優先する。
2. **Chat role / start / resume / rotation / handoff / recovery:** `CHAT-WORKFLOW.md` + current role owner (`CHAT-COORDINATOR.md` / `CHAT-AUTHORING.md` / `CHAT-IMPLEMENTATION.md` / `CHAT-E2E.md`)。
3. **Development work:** `shared/DEVELOPMENT.md`とcurrent repository `AGENTS.md`。
4. **Checkout / branch / local execution / concurrency:** `CHECKOUTS.md`。
5. **Local versioned helper / local dev-context sync / tool trial-promotion-repair:** `LOCAL-TOOLS.md`。
6. **Read-only evaluator audit:** `ASTRA-AUDIT.md` (Sol first pass; Astra only under the documented audit escalation conditions). D2-C admission, fixed-SHA read-only execution, audit limits, and final checkout verification are in `CHECKOUTS.md`; current audit Work follows `ISSUES.md`. For implementation-side autonomous discovery and repair, use the explicit Issue-body opt-in and owner rules in `CODING-AGENT.md`, plus D1 admission in `CHECKOUTS.md` and sequential checkpoints in `IMPLEMENTATION-SLICING.md`.
7. **Implementation-agent prompt generation:** `shared/AGENT-PROMPT-STYLE.md` + `shared/CODING-AGENT-WORKFLOW.md` + `EXECUTION-HANDOFF.md`.
8. **Implementation / blocking fix:** `shared/CODING-AGENT-WORKFLOW.md` + `CODING-AGENT.md`. Read Shared / nuinuiCAD Agent Skills when applicable.
9. **Implementation start / pause-resume / sequential PR / integration checkpoint / scope expansion:** `IMPLEMENTATION-SLICING.md`.
10. **New Work authoring / contract / re-audit:** `ISSUES.md`, `CONTRACT-DECISIONS.md`, and `CONTRACT-REAUDIT.md`; read the relevant current Issue and repository owners fresh.
11. **Historical Linear references or a compatible pre-existing SAY execution checkpoint:** `LINEAR.md` and only the applicable Linear owner. Do not use Linear for new Work, Documents, bulk updates, or reverse sync.
12. **PR creation / review / merge / Auto-merge:** [`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md), which owns current GitHub-native policy and retains the legacy SAY integration record.
13. **Manual E2E:** `MANUAL-E2E.md` + `LOCAL-TOOLS.md`. For a VS Code host, also read `VS-CODE-E2E.md`. Read `VS-CODE-E2E-LOCALE.md` only when display-language / locale-specific verification is required. The Manual E2E executor is always Human. `LUNA-E2E-PLAYBOOK.md` is inactive; load it only if the Human explicitly asks to consider reactivating Luna E2E.
14. **Shared CI incident suspicion / local reproduction:** read `CI-INCIDENTS.md` only when there is a strong signal. Reproduction also uses only a FREE declared implementation lane.
15. **Adding or changing a user-facing command surface:** `COMMAND-CONTRACTS.md`.
16. **Historical mirror mapping / provenance / disabled reconciliation investigation:** `GITHUB-ISSUES-SYNC.md`; load `GITHUB-ISSUES-MIRROR-CONTRACT.md` or `GITHUB-ISSUES-MIRROR-OPS.md` only to understand preserved history. Do not run ordinary reconciliation.
17. **Legacy history:** read `NOTION-LEGACY.md` only when needed.
18. **Current implementation / architecture / DSL decisions:** always inspect the latest repository.

## Maintenance rule

このREADMEへ新しい詳細ruleを直接積み上げない。

新しいdurable policyが既存ownerに収まらない場合は適切なowner documentを決め、このREADMEにはrouteとloading conditionだけを追加する。
