# nuinuiCAD Project Context

Repository: `sayosomi/nuinuiCAD`

この README は ChatGPT Project から参照する固定入口。
Current task の SHA、branch、進捗、個別 implementation plan はここに書かない。

## Required context

開発作業では最初に次を読む。

- [Shared Development Workflow](../../shared/DEVELOPMENT.md)
- repository の current `AGENTS.md`

Coding Agent prompt 作成・skill 選択時は必要に応じて次も読む。

- [Shared Agent Skills](../../shared/AGENT-SKILLS.md)
- [nuinuiCAD-specific Agent Skills](./AGENT-SKILLS.md)

## Repository-owned sources of truth

- 実装済みの事実・actual code: latest `sayosomi/nuinuiCAD` repository
- repository engineering policy: `AGENTS.md`
- current architecture / navigation index: `ARCHITECTURE.md`
- normative nui4 language contract: `docs/nui4/spec.md`
- implemented user-facing DSL documentation: `docs/dsl.md`

実装事実について、管理文書・過去チャット・work-management system と repository が矛盾する場合は latest repository を authoritative とする。

## Work / specification management

現在は Linear を移行先として試験運用する。

- [Linear workflow](./LINEAR.md)
- [Legacy Notion workflow](./NOTION-LEGACY.md) — 移行期間中だけ参照

新しい開発 Task の開始時は、GitHub remote state と既存 Linear Issue / Project、必要な Spec を確認してから implementation contract を策定する。

## Loading rule

毎回すべての linked document を読む必要はない。

1. この README を読む。
2. 開発 Task では `shared/DEVELOPMENT.md` と repository の current `AGENTS.md` を読む。
3. Coding Agent / skill が関係する場合だけ Agent Skills を読む。
4. Linear / Notion を操作・参照する場合だけ対応する管理ルールを読む。
5. current implementation / architecture / DSL を確認する場合は、必ず latest repository から取得する。
