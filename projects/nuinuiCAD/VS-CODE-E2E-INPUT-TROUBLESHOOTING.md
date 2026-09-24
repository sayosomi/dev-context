# VS Code / Electron pointer-input troubleshooting

## Purpose

VS Code上でCanvasの選択・ドラッグ・パンなどのpointer操作が突然効かなくなったとき、nuinuiCAD product failureと判定する前に、VS Code / Electron / macOS input stateを短時間で切り分けるための手順。

特に、wheel zoomなど一部のmouse入力は動く一方で、primary pointer操作だけが広く死ぬ症状を対象とする。

このdocumentは [`VS-CODE-E2E.md`](./VS-CODE-E2E.md) のhost troubleshooting supplementであり、Manual E2EのPASS / FAIL classification自体は [`MANUAL-E2E.md`](./MANUAL-E2E.md) がauthority。

## Known incident signature — 2026-09-24

SAY-359 Manual E2E中に次を観測した。

- 物理的にはmouse buttonを押していない状態でも、nuinuiCAD Webview内のidle `mousemove`が `buttons: 16` を返した。
- nuinuiCAD Webviewだけでなく、VS Code top-level workbench rendererでも同じ `buttons: 16` を確認した。
- ordinary left clickは `16 -> 17 -> 16` と観測された。
- MouseEventは届くがPointerEventが届かず、Canvasのselection / point drag / pan等のpointer-handler-based interactionが広く動かなくなった。
- VS Code以外のアプリはHuman observationでは正常だった。
- physical mouseの第5ボタンはELECOM Mouse AssistantでPaste（Cmd+V）に割り当てて多用しており、DevTools Consoleへのpasteにも使用していた。
- ELECOM Mouse Assistantの可視アプリだけを再起動しても直らなかった。
- mouseのdisconnect / reconnectでも直らなかった。
- Mac再起動後、同じtested refのfresh VS Code hostではselection / point drag / panが正常へ戻った。

重要: `buttons: 16` は「physical button 5が実際に押しっぱなし」であることを証明しない。**VS Code / Electron rendererがbutton 5を押下中として保持している状態**を示す観測値として扱う。

ELECOM Mouse Assistant / remapping pathがtriggerである可能性はあるが、2026-09-24 incidentではroot causeとしては未確定。

## 再発時チェックリスト

### 1. VS Code本体のDeveloper Toolsを開く

Command Paletteから:

`Developer: Toggle Developer Tools`

Webview DevToolsではなく、VS Code本体workbenchのDevToolsで確認する。

### 2. 確認先がtop-level workbenchか確認する

Consoleへそのまま貼る。

```js
({
  isTop: window === window.top,
  hasWorkbench: !!document.querySelector(".monaco-workbench"),
  hasCanvasViewport: !!document.querySelector(".canvas-viewport")
})
```

期待する確認先:

```text
isTop: true
hasWorkbench: true
```

`hasCanvasViewport: true`ならnuinuiCAD Webview側を見ている可能性があるため、VS Code本体Developer Toolsへ戻る。

### 3. buttonを何も押さずにidle mouse stateを確認する

Consoleへ貼る。

```js
new Promise(resolve => {
  document.addEventListener("mousemove", e => resolve({
    button: e.button,
    buttons: e.buttons
  }), { once: true, capture: true });
}).then(console.log)
```

その後、mouse buttonを押さずにmouseを少し動かす。

判定:

- `buttons: 0` → 2026-09-24 incidentとは別原因。通常のproduct / host triageへ戻る。
- `buttons: 16` → VS Code rendererがbutton 5を押下中扱いしている異常state。次へ進む。

### 4. Chrome / Safari等の通常browserでも同じprobeを実行する

同じJavaScriptをbrowser DevToolsで実行する。

- **browser = 0 / VS Code = 16** → VS Code / Electron固有stateの可能性が高い。
- **browserも16** → macOS input stack / device utility / remapper側まで広がっている可能性がある。

browser比較をせずにELECOM起因、VS Code起因、physical mouse故障のいずれかへ断定しない。

### 5. VS Codeだけ16ならVS Codeを完全終了して再起動する

全windowを閉じるだけではなく、macOSでVS Codeを完全終了（Cmd+Q）してから再起動する。

再起動後、step 2–3を再実行する。

- `0`へ戻る → VS Code / Electron内に残ったinput stateだった可能性が高い。
- `16`のまま → 次へ進む。

### 6. ELECOM Mouse Assistant関連processまで停止して再確認する

可視のMouse Assistant再起動だけでは直らなかった実績があるため、それだけでELECOM pathを除外しない。

Activity Monitor等でELECOM Mouse Assistant関連のbackground componentも確認して停止し、VS Codeを再起動してstep 2–3を再確認する。環境によってprocess名は変わり得るが、過去のmacOS版では `MouseEventChange` / `ElecomGesture` 等が見られる。

- ここで `0`へ戻る → ELECOM background/remapping pathの関与が強く疑われる。
- `16`のまま → 次へ進む。

### 7. 最後にMacを再起動する

2026-09-24 incidentではfull Mac restartで異常stateが解消した。

再起動後、VS Codeでstep 2–3を再確認し、`buttons: 0`になったことと、元のCanvas interactionが復旧したことを確認する。

## E2E classification rule

Manual E2E中にCanvasのselection / drag / pan等が広く死んでも、VS Code top-level workbench自体でidle `buttons: 16`が再現する場合は、nuinuiCAD product FAILとして即時確定しない。

その場合はhost/input-state problem candidateとして扱い、actual-host boundary triageを完了する。

特に:

- Webviewだけでなくworkbenchでも同じ異常stateがある;
- fresh restart後に同じtested refでproduct interactionが正常復旧する;

という証拠が揃う場合、そのdead-pointer observationはenvironment / host-stateとして分類し、qualifying product failureやstabilization streak incrementへ数えない。

## Search anchors

再発時にProject Context内検索で拾いやすい語:

`buttons=16` / `fifth-button` / `button 5` / `ELECOM` / `Mouse Assistant` / `pointerdown` / `Canvas selection drag pan`
