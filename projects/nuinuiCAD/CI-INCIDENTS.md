# nuinuiCAD shared CI incident escalation

## Purpose

`only_chatgpt` Issueで、個別Issue由来ではなく**shared `main` / common CI infrastructure由来のCI障害**が疑われる場合のdiagnosis / human-terminal escalationを定義する。

この文書は通常の`only_chatgpt` executionでは読まない。`ONLY-CHATGPT.md`のshared CI incident routeに該当した場合だけ読む。

目的は、人間をdiagnostic ownerにすることではない。web ChatGPTが調査主体のまま、必要なlocal executionだけを人間へ**完全なcopy-paste command**として渡し、失敗test / error evidenceを取得して元のIssue chatへ戻す。

## When to enter this playbook

通常のIssue-local CI failureをこのplaybookへ送らない。

shared CI incidentを合理的に疑うstrong signalには次がある:

- semantic footprintが独立した複数PR / branchで同じrequired job / stepが失敗している;
- failing test / source ownerがcurrent Issueのdiff / Parallel footprintから外れており、`main` advance後にfailureが現れた;
- latest `main`または別のunrelated branchでも同じfailure signatureが確認できる;
- current Issueの変更からfailing ownerへのplausible causal pathがなく、他のactive workでも同じCI degradationが見える。

単独PRの通常のtest failure、current diffが直接触るownerのfailure、またはissue-local regressionを示す明確なevidenceだけではshared incident扱いにしない。

shared incidentが疑われたら、affected Issueを個別に推測修正し続ける前にこのplaybookへ切り替える。

## Incident identity and authority

local reproductionを始める前にweb ChatGPTが次を確定する:

- repository;
- workflow run ID / URL;
- failing head SHA;
- failing job;
- failing step;
- failing stepのexact command;
- failing SHA時点のworkflow definitionとsetup sequence。

**環境authorityはlatest `main`ではなく、失敗したhead SHAで実行されたworkflow**とする。

Node / Rust version、environment variables、dependency installation、fixture / build preparation、test command等は、失敗したSHA時点の`.github/workflows/*`とrepository filesから導出する。現在のProject Contextや過去のincidentで使ったversionを固定値として再利用しない。

## Web evidence before human terminal

human terminalは最初のfallbackではない。まず`ONLY-CHATGPT.md`のCI failure fallbackに従い、web ChatGPTから取得できるrun / job / step / log / artifact / repository evidenceを使う。

web evidenceだけでexact failing test / errorとcauseが十分に特定できる場合は、不要なlocal reproductionを要求しない。

shared incidentが疑われ、web evidenceだけでは失敗test / errorを十分に特定できない、またはCIと近いexecution evidenceが必要な場合にhuman terminal escalationを開始する。

## Fixed Mac CI-repro checkout

human-terminal reproductionでは通常のprimary / persistent subを使わない。専用のdiagnostic checkoutを使用する。

Reserved path:

```text
/Users/yosomi/Code/nuinuiCAD-ci-repro
```

このcheckoutは**CI incident reproduction専用のseparate clone**とする。

- product implementation、blocking fix、Manual E2E、通常のCoding Agent workには使わない;
- user-authored workを置かない;
- branch ownershipを持たず、incident中はfailing SHAをdetached HEADで検証する;
- commit / push / mergeを行わない;
- `git reset --hard`、`git clean`、stash、force操作で状態を整えない;
- dirtyなら勝手に破棄せず、その状態を報告して停止する。

checkoutがまだ存在しない場合は、web ChatGPTが存在確認後にone-time clone commandを生成する。人間にpathやclone方法を選ばせない。

## Mac environment matching rule

GitHub Actions runnerがLinuxの場合、MacでOSそのものを一致させることはできない。Docker / VMによるLinux再現はこのplaybookの前提にしない。

その代わり、失敗したworkflowからMac上で再現可能な条件を最大限一致させる:

- failing head SHA;
- Node major / exact version specification;
- Rust toolchain / components when relevant;
- lockfileに従ったdependency installation (`npm ci`等);
- relevant environment variables;
- failing stepより前に必要なbuild / fixture / generation step;
- failing stepのexact test command。

OS / architectureなど一致できない条件は隠さずhandoff evidenceに記録する。MacでPASSしてもCI failureの解消や不存在を意味しない。

local Node / Rust等がworkflow指定と一致しない場合、web ChatGPTが利用可能なlocal toolchain manager / installation stateを確認し、**exact switch / install command**を生成する。人間にversion manager、version、PATH、test targetを選ばせない。

## Human-terminal interaction contract

人間の役割はterminal executorに限定する。

web ChatGPTは原則として一度に1つのcomplete command blockを提示し、人間には次だけを依頼する:

```text
このcommand blockをそのままTerminalへ貼り付けて実行し、outputをそのまま返してください。
```

人間へ次の判断を委ねない:

