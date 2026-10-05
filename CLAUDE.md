# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An Omarchy shell plugin — a `bar-widget` that shows network upload/download
speed in the Omarchy status bar, with a details panel. Omarchy's bar,
notifications, and overlays all run inside one long-running Quickshell process
(`omarchy-shell`), and plugins execute unsandboxed inside it.

## Commands

```sh
# Validate manifest + folder layout (same rules the shell enforces at load time)
omarchy plugin validate .

# Lint the QML against the installed shell imports
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml

# Exercise the sampler script and pure-JS helpers directly
bash netstats.sh
node -e 'const M = require("./Model.js"); console.log(M.formatRate(124800))'

# Install from a git remote for live testing
omarchy plugin add <git-url> --enable
```

Development loop: plugin code under `~/.config/omarchy/plugins/<id>/`
hot-reloads on save. After structural changes (new files, manifest edits),
force rediscovery:

```sh
omarchy-shell shell rescanPlugins
omarchy plugin list --json            # confirm id / kind / enabled
```

Panel lifecycle (routes to `BarWidget.qml`'s `open()`/`close()`):

```sh
omarchy-shell shell summon <id> '{}'  # open
omarchy-shell shell hide <id>         # close
```

## Plugin contract

A plugin is a folder with `manifest.json` plus QML entry points. The manifest
maps `kinds` to `entryPoints` files:

| kind        | entryPoints key | file            | purpose               |
|-------------|-----------------|-----------------|-----------------------|
| bar-widget  | barWidget       | BarWidget.qml   | item in the active bar |
| panel       | panel           | Panel.qml       | floating surface       |
| overlay     | overlay         | Overlay.qml     | fullscreen surface     |
| menu        | menu            | Menu.qml        | summoned menu          |
| service     | service         | Service.qml     | headless singleton     |
| bar         | bar             | Bar.qml         | full bar replacement   |

Manifest rules (enforced by `omarchy plugin validate`, mirroring the shell's
`PluginRegistry.qml`):

- `schemaVersion` must be the JSON number `1` (not the string `"1"`).
- Required fields: `id`, `name`, `version`, `kinds`, `entryPoints`.
- `id` matches `^[A-Za-z0-9][A-Za-z0-9._-]*$`; the `omarchy.*` namespace is
  reserved for first-party plugins.
- Every `entryPoints` value is a safe relative path to an existing file.
- A declared `kind` must have its corresponding `entryPoints.<key>`.
- No symlinks anywhere in the plugin folder.

## Architecture of this plugin

- `BarWidget.qml` — the manifest entry point. Root type is `BarWidget` (from
  `qs.Ui`), with `moduleName` set to the plugin id. It owns the sampler: a
  `Timer` fires every 1s and runs `netstats.sh` via `Process` +
  `StdioCollector`; `sample()` feeds the raw counters to `Model.throughputState`
  to get bytes/sec. It also forwards the panel lifecycle (`open()` / `close()` /
  `toggle()` / `closeForPopoutSwitch()` plus `opened` / `popoutSwitchClosing`)
  to a `Loader`-loaded `Panel.qml`, so `shell.summon`/`hide`/`toggle` routing
  (via the bar's `findPanelWidget`, which requires `open`/`close`/`opened` on
  the widget root) and popout switching work. `injectPanel()` copies `bar`,
  `anchorItem`, `hostWidget` into the panel after it loads.
- `netstats.sh` — helper invoked once per second. Prints
  `<iface>\t<rx_bytes>\t<tx_bytes>` for the interface returned by
  `ip route get 1.1.1.1` (the active route interface), read from
  `/sys/class/net/<iface>/statistics/`. Deliberately avoids `ping`/`jq` so
  polling stays cheap. Resolved relative to the QML via
  `Qt.resolvedUrl("netstats.sh")`, so it works both in-place and git-installed.
- `Model.js` — pure JS (node-testable): `parseSample`, `throughputState`
  (delta → bytes/sec, zero on first sample / interface switch), `formatBytes`,
  `formatRate`, `formatRateCompact` (bar label).
- `Panel.qml` — root type `Panel` (from `qs.Ui`) with `manageIpc: false`.
  `KeyboardPanel` anchors the surface to the bar button; `PanelKeyCatcher`
  closes on Escape and forwards Tab to `switchPanel()`. Reads live values off
  `hostWidget` (the BarWidget).
- Both QML files must use the same `moduleName`; the nested panel does not get
  its own `kinds` entry.

Note on interface selection: this widget reports the *active route* interface
(`ip route get 1.1.1.1`), matching `omarchy-network-status`. With a VPN/proxy
(e.g. mihomo/clash) the reported interface is the tunnel, not the physical NIC.

## Key APIs

- `qs.Ui` — `BarWidget`, `WidgetButton`, `Panel`, `KeyboardPanel`,
  `PanelKeyCatcher`.
- `Style` singleton — `Style.space(n)`, `Style.font.*`
  (caption/bodySmall/body/subtitle/title/heading/display/displayLarge),
  `Style.bar.*`.
- `Color` singleton — palette roles (`Color.foreground`, `Color.accent`,
  `Color.urgent`).
- On the `BarWidget` root: `root.bar`, `root.barForeground`, `root.settings`.

Built-in examples live under `$OMARCHY_PATH/shell/plugins/` — `panels/clock/`
is the closest to this widget's bar-widget + panel shape. The official shell
reference is in the `quattro` branch of `github.com/omacom/omarchy`
(`shell/README.md`).

## Publishing

Before publishing, set the permanent namespaced id (e.g.
`io.github.<user>.<name>`) and remove any clone-only `omarchy.clonedFrom`
field. See https://plugins.omarchy.org/publish.html.
