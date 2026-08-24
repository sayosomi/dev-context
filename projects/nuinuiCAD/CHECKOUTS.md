# nuinuiCAD checkout / worktree policy

## Purpose

nuinuiCAD固有のlocal checkout / worktree運用を定義する。

Shared ruleは [`shared/DEVELOPMENT.md`](../../shared/DEVELOPMENT.md) を基本とし、この文書はnuinuiCAD固有の例外だけを持つ。

このpolicyのworktree capacity / reuse ruleは、**localでCoding Agentまたはlocal executionを行うTask**に適用する。direct GitHub + CIで進める`only_chatgpt` Issueはlocal worktreeを占有しないため、このcapacity制約の対象外。`only_chatgpt`のparallel可否は [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) のinterference gateをauthorityとする。

## Standard worktree slots

通常運用では次の**常設3スロット**を基本とする。

- primary implementation slot: `/Users/yosomi/Code/nuinuiCAD`
- secondary implementation slot: `/Users/yosomi/Code/nuinuiCAD-sub`
- Manual E2E slot: `/Users/yosomi/Code/nuinuiCAD-e2e`

primaryとsecondaryはlocal implementation用、E2E slotはManual E2E専用とする。Issueごとにworktreeを増やすのではなく、まずこの3スロットを安全に再利用する。

worktree総数に固定numeric limitは設けないが、追加worktreeはstandard slotsでは安全に実行できない明確な理由がある場合だけ作る。

## Slot ownership / lease

各standard slotは、local metadata fileでcurrent Issue ownershipを明示する。

lease file path:

```bash
$(git -C <checkout> rev-parse --git-dir)/nuinui-slot
```

最小format:

```text
issue=SAY-123
purpose=implementation
```

Manual E2Eでは:

```text
issue=SAY-123
purpose=manual-e2e
ref=<exact tested commit or stable ref>
```

lease fileはrepository working treeへ置かず、Gitのlocal metadataとして扱う。

- leaseが存在するslotは、そのIssueが明示的にreleaseされるまで`BUSY`。
- cleanであることだけを理由に`FREE`と判断しない。
- leaseがなくてもdirty、unexpected branch / HEAD、unfinished local stateがある場合は`FREE`と判断しない。
- leaseとactual branch / HEAD / task contextが食い違う場合は`BLOCKED / UNKNOWN`として扱い、勝手にlease削除・reset・stash・force-switchして解消しない。
- local development Taskは原則としてLinear Issue keyを持ってからslotをclaimする。

## Mandatory slot preflight

新しいlocal implementationまたはManual E2Eを始める前に、**branch / HEADを変更する前にstandard 3 slotsすべてを確認する**。

最低限、各slotについて次を確認する。

- checkout pathが存在するか
- lease fileの有無と`issue` / `purpose`
- current branchまたはdetached HEAD
- current HEAD commit
- `git status --porcelain`がcleanか
- intended base / tested refと両立するか

開始前のreportは少なくとも次の形でIssue ownershipとavailabilityを明示する。

```text
slot      issue     ref/branch                     clean   state
primary   SAY-123   sayosomi/say-123-...           yes     BUSY
sub       -         detached origin/main           yes     FREE
e2e       SAY-122   <tested commit>                yes     BUSY
```

state判定:

- `FREE`: leaseなし、clean、slot固有のidle stateにある。
- `BUSY`: valid leaseがあり、actual checkout stateがそのIssueのcurrent Taskと整合する。
- `BLOCKED / UNKNOWN`: dirty、lease mismatch、unexpected branch / HEAD、missing checkout、またはownershipを安全に判断できない。

**新Taskは`FREE`と確認できたslotだけをclaimして開始する。** `BUSY`や`BLOCKED / UNKNOWN`のslotを空けるためにunrelated changesや進行中Taskをreset / stash / overwrite / force-switchしない。

## Claim / release lifecycle

### Claim

1. standard 3 slotsのmandatory preflightを行う。
2. Taskに適した`FREE` slotを選ぶ。
3. slotへIssue leaseを書く。
4. `git fetch origin --prune`を実行し、latest remote stateとintended base / tested refを確認する。
5. その後にTask branch作成、checkout、detached tested commit準備等を行う。

claim前にbranch / HEADをTask用stateへ変更しない。これにより「誰が使っているかわからないclean checkout」を作らない。

### Release

