# Shared Coding Agent Workflow

複数projectで共通利用するChatGPT / Coding Agentの役割分担、implementation prompt、handoff rule。

Project固有のrepository policy、task contract、Agent skill ruleがある場合はそちらを優先する。

## Role boundary

ChatGPTが担当する。

- repository調査
- architecture把握
- actual owner / change locationの特定
- implementation contract決定
- blocking review
- ChatGPTで実行できる調査・設計・管理作業

ChatGPTで実行できる調査・設計・管理作業をCoding Agentへ回さない。

Coding Agentにはarchitecture調査をさせない。ChatGPTが確定したcontractに従い、具体的なimplementation / test / git作業だけを依頼する。

Coding Agent向けpromptに次のようなopen-ended design instructionを入れない。

- architectureを調査する
- existing implementationを探してdesignを決める
- alternate designを探索する

Git remote/local同期確認、working tree確認、指定fileの確認はarchitecture調査ではない。

Git safety / remote-state preflightは [`GIT-WORKFLOW.md`](./GIT-WORKFLOW.md) に従う。

## Implementation prompt

current Taskの実行に必要な情報だけを書く。

原則として次を渡す。

- repository
- expected remote state
- branch / base
- change target
- concrete required changes
- required tests / verification
- commit / push requirement
- blocking conditions

promptは英語で書く。

英語はsimple and directにし、短い命令文を基本とする。

Coding Agent promptのstyleはhard contractとして扱う。

- plain textと必要最小限のstructural formattingだけを使う。presentation目的のdecorative Markdown、emoji、ornamental heading、decorative separator、blockquote、emphasisを使わない。
- direct imperative languageを使う。`please`、`could you`、`would you`などのpolite / request phrasingを使わない。
- 日本語を含める場合も「お願いします」「〜してください」などの敬語・依頼表現を使わず、「〜する」「〜を実行する」のようなplain / direct phrasingを使う。
- readabilityやconversational toneを理由にこのstyle ruleを弱めない。

避けるもの:

- unnecessary rhetoric / conversational filler
- decorative separators such as `====` / `----`
- headings beyond the minimum needed for readability
- same constraint repeated in different wording
- implementationに不要なlong background / settled design history
- shared rule / skillの一般論をcurrent Taskで不要なのに再掲すること

省略しないもの:

- Git safety condition
- blocking condition
- current Task固有のacceptance

Coding Agent promptをユーザーへ提示する前に、decorative formattingとpolite / request phrasingが残っていないことを確認する。

## Prompt and work-management ordering

新規開発Taskでwork-management Issueの新規作成が必要でも、Issue作成をCoding Agent開始の前提にしない。

1. remote state確認、existing Issue / Spec検索、repository調査を行い、implementation contractを確定する。
2. 新規Issueを作る前にbranch名を決め、Coding Agent promptを完成させてユーザーへ提示する。
3. branch名を、まだ存在しないIssue identifierやwork-management system生成branch名へ依存させない。
4. ユーザーが選んだCoding Agentでimplementation開始できる状態を先に作る。特定Coding Agent productを前提にしない。
5. Coding Agent実行中に、ChatGPTが必要なIssue create / description / Project / status等のmanagement workを行う。

existing Issue / Specのreadがcontract確定に必要なら先に行う。後回しにするのは、contract確定後の新規Issue createやstatus update等、Coding Agent開始を待たせる必要のないmanagement action。

existing IssueがあるTaskはそのIssueを再利用するが、management updateだけを理由にprompt提示を遅らせない。

## Execution boundary

- Coding Agentは確定済みcontractに従いimplementation / test / git作業を行う。
- current Task scope外のcleanup / future workを先取りしない。
- implementation後はChatGPTがrequired blocking review / verificationを行う。
- blocking issueのfixはcurrent planに従う。Coding Agentへproduct redesignを委ねない。
- commit / push / branch / review ruleは [`GIT-WORKFLOW.md`](./GIT-WORKFLOW.md) を参照する。

Agent skillを使う場合は [`AGENT-SKILLS.md`](./AGENT-SKILLS.md) とproject固有skill policyからcurrent Taskに必要なものだけ選ぶ。

## Handoff

ユーザーが「引き継ぎを書いて」と依頼した場合、少なくとも次を含める。

- ChatGPT / Coding Agent role boundary
- remote state verification
- worktreeは真に同時並行の複数implementationが必要な場合だけ使い、不要になったら即削除する原則
- commit / push
- prompt concise rule
- current project固有のwork-management / source-of-truth rule
