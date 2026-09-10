# fanbox-level-manager Execution Handoff

This document owns the canonical fanbox-level-manager Luna startup boundary.
Luna, not the Human or ChatGPT, runs the handoff after receiving the complete
prompt.

## Public contract

```text
/Users/yosomi/Code/dev-context/projects/fanbox-level-manager/scripts/fanbox-handoff <issue-number> <expected-main-sha>
```

The only public inputs are the positive GitHub Issue number and the expected
authoritative fanbox `main` SHA. The command does not accept or require a
branch, base, prompt file, expected-context file, lane, claim, checkpoint,
ticket, nonce, token, or topic mode.

The canonical product checkout is:

```text
/Users/yosomi/Code/fanbox-level-manager
```

## Required startup proof

The helper is fail-closed and emits `HANDOFF VERIFIED` only after all of these
checks pass, in this order:

1. Validate exactly two arguments.
2. Require the Issue number to be a positive decimal GitHub Issue number.
3. Require the expected main SHA to be exactly 40 hexadecimal characters.
4. Target the canonical product checkout, require it to exist, and require it
   to resolve as its own Git repository root.
5. Require exactly the canonical `sayosomi/fanbox-level-manager` origin in its
   normal GitHub SSH or HTTPS form.
6. Require a clean working tree including untracked files.
7. Require a named current branch and require that branch not to be `main`.
8. Capture the current branch and HEAD before refreshing the remote.
9. Run `git fetch origin --prune`.
10. Require the branch and HEAD to remain unchanged after fetch and require
    the checkout to remain clean.
11. Require `origin/main` to equal the supplied expected main SHA exactly.
12. Require the expected main SHA to be an ancestor of the current HEAD.
13. Inspect the exact remote-tracking ref for the current topic branch.

If the topic branch is absent on `origin`, the helper accepts only when the
current HEAD equals the expected main SHA. This is the freshly prepared local
topic case before its first push. If the topic branch exists, its
remote-tracking HEAD must equal the current local HEAD exactly.

Any stale main, remote-topic mismatch, dirty checkout, detached HEAD, `main`
checkout, repository or origin mismatch, branch or HEAD drift, missing remote
ref, or ancestry mismatch is `BLOCKED`.

On success the helper prints stable diagnostic fields for the repository,
Issue, checkout, branch, HEAD, expected main, remote-topic mode, and clean
state.

## Failure and test boundary

A failed handoff is terminal for that Luna startup attempt. The helper does
not create or switch branches, edit files, commit, push, merge, rebase, reset,
stash, clean, force-switch, or perform speculative repair. The Issue argument
is execution identity carried from the ChatGPT contract and reported by the
helper; it does not create durable lane, claim, or checkpoint ownership.

Production behavior is fixed to `/Users/yosomi/Code/fanbox-level-manager`.
The focused self-test may enable a narrowly gated override using explicit
self-test-only environment variables for an isolated checkout and expected
origin. Those variables are ignored unless self-test mode is explicitly
enabled and are not public workflow inputs.

The focused test creates local temporary Git repositories and remotes, avoids
real network access, and verifies both accepted topic modes and fail-closed
failure behavior without repairing branch, HEAD, or working-tree state.
