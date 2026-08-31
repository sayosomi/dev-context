# dev-context Development

この document は、`sayosomi/dev-context` repository 自体を変更するときの canonical development lifecycle owner である。
repository overview / routing は [root README](./README.md)、複数 project に再利用するmechanicsは [shared development router](./shared/DEVELOPMENT.md) と各 shared owner document、project固有のruleは [`projects/<project>/`](./projects) 配下の owner document が担当する。
GitHub Issue authoring、current contract、contract lifecycle、re-auditは [root ISSUES.md](./ISSUES.md) が担当する。
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
- root `ISSUES.md`（Issue authoringまたはcontract auditが関係する場合）
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
current Work scope / implementation contract
  -> GitHub Issue body
current Issue evidence / rationale / contract history
  -> GitHub Issue comments
implementation / review state
  -> GitHub branch / commits / PR / checks
```

dev-contextではGitHub Issuesがprimary Work / current-contract authorityであり、Issue authoring / contract / re-auditの詳細は [root ISSUES.md](./ISSUES.md) がownerする。

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

read-only inspectionと、canonical persistent worktreeをone-time bootstrapするために必要なGit / worktree metadata operationはstandard cloneで許可する。編集、validation、commitはpersistent dev-context development worktreeで行う。

### Canonical persistent dev-context development worktree

通常のdev-context development edit checkoutは、正確に次のpathである。

```text
/Users/yosomi/Code/dev-context-dev
```

これはpersistent development worktreeであり、各Taskごとに作成・削除しない。registered worktreeとして残し、dev-context development Taskをsequentialに再利用する。standard cloneは正確に `/Users/yosomi/Code/dev-context` のままであり、production / cache / toolbox専用で、development edit targetにはしない。

dev-context developmentはat most one active development trackを許可するsingle-track executionである。parallelなdev-context implementationはnormal workflowに含めない。このpolicyが有効な間はsecond dev-context development worktreeを作成しない。将来parallel dev-context developmentが必要になった場合は、additional development worktreeを作成する前にこのpolicyを明示的に変更する。これはnuinuiCAD product lane capacityには適用しない。

#### Persistent worktree bootstrap

canonical persistent worktreeが存在しない場合に限り、one-time bootstrapで作成する。作成前にregistered worktree一覧とtarget pathをread-only inspectionし、standard cloneでfreshにverifiedした remote `main`からcanonical persistent worktreeを作成する。作成に使うstandard cloneの操作はGit / worktree metadata operationに限る。targetに予期しない既存path、既存登録、またはその他のambiguous stateがある場合はfail closedして`BLOCKED`で停止する。曖昧な状態をdelete、overwrite、reset、stash、force-repairして作成を進めない。

このdurable documentには、current TaskのbranchやSHAをbootstrap ruleとして記録しない。詳細な共通Git mechanicsは [shared/GIT-WORKFLOW.md](./shared/GIT-WORKFLOW.md)へrouteする。

#### Sequential Task transition

各新しいdev-context development Taskでは、次を順に満たす。

- fresh remote bootstrap（remote `main`のfresh verificationを含む）を行う。
- 他のactive dev-context development Taskが存在しないことを確認する。
- persistent worktreeをinspectし、cleanであることを必須とする。
- prior Taskのimplementation / blocking-fix stateがconcludedであることを確認してからrepurposeする。
- 既存のfreshness rulesに従って、意図したcurrent remote stateをfetchしてre-readする。
- freshly verified remote `main`を基点にfresh topic branchをcreate / switchする。
- そのsame persistent worktreeでedit、validation、commit、push、pushed-state blocking review、PR、required verification、mergeを行う。

Task間でworktreeをremove / recreateしない。persistent worktreeをmerge後に`main`へ戻すことは必須ではなく、merged prior topic branchがnormal safe branch transitionまでlocalに残ることも許容する。next Taskを開始するためだけのbranch cleanupも要求しない。

Recurring transition checksはversioned helperへrouteする。production read-back後は、GitHub authoritative `main` SHAと生成artifact blob SHAをcaller expectationとして、`nuinui context-audit <expected-main> <expected-artifact-blob>`でstandard cloneをread-only監査し、成功後だけ`nuinui context-sync <expected-main> <expected-artifact-blob>`でguarded fast-forwardする。persistent worktreeは`nuinui context-dev-audit <expected-branch> <expected-head>`でread-only監査し、concluded prior Taskから次のTaskへ進める場合だけ`nuinui context-dev-transition <expected-old-branch> <expected-old-head> <expected-main> <new-branch>`を使う。後者は同じregistered worktreeを保持したまま、exact mainへのordinary detach/switchとfresh branch create/switchだけを行う。

`context-dev-transition`がexact immediate duplicateとして`DEV-CONTEXT ALREADY TRANSITIONED`と`mutation=no-op`を返した場合、そのenvelopeはrequested transitionが安全に完了済みであるterminal proofである。ChatGPTはその結果からcurrent Taskのnormal workflowへ直接継続する。duplicate invocationだけを理由に、追加の`context-dev-audit`、branch / HEAD / worktree-registration paste、最初のtransitionの確認、同じtransitionの再実行、またはgeneric diagnosisを求めない。current branchが進行済み、mismatched、またはambiguousな場合はalready-transitionedとは扱わず、従来どおりfail-closedしてnormal fresh-state routeを使う。このclarificationはsingle-track policyと通常のtransition safety rulesを変更しない。

#### Fail-closed reuse

persistent development worktreeがdirty、unexpectedなunresolved Task state、ambiguousなGit state、またはfreshly verifiedなnew Task baseへ安全にtransitionできない状態なら`BLOCKED`として停止する。reuseを成立させるためだけにreset、stash、force-switch、overwrite、delete / recreateを行わない。

#### Blocking review / fix continuity

implementation、validation、pushed-state blocking review、narrow blocking fix、PR lifecycleの全期間で、same persistent worktreeとcurrent topic branchを使い続ける。blocking fixのためにworktreeをrotateしない。

dev-contextのpersistent worktreeはnuinuiCADのfixed product laneではない。

## Separation from nuinuiCAD fixed lanes

resource modelを混ぜない。

```text
sayosomi/nuinuiCAD product fixed lanes:
  /Users/yosomi/Code/nuinuiCAD
  /Users/yosomi/Code/nuinuiCAD-sub
  /Users/yosomi/Code/nuinuiCAD-e2e

