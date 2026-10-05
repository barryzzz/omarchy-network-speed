# Network Speed

Live network upload/download speed for the Omarchy Quattro bar.

## Install

```sh
omarchy plugin add https://github.com/barryzzz/omarchy-network-speed.git --enable
```

## Usage

The bar shows a single speed value that alternates between ↓ download and
↑ upload every couple of seconds. Click it to open the details panel (which
shows both directions); press Escape to close.

The widget reports the **physical NIC(s)**, not a proxy tunnel: it sums every
hardware-backed interface (`/sys/class/net/<iface>/device`) that is up, so with
mihomo/clash active it still shows real NIC (e.g. `wlp6s0`) traffic rather than
the `mihomo` TUN device.

## Requirements

Standard on Omarchy/Arch, nothing to install:

- `ip` (iproute2) and `bash`/`sed` — resolve the active interface
- `/sys/class/net/<iface>/statistics/{rx,tx}_bytes` — kernel network counters

## Configure

```sh
omarchy bar move io.github.barryzzz.network-speed --section right
```

## Develop

```sh
omarchy plugin validate .
bash netstats.sh                      # sample the counters once
node -e 'const M=require("./Model.js"); console.log(M.formatRate(124800))'
```

## Remove

```sh
omarchy plugin remove io.github.barryzzz.network-speed
```
