# ZundaMonChan Coding Agent Policy

This document defines ZundaMonChan-specific agent roles and safeguards. Shared prompt, Git, and implementation-agent mechanics remain owned by the linked shared documents and are not repeated here.

## Roles and sequence

- ChatGPT independently refreshes the product repository and relevant Issues, inspects current source, identifies semantic owners, resolves required decisions and verification expectations, and prepares a complete executable implementation contract before writing the implementation prompt. Do not delegate open-ended product or architecture investigation to Luna.
- Luna is the default implementation and blocking-fix Coding Agent unless the Human or an authorized current-task contract overrides it. No fixed thinking effort is required.
- The Human gives Luna the complete English, direct-imperative implementation prompt prepared by ChatGPT.
- Luna verifies the exact repository, branch, base, and Git state required by that prompt; implements only the settled scope; runs the required checks; commits the intended changes; and pushes the specified topic branch using the shared Git workflow. Stop on a mismatch, unresolved material decision, or need to expand scope.
- ChatGPT independently reviews the exact pushed HEAD, manages any blocking fixes, and handles the PR and merge under the current task contract and shared Git workflow.
- The Human alone performs required physical-device validation and reports its result. Compilation or a successful build is not hardware verification.

Use one sequential implementation track and the ordinary shared primary-checkout Git workflow. Do not add project-specific worktrees, lanes, or agent handoff infrastructure. Do not import nuinuiCAD-specific Linear, SAY, declared-lane, Astra audit, or E2E lifecycle rules.

## Device safety

Compilation and builds are allowed. A successful build is not physical-device acceptance; the Human alone performs physical E2E.

For ordinary firmware-only uploads to the Human's identified M5Stack CoreS3, ChatGPT supplies the exact, safety-checked upload command in the same response as an independent pushed-HEAD review PASS, provided the applicable build passed. Do not introduce another chat approval turn for this normal review-to-E2E handoff. The Human authorizes that one firmware upload by choosing to execute the displayed command; neither ChatGPT nor a Coding Agent executes it on the device. Check the exact repository and reviewed HEAD, clean checkout, intended serial port/device, FQBN, and unchanged partition scheme before upload. Use the existing upload helper and supplement missing safety checks in the presented command when required.

Obtain separate, explicit Human authorization before any LittleFS/filesystem image upload, audio/avatar asset replacement, filesystem formatting, flash erasure, partition-layout change, other destructive device operation, or deletion of device data. A routine firmware-upload handoff never authorizes these actions. Stop rather than upload if target identity, side effects, or safe preconditions are uncertain.

When using any optional local Arduino CLI, M5Stack, or other agent skill, first inspect its actual installed contract and confirm it applies to the current task. No skill may override the device safety boundaries.

## Voice data and publication

Do not incidentally commit or publish personal voice recordings, datasets, generated personal models, credentials, or secrets. Treat reusable recording and training tools separately from personal recordings and models. Publishing a model trained on a person's voice requires a separate affirmative licensing and permission decision; do not treat publication as unconditionally prohibited.

## Shared owners

- Prompt timestamps, completeness, and English direct-imperative style: [Agent Prompt Style](../../shared/AGENT-PROMPT-STYLE.md) and [Implementation Coding Agent Workflow](../../shared/CODING-AGENT-WORKFLOW.md).
- Remote freshness, branch/base expectations, checkout safety, commit/push, and pushed-state review: [Git Workflow](../../shared/GIT-WORKFLOW.md).
- Reusable development routing: [Shared Development Workflow](../../shared/DEVELOPMENT.md).
- dev-context repository maintenance only: root [DEVELOPMENT.md](../../DEVELOPMENT.md) and [ISSUES.md](../../ISSUES.md).

Follow these owners for prompt/output timestamps, stop conditions, verification, and completion reporting instead of creating project-specific duplicates.
