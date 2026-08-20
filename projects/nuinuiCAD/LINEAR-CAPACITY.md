# nuinuiCAD Linear capacity policy

LinearはFree plan前提で運用する。
Free planのIssue数制限を、Work管理上の明示的な制約として扱う。

## Archive policy

- closed itemは早くarchiveへ退避し、activeなIssue枠を圧迫させない。
- Sayosomi Teamの`Auto-archive closed items after`は原則`1 month`を維持する。
- 後から参照・Manual E2Eする可能性だけを理由に、auto-archive期間を長くしない。
- Manual E2Eを後回しにしている実装Issueは`In Review + Manual E2E: Deferred`で未完了として保持する。Deferredのまま`Done`へ進めないため、通常のclosed-item archive対象にもならない。
- 必要なManual E2Eが`Passed`、または`Not Required`となって`Done`へ進んだ後は通常どおりarchive対象にしてよい。
- Project内の必要Issueが完了したらProjectも速やかにCompletedへ進め、ProjectがIssueのauto-archiveを妨げないようにする。

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

## Change policy

Free plan前提、auto-archive期間、stale auto-close方針を変更する場合は、ChatGPTが独断で変更・推奨せず、ユーザーと運用上の理由を確認してから変更する。
