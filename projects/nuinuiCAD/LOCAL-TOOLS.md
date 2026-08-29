# nuinuiCAD local tools

## Purpose

nuinuiCADで繰り返すmechanical / deterministicなHuman terminal operationを、version管理されたlocal helperとして安全に再利用する。

このdocumentはlocal helperの配置、利用、同期、verification、promotion / repair lifecycleをownerする。checkout / lane safety semanticsは[`CHECKOUTS.md`](./CHECKOUTS.md)をauthorityとする。

## Authority and local checkout

GitHub上の`sayosomi/dev-context`がauthoritative sourceであり、local cloneはcache / toolboxである。local cloneや過去chatをProject Contextのsource of truthにしない。

nuinuiCAD作業開始時はlocal cloneの有無にかかわらず、GitHub上のlatest [`README.md`](./README.md)を取得しloading ruleに従う。

標準local clone:

```text
/Users/yosomi/Code/dev-context
```

主要helper:

```text
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui
/Users/yosomi/Code/dev-context/projects/nuinuiCAD/scripts/nuinui-e2e-prepare
```

このcloneはnuinuiCAD repositoryの4th checkoutではない。

## Local sync rule

ChatGPTが承認済みdev-context create / update / deleteをGitHubへ反映した場合、同じ応答でlocal cloneへ反映するraw git commandを必ず提示する。

```bash
git -C /Users/yosomi/Code/dev-context pull --ff-only
```

cloneがないことが分かっている場合だけ初回cloneを案内する。

```bash
git clone https://github.com/sayosomi/dev-context.git /Users/yosomi/Code/dev-context
```

Humanが実行する前にlocal sync済みとみなさない。`nuinui context-sync`はconvenience commandだが、authoritative helper更新後にraw sync commandを提示する義務の代替ではない。

local cloneがdirty、`main`以外、またはfast-forward不可能ならreset / stash / forceせず`BLOCKED:`で停止する。

## Versioned `nuinui` helper

current standalone helper version: `1.5.1`。

`projects/nuinuiCAD/scripts/nuinui`はimplementation durable ownershipと既存のnon-lane mechanicsを単一scriptで実装する。runtime compatibility backendや別legacy helperへdelegateしない。

current commands:

| Command | Purpose |
| --- | --- |
| `nuinui preflight` | fixed main / sub / e2e 3-lane stateとdurable ownershipのread-only audit |
| `nuinui verify <main\|sub> <SAY-123> <expected-base-sha> <branch>` | initialized FREE laneのstart preconditionをread-only検証 |
| `nuinui lane-init <main\|sub>` | proven exact idle fixed laneへpermanent v1 ownership schema markerをbootstrap |
| `nuinui start <main\|sub> <SAY-123> <expected-base-sha> <branch>` | mutation lock + durable slotをbranch switch前に取得してnew claim generationを開始 |
| `nuinui resume <main\|sub> <SAY-123> <expected-base-sha> <expected-checkpoint-sha> <branch> <expected-claim>` | exact Base / checkpoint / branch / claimでsame generationへ復帰 |
| `nuinui release <main\|sub> <merged-checkpoint-sha> <expected-claim>` | exact claimを照合しclaim-specific tombstone経由でmerged laneをrelease |
| `nuinui recover <main\|sub> <expected-claim>` | known interrupted init/start/resume/release stateだけをexact claimでexplicit recovery |
| `nuinui pr-auto-merge <pr-number> <expected-head-sha> <expected-main-sha>` | reviewed exact headへrequired CI pending時だけGitHub Auto-mergeを予約 |
| `nuinui e2e-start <SAY-123> <tested-ref>` | idle e2e laneをexact tested refへ固定しmarker作成 |
| `nuinui e2e-start-local-main <SAY-123> <tested-ref>` | Active interim workflow時だけlocal main checkpointをe2eへ安全に固定 |
| `nuinui e2e-release` | verified e2e stateをlatest `origin/main` detachedへ戻しmarker削除 |
| `nuinui context-sync` | cleanなlocal dev-context `main`をsafe fast-forward |
| `nuinui doctor` | helper / lane / local dev-context diagnostic |
| `nuinui doctor --full` | preflight、E2E status、local dev-context stateのread-only snapshot |
| `nuinui transition-audit` | Active interim transition条件をread-only監査 |
| `nuinui context-check` | dev-context Markdown local linksと`nuinui` CLI-doc整合をread-only検査 |
| `nuinui self-test` | isolated temporary Git repositoriesでsupported safety pathsをexercise |

