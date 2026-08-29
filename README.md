# dev-context

ChatGPT / Coding Agent を使った開発運用の共有コンテキストを管理する repository。

- [`shared/`](./shared/): 複数 project で再利用する開発ルール・Agent Skills
- [`projects/`](./projects/): project 固有の入口・管理ルール・追加 skill

各 ChatGPT Project では、対応する `projects/<project>/README.md` を固定の入口として参照する。
Project 固有 README から、必要な shared / project-specific 文書へ辿る。

## dev-context 自身の開発

この `sayosomi/dev-context` repository 自体を変更するときは、まず [root DEVELOPMENT.md](./DEVELOPMENT.md) を読む。
root `DEVELOPMENT.md` が dev-context 自身の開発 lifecycle の canonical owner である。
各 external / project repository の開発では、引き続き対応する [`projects/<project>/README.md`](./projects/nuinuiCAD/README.md) を入口にする。
root README は repository overview / router であり、詳細な development workflow の owner ではない。

## Projects

- [nuinuiCAD](./projects/nuinuiCAD/README.md)

## Shared context

- [Development Workflow router](./shared/DEVELOPMENT.md)
- [Git Workflow](./shared/GIT-WORKFLOW.md)
- [Agent Prompt Style](./shared/AGENT-PROMPT-STYLE.md)
- [Implementation Coding Agent Workflow](./shared/CODING-AGENT-WORKFLOW.md)
- [Agent Skills](./shared/AGENT-SKILLS.md)
- [Autonomous ChatGPT Runner Pattern](./shared/AUTONOMOUS-RUNNER-PATTERN.md)

この repository には current task の commit SHA、branch、進捗、個別 implementation plan などの一時情報を置かない。そうした情報は各 project の repository または work-management system で管理する。
