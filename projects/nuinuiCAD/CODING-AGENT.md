# nuinuiCAD Implementation Coding Agent Policy

nuinuiCADでimplementation / blocking-fixをCoding Agentへ渡すときのproject-specific defaultとresource policy。

Shared role boundary / prompt content / Git handoffは [`../../shared/CODING-AGENT-WORKFLOW.md`](../../shared/CODING-AGENT-WORKFLOW.md) に従う。Prompt language / formattingは [`../../shared/AGENT-PROMPT-STYLE.md`](../../shared/AGENT-PROMPT-STYLE.md) に従う。

## Default agent

ユーザーまたはcurrent Taskが別のagent / reasoning effortを明示しない限り、nuinuiCADのimplementation / blocking-fix Coding Agentは次を既定とする。

- agent: Codex Luna
- reasoning effort: xhigh

ユーザーが単に「Coding Agent」「コーディングエージェント」「Lunaに実装させる」と指定し、別model / effortを指定していない場合もこのdefaultを使う。

このdefaultはimplementation / blocking-fix roleに対するもの。`only_chatgpt` execution、Manual E2EのJudgment / Executor分類、Human作業へ自動的に適用しない。Manual E2Eで`Executor: Luna`を使う場合は [`LUNA-E2E-PLAYBOOK.md`](./LUNA-E2E-PLAYBOOK.md) をauthorityとする。

## Resource objective

Lunaは貴重なimplementation resourceとして扱う。目的はLunaの使用回数を減らすことではなく、**1 runあたりの無駄なtoken / exploration / rerunを減らし、低コストで大量かつ確実に実装を進めること**。

xhighを既定にする理由はimplementation reliabilityを優先するため。コスト削減の第一手段はreasoning effortを下げることではなく、ChatGPT側でworkをimplementation-readyにしてLunaへ渡すcontextと判断負荷を減らすこと。

## Before Luna run — ChatGPT owns preparation

Lunaへ渡す前に、ChatGPTがcurrent Project Contextとlatest remote repositoryを使って次を完了する。

- repository / implementation調査
- architecture / semantic owner / change locationの特定
- product / architecture / implementation contractの決定
- implementation slicingとcurrent executable sliceの確定
- dependency / blocker / expected baseの確認
- required acceptance / tests / verificationの確定
- ChatGPTで実行できるwork-management / design / review準備

Expected baseのfreshness checkは [`../../shared/GIT-WORKFLOW.md`](../../shared/GIT-WORKFLOW.md) のChatGPT-side handoff freshness checkと [`../../shared/CODING-AGENT-WORKFLOW.md`](../../shared/CODING-AGENT-WORKFLOW.md) のPre-prompt remote freshness gateに従う。

このcheckはLuna promptを作成・提示する**前**に行う。repository調査、contract策定、previous checkpointで確認したremote SHAを、そのままLuna promptのexpected baseへ転記しない。freshness check後のauthoritative remote stateを基準としてpromptを作る。

Luna側の`git fetch origin --prune`は、このpre-prompt check後からagent開始までのremote advanceを検出するsecond safety checkとして扱う。ChatGPT-side freshness checkの代替にしない。

これらをLunaへopen-ended taskとして委ねない。

## Luna receives only executable work

Luna promptにはcurrent executable sliceを完了するために必要な情報だけを渡す。

必須情報はshared workflowのimplementation prompt contractに従う。加えて次を守る。

- broad Issue全体ではなく、current safe sliceだけを渡す。
- future slice、後続integration、未確定designを先取りさせない。
- repository調査、architecture探索、design比較、scope決定を依頼しない。
- settled design history、過去チャット、長い背景説明、Issueの全文を必要なく貼らない。
- shared policyをpromptへ長く再掲しない。current taskで実行に必要なconstraintだけを書く。
- change owner / required changes / acceptance / verification / Git safety / stop conditionを具体的に書く。
- agentが自力でcontractを再構築しないと実装できないpromptはimplementation-readyではないため、ChatGPT側で先に不足を解消する。

## Stop instead of spending tokens on uncertainty

Lunaが次に当たった場合、勝手な広域調査・redesign・scope expansionへ進ませない。

- expected remote state mismatch
- contractから一意に決められないproduct / architecture decision
- current slice外のowner変更が必要になった
- unrelated user changes / dirty checkoutで安全に進められない
- required dependency / prerequisiteが成立していない

その場合はblockerを簡潔に返して停止する。ChatGPTが再調査・再分解し、必要ならより狭いnext promptを作る。