sayosomi/dev-context repository:
  /Users/yosomi/Code/dev-context        production/cache/toolbox clone
  /Users/yosomi/Code/dev-context-dev   persistent single-track development worktree
```

明示的な境界は次のとおり。

- dev-context worktreeはnuinuiCAD `main` / `sub` / `e2e` laneではない。
- dev-context taskはnuinuiCADのthree-lane capacityを消費しない。
- nuinuiCAD lane occupancyだけを理由にdev-context developmentをblockしない。
- dev-context worktreeを使うことは、nuinuiCADのfourth product checkoutを作る許可にならない。
- nuinuiCADのdurable lane claim / checkpoint semanticsをdev-context worktreeへmechanically適用しない。
- root `DEVELOPMENT.md`がdev-context persistent worktree lifecycleをownerし、`projects/nuinuiCAD/CHECKOUTS.md`がproduct fixed lanesをownerする。

## Development lifecycle

dev-context repository file changeのnormal pathは次のとおりである。

```text
fresh remote main
  -> approved task contract
  -> persistent dev-context development worktree
  -> fresh topic branch
  -> edit
  -> validation
  -> commit
  -> push
  -> pushed-state blocking review
  -> PR
  -> required verification
  -> merge
  -> authoritative GitHub read-back
  -> retain persistent worktree for next Task
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

persistent development worktreeはmerge後もremoveしない。next sequential Taskに利用可能な状態として保持し、次のTask自身がfresh remote/bootstrapとsafe branch transitionを行う。mergeごとに直ちに`main`をcheckoutすることは、後続のsafe operationに必要な場合を除いて要求しない。

通常のsyncは、GitHub authoritative read-backで確定したexpected valuesを埋めたversioned helperで行う。

```bash
nuinui context-audit <expected-main> <expected-artifact-blob>
nuinui context-sync <expected-main> <expected-artifact-blob>
```

`context-audit`はmutation-freeであり、production cloneがexpected mainよりbehindでもlocal artifact blobをtargetと一致させることは要求しない。`context-sync`はfresh fetch後にauthoritative main、ancestry、expected-main treeのartifact blobを再検証し、fast-forward後もHEAD / artifact / clean stateをread backする。standard cloneがdirty、`main`以外、またはfast-forward不能なら`BLOCKED`として停止する。versioned helperが未install、stale、broken、またはcurrent operationをsupportしていない場合に限り、同じread-backとmanual safety checkを満たしたfallbackとして`git -C /Users/yosomi/Code/dev-context pull --ff-only`を提示する。reset、stash、force-switch、force-updateで修復しない。Human / local executionが実際に成功するまでsyncedと呼ばない。

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
