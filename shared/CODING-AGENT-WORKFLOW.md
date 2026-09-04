# Shared Implementation Coding Agent Workflow

複数projectで共通利用する、implementation / blocking-fixを担当するCoding Agentの役割分担、implementation prompt、continuity rule。

この文書は**implementation agent専用**。Manual E2E test operatorなど、repository implementationを変更しないexecution roleには適用しない。

Project固有のrepository policy、task contract、Agent skill ruleがある場合はそちらを優先し、shared ruleよりstricterなrequirementを追加できる。ただし、このshared completeness gateを省略してunder-specified promptをexecutableに扱ってはならない。Agent promptのlanguage / formattingは [`AGENT-PROMPT-STYLE.md`](./AGENT-PROMPT-STYLE.md) に従う。

Projectがimplementation Coding Agentのdefault product / reasoning effort / resource policyを定義している場合は、そのproject-specific authorityを使う。ユーザーまたはcurrent Taskの明示指定はproject defaultより優先する。Project-specific defaultがない場合、このshared workflowだけを根拠に特定Coding Agent product / effortを仮定しない。

## Role boundary

ChatGPTが担当する。

- repository調査
- architecture把握
- actual owner / change locationの特定
- implementation contract決定
- implementation prompt completenessの判定
- blocking review
- ChatGPTで実行できる調査・設計・管理作業

ChatGPTで実行できる調査・設計・管理作業をimplementation Coding Agentへ回さない。

Implementation Coding Agentにはarchitecture調査をさせない。ChatGPTが確定したcontractに従い、具体的なimplementation / test / git作業だけを依頼する。

Implementation promptに次のようなopen-ended design instructionを入れない。

- architectureを調査する
- existing implementationを探してdesignを決める
- alternate designを探索する

Git remote/local同期確認、working tree確認、指定fileの確認はarchitecture調査ではない。

Git safety / remote-state preflightは [`GIT-WORKFLOW.md`](./GIT-WORKFLOW.md) に従う。

## Pre-prompt remote freshness gate

Implementation Coding Agent向けpromptを作成・提示する**前**に、ChatGPTは [`GIT-WORKFLOW.md`](./GIT-WORKFLOW.md) のChatGPT-side handoff freshness checkを実行する。

repository調査、contract策定、previous checkpoint、過去チャットで取得したremote SHAを、そのままimplementation promptのexpected baseへ転記しない。promptに書くexpected base / remote stateは、このpre-prompt checkで再取得したauthoritative remote stateから決める。

preparation中にauthoritative remote stateがadvanceしていた場合:

- intervening changesがcurrent Taskのcontract / semantic owner / slicingへ影響するか、promptを書く前にChatGPTが判断する;
- unrelated changeだけでcontractが維持できる場合は、expected baseを新しいremote stateへ更新してからpromptを作る;
- relevant changeまたは影響が一意に判断できない場合は、prompt生成を止めてcontract / sliceを再評価する。

このgateを通過してからimplementation promptを作成・提示する。Coding Agent側の`git fetch origin --prune`は、このcheck後からagent開始までのraceを検出するsecond safety checkであり、ChatGPT-side pre-prompt checkの代替ではない。

## Implementation prompt

Implementation promptはhigh-level task descriptionではなく、executable implementation contractとして扱う。current implementation Taskの実行に必要な情報だけを書く。

### Prompt-completeness gate

Handoff前に、ChatGPTはcurrent Taskがmissing architecture / product / contract decisionをCoding Agentへ委ねずに実行できる具体性を持つことを確認する。`implement feature X`、`fix Issue X`、`follow the Issue`、または同等のhigh-level wordingだけではgateを通過しない。

次のcontract fieldsをすべて埋めてgateを通過させる。各fieldは、適用されない場合だけcurrent Taskに即した理由を明記してinapplicableとできる。未確定のowner、boundary、behavior、decisionを省略してはならない。このgateはfail-closedであり、under-specified implementation contractをhandoffしてはならない。

`expected remote state`と`branch / base`は、先行する`Pre-prompt remote freshness gate`でestablishまたはrevalidateされた値を使う。freshness前のobservationだけでは、このfinal completeness gateを満たさない。

- repository
- expected remote state
- branch / base
- concrete semantic owner and change boundary
- concrete required changes
- Task-specific acceptance criteria
- required tests / verification
- explicit non-goals
- Git safety conditions
- commit / push requirement
- blocking / stop conditions
- required completion report

`concrete semantic owner and change boundary`には、適用される場合、exact files、symbols、API boundaries、data contracts、state transitions、persistence boundaries、またはその他のconcrete implementation targetsを含める。意味のあるboundaryが本当に存在しないTaskではその理由を示すが、unspecified boundaryをCoding Agentの調査へ委ねてはならない。

`concrete required changes`には、feature名やIssue番号だけでなく、Taskに必要なobservable behaviorとrelevant data、state、validation、error、compatibility、side-effect semanticsを含める。

`Task-specific acceptance criteria`はTask完了時にtrueであるべきことを定義し、`required tests / verification`はそのacceptanceをどのtest、command、oracle、またはevidenceで証明するかを定義する。acceptanceとverificationを同じ曖昧なstatementで代用しない。

`explicit non-goals`はgeneric policyの反復ではなく、current executable scopeをboundするTask-specificな除外事項として必須にする。

`Git safety conditions`には、Coding Agent側の`git fetch origin --prune`、expected remote stateとの照合、cleanなintended checkout、mismatch時のreset / rebase / merge / force-pushによるrecovery禁止、および指定branchへの通常のcommit / push条件を含める。詳細なprocedureは [`GIT-WORKFLOW.md`](./GIT-WORKFLOW.md) に従う。

