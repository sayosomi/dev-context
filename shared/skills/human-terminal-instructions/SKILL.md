---
name: human-terminal-instructions
description: Generate copy/paste-ready terminal commands and shell scripts for a Human running macOS with zsh, with explicit worktree targeting, safe preconditions, and failure messages that explain why execution stopped.
---

# Human Terminal Instructions

Use this skill whenever ChatGPT generates terminal commands or shell scripts for a Human to copy/paste and execute.

This skill governs command presentation and execution safety. It does not override project-specific repository, worktree, branch, task, or mutation policy.

## Default Human environment

Assume the Human terminal environment is:

- Apple Silicon Mac, currently an M1 Mac mini
- macOS
- interactive shell: zsh

Do not add Ghostty-specific behavior unless a task genuinely depends on terminal-emulator behavior. Ghostty is not the shell.

Prefer commands that work directly in macOS zsh. Use an explicit `bash` child shell only when bash-specific behavior is actually useful or required; do not use bash merely to avoid understanding zsh semantics.

Do not assume GNU userland options are available when macOS ships BSD variants.

## Preserve the Human's interactive shell

A copy/paste block must not terminate, replace, or persistently reconfigure the Human's interactive shell when a precondition fails.

For multi-line blocks pasted into an interactive terminal:

- do not use top-level `exit`, `return`, `exec`, or `logout`;
- do not enable `set -e`, `set -u`, `setopt`, install `trap`s, or otherwise change shell options/state at top level when that state could survive after the block;
- when early termination or strict shell state is useful, wrap the whole block in a subshell such as `(...)` or an explicit child shell and terminate only that child execution boundary;
- a safety failure must leave the Human's terminal session alive and usable;
- treat **"failure does not close the terminal"** as a regression invariant for Human-facing blocks.

A subshell is the preferred default when a block contains multiple safety checks followed by mutation:

```zsh
(
  # checks and mutations
  if [[ "..." != "..." ]]; then
    echo "BLOCKED: precondition mismatch"
    exit 1
  fi
)
```

Top-level one-line commands that naturally return a non-zero status are fine; the prohibition is against terminating or persistently altering the interactive shell itself.

## Make the execution target self-contained

When a command is intended for a specific checkout or worktree, make the command itself establish that location instead of requiring the Human to navigate there beforehand.

Prefer an absolute-path target inside the same safe execution boundary:

```zsh
(
  cd /absolute/path/to/worktree || {
    echo "ERROR: cannot enter the required worktree:"
    echo "  /absolute/path/to/worktree"
    exit 1
  }

  # remaining checks / commands
)
```

If a particular starting branch, detached commit, repository identity, or other checkout state is required, verify it inside the same block before mutation.

Do not rely on prose such as "run this from X" when the command can establish and verify X itself.

## Stop safely and explain why

The principle is not merely "stop safely". The Human must be able to understand why execution stopped.

For a meaningful failure boundary:

- print `ERROR:` for an execution/setup failure or `BLOCKED:` for a safety/precondition mismatch;
- state the concrete reason before terminating the child execution boundary or skipping mutation;
- when there is an expected and actual value, print both;
- when useful, state what mutation was not performed because the command stopped;
- make the message actionable enough that the Human can report the exact blocker back to ChatGPT.

Avoid bare forms such as:

```zsh
cd /some/path || exit 1
```

or important checks that rely only on `set -e` and disappear without context.

`set -e` / strict modes may be used inside a deliberately chosen child shell, but important safety checks must still produce explicit Human-readable failure messages.

## Write for zsh deliberately

Do not use zsh special, reserved, or readonly parameter names as ordinary variables.

In particular, avoid:

```zsh
status="$(git status --short)"
```

because `status` is special/read-only in zsh.

Prefer purpose-specific names such as:

```zsh
wt_status="$(git status --short)"
cmd_status=$?
result_code=$?
```

When shell-specific semantics are uncertain and materially affect correctness, verify them before giving the Human the command.

## Separate audit from mutation

Prefer a read-only audit before destructive or state-changing work when the current state is not already established.

Read-only audit commands must actually be read-only. Do not quietly include mutation such as:

- `git fetch`
- `git checkout` / `git switch`
- `git reset`
- `git stash`
- `git worktree prune` / `git worktree remove`
- file deletion

When a later mutation block is justified, re-check the safety-critical facts immediately before mutation when they could have changed, such as:

- target absolute path
- repository/worktree identity
- branch or detached HEAD
- exact HEAD when relevant
- clean/dirty working tree
- intended remote/base relationship

Never reset, stash, overwrite, force-switch, force-push, or delete unrelated Human work merely to make capacity or simplify the script unless the governing task/policy explicitly authorizes that operation.

## Treat remote pruning as state-changing evidence loss

`git fetch --prune` can remove remote-tracking refs. Do not write a script that prunes a ref and then assumes that same remote-tracking ref still exists for a later safety check.

If the remote branch itself is the evidence, verify it before pruning or preserve the exact commit needed for the later check.

For a merged checkpoint whose remote topic branch may already be deleted, prefer verifying the exact checkpoint commit against the authoritative surviving ref, for example:

```zsh
(
  if ! git merge-base --is-ancestor "$EXPECTED_HEAD" origin/main; then
    echo "BLOCKED: checkpoint commit is not contained in origin/main"
    echo "  checkpoint: $EXPECTED_HEAD"
    echo "No branch switch or cleanup was performed."
    exit 1
  fi
)
```

Choose the exact ancestry/ref check according to the governing repository policy; this skill does not itself decide which ref is authoritative.

## Prefer whole-block copy/paste reliability

A Human-facing command block should be runnable as a whole.

Reduce hidden dependencies on:

- the Human's current directory;
- prior shell variables;
- prior `cd` commands from an earlier message;
- transient aliases/functions;
- shell options previously enabled in the interactive session.

Quote paths and variable expansions where appropriate. Avoid broad wildcards for deletion or cleanup when exact paths are known.

Use `git -C "$path" ...` when operating on another checkout without moving away from the command block's established primary location. Use `cd` when the command itself is conceptually executed in that target worktree and showing that location to the Human improves clarity.

## Mutation messages

For commands that change local state, make the target obvious in output when useful. Prefer messages such as:

```text
WORKTREE: /absolute/path
BRANCH:   current-branch
REMOVE:   /exact/worktree/path
BLOCKED:  HEAD changed since audit
```

Do not bury a destructive action inside an opaque one-liner when a short explicit block can make the precondition and target clear.

## Scope

This skill applies to Human-executed terminal instructions only.

It does not automatically apply the same macOS/zsh assumptions to CI, GitHub Actions, containers, Coding Agent environments, Luna/Manual E2E environments, or other execution hosts. Those commands must follow their actual environment and project-specific policy.
