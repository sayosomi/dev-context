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

## Occupancy model

current occupancyは`dev-context`へ保存しない。新しいlocal Taskを始めるたびにactual local checkout stateを確認して判断する。

implementation slotのownershipは追加lease fileを使わず、current branch / HEAD / dirty stateから判断する。

- Task branchをcheckoutしており、そのbranch名からLinear Issue key（例: `SAY-123`）を一意に読める場合、そのIssueがそのslotを使用中と判断する。
- slot固有のidle stateにありcleanなら`FREE`。
- dirty、unexpected branch / HEAD、Issue ownershipを一意に判断できない、またはcurrent Task contextとactual stateが食い違う場合は`BLOCKED / UNKNOWN`。
- cleanであることだけを理由に、Task branch上のimplementation slotを`FREE`と判断しない。

Manual E2E slotは通常detached HEADで使うため、branch名だけではIssue ownershipを表せない。E2E実行中だけGit local metadataに最小markerを持つ。

marker path:

```bash
$(git -C <checkout> rev-parse --git-dir)/nuinui-slot
```

format:

```text
issue=SAY-123
ref=<exact tested commit or stable ref>
```

このmarkerはrepository working treeへ置かない。Manual E2E終了後、checkoutを安全にidle stateへ戻した最後に削除する。

- E2E markerが存在し、actual detached HEAD / tested refと整合する場合は`BUSY`。
- markerとactual stateが食い違う場合は`BLOCKED / UNKNOWN`。
- E2E markerだけ先に削除して見かけ上`FREE`にしない。

## Mandatory slot preflight

新しいlocal implementationまたはManual E2Eを始める前に、**branch / HEADを変更する前にstandard 3 slotsすべてを確認する**。

最低限、各slotについて次を確認する。

- checkout pathが存在するか
- current branchまたはdetached HEAD
- current HEAD commit
- `git status --porcelain`がcleanか
- branch名から読めるIssue key、またはE2E markerの`issue` / `ref`
- intended base / tested refと両立するか

開始前のreportは少なくとも次の形でIssue ownershipとavailabilityを明示する。

```text
slot      issue     ref/branch                     clean   state
primary   SAY-123   sayosomi/say-123-...           yes     BUSY
sub       -         detached origin/main           yes     FREE
e2e       SAY-122   <tested commit>                yes     BUSY
```

state判定:

- `FREE`: cleanで、slot固有のidle stateにあり、E2Eならmarkerもない。
- `BUSY`: implementationではTask branchからIssue ownershipを一意に判断できる。E2Eではmarkerとactual tested stateが整合する。
- `BLOCKED / UNKNOWN`: dirty、unexpected branch / HEAD、marker mismatch、missing checkout、またはownershipを安全に判断できない。

**新Taskは`FREE`と確認できたslotだけを使う。** `BUSY`や`BLOCKED / UNKNOWN`のslotを空けるためにunrelated changesや進行中Taskをreset / stash / overwrite / force-switchしない。

## Start / release lifecycle

### Start

1. standard 3 slotsのmandatory preflightを行う。
2. Taskに適した`FREE` slotを選ぶ。
3. `git fetch origin --prune`を実行し、latest remote stateとintended base / tested refを確認する。
4. implementationではTask branchを作成 / checkoutする。
5. Manual E2Eではexact tested commit / stable refへdetached checkoutし、actual HEADを確認したうえでE2E markerへ`issue` / `ref`を書く。

### Release

Task完了・merge・中止に加え、**safe checkpointでcurrent workがremoteに安全に保存され、local slotを保持し続ける必要がない場合もimplementation slotをreleaseしてよい。** Issue自体をDoneにする必要はない。

release時は次の順に行う。

1. 未commit変更がないことを確認する。
2. current workが必要なremote branch / merged commit等に安全に保存されていることを確認する。
3. slot固有のidle stateへnon-destructiveに戻す。
4. actual stateがidle条件を満たすことを確認する。
5. Manual E2Eでは最後にmarkerを削除する。

安全にidle stateへ戻せない場合は`BLOCKED`として扱う。reset / stash / force-switch等で無理にreleaseしない。

## Idle state by slot

### Primary implementation slot

- 通常の第一implementation slot。
- idle時はcleanな`main`で待機する。
- Task開始時はlatest remote `main`を再確認し、必要なら安全なfast-forwardで同期してからTask branchを作る。
- `main`に未commit変更、unexpected local commit、または別Task branchが残っている場合はidleではない。

### Secondary implementation slot

- primaryで別local Taskが進行中で、本当に並列実装する必要がある場合に使う。
- idle時はcleanに保ち、latest `origin/main`をdetached HEADでcheckoutして待機させる。
- Task完了・merge・中止・safe checkpoint release後は、未commit変更がないことを確認してからdetached HEADのlatest `origin/main`へ戻す。安全なら完了Taskのlocal branchを削除してよい。
- persistent sub自体はTask完了後も削除しない。
- 同じbranchをprimaryとsecondaryの両方でcheckoutしない。

### Manual E2E slot

- Manual E2E専用。通常implementationには使わない。
- tested Issueとexact tested commit / stable refをE2E markerへ明示する。
- Manual E2E実行中にimplementation Taskへ転用しない。
- E2E終了後はhost / temporary test stateのcleanupをcurrent Manual E2E policyに従って完了し、checkoutがcleanであることを確認してからdetached HEADのlatest `origin/main`へ戻し、最後にmarkerを削除する。
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

additional worktreeを継続reuseする場合もownershipを曖昧にしない。少なくともcurrent Issue、branch / HEAD、dirty stateを開始前に確認する。
