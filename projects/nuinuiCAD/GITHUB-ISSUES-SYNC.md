# nuinuiCAD GitHub Issues public mirror policy

## Purpose

LinearをnuinuiCADの正式なWork管理・仕様管理のsource of truthとして維持しつつ、`sayosomi/nuinuiCAD` のGitHub Issuesを公開mirror / public discussion surfaceとして使う。

この文書はGitHub Issues mirrorの**入口 / router**。mapping / fields / comments / Documentsのreconciliation contractと、Cloudflare Workerの運用ruleは専用ownerへ分離する。

## Authority

- Work / specificationのauthorityはLinear。
- GitHub Issuesはpublic mirror / public discussion surface。
- GitHub IssuesからLinearへfield / status / commentを逆同期しない。
- repository implementation factsはlatest repositoryがauthority。
- Linear公式GitHub Issues repo↔team two-way sync mappingはOFFのまま維持する。
- GitHub PR integration / PR workflow automationはGitHub Issues mirrorとは別物。PR integrationは [`LINEAR-GITHUB.md`](./LINEAR-GITHUB.md) を参照する。

## Public-information boundary

GitHub Issuesへ公開することを前提とするWork informationは、Linear側だけに残さずautomatic mirrorへ流す。

ChatGPTとの通常会話そのものはmirror sourceではない。Linear Issue / Comment / Documentへ保存された内容がautomatic mirror対象になる。

Linearで書かれたIssue / Document commentは公開情報として扱う。internal / non-public情報をLinearへ保存した後にmirror側でprivacy marker等によって非公開へ変える仕組みは設けない。

したがって、Linearへ保存する前にpublicにしてよい内容かを判断する。

## Policy map

| Topic | Owner |
| --- | --- |
| authority / public-information boundary / loading | this file |
| Issue mapping / exclusions / mirrored fields | [Mirror contract](./GITHUB-ISSUES-MIRROR-CONTRACT.md) |
| Comment / Linear Document mirror / GitHub-side edits | [Mirror contract](./GITHUB-ISSUES-MIRROR-CONTRACT.md) |
| Worker / webhook / Queue / safety sweep | [Mirror operations](./GITHUB-ISSUES-MIRROR-OPS.md) |
| shadow cleanup / drift repair / fallback operation | [Mirror operations](./GITHUB-ISSUES-MIRROR-OPS.md) |
| Linear ↔ GitHub Pull Request integration | [Linear / GitHub integration](./LINEAR-GITHUB.md) |

## Automatic mirror owner

通常のautomatic reconciliation ownerはCloudflare Worker `nuinuicad-linear-github-mirror`。

Linear Issue / Comment / Document changeをwebhookからQueue reconciliationへ流し、12-hour safety sweepでevent gap / driftを回収する。具体的なpipeline / schedule / fallbackは [`GITHUB-ISSUES-MIRROR-OPS.md`](./GITHUB-ISSUES-MIRROR-OPS.md) がauthority。

## ChatGPT boundary

Linear Issue / Documentを更新するときはLinearを先に更新し、automatic mirrorを通常経路とする。

通常のfield / comment update、新規Issue / Document mirrorについて、ChatGPTが同じcheckpointでGitHub Issueを手動二重更新 / 作成しない。

mirror drift / outage / shadow cleanupが関係するときだけ [`GITHUB-ISSUES-MIRROR-OPS.md`](./GITHUB-ISSUES-MIRROR-OPS.md) を読み、manual reconciliationの必要性を判断する。

## Loading rule

1. Linear workを扱い、public mirror policyが関係する場合はこの`GITHUB-ISSUES-SYNC.md`を読む。
2. mapping、mirrored field、comment、Document、GitHub-side editの判定が必要なら`GITHUB-ISSUES-MIRROR-CONTRACT.md`を読む。
3. Worker、webhook、Queue、cron、mirror drift、shadow cleanup、manual repair / fallbackが関係する場合だけ`GITHUB-ISSUES-MIRROR-OPS.md`を読む。
4. Pull Request linking / Linear PR automationは`LINEAR-GITHUB.md`を読む。GitHub Issues mirrorと混同しない。

## Maintenance rule

reconciliation data contractをops文書へ書かず、Worker運用 / repair手順をcontract文書へ書かない。

このrouterにはauthority、public boundary、route / loading conditionだけを残す。
