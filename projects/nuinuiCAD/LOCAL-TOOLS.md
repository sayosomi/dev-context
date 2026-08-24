# nuinuiCAD local tools

## Purpose

nuinuiCADで繰り返すmechanical / deterministicなHuman terminal operationを、長いcopy/paste shellへ毎回展開せず、version管理されたlocal helperとして安全に再利用する。

このdocumentはlocal helperの配置、利用、同期、実機verification、promotion / repair lifecycleをownerする。checkout / lane safety semanticsそのものは[`CHECKOUTS.md`](./CHECKOUTS.md)をauthorityとする。

## Authority and local checkout

GitHub上の`sayosomi/dev-context`がauthoritative sourceであり、local cloneはcache / toolboxである。local cloneや過去chatをProject Contextのsource of truthにしない。

ChatGPTはnuinuiCAD作業開始時、local cloneの有無にかかわらず、常にGitHub上のlatest [`README.md`](./README.md)を取得し、そのloading ruleに従う。

標準local clone path:

```text
/Users/yosomi/Code/dev-context
```

versioned helper paths:

```text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-e2e-prepare
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-integrate
```

この`dev-context` cloneはnuinuiCAD repositoryの4th checkoutではない。

## Local sync rule

ChatGPTが承認済みdev-context create / update / deleteをGitHubへ反映した場合、同じ応答でlocal cloneへ反映するgit commandを必ず提示する。

既存cloneの標準sync:

```bash
git -C /Users/yosomi/Code/dev-context pull --ff-only
```

cloneがまだ存在しないことが分かっている場合は、初回clone commandを提示する。

```bash
git clone https://github.com/sayosomi/dev-context.git /Users/yosomi/Code/dev-context
```

ChatGPTはHumanが実行する前にlocal sync済みとみなさない。

`nuinui context-sync`は既存cloneをsafe fast-forwardするconvenience commandとして利用できるが、ChatGPTがdev-contextを書き換えた後にraw git sync commandをHumanへ案内する義務の代替にはしない。

local cloneがdirty、`main`以外、またはfast-forward不可能なら、syncは勝手にreset / stash / forceせず`BLOCKED:`で停止する。

## Versioned `nuinui` helper

`projects/nuinuiCAD/scripts/nuinui`は、実機verification済みのmechanical operationだけを持つ。

current commands:

| Command | Purpose |
| --- | --- |
| `nuinui preflight` | fixed main / sub / e2e 3-lane stateのread-only audit |
| `nuinui start <main\|sub> <SAY-123> <expected-base-sha> <branch>` | verified FREE laneをexact baseからTask branchへ開始 |
| `nuinui release <main\|sub> <checkpoint-sha>` | merged checkpointを確認してimplementation laneをidleへrelease |
| `nuinui e2e-start <SAY-123> <tested-ref>` | idle e2e laneをexact tested refへ固定しmarker作成 |
| `nuinui e2e-release` | verified e2e stateをlatest `origin/main` detachedへ戻しmarker削除 |
| `nuinui context-sync` | cleanなlocal dev-context `main`をsafe fast-forward |
| `nuinui doctor` | helper / lane / local dev-contextのdiagnostic表示 |
| `nuinui self-test` | isolated temporary Git repositoriesでsupported mutation safetyをexercise |

## Versioned `nuinui-integrate` helper

`projects/nuinuiCAD/scripts/nuinui-integrate`は、integration checkpointで繰り返すdeterministicなtask-branch safety auditと、GitのEOF blank-line whitespaceだけを対象にした安全なrepairを提供する正式versioned helperである。

current commands:

```text
nuinui-integrate audit <repo> <expected-base> <branch>
nuinui-integrate repair-eof <repo> <expected-base> <commit-message>
```

`audit`はclean worktree、expected baseとのancestor関係、expected task branch、main直接変更禁止を確認する。`repair-eof`はcleanな非-main task branch上で、expected baseからのdiffにGitの`new blank line at EOF`だけが存在する場合に限ってEOF改行を正規化し、semantic content preservationを比較確認したうえでrepair commitを作成する。対象外のwhitespace anomaly、unexpected diff-check failure、semantic change、precondition mismatchは`BLOCKED:`または`ESCALATE:`で停止する。

このhelperはreset / stash / force-switch / force-push / conflict resolution / CI / PR / merge、またはproduct / UX / Linear checkpoint判断を自動化しない。

## Human Manual E2E preparation helper

`projects/nuinuiCAD/scripts/nuinui-e2e-prepare`は、`nuinui e2e-start`で固定済みのdedicated e2e laneを使って、Human Manual E2Eのhostを一発で準備するversioned helperである。

current commands:

```text
nuinui-e2e-prepare check <SAY-123> <tested-ref> <fixture-path>
nuinui-e2e-prepare prepare <SAY-123> <tested-ref> <fixture-path> [cdp-port]
```

