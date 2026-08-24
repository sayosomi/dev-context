# Shared Agent Skills

複数 project で再利用できる Agents custom skill の説明。
Skill は parent task、project 固有の `AGENTS.md`、task contract、repository 固有の plan / instructions を上書きしない。

## Keep Task Scope Tight

`keep-task-scope-tight`

親 Task の scope を守るための skill。

- parent task / acceptance / non-goal / deferred work を scope contract として扱う。
- 調査は広く行ってよいが、変更は current task に必要な範囲だけにする。
- 「ついでの cleanup」「future-proofing」「後続 Task の先取り」を防ぐ。
- 発見した問題を current / caused-by-task / deferred / unrelated に分ける。
- current task が完了したら追加作業を始めず止まる。

## Reuse Existing Architecture

`reuse-existing-architecture`

既存 architecture を再利用し、同じ概念の二重実装を防ぐ skill。

- 新しい parser / resolver / index / evaluator / serializer / state model 等を作る前に既存 owner を確認する。
- 既存 API の reuse → narrow extension → thin adapter を優先する。
- 同じ semantic concept について second source of truth を作らない。
- resolved identity / canonical path / compiled reference 等を下流で再解決せず引き継ぐ。
- UI / CLI / Automation / tests のためだけの parallel implementation を防ぐ。
- parent task が architecture 変更を要求する場合は、既存 owner を適切な境界で変更する。

## Keep Code Context Small

`keep-code-context-small`

変更の置き場所・責務分割を判断する skill。

判断優先順位:

1. Parent-task scope and existing ownership
2. Responsibility and cohesion
3. Ease of independent testing/reasoning
4. File size

- file size は signal にすぎない。
- 行数閾値だけで task 外 refactor を始めない。
- 既存 owner に自然に収まる小さな変更なら、大きな file でも local edit を優先する。
- 新しい独立責務が生まれた場合だけ narrow module への分離を検討する。

## Fix Precommit Errors

`fix-precommit-errors`

required verification gate が失敗したときの修理 skill。

- parent task / user が指定した required gate を最優先する。
- 明示された command を勝手に別 command へ置換しない。
- failure evidence から原因を調査する。
- focused check → directly related required gate → required full gate の順で再検証する。
- unrelated / pre-existing failure を勝手に修正しない。
- lint / test / type safety を弱めて通さない。
- repository 固有の change-aware verification を尊重する。
- active parent task が作った intended changes は修理対象にしてよいが、それ以前からある unrelated user changes は保護する。
- commit / push / PR / cleanup は parent task が要求した場合だけ行う。

## Review Against Contract

`review-against-contract`

実装後の blocking review 用 skill。

source of truth:

- parent task
- specification
- established plan
- explicit constraints
- acceptance criteria
- explicit non-goals / deferred work

確認すること:

- required behavior の missing implementation
- explicit constraint 違反
- unintended semantic change
- scope creep
- deferred work の先取り
- 不要な compatibility hack
- duplicate architecture
- task 外 refactor
- tests が changed contract を十分固定しているか
- 必要な場合、production path が実際に新実装を使っているか

blocking ではないもの:

- optional cleanup
- naming preference
- speculative robustness
- future improvement
- deferred work
- unrelated pre-existing issue
- 単なる別設計案

blocking issue がなければ PASS。
blocking issue 修正後はその修正と直接影響範囲を確認し、「念のため」で全面 review を何度も繰り返さない。

## Skill selection

一般的な Task 実装:

- `keep-task-scope-tight`
- `reuse-existing-architecture`
- 必要なら `keep-code-context-small`

required gate failure 修正:

- `fix-precommit-errors`

実装後 blocking review:

- `review-against-contract`

Human向けterminal instruction generation:

- dedicated skill identifier: `human-terminal-instructions`
- trigger: ChatGPTがHumanにcopy/pasteして実行してもらうterminal command / shell scriptを生成するとき。
- activation: skill本文がrepositoryに追加された後は、このtriggerに該当する生成で常に適用する。
- skill本文がまだ存在しない間はidentifierだけからshell-specific ruleを推測してnormative behaviorとして扱わない。

project 固有の追加 skill がある場合は、その project の `AGENT-SKILLS.md` を参照する。
