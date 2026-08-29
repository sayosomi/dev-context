# Execution handoff authority

## Purpose

Implementation Coding Agentへ渡すcurrent-run execution stateのauthorityと、retained / stale contextがexpected stateへ混入することを防ぐruleを定義する。

このdocumentはpromptのpresentation styleではなく、**expected-state provenance**をownerする。Git remote freshness自体は[`GIT-WORKFLOW.md`](./GIT-WORKFLOW.md)、implementation roleは[`CODING-AGENT-WORKFLOW.md`](./CODING-AGENT-WORKFLOW.md)、prompt language / formattingは[`AGENT-PROMPT-STYLE.md`](./AGENT-PROMPT-STYLE.md)をauthorityとする。

## Core rule

Coding Agentがrepository operation前に使うexpected branch / Base / checkpoint / remote main / execution phase等は、**current handoffで明示的に注入されたexecution envelopeだけ**から得る。

次をexpected stateのsourceにしない。

- previous Coding Agent sessionのtask state;
- retained conversation / project context;
- past Issue checkpointや過去chat;
- branch historyからの推測;
- same Issueで以前使ったbranch / SHA;
- agent自身が「current Taskだと思う」state。

`New session`はcontext hygieneでありauthority boundaryではない。New sessionでもretained / stale task stateが存在し得る前提でhandoff safetyを設計する。

## Execution identity

Issue identifierだけをexecution identityにしない。

same Issueがsequential slice / PR / integration / blocking fixを持つ場合、current runを少なくとも次の組み合わせで識別する。

- Issue;
- current slice;
- execution phase;
- assigned lane / checkout;
- exact current checkpoint or equivalent immutable execution token;
- projectがdurable claim / generation tokenを持つ場合はそのtoken。

Project固有policyがより強いidentityを定義する場合はそちらを使う。

## Execution envelope

ChatGPTはCoding Agent prompt内にcurrent-run execution envelopeを明示する。

Envelopeにはcurrent runの実行に必要なidentity / checkpointだけを入れ、過去sliceの値をhistoryとして併記しない。

Projectがversioned handoff-check helperを持つ場合、expected stateをagentに自然言語から再構成させず、ChatGPTが確定値を埋めた**exact helper invocation**をenvelope内へ置く。

Coding Agentはそのcommandをそのまま最初に実行し、同じ値を別のmemory / session stateから再生成しない。

## Stale execution context

Coding Agent内のretained stateとcurrent execution envelopeが食い違うsignalが出た場合、repository mutation前に`STALE_EXECUTION_CONTEXT`として停止する。

典型例:

- current envelopeと異なるbranch / checkpointをagentがexpectedとして提示した;
- helperのcaller-supplied identityとdurable lane claimが一致しない;
- same Issueのolder slice branch / SHAがcurrent expected stateとして現れた。

このfailureはactual repository stateをrepairする理由にしない。reset / stash / checkout / merge / rebase / force操作へ進まず、current envelopeとactual evidenceをChatGPTへ返す。

## Preflight reporting

Expected / actualを報告する場合、expected値のprovenanceを曖昧にしない。

- current envelope / exact helper invocationから来た値: `HANDOFF_EXPECTED`または`CALLER_EXPECTED`;
- repository / laneから観測した値: `ACTUAL`;
- agent memory由来の値はexpectedとして扱わない。

## Freshness layering

このruleはChatGPT-side pre-prompt freshness gateを置き換えない。

```text
ChatGPT authoritative remote / management reconstruction
-> current execution envelope生成
-> exact helper invocation生成
-> Coding Agent-side mechanical verification
-> implementation / integration operation
```

Coding Agent-side verificationはhandoff生成後のrace / stale execution contextを検出するsecond safety layerである。

## Maintenance rule

このdocumentはexecution handoff stateのprovenanceだけをownerする。lane semantics、Git mutation、implementation slicing、session selection、prompt styleの詳細を複製しない。
