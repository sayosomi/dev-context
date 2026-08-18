# dev-context

ChatGPT / Coding Agent を使った開発運用の共有コンテキストを管理する repository。

- `shared/`: 複数 project で再利用する開発ルール・Agent Skills
- `projects/`: project 固有の入口・管理ルール・追加 skill

各 ChatGPT Project では、原則として対応する `projects/<project>/PROJECT.md` を固定の入口として参照する。
Project 固有の `PROJECT.md` から必要な shared / project-specific 文書へ辿る。

この repository には current task の commit SHA、branch、進捗、個別 implementation plan などの一時情報を置かない。そうした情報は各 project の repository または work-management system で管理する。
