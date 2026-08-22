# nuinuiCAD checkout / worktree policy

## Purpose

nuinuiCAD固有のlocal checkout / worktree運用を定義する。

Shared ruleは [`shared/DEVELOPMENT.md`](../../shared/DEVELOPMENT.md) を基本とし、この文書はnuinuiCAD固有の例外だけを持つ。

このpolicyのworktree capacity / reuse ruleは、**localでCoding Agentまたはlocal executionを行うTask**に適用する。direct GitHub + CIで進める`only_chatgpt` Issueはlocal worktreeを占有しないため、このcapacity制約の対象外。`only_chatgpt`のparallel可否は [`ONLY-CHATGPT.md`](./ONLY-CHATGPT.md) のinterference gateをauthorityとする。

## Standard checkouts

現在の標準配置:

- primary: `/Users/yosomi/Code/nuinuiCAD`
- persistent sub: `/Users/yosomi/Code/nuinuiCAD-sub`

nuinuiCADではprimary repository checkoutに加えて、並列local implementation用の**常設汎用sub worktreeを1つ**維持してよい。

標準checkoutはこの2つだが、worktree総数に固定numeric limitは設けない。

## Shared CI incident reproduction checkout

shared CI incidentでhuman-terminal reproductionが必要な場合は、通常のimplementation checkoutとは分離した専用clone `/Users/yosomi/Code/nuinuiCAD-ci-repro` を使う。

このcheckoutはimplementation / Manual E2E / Coding Agent用slotではない。通常のlocal execution capacityやreuse-first判断には含めない。詳細なtrigger、環境合わせ、allowed operations、handoffは [`CI-INCIDENTS.md`](./CI-INCIDENTS.md) がauthorityであり、shared CI incidentが実際に疑われる場合だけ読む。

## Reuse-first rule

新しいlocal Coding Agent Taskを開始するときは、まず既存checkout / worktreeを安全に再利用できるか確認する。

- cleanでidleな既存worktreeがTaskのbase / branchを安全に扱えるなら、新規worktreeを作らず再利用する。
- Taskごとに専用worktreeを作成し、Task終了ごとに削除し、次Taskでまた作るdisposable運用を既定にしない。
- active Task、unrelated user changes、異なる同時base等を壊さず既存worktreeを再利用できない場合にだけ追加worktreeを作る。
- 追加worktreeを作る理由は「別Issueだから」「Ready Issueが余っているから」ではなく、そのlocal Taskを安全に実行するためのisolationが実際に必要であること。
- unrelatedなuser changesや進行中Taskをreset / stash / overwrite / force-switchしてslotを空けない。

## Persistent sub rule

- persistent subは、primaryで別local Taskを進めている間に本当に並列実装する必要があるTaskへ使う。
- idle時はcleanに保ち、latest `origin/main` をdetached HEADでcheckoutして待機させる。
- 新しいTaskを始める前に `git fetch origin --prune` を実行し、latest remote stateとintended baseを確認してからTask専用branchを作る。
- Task完了・merge・中止後は、未commit変更がないことを確認してからdetached HEADのlatest `origin/main`へ戻す。安全なら完了Taskのlocal branchを削除する。
- persistent sub自体はTask完了後も削除しない。
- 同じbranchをprimaryとpersistent subの両方でcheckoutしない。
- unrelatedなuser changesや進行中Taskをreset / overwriteしてsubを再利用しない。cleanでない場合はblocking pointとして扱う。

## Additional worktrees

追加worktreeは、既存standard / reusable worktreeでは安全に進められないlocal Coding Agent / local execution Taskが実際にある場合だけ作る。

追加worktreeをTask終了直後に機械的に削除する必要はない。cleanで、今後もlocal Taskのreuse先として運用上の価値があるなら保持してよい。

一方、特定の一時検証だけのために作ったもの、重複して役割がないもの、checkout数を増やすだけでreuse価値がないものは不要になった時点で整理する。

この節はShared Git Workflowの「temporary worktreeは終了時に削除」をnuinuiCAD向けに上書きする。目的はworktreeを増やすことではなく、**安全な既存checkoutを優先して再利用し、不必要なcreate/delete churnを避けること**。

## Manual E2E

Manual E2E、blocking fix、PR merge後の追従作業は、原則として既存の安全なstandard / reusable checkoutを継続利用する。

Frozen commitを一時的に検証する必要がある場合、cleanでidleなcheckoutならdetached HEADを使ってよい。テストのためにuser workをstash / reset / discard / force-switchしない。

Manual E2Eのためだけにdetachedへ移動した場合は、終了後にoriginal refへnon-destructiveなnormal switchで戻す。安全に戻せない状態なら勝手に整理せずblocking pointとして扱う。
