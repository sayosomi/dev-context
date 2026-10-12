# nuinuiCAD historical Linear reference and legacy execution router

## Purpose

Linearは過去のnuinuiCAD Work / decision / specification recordを参照する場所であり、新しいWorkやlong-term specificationのauthorityではない。C1後に例外的に書き込めるのは、既存SAY taskが現行`nuinui begin` / `handoff` / `release` lifecycleを継続するために必要とする最小限のexecution/status checkpointだけである。

Current Work、contract、readiness、completionは[GitHub Issues policy](./ISSUES.md)を使う。実装済み事実はlatest `sayosomi/nuinuiCAD` repository、repository-owned normative specificationは該当するrepository ownerがauthority。Linear checkpointはGitHub Issue contractやbranch / commit / PR / checksのexecution evidenceを置き換えない。

## Legacy record structure

以下は既存recordの解釈と互換executionに必要な歴史的案内であり、新しいLinear workflowを開始する許可ではない。

- Workspace: Sayosomi
- Team: Sayosomi
- Initiative: nuinuiCAD
- Project: historical aggregate records
- Issue: existing SAY Work identity / historical checkpoint
- Document: existing historical decision and specification record

SAY identifier、Linear Issue / Document identity、GitHub linksを保存する。SAY番号とGitHub Issue番号を同一視しない。

## Policy map

| Topic | Owner / use |
| --- | --- |
| Current Work / contract / readiness / close | [GitHub Issues policy](./ISSUES.md) |
| Historical Linear Issue status and legacy execution checkpoints | [Linear Issue workflow](./LINEAR-ISSUES.md), compatible pre-existing SAY execution only |
| Historical Linear Project records | [Linear Project policy](./LINEAR-PROJECTS.md) |
| Historical Linear Documents and provenance | [Linear Document policy](./LINEAR-DOCUMENTS.md) |
| Current GitHub PR linking / review / merge | [GitHub PR policy](./LINEAR-GITHUB.md) |
| Current implementation facts | latest product repository |
| Checkout / execution lifecycle | [Checkout policy](./CHECKOUTS.md); compatible pre-existing SAY tasks retain the legacy lifecycle |
| Manual E2E judgment / Human executor | [Manual E2E execution rules](./MANUAL-E2E.md) |

## Compatible pre-existing SAY execution

既存SAY taskがすでにcurrent `nuinui` lifecycleへ入っている場合だけ、そのlifecycle checkpointで要求されるstatus / branch / slice / release factsをLinearへ最小限記録してよい。既存checkpointをfreshに読んで必要な事実を確認し、余分なtranscript、commit log、mirror repair、contract rewriteを追加しない。

この互換運用は新規SAY Issue / Linear Work / Documentを作成せず、新しいLinear-driven lifecycleを開始しない。GitHub-native Workのcontractやexecution evidenceをLinear側へ複製しない。一般D1 activation checkpoint後のGitHub-native implementationはGit-only routeを使い、Linear lifecycleへ渡さない。

## Prohibited post-cutover operations

- 新しいSAY Issue / Linear Work / Linear Documentを作成する。
- Linear Ready Queueを新規Work選定やGitHub Issue readinessの代わりに使う。
- Bulk status / label / description update、contract migration campaign、mirror history replayを行う。
- LinearからGitHubへ、またはGitHubからLinearへautomatic / manual reverse syncする。
- Historical Documentをfreshness reviewと明示的promotionなしにcurrent normative specificationとして扱う。
- Official two-way syncまたはdisabled Cloudflare mirrorをreactivateする。

## Loading rule

1. 新しいWork authoring、contract、readiness、completionでは[GitHub Issues policy](./ISSUES.md)を読む。
2. 既存SAY taskが旧`nuinui` execution lifecycle上にある場合だけ、必要なLinear checkpoint ownerを読む。
3. Linear historyまたはDocument provenanceを調べる場合は該当ownerをhistorical referenceとして読む。
4. PR linking、review、mergeでは[`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md)のcurrent GitHub-native policyを使う。

このrouterにはLinearの過去運用や互換checkpointの説明だけを置き、新しいWorkの作成・status・specification手順は定義しない。
