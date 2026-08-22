# Shared Agent Prompt Style

複数projectで共通利用する、ChatGPTからexecution agentへ渡すpromptのlanguage / presentation style contract。

この文書はpromptの**styleだけ**を所有する。agentのrole、許可されたoperation、workflow、test oracle、implementation contract、Git write権限を決めない。それらはcurrent Taskとrole-specific owner documentに従う。

## Style contract

Agent promptのstyleはhard contractとして扱う。

- promptは英語で書く。
- plain textと必要最小限のstructural formattingだけを使う。
- presentation目的のdecorative Markdown、emoji、ornamental heading、decorative separator、blockquote、emphasisを使わない。
- direct imperative languageを使う。`please`、`could you`、`would you`などのpolite / request phrasingを使わない。
- 日本語を含める場合も「お願いします」「〜してください」などの敬語・依頼表現を使わず、「〜する」「〜を実行する」のようなplain / direct phrasingを使う。
- headingsは可読性に必要な最小限だけ使う。
- unnecessary rhetoric / conversational fillerを入れない。
- same constraintを別表現で繰り返さない。
- current agent roleの実行に不要なbackground、settled design history、shared ruleの一般論を長く再掲しない。
- readabilityやconversational toneを理由にこのstyle ruleを弱めない。

Agent promptをユーザーへ提示する前に、英語で書かれていること、decorative formattingがないこと、polite / request phrasingがないことを確認する。

## Role boundary

このstyle contractを読んだことは、agentへimplementationやrepository mutationを許可しない。

特に、この文書から次を推論しない。

- implementation codeを変更してよい
- failureをfixしてよい
- commit / pushしてよい
- architecture / product designを調査・決定してよい
- test planやoracleを変更してよい

Allowed operationsはrole-specific authorityで決める。

例:

- implementation / blocking-fix agent: [`CODING-AGENT-WORKFLOW.md`](./CODING-AGENT-WORKFLOW.md) とproject-specific implementation contract
- Manual E2E test operator: project-specific Manual E2E authority / playbook

同じCoding Agent productを使っていても、implementation agentとtest operatorは別roleとして扱う。

## Loading rule

1. ChatGPTがexecution agent向けpromptを生成するときは、この文書を読む。
2. その後、current agent roleに対応するowner documentだけを追加で読む。
3. Role-specific ownerがoperationを禁止している場合、このstyle文書を根拠に許可へ広げない。

## Maintenance rule

Promptのlanguage / formatting / directnessに関するshared ruleだけをここに置く。

Implementation responsibility、Git workflow、Manual E2E execution semanticsなどのrole-specific ruleをこの文書へ積み上げない。
