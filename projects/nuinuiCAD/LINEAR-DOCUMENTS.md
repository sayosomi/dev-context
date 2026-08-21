# nuinuiCAD Linear Document policy

## Purpose

Linear Documentsを長期仕様・設計の正式な保存先として使うためのruleを定義する。

Notion migration / legacy browsingの詳細は [`NOTION-LEGACY.md`](./NOTION-LEGACY.md) を参照する。

## What belongs in a Linear Document

Linear Documentは、Issueを閉じた後もcurrent authorityとして残す必要があり、複数のfuture Issue / Taskから再利用される長期仕様・設計に使う。

長い文章だから、調査に時間がかかったから、またはIssue本文が大きくなったからという理由だけでDocumentへ昇格しない。

一時的なimplementation contract、調査ログ、Manual E2E plan、完了済みTask plan、単一Issueだけで消費される実装メモを長期SpecとしてDocument化しない。

Task固有のcurrent contractや進捗はIssue / Commentへ置く。

### Promotion check

Issue内の決定を長期保存するときは順に確認する。

1. **Issueを閉じた後もcurrent authorityとして残す必要があるか？**
   - NO → Issue / Comment内で完結させる。
2. **複数のfuture Issue / Taskがその決定を再利用するか？**
   - NO → 原則Issue / Comment内で完結させる。
3. **repositoryに既存の正式ownerがあるか？**
   - YES → repository ownerを更新し、同内容のLinear Documentを重複作成しない。
   - NO → Linear Documentを長期仕様・設計のowner候補とする。

repository ownerの例:

- normative nui4 language semantics → `docs/nui4/spec.md`
- current architecture / navigation → `ARCHITECTURE.md`
- durable repository engineering / product policy → `AGENTS.md`
- implemented user-facing DSL documentation → `docs/dsl.md`

Linear Documentはrepositoryに既にあるnormative ownerを複製するためのmirrorではない。

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
- repository-owned normative contract: repositoryの該当spec / policy owner
- work plan / progress / research result: Linear Issue / Project
- repositoryにownerがない長期specification / design: Linear Document
- pre-migration history: Notion legacy archive

actual codeは「現在どう実装されているか」のauthority。normative spec / designは「本来どうあるべきか」のauthorityとして扱う。

Linear Documentとactual implementationが食い違っただけで、Documentをcodeへ自動的に合わせない。まず新しいauthoritative decisionがDocumentをsupersedeしたのか、implementation bugなのかを確認する。一意に決まらない場合は [`CONTRACT-DECISIONS.md`](./CONTRACT-DECISIONS.md) に従いproduct decisionへ戻す。

actual implementation factだけが古い場合はDocument内のfact referenceをcurrent repositoryへrefreshしてよいが、既決定のnormative semanticsをfreshness更新として変更しない。

## Notion legacy migration

Notionは新規Work / Specの管理先にしない。

新しいTaskでNotionを通常のSpec検索先として使わない。

必要なSpecがLinearに見つからずlegacy Notionにのみ存在する場合は、内容とcurrent repositoryに対する現在性を確認し、必要ならrepositoryの既存ownerまたはLinear Documentへ移行してから正式参照先にする。

例外として、移行前から進行中のTaskが特定の未移行Notion Specを明示的source of truthとして開始済みの場合だけ、そのTaskの次の明確なcheckpointまでは参照を継続してよい。checkpoint後に正式ownerへ移行し、Issue側の参照先も更新する。

legacy参照・移行作業自体は [`NOTION-LEGACY.md`](./NOTION-LEGACY.md) のruleに従う。
