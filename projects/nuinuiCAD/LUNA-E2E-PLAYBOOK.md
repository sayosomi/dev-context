# nuinuiCAD Luna Manual E2E playbook

## Purpose

Codex Luna xhighでnuinuiCAD Manual E2Eを安定して実行するための**operational playbook**。

Authorityを分ける。

- test classification、`Judgment`、`Executor`、PASS / FAIL / BLOCKED、Sol High result ownership: [`MANUAL-E2E.md`](./MANUAL-E2E.md)
- VS Code isolated Extension Development Host baseline: [`VS-CODE-E2E.md`](./VS-CODE-E2E.md)
- current Issueのfixture / action / oracle / acceptance: current Linear Issue contract / Manual E2E plan
- この文書: Luna prompt、stable tested state、evidence、retry、common pitfalls

このplaybookがauthority文書と矛盾したらauthority側を優先し、その後playbookをrefreshする。

## Operating model

Lunaはtest operatorでありtest designerではない。

```text
prepare exact state
-> operate
-> observe
-> compare with predeclared oracle
-> capture evidence
-> report PASS / FAIL / BLOCKED
```

Lunaへ次をさせない。

- architecture調査
- product / UX / aesthetic judgment
- test plan redesign
- missing oracleの発明
- implementation fix
- unrelated cleanup
- Human-assigned unitの実行

## 1. Freeze the tested state when `main` is moving

Manual E2E実行前に必ず:

```bash
git fetch origin --prune
```

quietなrepositoryならcurrent `origin/main` exact commitをtested stateにしてよい。

nuinuiCADでは並行mergeが多いため、prompt生成からLuna実行までの間に`origin/main`が進むことがある。単純に:

```text
origin/main == <prompt SHA>
```

を要求すると、tested behaviorが変わっていなくてもfalse `BLOCKED`になり得る。

必要ならreview済みcommitへstable remote E2E refを作る。

```text
origin/sayosomi/<issue>-manual-e2e-freeze
```

Luna側で最低限:

```bash
EXPECTED="<tested commit>"
E2E_REF="origin/sayosomi/<issue>-manual-e2e-freeze"

test "$(git rev-parse "$E2E_REF")" = "$EXPECTED"
git merge-base --is-ancestor "$EXPECTED" origin/main
```

`origin/main`のnormal advancementだけではblockしない。実行時の`origin/main` SHAをresultへ記録する。

Luna結果受領後、Sol Highがlatest `main`をfresh-checkしてtested commitとの差分をreviewする。

- unrelated drift: E2Eをaccept可能
- tested semanticsへmaterial drift: affected unitをnew reviewed stateでrerun
- tested commitが`main`のancestorでなくなった: remote-state staleness / rewriteとして扱う

completed evidenceを持つfreeze refを黙って別commitへ動かさない。新しいtested stateが必要ならnew/versioned refを使う。

## 2. Protect local checkouts

checkout運用は [`CHECKOUTS.md`](./CHECKOUTS.md) に従う。

Luna promptでは実行前にstandard checkoutsのstateを確認させる。

最低限:

```bash
git status --short
git branch --show-current
git rev-parse HEAD
```

cleanでidleなcheckoutだけを使う。

frozen commit検証でdetached HEADを使う場合:

```bash
git switch --detach "$EXPECTED"
test "$(git rev-parse HEAD)" = "$EXPECTED"
test -z "$(git status --porcelain)"
```

Manual E2Eのためにunrelated user workをreset / stash / discard / overwrite / force-switchしない。

## 3. Run environment preflight before product tests

VS Code host setupは [`VS-CODE-E2E.md`](./VS-CODE-E2E.md) のcanonical baselineを使う。

product oracle実行前にextension-registration preflightを行う。

`.nui` fixtureで:

1. fixtureをactiveにする。
2. language modeが`nui` / nuinuiCADでありPlain Textでないことを確認する。
3. current testに必要なnuinuiCAD contributed commandがCommand Paletteに存在することを確認する。
4. 必要ならRunning Extensions / fresh profile logsも確認する。

preflight失敗は:

```text
BLOCKED — development extension registration / test environment unavailable
```

でありproduct `FAIL`ではない。

必要ならfresh profileのlogsからextension host / window / main logを確認し、`nuinuiCAD`、`extensionDevelopmentPath`、scanning / activation、error / warningをevidenceとして返す。

Lunaはその場でimplementation codeを修正しない。

## 4. Design fixtures for objective identity

Luna向けfixtureは、UI上で機械的に識別できるidentity markerを持たせる。

multi-document test例:

```text
PrintA / SvgA / PieceA
PrintB / SvgB / PieceB
```

oracleにも識別方法を書く。

悪い例:

```text
the right document opened
```

良い例:

```text
Preview selector shows PrintA and active Canvas tab identifies say89-A.nui
```

state-preservation testはbefore / afterで同じidentityを記録する。

例:

- selected geometry identity
- Preview selector value
- active tab title
- exact source span
- session count / duplicate absence
- A/B tabs before and after source close

## 5. Prefer objective evidence over narration

