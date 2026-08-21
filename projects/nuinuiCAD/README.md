# nuinuiCAD Project Context

Repository: `sayosomi/nuinuiCAD`

この README は ChatGPT Project から参照する固定入口。
Current task の SHA、branch、進捗、個別 implementation plan はここに書かない。

## Required context

開発作業では最初に次を読む。

- [Shared Development Workflow](../../shared/DEVELOPMENT.md)
- repository の current `AGENTS.md`

Coding Agent prompt 作成・skill 選択時は必要に応じて次も読む。

- [Shared Agent Skills](../../shared/AGENT-SKILLS.md)
- [nuinuiCAD-specific Agent Skills](./AGENT-SKILLS.md)

## Git worktree policy — nuinuiCAD exception

nuinuiCAD では primary repository checkout に加えて、並列実装用の**常設汎用 sub worktree を1つ**維持してよい。

現在の標準配置:

- primary: `/Users/yosomi/Code/nuinuiCAD`
- persistent sub: `/Users/yosomi/Code/nuinuiCAD-sub`

運用ルール:

- persistent sub は、primary で別Taskを進めている間に本当に並列実装する必要があるTaskへ使う。
- idle時の persistent sub は clean な状態を保ち、`origin/main` の latest commit を detached HEAD で checkoutして待機させる。
- subで新しいTaskを始める前に `git fetch origin --prune` を実行し、latest remote state と intended base を確認してから、そのTask専用branchを作る。
- Task完了・merge・中止後は、未commit変更がないことを確認してから persistent sub を detached HEAD の latest `origin/main` へ戻し、安全なら完了Taskのlocal branchを削除する。
- persistent sub 自体はTask完了後も削除しない。Shared Development Workflowの「一時worktreeは不要になったら削除する」ルールは、この常設sub以外の追加worktreeに適用する。
- 同じbranchを primary と persistent sub の両方でcheckoutしない。
- 常設subは1つだけとする。3本目以降のworktreeは真に追加の同時並列実装が必要な場合だけ作成し、不要になったらShared Development Workflowどおり削除する。
- unrelatedなuser changesや進行中Taskをreset / overwriteしてsubを再利用しない。cleanでない場合はblocking pointとして扱う。

## VS Code Manual E2E environment

VS Code extension の user-facing behavior を Manual E2E で確認するときは、**fresh profile + VS Code標準補完OFF + task-specific fixture込み**の isolated Extension Development Host を標準環境とする。普段使いの VS Code profile をそのまま使わない。

通常の user settings、word-based suggestions、inline suggestions、keybindings、installed extensions 等が結果へ混入すると、nuinuiCAD extension 自体の PASS / FAIL を判定できない。Manual E2E の起動手順は、毎回この baseline を再現できる一つのコピペ可能な command block として提示する。

運用ルール:

- Manual E2E の判定に使う VS Code は、毎回新しい `--user-data-dir` と空の `--extensions-dir` で起動する。
- E2E user-data を作る時点で VS Code built-in completion を無効化する。最低限 `editor.wordBasedSuggestions: "off"`、`editor.inlineSuggest.enabled: false`、`editor.quickSuggestions: false`、`editor.snippetSuggestions: "none"` を設定する。
- Task の Manual E2E fixture は同じ command block 内で `$E2E_ROOT` 配下へ生成し、その fixture file を起動時に明示的に開く。fixture は checkout/worktree を汚さない場所へ置く。
- Manual E2E の起動コマンドを提示するときは、`npm run build:vscode`、fresh user-data/extensions 作成、標準補完OFF settings 作成、task-specific fixture 作成、Extension Development Host 起動までを一つのコピペ可能な block に含める。ユーザーへ途中の手作業設定を要求しない。
- completion の Manual E2E は自動 popup の有無ではなく、必要に応じて `Trigger Suggest` を明示実行し、nuinuiCAD provider の候補を確認する。
- project の開発中 extension は `--extensionDevelopmentPath="$PWD/vscode-extension"` で読み込む。
- 起動前に current checkout で `npm run build:vscode` を実行する。
- rebuild、branch / commit 切り替え、blocking fix 後の再試験では、古い Extension Development Host を閉じてから fresh isolated host を起動し直す。
- 普段の VS Code 側で settings や extension を手動で無効化する方法を標準手順にしない。
- 通常 user profile でのみ再現する問題は、isolated environment の Manual E2E failure と混同せず、profile / interoperability 固有の別問題として扱う。
- Task-specific Manual E2E が意図的に既存 user settings / installed extensions との interoperability を検証する場合だけ、この isolated baseline に加えて別途 profile-dependent test を行う。

Canonical launch shape:

```bash
cd <nuinuiCAD checkout>
npm run build:vscode

E2E_ROOT="$(mktemp -d /tmp/nuinui-vscode-e2e.XXXXXX)"
mkdir -p "$E2E_ROOT/user-data/User" "$E2E_ROOT/extensions"

cat > "$E2E_ROOT/user-data/User/settings.json" <<'EOF'
{
  "editor.wordBasedSuggestions": "off",
  "editor.inlineSuggest.enabled": false,
  "editor.quickSuggestions": false,
  "editor.snippetSuggestions": "none"
}
EOF

cat > "$E2E_ROOT/<task-fixture>.nui" <<'EOF'
<task-specific fixture source>
EOF

code --new-window \
  --user-data-dir="$E2E_ROOT/user-data" \
  --extensions-dir="$E2E_ROOT/extensions" \
  --extensionDevelopmentPath="$PWD/vscode-extension" \
  "$PWD" \
  "$E2E_ROOT/<task-fixture>.nui"
```

