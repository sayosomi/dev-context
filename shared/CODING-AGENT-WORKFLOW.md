# Shared Implementation Coding Agent Workflow

複数projectで共通利用する、implementation / blocking-fixを担当するCoding Agentの役割分担、implementation prompt、continuity rule。

この文書は**implementation agent専用**。Manual E2E test operatorなど、repository implementationを変更しないexecution roleには適用しない。

Project固有のrepository policy、task contract、Agent skill ruleがある場合はそちらを優先する。Agent promptのlanguage / formattingは [`AGENT-PROMPT-STYLE.md`](./AGENT-PROMPT-STYLE.md) に従う。

Projectがimplementation Coding Agentのdefault product / reasoning effort / resource policyを定義している場合は、そのproject-specific authorityを使う。ユーザーまたはcurrent Taskの明示指定はproject defaultより優先する。Project-specific defaultがない場合、このshared workflowだけを根拠に特定Coding Agent product / effortを仮定しない。

## Role boundary

ChatGPTが担当する。

- repository調査
- architecture把握
- actual owner / change locationの特定
- implementation contract決定
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

## Implementation prompt

current implementation Taskの実行に必要な情報だけを書く。

原則として次を渡す。

- repository
- expected remote state
- branch / base
- change target
- concrete required changes
- required tests / verification
- commit / push requirement
- blocking conditions

Promptのlanguage / formatting / directnessは [`AGENT-PROMPT-STYLE.md`](./AGENT-PROMPT-STYLE.md) をauthorityとする。

Implementation promptでは次を省略しない。

- Git safety condition
- blocking condition
- current Task固有のacceptance

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
2. 新規Issueを作る前にbranch名を決め、implementation promptを完成させてユーザーへ提示する。
3. branch名を、まだ存在しないIssue identifierやwork-management system生成branch名へ依存させない。
4. project-specific default agent / effortがあればそれを使い、ユーザーまたはcurrent Taskの明示overrideがあればそちらを使う。defaultがない場合は特定Coding Agent productを前提にしない。
5. Coding Agent実行中に、ChatGPTが必要なIssue create / description / Project / status等のmanagement workを行う。

existing Issue / Specのreadがcontract確定に必要なら先に行う。後回しにするのは、contract確定後の新規Issue createやstatus update等、Coding Agent開始を待たせる必要のないmanagement action。

existing IssueがあるTaskはそのIssueを再利用するが、management updateだけを理由にprompt提示を遅らせない。

## Execution boundary

- Implementation Coding Agentは確定済みcontractに従いimplementation / test / git作業を行う。
- current Task scope外のcleanup / future workを先取りしない。
- implementation後はChatGPTがrequired blocking review / verificationを行う。
- blocking issueのfixはcurrent planに従う。Coding Agentへproduct redesignを委ねない。
- commit / push / branch / review ruleは [`GIT-WORKFLOW.md`](./GIT-WORKFLOW.md) を参照する。

Agent skillを使う場合は [`AGENT-SKILLS.md`](./AGENT-SKILLS.md) とproject固有skill policyからcurrent Taskに必要なものだけ選ぶ。

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
