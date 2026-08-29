# dev-context Development

この document は、`sayosomi/dev-context` repository 自体を変更するときの canonical development lifecycle owner である。
repository overview / routing は [root README](./README.md)、複数 project に再利用するmechanicsは [shared development router](./shared/DEVELOPMENT.md) と各 shared owner document、project固有のruleは [`projects/<project>/`](./projects) 配下の owner document が担当する。
この document はそれらの全文を複製せず、dev-context self-developmentに固有のauthority、checkout境界、lifecycle、routingを定める。

## Scope and authority

sayosomi/dev-context 自身が変更対象のrepositoryである場合、この document が canonical development lifecycleを定める。

再利用可能なshared mechanicsは既存のownerへrouteする。

- remote / local verification、Git safety、commit、push、pushed-state reviewの詳細: [shared/GIT-WORKFLOW.md](./shared/GIT-WORKFLOW.md)
- cross-cuttingなHuman write approval gate: [shared/DEVELOPMENT.md](./shared/DEVELOPMENT.md) とこの document のself-development適用
- project-specific policy: [`projects/<project>/README.md`](./projects/nuinuiCAD/README.md) とそこからrouteされるowner document

root READMEはoverview / routerであり、詳細なself-development workflowのownerではない。

## Fresh remote bootstrap

すべての新しいdev-context development taskでは、implementation contractを確定する前にfreshな状態確認を行う。過去chat、handoff text、promptに記載されたSHA、またはlocal cloneを現在のrepository stateとして信頼しない。

最低限、次をfreshに確認する。

- 最新のremote `sayosomi/dev-context` `main`
- root `README.md`
- root `DEVELOPMENT.md`
- relevantなshared / project owner document
- 関連するcurrent GitHub Issue / PR state

actual dev-context repository stateのauthorityは、latest GitHub remote `sayosomi/dev-context` である。local cloneの内容、過去の管理文書、会話履歴はその代替ではない。

## Source-of-truth hierarchy

責務ごとのsource of truthを混同しない。

```text
actual repository state
  -> latest sayosomi/dev-context remote
dev-context self-development policy
  -> root DEVELOPMENT.md
shared reusable development policy
  -> shared owner documents
project-specific policy
  -> projects/<project>/ owner documents
current task contract / progress
  -> GitHub Issue / PR / comments or another explicit current work owner
```

durable policy documentへcurrent taskのSHA、branch、checkpoint、progress、temporary implementation planを記録しない。

dev-context documentがsayosomi/nuinuiCADなどexternal repositoryのimplemented factを扱う場合、その事実は対象external repositoryでfreshに確認する。dev-contextをexternal repositoryのimplementation authorityとして扱わない。

## Human write approval gate

既存のdev-context write gateをself-development lifecycleへ適用する。[shared/DEVELOPMENT.md](./shared/DEVELOPMENT.md) のgateはcross-cuttingなshared safety requirementであり、別の弱いgateや競合するapproval ruleを作らない。

ChatGPTがdev-context repository fileのcreate / update / deleteを行う前に、Human-approved planを得る。そのplanには最低限、次を含める。

- current state / problem
- change purpose
- target files
- intended change summary

read-only investigationはapproval不要である。approvalは提示したscopeにだけ適用される。target file、responsibility、またはsemantic scopeをmaterially拡大する場合は、write前に更新planを提示して再承認を得る。

## Checkout and worktree boundary

### Standard clone

`/Users/yosomi/Code/dev-context` はproduction / cache / toolbox cloneであり、development edit checkoutではない。Markdown-only changeを含め、dev-context tracked fileの変更にこのstandard cloneのworking treeを使わない。

read-only inspectionと、dedicated worktreeを作成・管理するために必要なGit metadata operationはstandard cloneで許可する。編集、validation、commitはdedicated dev-context worktreeで行う。

### Dedicated dev-context worktree