macOS で `code` command が unavailable な場合も、fresh profile、標準補完OFF settings、fixture生成、同じ isolation flags を維持して VS Code executable を直接使う。

```bash
/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code --new-window \
  --user-data-dir="$E2E_ROOT/user-data" \
  --extensions-dir="$E2E_ROOT/extensions" \
  --extensionDevelopmentPath="$PWD/vscode-extension" \
  "$PWD" \
  "$E2E_ROOT/<task-fixture>.nui"
```

## Repository-owned sources of truth

- 実装済みの事実・actual code: latest `sayosomi/nuinuiCAD` repository
- repository engineering policy: `AGENTS.md`
- current architecture / navigation index: `ARCHITECTURE.md`
- normative nui4 language contract: `docs/nui4/spec.md`
- implemented user-facing DSL documentation: `docs/dsl.md`

実装事実について、管理文書・過去チャット・work-management system と repository が矛盾する場合は latest repository を authoritative とする。

## Work / specification management

現在のWork / specification管理は Linear を正式な管理先とする。
LinearはFree plan前提で運用し、closed itemの早期archiveによるIssue枠管理を明示的な運用制約とする。

- 作業予定・進捗・調査結果: Linear Issue / Project
- 長期的に参照する仕様・設計: Linear Document
- [Linear workflow](./LINEAR.md)
- [Implementation contract decision rule](./CONTRACT-DECISIONS.md)
- [Linear free-plan capacity policy](./LINEAR-CAPACITY.md)
- [GitHub Issues public mirror / sync](./GITHUB-ISSUES-SYNC.md)
- [Legacy Notion archive](./NOTION-LEGACY.md) — 移行前の履歴参照専用

Notion は新規Work / Specの管理先には使わない。
ただし、移行前から進行中のTaskが特定の未移行Notion Specを明示的なsource of truthとして開始済みの場合、そのTaskの次の明確なcheckpointまでは参照を継続してよい。checkpoint後にLinear Documentへ移行し、Task側の参照先も更新する。

新しい開発 Task の開始時は、GitHub remote state と既存 Linear Issue / Project / Document を確認してから implementation contract を策定する。

## User-facing command design

新しい user-facing command を追加・仕様策定するときは、実装前の command contract で command surface を明示する。

最低限、次を必ず決める。

- user-facing command name / title は英語に統一する。VS Code の `contributes.commands[].title`、Command Palette、context menu、Ribbon 等で表示される command 名を日本語にしない。internal command ID も英語を維持する。
- VS Code command は既存 `AGENTS.md` ruleどおり `Global | Source | Canvas | Source+Canvas` の Palette scope を明示する。
- 右クリック context menu へ出すかどうかを必ず明示する。`Context menu: None` は正当な選択肢であり、右クリックへ出す必要がない command を無理に追加しない。
- context menu へ出す場合は、どの context で表示するかと、その visibility 条件を contract に書く。Source Editor / blank Canvas / Canvas element / Canvas Ribbon 等、実際に存在する surface/context だけを使い、未確定 surface を先取りしない。
- Command Palette visibility と context-menu visibility は別契約として扱う。Palette は surface relevance を表し、selection / caret / semantic target 等の transient state で細かく出し分けない。一方 context menu は現在の文脈に合う操作だけを出すため、必要な transient / semantic state で絞り込んでよい。
- Source Editor の nuinuiCAD context command は、別途明示しない限り右クリックした座標ではなく current caret position (`activeTextEditor.selection.active`) を target / semantic context の基準にする。
- menu / Ribbon / shortcut / button 用に command business logic を複製せず、同じ command implementation を再利用する。

既存 command を改修する Task でも、その Task が command surface を変更する場合は同じ観点で再確認する。

## 連続 Task の前 Task PR merge 確認

連続 Task で前 Task に Pull Request がある場合、次 Task の Coding Agent へ実装指示を出す前に、その Pull Request が GitHub 上で merge 済みか必ず確認する。

- 未 merge: repository 調査、Linear 確認、implementation contract 策定までは進めてよいが、Coding Agent に実装開始を指示しない。
- merge 済み: merge 後の latest remote `main` を再確認し、それを次 Task の実装 base とする。

## Loading rule

毎回すべての linked document を読む必要はない。

1. この README を読む。
2. 開発 Task では `shared/DEVELOPMENT.md` と repository の current `AGENTS.md` を読む。
3. Coding Agent / skill が関係する場合だけ Agent Skills を読む。
4. Linear を操作・参照する場合、またはimplementation contractを策定する場合は `LINEAR.md`、`CONTRACT-DECISIONS.md`、`LINEAR-CAPACITY.md`、`GITHUB-ISSUES-SYNC.md` を読む。
5. legacy履歴または明示的な移行中例外でNotionを参照する場合だけ `NOTION-LEGACY.md` を読む。
6. current implementation / architecture / DSL を確認する場合は、必ず latest repository から取得する。
