# dev-context

ChatGPT / Coding Agent を使った開発運用の共有コンテキストを管理する repository。

- [`shared/`](./shared/): 複数 project で再利用する開発ルール・Agent Skills
- [`projects/`](./projects/): project 固有の入口・管理ルール・追加 skill

各 ChatGPT Project では、対応する `projects/<project>/README.md` を固定の入口として参照する。
Project 固有 README から、必要な shared / project-specific 文書へ辿る。

## Projects

- [nuinuiCAD](./projects/nuinuiCAD/README.md)

## Shared context

- [Development Workflow router](./shared/DEVELOPMENT.md)
- [Git Workflow](./shared/GIT-WORKFLOW.md)
- [Coding Agent Workflow](./shared/CODING-AGENT-WORKFLOW.md)
- [Agent Skills](./shared/AGENT-SKILLS.md)

この repository には current task の commit SHA、branch、進捗、個別 implementation plan などの一時情報を置かない。そうした情報は各 project の repository または work-management system で管理する。