各dev-context development taskは、freshに確認したremote `main`からtask-specific dedicated worktreeとtopic branchを用いる。これは、通常はprimary checkoutを使うというgeneric shared Git defaultに対するdev-context repository-specific overrideである。詳細な共通Git mechanicsは [shared/GIT-WORKFLOW.md](./shared/GIT-WORKFLOW.md)へrouteする。

作成・継続・終了時は次を守る。

- 既存pathとregistered worktree stateをread-only inspectionしてから作成する。
- unexpected stateをdelete、overwrite、reset、stash、force-repairしない。
- blocking review / blocking fixがactiveな間はworktreeを保持する。
- taskがmergeまたはabandonされ、worktreeがcleanで不要になったことを証明した後だけremoveする。

dev-contextのdedicated worktreeはnuinuiCADのfixed product laneではない。

## Separation from nuinuiCAD fixed lanes

resource modelを混ぜない。

```text
sayosomi/nuinuiCAD product fixed lanes:
  /Users/yosomi/Code/nuinuiCAD
  /Users/yosomi/Code/nuinuiCAD-sub
  /Users/yosomi/Code/nuinuiCAD-e2e

sayosomi/dev-context repository:
  /Users/yosomi/Code/dev-context        production/cache/toolbox clone
  task-specific dedicated development worktree(s)
```

明示的な境界は次のとおり。

- dev-context worktreeはnuinuiCAD `main` / `sub` / `e2e` laneではない。
- dev-context taskはnuinuiCADのthree-lane capacityを消費しない。
- nuinuiCAD lane occupancyだけを理由にdev-context developmentをblockしない。
- dev-context worktreeを作ることは、nuinuiCADのfourth product checkoutを作る許可にならない。
- nuinuiCADのdurable lane claim / checkpoint semanticsをdev-context worktreeへmechanically適用しない。
- root `DEVELOPMENT.md`がdev-context worktree lifecycleをownerし、`projects/nuinuiCAD/CHECKOUTS.md`がproduct fixed lanesをownerする。

## Development lifecycle

dev-context repository file changeのnormal pathは次のとおりである。

```text
fresh remote main
  -> approved task contract
  -> dedicated worktree
  -> topic branch
  -> implementation / documentation edit
  -> responsibility-appropriate validation
  -> commit
  -> push
  -> blocking review of pushed state
  -> PR
  -> required verification
  -> merge
  -> authoritative GitHub read-back
```

direct `main` file editをnormal pathにしない。Markdown-only changeを理由にこのlifecycleを省略しない。このtaskではemergency bypassを定義しない。

## Validation

validationは変更したresponsibilityに合わせる。universalなsingle suiteを前提にしない。

- Markdown / routing: local link / route consistencyとrelevant context-check。
- Shell / helper: shell syntax、focused regression、必要な場合はcandidate / production isolation。
- Loading / governance: duplicated or conflicting owner auditと、affected routerからのentrypoint / loading-path verification。
- Blocking review: evidenceは必ずpush済みstateに対応させる。

## Merge read-back and standard clone sync

merge後は、最初にauthoritative GitHub `main`をread backし、意図した変更が含まれることを確認する。その後にだけstandard local cloneを同期する。

通常のsyncは次で行う。

```bash
git -C /Users/yosomi/Code/dev-context pull --ff-only
```

standard cloneがdirty、`main`以外、またはfast-forward不能なら`BLOCKED`として停止する。reset、stash、force-switch、force-updateで修復しない。Human / local executionが実際に成功するまでsyncedと呼ばない。

## Ownership boundaries

この documentは次を吸収しない。

- nuinui helperのimplementation architecture
- nuinuiCAD product lane policy
- project-specific implementation rule
- [shared/GIT-WORKFLOW.md](./shared/GIT-WORKFLOW.md)がすでにownerするshared Git mechanics
- shared documentがすでにownerするCoding Agent prompt / style detail

root `DEVELOPMENT.md`がownerするのは、dev-context repository自身のself-development governanceとroutingだけである。

## Maintenance rule

temporary task stateをこのdocumentへ置かない。将来のself-development ruleが既存のshared / project ownerの責務に属する場合は、そのownerを更新し、root documentへduplicate policyを蓄積しない。
