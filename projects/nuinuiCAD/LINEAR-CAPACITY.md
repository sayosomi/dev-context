# nuinuiCAD Linear capacity policy

LinearはFree plan前提で運用する。
Free planのIssue / Project capacityを、Work管理上の明示的な制約として扱う。

## Archive policy

- closed itemは早くarchiveへ退避し、activeなIssue枠を圧迫させない。
- Sayosomi Teamの`Auto-archive closed items after`は原則`1 month`を維持する。
- 後から参照・Manual E2Eする可能性だけを理由に、auto-archive期間を長くしない。
- Manual E2Eを後回しにしている実装Issueは`In Review + Manual E2E: Deferred`で未完了として保持する。Deferredのまま`Done`へ進めないため、通常のclosed-item archive対象にもならない。
- 必要なManual E2Eが`Passed`、または`Not Required`となって`Done`へ進んだ後は通常どおりarchive対象にしてよい。
- pure tracking parentを長期間維持しない。scope / acceptanceをleaf Issueへ完全に移したtracking shellは [`LINEAR-ISSUES.md`](./LINEAR-ISSUES.md) のdecomposition / parent-handling ruleに従って整理する。

## Project capacity

ProjectはFree plan capacity上の通常管理単位にしない。作成・assignment・cleanupのauthorityは [`LINEAR-PROJECTS.md`](./LINEAR-PROJECTS.md)。

- Projectは原則作らない。
- Issue relationで十分ならProjectなしで管理する。
- 例外的に使うProjectは極短期aggregate trackingに限る。
- aggregate trackingの役目が終わったら速やかにCompletedへ進め、不要なProjectを長期間保持しない。
- category / roadmap / historyのためにProjectを常設しない。

## Stale issue policy

- `Auto-close stale issues`は原則OFFとする。
- `Contract: Pending` / `Contract: Blocked` / dependency待ちのIssueを、長期間更新されていないことだけを理由にCanceledへ移さない。
- `In Review + Manual E2E: Deferred`も、E2E待ちであることだけを理由にstale closeしない。
- 不要になったIssueを閉じる場合は、stalenessではなくWorkとして不要になったことを確認してからCanceledへ進める。

## Issue count policy

- 新規Issue作成前に既存Issueを検索する。
- まだ独立Workとして管理する必要がない軽い思いつきは、原則`SAY-55 — Idea Inbox — future work / 思いつきメモ`へ入れる。
- Issue枠に余裕があることだけを理由にIdea Inboxの項目を機械的にIssue化しない。
- 完了済みWorkをactive側へ長期間残さない。
- `In Review + Deferred`は未完了Workなので、Issue枠節約だけを理由にDoneへ進めない。
- feature scopeをleaf Issueへ完全移管しただけの元Issueを、aggregate progress表示のためだけにtracking parentとして保持しない。

## Change policy

Free plan前提、auto-archive期間、stale auto-close方針を変更する場合は、ChatGPTが独断で変更・推奨せず、ユーザーと運用上の理由を確認してから変更する。
