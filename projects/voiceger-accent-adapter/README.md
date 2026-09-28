# voiceger-accent-adapter Project Context

Repository: `sayosomi/voiceger-accent-adapter`

This README is the fixed project entrypoint and router. Keep it limited to project-wide authority, loading, and routing. Repository implementation facts and product behavior belong to the product repository.

## Normal development flow

```text
Human asks ChatGPT to develop or fix voiceger-accent-adapter
-> ChatGPT refreshes current dev-context, product remote, relevant GitHub Issue, and repository documentation
-> ChatGPT investigates the repository and settles the implementation contract
-> ChatGPT performs the shared remote freshness gate
-> implementation Coding Agent implements the settled contract, tests, commits, and pushes
-> ChatGPT independently reviews pushed GitHub state
-> PR / merge / Issue continuation follow the current Task and shared Git workflow
```

No dedicated execution-handoff helper, declared lane, or persistent parallel-worktree model is defined for this project. Use the shared Git workflow unless a future project-specific owner explicitly adds a stricter rule.

## Always load for development work

- [Shared Development Workflow](../../shared/DEVELOPMENT.md)
- The product repository's current [`AGENTS.md`](https://github.com/sayosomi/voiceger-accent-adapter/blob/main/AGENTS.md)

When Git state, checkout, branch, commit, push, or review is involved, load:

- [Shared Git Workflow](../../shared/GIT-WORKFLOW.md)

## Execution-agent prompt generation

When generating an implementation or blocking-fix agent prompt for this project, also load:

- [Shared Agent Prompt Style](../../shared/AGENT-PROMPT-STYLE.md)
- [Shared Implementation Coding Agent Workflow](../../shared/CODING-AGENT-WORKFLOW.md)
- [Project Coding Agent policy](./CODING-AGENT.md)

This project currently has no project-specific prompt-publication checker or execution-handoff helper.

## Authority

Implemented behavior and repository facts are authoritative only from the latest remote `sayosomi/voiceger-accent-adapter` repository, not from dev-context, past chats, or local copies.

GitHub Issues in `sayosomi/voiceger-accent-adapter` are the primary Work / current implementation-contract authority.

Long-lived product requirements, API behavior, supported Voiceger compatibility targets, and design documentation belong in versioned documents in the product repository.

Repository-local implementation environment details, exact automated test commands, generated-file placement rules, and repository hygiene remain owned by the product repository's `AGENTS.md` and current repository documentation.

ChatGPT-only Human orchestration for manual E2E start / teardown belongs in this dev-context entrypoint, not in product `AGENTS.md` or Coding Agent policy.

## ChatGPT manual E2E orchestration

This section is for ChatGPT coordinating Human-run manual E2E. Do not copy it into implementation Coding Agent prompts or product `AGENTS.md`.

- Prefer one Human copy/paste block that owns the routine lifecycle: safe checkout normalization, stale-scratch cleanup, scratch recreation, E2E launch, and post-run cleanup. Do not turn normal setup / teardown into extra Human round trips unless a real safety ambiguity blocks progress.
- Manual E2E normally runs from the freshly verified intended checkout, usually current `main` after the tested change has merged. If the primary checkout is clean and still on a merged topic branch whose exact HEAD is verified as contained in the intended remote base, the startup block may switch to that base and fast-forward it instead of stopping only because of the branch name. Dirty, unmerged, mismatched, or ambiguous state still blocks.
- Use one canonical disposable scratch directory per Issue, normally `scratch/issue<N>-e2e`.
- At E2E start, stale contents in that exact directory are expected residue from an interrupted or prior run: remove that exact directory automatically, then recreate it cleanly. Its existence alone is not a blocker.
- Automatic cleanup must target only the exact known E2E scratch path. Never use broad wildcards and never delete unrelated `scratch/` content.
- Do not create accumulating fallback paths such as `issue<N>-e2e-resume`; reuse the canonical path after cleanup.
- Keep E2E config, generated audio, logs, and disposable outputs inside the canonical scratch directory so the run is isolated from normal user settings and cleanup is one exact-path operation.
- For Human-facing macOS lifecycle setup / cleanup commands, use absolute system-tool paths such as `/bin/rm` and `/bin/mkdir` so an unusual interactive `PATH` does not stall routine E2E handling.
- By default, once the E2E process returns to the shell, the same Human-facing block removes the exact E2E scratch directory and verifies cleanup. Preserve evidence first only when the current test explicitly requires later inspection.
- If the E2E process or terminal is interrupted before teardown runs, do not create a separate recovery workflow. The next E2E start performs the same exact-path cleanup before recreating the workspace.
- Routine stale scratch, a clean already-merged topic checkout, or ordinary prior-run residue must not trigger a separate recovery conversation step. Only genuine safety ambiguity requires Human intervention before launch.

## Voiceger upstream boundary

Voiceger is maintained separately from this repository. The adapter integrates with a locally installed Voiceger runtime but does not own Voiceger source, models, reference audio, or upstream behavior.

Do not modify Voiceger source as part of a voiceger-accent-adapter Task unless the current Task explicitly authorizes a separate upstream Voiceger change. If the adapter contract cannot be completed without an upstream change that was not authorized, stop and report the boundary instead of silently editing Voiceger.

Treat normal repository unit tests and opt-in real Voiceger integration tests as distinct verification layers. Exact commands, environment paths, and compatibility revisions are read from the current product repository rather than copied into dev-context.

## Project separation

Do not inherit or copy nuinuiCAD-specific Linear workflow, declared-lane semantics, Astra policy, Manual E2E policy, or other nuinuiCAD product rules into this project.

Reusable development mechanics should remain in shared dev-context owners instead of being duplicated here.