required architecture、product、design decisionが未確定、またはcontractがこのgateを満たさない場合、ChatGPTはhandoffせず調査またはcontract workを継続する。Coding Agentをmissing ChatGPT-side investigationの代替にせず、incomplete promptを実行可能にするためのalternate design探索やarchitecture決定をCoding Agentへ指示しない。

Promptのlanguage / formatting / directnessは [`AGENT-PROMPT-STYLE.md`](./AGENT-PROMPT-STYLE.md) をauthorityとする。

## Excluded execution roles

Manual E2E test-operator promptはこのworkflowの対象外。

Manual E2E operatorへ、この文書を根拠として次を追加しない。

- change target
- concrete required changes
- implementation fix
- commit / push requirement
- blocking failureのrepair

Manual E2Eではproject-specific Manual E2E authority / playbookをrole authorityとし、shared prompt styleだけ [`AGENT-PROMPT-STYLE.md`](./AGENT-PROMPT-STYLE.md) から適用する。

同じCoding Agent productをimplementationとManual E2Eの両方に使う場合も、roleを混同しない。

## Prompt and work-management ordering

新規開発Taskでwork-management Issueの新規作成が必要でも、Issue作成をimplementation Coding Agent開始の前提にしない。

1. remote state確認、existing Issue / Spec検索、repository調査を行い、implementation contractを確定する。
2. `Pre-prompt remote freshness gate`を通過する。
3. expected remote state / branch / baseをfreshness gateの結果でrefreshし、relevantなremote changeがcurrent Taskのcontract / semantic owner / slicingへ影響する場合は再評価する。branch名は、まだ存在しないIssue identifierやwork-management system生成branch名へ依存させずに決める。
4. `Prompt-completeness gate`を、finalなimplementation-contract completeness approvalとして通過する。
5. 両gateを通過した後だけimplementation promptを完成・提示する。新規Issueが必要な場合も、branch名を決めてpromptを完成させてからIssueを作る。
6. project-specific default agent / effortがあればそれを使い、ユーザーまたはcurrent Taskの明示overrideがあればそちらを使う。defaultがない場合は特定Coding Agent productを前提にしない。
7. Coding Agent実行中に、ChatGPTが必要なIssue create / description / Project / status等のmanagement workを行う。

existing Issue / Specのreadがcontract確定に必要なら先に行う。後回しにするのは、contract確定後の新規Issue createやstatus update等、Coding Agent開始を待たせる必要のないmanagement action。

existing IssueがあるTaskはそのIssueを再利用するが、management updateだけを理由にprompt提示を遅らせない。

## Execution boundary

- Implementation Coding Agentは確定済みcontractに従いimplementation / test / git作業を行う。
- settled scopeをsilently broadenしてはならない。current contractに明示的に含まれないunrelated refactoring、cleanup、dependency addition / change、architecture change、product / design change、future-work implementationを行わない。これらはcurrent contractが明示的にauthorizeした場合に限り許可される。
- 実行中に、settled contractが許可していないmaterialなdesign choice、architecture change、dependency change、またはscope expansionが必要になった場合は、Coding Agentは独自判断せず`BLOCKED`として報告する。
- settled contractを満たすために必要なnarrowなimplementation-side diagnosisとfixはCoding Agentのworkに含まれ、これを禁止事項と解釈しない。
- implementation後はChatGPTがrequired blocking review / verificationを行う。
- blocking issueのfixはcurrent planに従う。Coding Agentへproduct redesignを委ねない。
- commit / push / branch / review ruleは [`GIT-WORKFLOW.md`](./GIT-WORKFLOW.md) を参照する。

Agent skillを使う場合は [`AGENT-SKILLS.md`](./AGENT-SKILLS.md) とproject固有skill policyからcurrent Taskに必要なものだけ選ぶ。

## Completion report

Coding Agentはimplementation runの完了時に、applicableな次の事項を報告する。

- branch
- base
- final HEAD
- changed files
- concise implementation summary
- each required verificationとそのresult
- 各acceptance criterionがどのようにcoveredされたか
- scope deviation（なければnone、あればexactな内容）
- remaining blockersまたはresidual risks（なければnone、あればexactな内容）

normal successful completionでは、scope deviationがないこととremaining blockerがないことを明示する。

## Continuity and user-facing handoff

Durable policyやproject-wide workflowをchat-specific handoffへ複製しない。次のconversation / executionが必要とするcurrent Task固有の確定事項は、projectがwork-management / specification sourceを持つなら、そのdurable ownerへcheckpointで記録する。

別のChatGPT conversationやexecution trackへ継続するためだけに、毎回user-facing handoff文を書くことを標準工程にしない。次のconversationはcurrent Project Context、latest remote repository、work-management / spec sourceを再取得して再構成する。

ユーザーが明示的にhandoff文を求めた場合、またはdurable current-state storeが存在しない場合だけ、handoffはcurrent Task固有の差分に限定する。必要に応じて含めるのは次のような情報。

- current Task / Work identifier
- current branch / PR / headなど、durable management sourceから一意に復元できないexecution state
- completed acceptance / remaining acceptance
- current blocker / verification result
- next safe action
- current Taskだけに適用されるexception / override

通常のrole boundary、Git / worktree rule、prompt style、project-wide source-of-truth ruleをhandoffへ再掲しない。これらはowner documentを再読する。

Handoff文そのものをsource of truthにしない。handoffとlatest repository / durable project recordが矛盾する場合は、current authorityを再取得して判断する。
