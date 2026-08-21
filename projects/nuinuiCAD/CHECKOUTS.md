# nuinuiCAD checkout / worktree policy

## Purpose

nuinuiCAD固有のlocal checkout / worktree運用を定義する。

Shared ruleは [`shared/DEVELOPMENT.md`](../../shared/DEVELOPMENT.md) を基本とし、この文書はnuinuiCAD固有の例外だけを持つ。

## Standard checkouts

現在の標準配置:

- primary: `/Users/yosomi/Code/nuinuiCAD`
- persistent sub: `/Users/yosomi/Code/nuinuiCAD-sub`

nuinuiCADではprimary repository checkoutに加えて、並列実装用の**常設汎用sub worktreeを1つ**維持してよい。

## Persistent sub rule

- persistent subは、primaryで別Taskを進めている間に本当に並列実装する必要があるTaskへ使う。
- idle時はcleanに保ち、latest `origin/main` をdetached HEADでcheckoutして待機させる。
- 新しいTaskを始める前に `git fetch origin --prune` を実行し、latest remote stateとintended baseを確認してからTask専用branchを作る。
- Task完了・merge・中止後は、未commit変更がないことを確認してからdetached HEADのlatest `origin/main`へ戻す。安全なら完了Taskのlocal branchを削除する。
- persistent sub自体はTask完了後も削除しない。Shared Development Workflowの「一時worktreeは不要になったら削除する」ルールは、この常設sub以外の追加worktreeに適用する。
- 同じbranchをprimaryとpersistent subの両方でcheckoutしない。
- 常設subは1つだけとする。3本目以降のworktreeは真に追加の同時並列実装が必要な場合だけ作成し、不要になったらShared Development Workflowどおり削除する。
- unrelatedなuser changesや進行中Taskをreset / overwriteしてsubを再利用しない。cleanでない場合はblocking pointとして扱う。

## Manual E2E

Manual E2E、blocking fix、PR merge後の追従作業は、Shared Development Workflowどおり原則として既存の安全なstandard checkoutを継続利用する。

Frozen commitを一時的に検証する必要がある場合、cleanでidleなcheckoutならdetached HEADを使ってよい。テストのためにuser workをstash / reset / discard / force-switchしない。

Manual E2Eのためだけにdetachedへ移動した場合は、終了後にoriginal refへnon-destructiveなnormal switchで戻す。安全に戻せない状態なら勝手に整理せずblocking pointとして扱う。
