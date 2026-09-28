# voiceger-accent-adapter Manual E2E Orchestration

This document owns ChatGPT coordination of Human-run manual E2E for `voiceger-accent-adapter`.

Do not load or copy this document into implementation Coding Agent prompts or product `AGENTS.md`. Repository implementation facts, automated test commands, and generated-file placement rules remain owned by the product repository.

## Lifecycle

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
