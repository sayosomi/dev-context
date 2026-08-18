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

現在のWork / specification管理は Linear を正式な管理先とする。

- 作業予定・進捗・調査結果: Linear Issue / Project
- 長期的に参照する仕様・設計: Linear Document
- [Linear workflow](./LINEAR.md)
- [Legacy Notion archive](./NOTION-LEGACY.md) — 移行前の履歴参照専用

Notion は新規Work / Specの管理先として使わない。
ただし、移行前から進行中のTaskが特定の未移行Notion Specを明示的なsource of truthとして開始済みの場合、そのTaskの次の明確なcheckpointまでは参照を継続してよい。checkpoint後にLinear Documentへ移行し、Task側の参照先も更新する。

新しい開発 Task の開始時は、GitHub remote state と既存 Linear Issue / Project / Document を確認してから implementation contract を策定する。

## Loading rule

毎回すべての linked document を読む必要はない。

1. この README を読む。
2. 開発 Task では `shared/DEVELOPMENT.md` と repository の current `AGENTS.md` を読む。
3. Coding Agent / skill が関係する場合だけ Agent Skills を読む。
4. Linear を操作・参照する場合だけ `LINEAR.md` を読む。
5. legacy履歴または明示的な移行中例外でNotionを参照する場合だけ `NOTION-LEGACY.md` を読む。
6. current implementation / architecture / DSL を確認する場合は、必ず latest repository から取得する。