## Rerun minimization

失敗runを同じ曖昧promptのまま繰り返さない。

1. Luna result / failure evidenceをChatGPTが読む。
2. failure classとownerをChatGPTが特定する。
3. contract / slice / verificationを必要な範囲だけ更新する。
4. blocking-fixをLunaへ戻す場合は、failure evidenceと具体的fix targetだけを含むnarrow promptを作る。

Lunaへroot-cause investigationとproduct redesignをまとめて委ねない。

## Prompt economy

良いLuna promptは短いこと自体が目的ではない。**実装に必要な情報密度が高く、不要な探索を発生させないこと**を目的とする。

削らないもの:

- current Task固有のacceptance
- exact base / branch / Git safety
- concrete change target
- required verification
- explicit non-goal / stop conditionのうちimplementation driftを防ぐもの

削るもの:

- decorative formatting
- conversational filler
- duplicated rule text
- settled design history
- current sliceに無関係なfuture work
- ChatGPTが既に解決済みの調査過程

## Luna session selection

Lunaへimplementation / blocking-fix promptを提示するとき、ChatGPTはそのpromptをどのCoding Agent sessionへ渡すかをユーザーへ必ず明示する。

このsession instructionはLuna自身へのinstructionではなく、人間がどのsessionへpromptを渡すかを決めるためのhuman-facing instructionとする。Luna prompt本文には含めず、promptの外側に表示する。

Defaultは**new Luna session**とする。

Existing Luna sessionを再利用するのは、new sessionを開始するよりcurrent Work全体で消費するtokenを減らせるとChatGPTが確信できる場合だけとする。判断が不確実ならnew sessionを選ぶ。

Existing session reuseが適する典型例:

- same current executable sliceの直後のnarrow blocking-fix;
- same branch / same implementation contextをそのまま継続する;
- existing sessionが保持するrelevant contextにより、new sessionで必要になるcontext reconstruction / repeated explanationを明確に減らせる;
- accumulated stale / irrelevant contextによる追加reasoning costよりcontinuityによるtoken savingの方が明らかに大きい。

次の場合は原則new sessionを使う:

- new implementation slice;
- safe checkpoint後のnext slice;
- execution route / semantic owner / contractが変わった;
- remote advance等によりimplementation contextを大きくrefreshした;
- previous Luna runがbroad explorationやstale assumptionsを多く含む;
- existing session reuseとnew sessionのどちらがtoken-efficientか確信できない。

Session reuseはcontinuity自体を目的にしない。判断基準はcurrent Work全体でのexpected token consumptionとする。

ユーザーへpromptを提示するときは、promptの外側に少なくとも次のどちらかを明示する。

```text
Luna session: New session
```

または:

```text
Luna session: Reuse current session
Reason: <why reuse is expected to reduce total token consumption>
```

Reuseの場合だけ理由を短く添える。session selection lineやreasonをLuna prompt本文へ混ぜない。

## Cross-chat continuity

nuinuiCADのimplementation Taskを別ChatGPT conversationへ継続する場合、別途長いhandoff文を書くことをdefaultにしない。

current Task固有で次のconversationにも必要な確定事項は、通常はcurrent Linear Issueへcheckpointとして記録する。既存のrule / source-of-truth / repositoryから再取得できる情報はLinearへ重複保存しない。

Linearへ残す対象は、たとえば次のようなcurrent-state差分。

- completed acceptance / remaining acceptance
- current branch / PR / tested headなど、継続に必要なexecution state
- current blocker / verification result
- next safe slice / next execution route / intended base
- chat内で確定し、まだ他のdurable ownerに存在しないTask固有decision

新しいconversationはhandoff proseや過去チャットをsource of truthにせず、latest Project Context、latest remote repository、current Linear Issue / Commentを再取得して再開する。

ユーザーが明示的に「引き継ぎを書いて」と求めた場合でも、rule repoにある一般ruleを再掲せず、Linearやrepositoryから一意に復元できないcurrent Task固有事項だけを短くまとめる。

## Re-evaluation boundary

same Issueを複数sliceで進める場合、各safe checkpointで次のsliceを再分類する。

- direct GitHub + CI向きなら`only_chatgpt`
- local / integration-heavy implementationならLuna xhigh
- product / architecture判断が再発したらChatGPTへ戻す

一度Luna routeを選んだことを理由に、Issueの残り全体をLunaへ渡し続けない。