Task完了・merge・中止・Manual E2E終了後は、次の順にreleaseする。

1. 未commit変更がないことを確認する。
2. slot固有のidle stateへnon-destructiveに戻す。
3. actual stateがidle条件を満たすことを確認する。
4. 最後にlease fileを削除する。

安全にidle stateへ戻せない場合はleaseを残したまま`BLOCKED`として扱う。leaseだけ先に削除して見かけ上`FREE`にしない。

## Idle state by slot

### Primary implementation slot

- 通常の第一implementation slot。
- idle時はcleanな`main`で待機する。
- Task開始時はlatest remote `main`を再確認し、必要なら安全なfast-forwardで同期してからTask branchを作る。
- `main`に未commit変更、unexpected local commit、または別Task branchが残っている場合はidleではない。

### Secondary implementation slot

- primaryで別local Taskが進行中で、本当に並列実装する必要がある場合に使う。
- idle時はcleanに保ち、latest `origin/main` をdetached HEADでcheckoutして待機させる。
- Task完了・merge・中止後は、未commit変更がないことを確認してからdetached HEADのlatest `origin/main`へ戻す。安全なら完了Taskのlocal branchを削除する。
- persistent sub自体はTask完了後も削除しない。
- 同じbranchをprimaryとsecondaryの両方でcheckoutしない。

### Manual E2E slot

- Manual E2E専用。通常implementationには使わない。
- tested Issueをleaseへ明示し、必要なexact tested commit / stable refへcheckoutして使う。
- Manual E2E実行中にimplementation Taskへ転用しない。
- E2E終了後はhost / temporary test stateのcleanupをcurrent Manual E2E policyに従って完了し、checkoutがcleanであることを確認してからdetached HEADのlatest `origin/main`へ戻し、最後にleaseをreleaseする。
- testのためにprimary / secondaryのuser workをstash / reset / discard / force-switchしない。

VS Code Manual E2Eのhost isolation、fixture、build、launch、process cleanup等は [`VS-CODE-E2E.md`](./VS-CODE-E2E.md) がauthority。

## Shared CI incident reproduction checkout

shared CI incidentでhuman-terminal reproductionが必要な場合は、通常のimplementation / E2E slotsとは分離した専用clone `/Users/yosomi/Code/nuinuiCAD-ci-repro` を使う。

このcheckoutはimplementation / Manual E2E / Coding Agent用slotではない。通常のlocal execution capacityやreuse-first判断には含めない。詳細なtrigger、環境合わせ、allowed operations、handoffは [`CI-INCIDENTS.md`](./CI-INCIDENTS.md) がauthorityであり、shared CI incidentが実際に疑われる場合だけ読む。

## Reuse-first rule

新しいlocal Coding Agent Taskを開始するときは、mandatory slot preflight後、既存standard slotを安全に再利用できるか確認する。

- `FREE`なprimaryを通常の第一候補とする。
- primaryが`BUSY`で、本当に並列local implementationが必要なら`FREE`なsecondaryを使う。
- Manual E2Eは`FREE`なE2E slotを使う。
- Taskごとに専用worktreeを作成し、Task終了ごとに削除し、次Taskでまた作るdisposable運用を既定にしない。
- active Task、unrelated user changes、異なる同時base等を壊さずstandard slotを再利用できない場合にだけ追加worktreeを検討する。
- 追加worktreeを作る理由は「別Issueだから」「Ready Issueが余っているから」ではなく、そのlocal Taskを安全に実行するためのisolationが実際に必要であること。

## Additional worktrees

追加worktreeは、既存standard slotsでは安全に進められないlocal Coding Agent / local execution Taskが実際にある場合だけ作る。

追加worktreeをTask終了直後に機械的に削除する必要はない。cleanで、今後もlocal Taskのreuse先として運用上の価値があるなら保持してよい。

一方、特定の一時検証だけのために作ったもの、重複して役割がないもの、checkout数を増やすだけでreuse価値がないものは不要になった時点で整理する。

この節はShared Git Workflowの「temporary worktreeは終了時に削除」をnuinuiCAD向けに上書きする。目的はworktreeを増やすことではなく、**安全な既存checkoutを優先して再利用し、不必要なcreate/delete churnを避けること**。

additional worktreeを継続reuseする場合も、standard slotsと同じくownershipを曖昧にしない。少なくともcurrent Issue、branch / HEAD、dirty stateを開始前に確認する。
