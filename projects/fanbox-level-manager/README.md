# fanbox-level-manager Project Context

Repository: `sayosomi/fanbox-level-manager`

This README is the fixed project entrypoint and router. Keep it limited to routing and authority boundaries; do not add speculative project documents here.

## Normal implementation flow

```text
Human asks ChatGPT to implement
-> ChatGPT refreshes current dev-context, the fanbox remote, the GitHub Issue, and the repository specification
-> ChatGPT investigates the repository and settles the implementation contract
-> ChatGPT performs the shared pre-prompt remote freshness gate
-> Human performs only a genuinely required one-shot local startup mutation
-> ChatGPT publishes one complete Luna prompt directly in chat after required prompt preflight passes
-> Human copies the prompt to Luna
-> Luna runs the canonical fanbox handoff itself
-> HANDOFF VERIFIED
-> Luna implements, tests, commits, and pushes
-> Luna returns a timestamped success or BLOCKED/stopped report
-> ChatGPT independently reviews pushed GitHub state
-> ChatGPT owns PR, CI, merge, and GitHub Issue continuation
```

The Human does not manage prompt files, expected-context files, temporary
checker inputs, branch/base transport metadata, or handoff verification merely
to transport a Luna prompt. Prompt preflight files are internal publication
validation plumbing; the normal publication boundary is ChatGPT preparing the
complete prompt, passing project preflight, printing it directly in chat, and
the Human copying it to Luna.

## Always load for development work

- [Shared Development Workflow](../../shared/DEVELOPMENT.md)
- The product repository's current [`AGENTS.md`](https://github.com/sayosomi/fanbox-level-manager/blob/main/AGENTS.md), once it exists

## Execution-agent prompt generation

When generating an execution-agent prompt for this project, also load:

- [Shared Agent Prompt Style](../../shared/AGENT-PROMPT-STYLE.md)
- [Shared Agent Prompt Preflight](../../shared/AGENT-PROMPT-PREFLIGHT.md)
- [Shared Implementation Coding Agent Workflow](../../shared/CODING-AGENT-WORKFLOW.md)
- [Project Prompt Preflight](./PROMPT-PREFLIGHT.md)
- [Prompt checker](./scripts/fanbox-prompt-check)

## Project-specific owners

- Implementation and blocking-fix responsibility: [Project Coding Agent policy](./CODING-AGENT.md)
- Luna startup identity and safety: [Execution handoff authority](./EXECUTION-HANDOFF.md)

## Authority

Implemented behavior and repository facts are authoritative only from the latest remote `sayosomi/fanbox-level-manager` repository, not from dev-context, past chats, or local copies.

GitHub Issues in `sayosomi/fanbox-level-manager` are the primary Work / current implementation-contract authority.

Long-lived product requirements and design belong in versioned documents in the product repository.

Do not inherit or copy nuinuiCAD Linear workflow, declared-lane semantics, or other nuinuiCAD-specific policy into this project context.