`prepare`は、exact tested ref / e2e marker / clean detached checkoutを検証し、必要ならisolated npm cacheでdevDependenciesをmaterializeし、VS Code extensionと`evaluation_stdio`をbuildし、fresh profile / empty extensions / fixture / caller-selected CDP portでExtension Development Hostを起動し、CDP readinessとHuman handoffを確認する。成功時は`READY FOR HUMAN E2E`を出す。

このhelperはproduct source、tested marker、既存の無関係なVS Code processを自動repairしない。fixtureはdedicated e2e checkoutの外側でなければならず、dependency準備またはbuildによるtracked-file mutationはBLOCKされる。

Humanへcommandを渡すときは、Issue key、tested ref、fixture path、必要ならCDP port等、確定値を埋めたcopy/paste-ready commandにする。Humanにplaceholder判断を委ねない。

ChatGPTがHumanへhelper commandを渡すときは、path、Issue key、expected base、checkpoint、branch、tested ref等、ChatGPT側で確定できる値を埋めたcopy/paste-ready commandにする。Humanにplaceholder判断を委ねない。

helperはproduct / UX / scope判断、Linear checkpoint判断、implementation、conflict resolution、dirty workの保存判断を自動化しない。helperの責務は`CHECKOUTS.md`でHumanに許されるmechanical / deterministic operationだけである。

mutation commandは実行直前にsafety-critical stateを再確認し、precondition mismatchでは`BLOCKED:`で停止する。reset / stash / force-switch / force-push / unrelated work破棄を自動repairとして行わない。

## Tool discovery and promotion rule

ChatGPTはnuinuiCAD作業中、繰り返し発生するmechanical / deterministicなHuman terminal operationを見つけた場合、ユーザーから明示的に依頼されなくてもtool化候補としてtrialを提案してよい。

ただし、**未検証のoperationをversioned helperまたはLOCAL-TOOLSへ正式追加してはならない。**

正式追加をChatGPTから提案できる最低条件:

1. intended operationとsafety preconditionが明確である。
2. Humanへ任せてよいmechanical / deterministic scopeである。
3. ユーザーのMac上で、そのoperationをexerciseするtrialが少なくとも1回SUCCESSしている。
4. mutationを含む場合、可能ならisolated temporary repository / dry-runでfailure pathとsafe stopも確認している。
5. trialでfailureが見つかった場合、修正版がSUCCESSするまで正式化しない。

isolated self-testは、production commandと同じmechanics / safety conditionを実際にexerciseしている場合にsuccess evidenceとして使える。real environmentとの差がmaterialでself-testだけでは保証できない場合は、その差に対応する実機successを追加で確認してから正式化する。

一度成功したtrialへ、未検証の追加featureを混ぜてそのまま正式化しない。新しいbehaviorを追加するなら、そのbehaviorもsuccess evidenceを得てからpromotion対象にする。

success evidenceが得られたら、ChatGPTは「このoperationをversioned helper / LOCAL-TOOLSへ正式追加すると反復作業を減らせる」とproactiveに提案する。dev-contextへのwriteは[`../../shared/DEVELOPMENT.md`](../../shared/DEVELOPMENT.md)のapproval ruleに従い、target file / purpose / intended changeを提示して明示承認を得てから行う。

successful trialは自動promotionではない。Human approvalなしにdev-contextへ追加しない。

## Failure repair loop

versioned helperを実運用してunexpected error、hang、wrong output、unsafe-looking behaviorが出た場合、one-off workaroundだけで終わらせずhelper defectの可能性を確認する。

標準repair loop:

```text
failure evidence
-> exact blocker / cause確認
-> local trial fix
-> isolated / relevant self-test
-> SUCCESSするまで修正と再試験
-> dev-context fix planを提示して承認
-> GitHub authoritative helperへ反映
-> local clone用git sync commandを提示
-> synced helperで必要な再確認
```

repair中もunsafe recoveryは行わない。failureを通すためにsafety checkを弱めたり、dirty workをreset / stash / overwriteしたりしない。

GitHubへ反映する修正版は、少なくとも1回SUCCESSしたbehaviorに限定する。実機でまだ成功していない推測修正をauthoritative helperへ直接入れない。

## Fallback

versioned helperが未install、stale / broken、またはcurrent operationをまだsupportしていない場合は、helper利用を強行しない。

mandatory preflight等でHuman actionが必要なら、[`CHECKOUTS.md`](./CHECKOUTS.md)とshared `human-terminal-instructions` skillに従ったcomplete inline commandをfallbackとして提示する。

fallbackで得られた反復可能なoperationが安定して成功した場合は、上記promotion ruleに従ってChatGPTからtool化を提案する。