旧claimless `resume <lane> <Issue> <checkpoint> <branch>`、旧`release <lane> <checkpoint>`、active checkoutをownershipへadoptするpublic commandはcurrent CLIではない。argument count mismatchはfail-closedでusage errorにする。

### Durable ownership behavior

ownership schemaは[`CHECKOUTS.md`](./CHECKOUTS.md)の`version=1`をそのままconsumeする。helper versionとmetadata versionは独立している。

`preflight`はread-only。main/sub FREE判定はauthoritative `ls-remote origin main`を使い、cleanでもbehindならFREEにしない。mutation lock、active slot、releasing tombstoneを優先して分類し、strict schema violationはBLOCKする。

`lane-init`はfixed laneを正当に新規 / 再作成した場合のschema bootstrap。slot / lock / release stateがなくexact safe idleを証明できる場合だけmarkerを書く。既存active-looking checkoutからclaimを生成するrepair用途には使わない。

`start`はbranch switchより先にnew claim + lock + slotをdurable化する。成功outputのclaimは[`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md)へcheckpointする。

`resume`はcaller-supplied Lane / Issue / Base / exact pushed checkpoint / branch / claimとslotをexact照合する。Base refresh、merge-main、rebase、reset、stash、force-switch、branch generation、claim inferenceを行わない。

`release`はcaller-supplied merged checkpoint + claimを必須とする。remote topic branchがpost-mergeで削除済みでも、saved checkpointがcurrent authoritative mainに含まれることを証明できればrelease可能。release開始時にclaimed local topic branchをcheckoutしていた場合だけ、そのexact branchをsafe cleanup candidateにする。

`recover`は一般repairではない。lock/tombstone age expiry、自動削除、reset、stash、force-switch、broad branch cleanupを行わない。metadata malformed、multiple tombstones、claim mismatch、dirty、不一致stateはfail-closed。

### Standalone non-lane mechanics

`pr-auto-merge`, E2E, context-sync, doctor, transition-audit, context-checkも同じ`nuinui` scriptが直接実装する。別backend fileの存在をruntime preconditionにしない。

`nuinui pr-auto-merge`は`sayosomi/nuinuiCAD`だけを対象とするreservation-only command。PRがOPEN / non-draft / base=`main` / exact reviewed headで、current base OIDがexpected mainに一致し、mergeabilityがunambiguous、required checksがfailure/cancel/skip/unknownなしで少なくとも1件pendingの場合だけ予約へ進む。

visible required checksは`gh pr checks --required`のpending / passだけを許可する。required check viewが空の場合はbranch protectionのsource-bound checks、exact-head pull_request workflow run、check suite、check runを相関し、complete proofが得られない場合はBLOCKする。

mutation直前にpreconditionを再確認し、GraphQL `enablePullRequestAutoMerge`へ`mergeMethod=MERGE`と`expectedHeadOid`を渡す。reservation pathからdirect mergeへfallbackしない。mutation後はsame PR / head / expected main / OPEN / `autoMergeRequest.mergeMethod=MERGE`をread-backして成功扱いする。

`nuinui doctor --full`、`transition-audit`、`context-check`はread-only。checkout mutation、cleanup、process stop、Issue selection、Linear/GitHub update、merge判断を行わない。

## Human Manual E2E preparation helper

`projects/nuinuiCAD/scripts/nuinui-e2e-prepare`はdedicated e2e laneでHuman Manual E2E hostを準備するversioned helper。

```text
nuinui-e2e-prepare check <SAY-123> <tested-ref> <fixture-path>
nuinui-e2e-prepare prepare <SAY-123> <tested-ref> <fixture-path> [cdp-port]
nuinui-e2e-prepare status
nuinui-e2e-prepare closure-check <SAY-123>
nuinui-e2e-prepare cleanup
```

`prepare`はexact tested ref / marker / clean detached checkoutを検証し、dependency materializationとrequired build後にfresh VS Code Extension Development Hostを起動してHuman handoffを作る。tracked-file mutationはBLOCKする。

session metadataはexact E2E root / handoff / launch PIDを保持する。`cleanup`はmetadataとmarkerを再検証しowned resourcesだけを終了・削除する。session metadataが残る間はe2e laneをreleaseしない。

`status`と`closure-check`はread-only。unmanaged artifactや別Issue stateを勝手にcleanupしない。

`projects/nuinuiCAD/scripts/test-nuinui-e2e-prepare`はtemporary Git checkoutとfake hostでisolated self-testを行う。実機VS Code / dependency / CDP lifecycleはactual e2e preparation時に別途確認する。

Humanへhelper commandを渡す場合、Issue、Base、checkpoint、claim、branch、tested ref、fixture path等、ChatGPT側で確定できる値を埋めたcopy/paste-ready commandにする。

## Helper promotion rule

helper sourceをauthoritative GitHubへpromotionする前に:

1. current authoritative source identityを取得する。
2. candidateをauthoritative fileとは別に作る。
3. supported safety-critical pathsをisolated environmentで実行する。
4. failure path / fail-closed behaviorもexerciseする。
5. exact tested candidate identityを固定する。
6. tested candidateへpromotion後の未試験変更を足さない。
7. dev-context write planへのHuman approvalを得る。
8. promotion直前にtarget blob / repo head driftを再確認する。
9. exact candidateをpromotionしread-backする。
10. local clone sync commandをHumanへ提示する。

live implementation laneでhelper candidateのmutation commandを試験しない。production promotion前のlive checkはread-only preflight / external evidence照合に限定する。

unexpected error、hang、wrong output、unsafe-looking behaviorが出た場合はone-off workaroundで終わらせずhelper defectとしてrepair loopへ戻す。safety checkを弱めてfailureを通さない。

## Standalone durable helper promotion evidence

current `nuinui` 1.5.1 exact Git blob:

```text
c3ce9695ceaaefbf2f5c2144faecd779a88c3ed8
```

candidate SHA-256:

```text
43807a0fb08b1f55838cd3ea68db796e528300aee8796c18174b4cb6fafc301b
```

promotion candidateはseparate legacy/backend fileなしでisolated temporary Git repositories上の`nuinui self-test`を完走し、次を確認した。

- initialization gate / exact idle;
- old resume/release signature rejection;
- strict v1 unknown/missing/duplicate/unsupported schema failure;
- tombstone claim/suffix fail-closed;
- durable start claimとcheckout mismatch detection;
- Base + claim付きresume;
- failed unmerged releaseのslot保持 / own-lock rollback;
- newer authoritative mainへのmerged release;
- interrupted start / release recovery;
- existing v1 BUSY slotの無変換classification;
- E2E marker lifecycle;
- standalone Auto-merge reservation path;
- stale clean mainのFREE拒否。

result:

```text
SELFTEST PASS
DURABLE EXTENDED PASS
AUTO-MERGE EXTENDED PASS
CONTEXT CHECK PASS
```

1.5.1 repairではpromotion後のmacOS標準awk failureを再現根拠として、strict metadata parserの出力をternary expressionなしのPOSIX awkへ変更した。exact candidateで`/bin/sh -n`と`nuinui self-test`を再実行し、parser単体は`awk` / `nawk` / BusyBox awkでvalid slotの同一field outputとduplicate-key rejectionを確認した。GitHub compareで1.5.0からのcode diffはversion bumpとこのparser rewriteだけである。

runtime compatibility backendはcurrent designに存在しない。過去の1.4.0 wrapper / 1.3.5 backendはGit historyからrollback可能だが、current treeで別authorityやfallbackとして保持しない。

## Fallback

versioned helperが未install、stale / broken、またはcurrent operationをsupportしていない場合は利用を強行しない。

mandatory preflight等でHuman actionが必要なら[`CHECKOUTS.md`](./CHECKOUTS.md)とshared `human-terminal-instructions` skillに従ったcomplete inline commandをfallbackとして提示する。

fallbackで得られた反復可能operationをhelperへ追加する場合も、上記promotion ruleでcandidate verificationとapprovalを行う。
