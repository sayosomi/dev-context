# nuinuiCAD Linear Document policy

## Purpose

Linear Documentsを長期仕様・設計の正式な保存先として使うためのruleを定義する。

Notion migration / legacy browsingの詳細は [`NOTION-LEGACY.md`](./NOTION-LEGACY.md) を参照する。

## What belongs in a Linear Document

長期的に参照する仕様・設計をDocumentへ置く。

一時的なimplementation contract、調査ログ、Manual E2E plan、完了済みTask planを長期SpecとしてDocument化しない。

Task固有のcurrent contractや進捗はIssue / Comment、actual implementationはlatest repositoryをauthorityとする。

## Spec metadata

必要に応じてDocument冒頭へmetadataをテキストで持たせる。

例:

```text
Status: Ready
Area: Typed Expression / Evaluation / Module
Category: DSL
Source: ...
```

Spec statusとして必要に応じて次を使う。

- `Draft`
- `Ready`
- `Current`
- `Superseded`

## Source-of-truth boundary

- actual code / implemented behavior: latest `sayosomi/nuinuiCAD` repository
- work plan / progress / research result: Linear Issue / Project
- long-term specification / design: Linear Document
- pre-migration history: Notion legacy archive

Linear Documentがactual implementation factと矛盾する場合、implementationについてはlatest repositoryをauthoritativeとする。必要ならDocumentをcurrent designへrefreshする。

## Notion legacy migration

Notionは新規Work / Specの管理先にしない。

新しいTaskでNotionを通常のSpec検索先として使わない。

必要なSpecがLinearに見つからずlegacy Notionにのみ存在する場合は、内容とcurrent repositoryに対する現在性を確認し、必要ならLinear Documentへ移行してから正式参照先にする。

例外として、移行前から進行中のTaskが特定の未移行Notion Specを明示的source of truthとして開始済みの場合だけ、そのTaskの次の明確なcheckpointまでは参照を継続してよい。checkpoint後にLinear Documentへ移行し、Issue側の参照先も更新する。

legacy参照・移行作業自体は [`NOTION-LEGACY.md`](./NOTION-LEGACY.md) のruleに従う。
