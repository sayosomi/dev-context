# Shared Git Workflow

複数projectで共通利用するremote/local同期、checkout / worktree、commit / push / reviewの安全rule。

Project固有のrepository policyやcheckout例外がある場合はそちらを優先する。

## Remote state verification

過去チャットやpromptに書かれたcommit hash、local `main`、既存branch、既存worktreeを現在値として無条件に信用しない。

新しい開発Taskのimplementation contractを確定する前に、GitHub上のremote stateを確認する。必要に応じて:

- latest remote main
- target branchのremote HEAD
- related PR state
- projectのwork-management / spec source

実装済みの事実について、過去チャットや管理文書とrepositoryが矛盾する場合はlatest repositoryをauthoritativeとする。

## Coding Agent start preflight

Coding Agent向けimplementation promptでは、実装前に必ず:

```bash
git fetch origin --prune
```

を実行させる。

fetch後、promptで指定したexpected remote commit / branchとactual remote stateを照合する。

- 一致: specified procedureで実装開始。
- 不一致: stale local stateを前提に進めない。勝手にrebase / reset / merge / redesignせず、blocking pointとして報告して停止。

Expected baseは必ずしも`origin/main`ではない。連続Taskではcurrent track / project ruleが許すreviewed pushed commitを使ってよい。

## Checkout / worktree

- 通常の開発ではprimary repository checkoutを使う。Taskごとにworktreeを作らない。
- 新しいworktreeを作ってよいのは、2本以上のimplementationを本当に同時並行で走らせる必要があり、同じcheckoutでは安全に進められない場合だけ。
- 単に別branch / 別baseで作業したい、current Taskを切り替えたい、既存branchを保護したい、後で戻る可能性がある、という理由だけではworktreeを作らない。通常のbranch switch / fetch / merge等で対応する。
- 連続Task、blocking fix、Manual E2E、PR merge後の追従作業は原則同じprimary checkoutを継続利用する。
- 一時worktreeは、その並行実装が終了・merge・中止して不要になった時点で片付ける。放置して次Taskへ持ち越さない。
- worktree削除前に`git status --short`等で未commit変更がないことを確認する。変更が残る場合は勝手に削除せずblocking pointとして報告する。
- cleanな不要worktreeは、次の通常作業へ進む前に`git worktree remove <path>`で削除する。
- unrelated user changesがある作業環境を無理に再利用しない。並列実装が不要なら新worktreeを既定解にせず、安全なbranch / checkout整理を優先する。
- Taskごとにmain mergeやPR作成を機械的に要求しない。current track / planに従う。
- unrelated user changes、branch、worktreeを勝手に削除・上書き・resetしない。

Projectがpersistent sub worktree等の明示的例外を持つ場合はproject policyを優先する。

## Commit / push / review

repository fileを変更したTaskは、current planが別途定めない限り、指定branchへintended changesだけをcommitし、`git push origin <branch>`を行う。local-only commitを完了扱いにしない。

reviewはpushed GitHub stateに対して行う。

blocking fixはcurrent Taskのplanに反しない限り同じTask branchでcommit / pushして再reviewする。

blocking-review PASS後にPR / mergeするか、review済みcommitから次Taskへ進むかはcurrent track / project planに従う。

## Safety boundary

remote mismatch、unrelated user changes、dirty checkout、unexpected branch ownership等で安全に進められない場合、勝手なreset / stash / force-switch / force-pushで解消しない。blocking pointとして扱う。