- どのcheckout / branch / SHAを使うか;
- どのNode / Rust versionにするか;
- どのsetup stepが必要か;
- どのtestを実行するか;
- failure outputのどこが重要か;
- 次に何を試すか。

各command blockについて、web ChatGPTは実行前にstate-changing operationの有無を把握する。repository stateを変更する必要がないdiagnosisではread-only / dependency-install / test executionを優先する。

## Reproduction sequence

### 1. Repro checkout preflight

最初に専用checkoutの存在、cleanliness、remote access、failing SHA availabilityを確認する。

既存checkoutを使う場合のcanonical shape:

```bash
set -euo pipefail
REPO=/Users/yosomi/Code/nuinuiCAD-ci-repro
SHA=<FAILING_SHA>

cd "$REPO"
if [[ -n "$(git status --porcelain)" ]]; then
  echo "CI_REPRO_DIRTY"
  git status --short --branch
  exit 2
fi

git fetch origin --prune
git cat-file -e "${SHA}^{commit}"
git switch --detach "$SHA"

printf '\n=== repo ===\n'
git status --short --branch
git rev-parse HEAD
printf '\n=== host ===\n'
uname -a
printf '\n=== toolchain ===\n'
node --version || true
npm --version || true
rustc --version || true
cargo --version || true
```

web ChatGPTは`<FAILING_SHA>`を実値へ置換してから提示する。placeholderを人間に編集させない。

### 2. Match the failing workflow setup

preflight outputとfailing SHA時点のworkflowを比較し、必要ならtoolchainを合わせる。

その後、CIがfailing stepに到達するまでにtest outcomeへ影響するsetupを同じ順序で実行する。例としてNode Full Testなら`npm ci`、必要なRust fixture build等を含めるが、**current exampleを固定手順として扱わない**。実際のfailing workflowがauthorityである。

### 3. Run the exact failing CI command first

失敗testを推測してfocused testから始めない。まずfailing stepのexact commandを実行する。

command outputはstdout / stderrを保持し、必要なら`tee`で`/tmp/nuinuicad-ci-repro.log`へ保存する。web ChatGPTがexit statusを失わないcomplete command blockを生成する。

### 4. Identify the failing test

exact commandがlocalでもFAILしたら、まず次を確定する:

- failing file / suite;
- failing test full name;
- first relevant error / assertion / unhandled error;
- stack / source location when available。

Vitestで通常outputだけでは十分に特定できない場合、過去のdiagnosisと同様にJSON reporterを使ってfailed assertionsを抽出してよい。web ChatGPTがcurrent commandに合わせて`--reporter=json` / `--outputFile=...`を組み込んだcopy-paste blockを生成し、人間にreporter optionを組み立てさせない。

race / flakyが疑われる場合は、失敗testを特定した後にfocused testをChatGPT指定回数だけrepeatして再現性を確認してよい。full suiteを無目的に大量repeatしない。

### 5. If Mac does not reproduce

MacでPASSした場合は`resolved`と結論しない。

- CIと一致できなかったOS / architecture / environment条件を記録する;
- race / flakyのplausible evidenceがある場合だけ、ChatGPTがbounded repeatまたはfocused reproductionを指示する;
- それでも再現しなければ`not reproduced on macOS`をevidenceとして元のIssue chatへ返す。

Linux-specific failureの可能性が残る場合、人間へLinux環境の構築を要求せず、web側のCI evidence / subsequent runで継続診断する。

## Handoff to the original Issue chat

失敗test / errorを特定した時点で、local repro checkoutでfixを始めない。web ChatGPTは人間が元のIssue chatへ貼れるcompact handoffを作る。

```text
SHARED CI INCIDENT EVIDENCE
- Run: <workflow run>
- Head SHA: <sha>
- Job / step: <job> / <step>
- Local host: macOS <arch>
- Matched environment: <Node / Rust / setup / env>
- Unmatched environment: <Linux runner etc., or none>
- Exact command: <command>
- Result: PASS / FAIL
- Failing file: <path or unknown>
- Failing test: <full name or unknown>
- Error: <concise first relevant error>
- Reproduction: <1/N, intermittent, or not reproduced>
```

人間の次の操作は原則として**このhandoffを元のIssue chatへcopy-pasteすること**だけとする。

元のIssue chatはこのevidenceを受けてrepository / contractを再確認し、common fixまたはIssue-local fixを判断して通常のGitHub + CI loopを再開する。

## Shared-incident completion

common fixが`main`へmergeされたら、affected `only_chatgpt` Issuesはlatest `main`を再確認し、Main-advance interference checkpointを通してからCIをrerun / resumeする。

同じshared failureについて、各Issue chatが独立にhuman-terminal reproductionを繰り返さない。既に十分なincident evidenceまたはmerged common fixがある場合はそれを利用し、Issueごとのduplicate escalationを避ける。
