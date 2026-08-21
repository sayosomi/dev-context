# nuinuiCAD user-facing command contract policy

## Purpose

新しいuser-facing commandを追加・仕様策定するとき、または既存commandのsurfaceを変更するときに、implementation contractへ必ず含める観点を定義する。

Repositoryのdurable engineering ruleはcurrent [`AGENTS.md`](https://github.com/sayosomi/nuinuiCAD/blob/main/AGENTS.md) がauthority。この文書ではallowed Palette scope等のcurrent enumを重複管理せず、Task contractで何を明示するかだけをownerとする。

## Required contract fields

最低限、次を決める。

### Name / title

- user-facing command name / titleは英語に統一する。
- VS Code `contributes.commands[].title`、Command Palette、context menu、Ribbon等で表示されるcommand名を日本語にしない。
- internal command IDも英語を維持する。

### Palette scope

- current repository `AGENTS.md` が許可するPalette scopeから1つを明示する。
- allowed scope listをこのdev-context文書へ複製しない。repository側でsurface taxonomyが変わった場合はcurrent `AGENTS.md`を読む。
- Palette visibilityはsurface relevanceを表す。selection、caret、semantic target、drawable availability等のtransient stateで細かく出し分ける設計にしない。

### Context menu

- context menuへ出すかどうかを必ず明示する。
- `Context menu: None`は正当な選択肢。
- context menuへ出す場合は、実際に存在するsurface/contextとvisibility条件を書く。
- Command Palette visibilityとcontext-menu visibilityは別契約として扱う。
- context menuは現在の文脈に合う操作だけを出すため、必要ならselection / caret / semantic stateで絞り込んでよい。

### Source target semantics

Source EditorのnuinuiCAD context commandは、別途明示しない限り、右クリック座標ではなくcurrent caret position (`activeTextEditor.selection.active`) をtarget / semantic contextの基準にする。

別のtarget semanticsが必要なTaskは、実装前にcontractへ明示する。

### Reuse

menu / Ribbon / shortcut / button用にcommand business logicを複製しない。同じcommand implementationを再利用する。

## Existing command changes

既存commandを改修するTaskでも、そのTaskがcommand surfaceを変更する場合は上記観点で再確認する。

## Freshness

command contract策定時はlatest remote repositoryのcurrent manifest、registered command ID、menu contribution、current surface implementationを確認する。

Ready contractのcurrent implementation前提が別Taskのmergeで変わった場合は、Done-before Ready contract freshness checkでactual repository stateへ追従させる。product / UX decisionの変更が必要なら単なるfreshness更新として処理しない。