Lunaの`PASS`は「looks correct」だけではacceptしない。

優先するevidence:

- exact visible strings
- accessibility state / accessible name
- active tab title
- selector value
- exact source text
- before / after state
- count evidence
- screenshot

visual checkでもoracleをbinary factへ固定する。

例:

```text
PASS if the same selection marker remains on the same identified geometry.
```

スクリーンショットがあること自体はaesthetic judgmentの許可ではない。

## 6. Order units to preserve evidence

破壊的操作は可能なら最後へ置く。

例:

- source close / session disposal
- delete
- state reset
- irreversible mutation

promptにはfailureが後続unitを無効化するかを書く。

独立unitなら、1 unitのFAILで残りのevidenceを隠さずcontinueさせる。

## 7. Build a self-contained Luna prompt

fresh Luna sessionでは、execution-critical informationをprompt内へ完結させる。

必須要素:

- repository / checkout identity
- expected tested commit / stable ref
- remote verification commands
- checkout safety conditions
- exact build / launch baseline or task-specific additions
- exact fixture contents
- selected Luna units only
- per unit: initial state / action / oracle / evidence
- stop / continue conditions
- result format

LunaへLinear、GitHub、過去chat、repository architectureからtest planを再発見させない。

promptへ明示するboundary例:

```text
Do not modify implementation code.
Do not fix a failure.
Do not redesign or expand the test plan.
Do not perform Human-assigned units.
Return BLOCKED if the required state cannot be established objectively.
```

same Luna sessionへretryする場合はdelta promptでもよいが、retained contextが曖昧ならself-contained promptへ戻す。

## 8. Do not weaken the oracle for Luna

Lunaがrequired stateを確実に作れない、または観測できない場合は`BLOCKED`でよい。

例:

- required selectionを客観的identity付きで確立できない
- popup/candidateをevidence上区別できない
- physical-device操作が必要
- judgmentがHuman quality gateを含む

Sol Highは必要に応じて:

```text
Judgment: Objective
Executor: Human
Reason: Luna capability
```

へreclassifyしてよい。

Lunaを維持するためにoracleを簡単な別物へ置換しない。

## 9. Distinguish BLOCKED from FAIL

典型的`BLOCKED`:

- tested remote stateがstale / rewritten
- stable refがexpected commitを指さない
- safe clean checkoutがない
- VS Code executable / Rust binaryがない
- development extensionがregisteredされない
- `.nui`がPlain Text
- extension未loadのためrequired commandがない
- required initial UI stateを確実に作れない
- required resultを確実にobserveできない
- prompt / oracleがambiguous

典型的true `FAIL`:

```text
Environment preflight passed.
Specified action was executed.
Required state was objectively observable.
Observed result contradicted the predeclared oracle.
```

environment / instruction problemをimplementation failure loopへ入れない。

## 10. Result format

headerでtested environmentを記録する。

```text
Tested commit:
Stable E2E ref:
Checkout used:
origin/main at execution:
Repository status before test:
VS Code executable:
VS Code version:
E2E_ROOT:
Extension registration preflight:
Repository implementation files modified: YES | NO
```

per unit:

```text
Unit <id>: PASS | FAIL | BLOCKED
Expected:
Observed:
Evidence:
Reproduction steps if FAIL:
Blocker if BLOCKED:
```

grouped identity testは各subcaseを明示する。`works`だけでまとめない。

## 11. Sol High acceptance checklist

Luna結果をacceptする前に確認する。

1. tested commit / stable refがintended stateか。
2. environment preflightがPASSか。
3. Manual E2E中にrepository implementation filesを変更していないか。
4. 各required Luna unitにoracleを直接支えるevidenceがあるか。
5. Human-assigned unitが残っていないか。
6. latest `origin/main` driftをreviewしたか。
7. tested semanticsへmaterial driftがある場合、affected unitをrerunしたか。
8. aggregate `Manual E2E: Passed`の前提を満たすか。
9. Done-before Ready contract freshness checkは別checkpointとして実施したか。

## Common pitfalls

### Moving-main false blocker

症状: fetch直後、`origin/main`がprompt SHAより新しいだけでLunaがBLOCKED。

対策: Sol Highがdriftをreviewし、stable E2E refでtested stateを固定し、実行後にlatest-main freshness reviewを分離する。

### VS Code opens but nuinuiCAD is absent

症状:

- VS Code自体は起動
- `.nui`がPlain Text
- required nuinuiCAD commandがない
- Running Extensionsにdev extensionがない

対策: product FAILにせずenvironment BLOCKED。`VS-CODE-E2E.md`のcanonical isolated launchを使い、extension-registration preflightを先に通す。

## Maintenance rule

Manual E2Eから再利用可能なoperational lessonが得られたらこのplaybookへ追加する。

追加対象:

- stable ref / freshness strategy
- evidence technique
- repeated Luna capability boundary
- prompt pattern
- environment pitfall

個別Issueの完了履歴や巨大なcompleted promptを保存しない。incident detailはGit / Linear historyへ残し、ここには再利用可能なruleだけを残す。
