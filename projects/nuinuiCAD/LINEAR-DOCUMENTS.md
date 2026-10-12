# nuinuiCAD historical Linear Documents

## Purpose and status

Existing Linear Documents are historical evidence and provenance records. They are not the default current normative-specification owner, and C1 does not create new Linear Documents or bulk migrate / rewrite the old ones. Preserve each document's identity, original URL, comments, attachments, and GitHub mirror relationship.

Current Work scope / acceptance belongs in a GitHub Issue body; material decision history and evidence belong in Issue comments. A current normative language, architecture, or engineering decision belongs in its appropriate repository-owned specification / policy. Actual implemented behavior belongs to the latest product repository.

## Reviewing a historical document

When a historical Linear Document appears relevant:

1. Read the existing document and preserve its identity and links.
2. Check the latest `sayosomi/nuinuiCAD` repository and relevant current GitHub Issue / comments.
3. Determine whether its decision remains current, has been superseded, or conflicts with implemented behavior. Do not silently rewrite normative meaning as a freshness refresh.
4. If a still-relevant normative decision has no repository owner, review it for currentness and obtain an explicit decision to promote it into the appropriate repository-owned specification before using it as current normative authority.
5. Keep task-specific scope and acceptance in its GitHub Issue, not in a new or rewritten Linear Document.

If the intended decision cannot be established from current authority, return the real choice to the Human. A historical record's `Ready`, `Current`, or similar text alone does not prove that it remains current.

## Existing record references

Previously, Linear Documents were used for decisions intended to survive a task and inform multiple future tasks when no repository owner existed. The existing records and provenance remain available for historical investigation. Repository owner examples include:

- normative language semantics: the relevant `docs/*/spec.md`;
- current architecture / navigation: `ARCHITECTURE.md`;
- durable repository engineering / product policy: `AGENTS.md`;
- implemented user-facing DSL guide: `docs/dsl.md`.

These examples route a reviewed decision to an existing owner; they do not authorize copying or bulk migration. Update a repository owner only after freshness review and the required explicit promotion decision.

## Notion references

Notion remains a legacy archive. Do not use a new Linear Document as its automatic replacement. If an old Notion item is relevant to a current decision, review it against the latest repository and current GitHub Issue before considering explicit promotion into a repository-owned specification.

## Maintenance boundary

This document preserves how to inspect legacy Linear Documents and route a deliberately refreshed decision. It does not own current normative specifications, new Work authoring, or a Linear Document migration process.
