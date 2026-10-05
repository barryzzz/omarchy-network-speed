#!/usr/bin/env bash
# Print "<iface>\t<rx_bytes>\t<tx_bytes>" for the active physical NIC(s).
# Read by BarWidget.qml's sampler once per second. Kept tiny on purpose:
# no ping, no jq — just sysfs reads.
#
# Only interfaces backed by real hardware are counted:
# /sys/class/net/<iface>/device exists for PCI/USB NICs but not for virtual
# devices (lo, tun/tap, veth, docker, bridges, or proxy tunnels like mihomo).
# Sum every physical interface that is currently up, so the readout reflects
# real NIC traffic instead of a tunnel.

rx=0
tx=0
iface=""

for dev in /sys/class/net/*; do
  name=$(basename "$dev")
  [ "$name" = "lo" ] && continue
  [ -L "$dev/device" ] || continue
  [ "$(cat "$dev/operstate" 2>/dev/null)" = "up" ] || continue

  r=$(cat "$dev/statistics/rx_bytes" 2>/dev/null); r=${r:-0}
  t=$(cat "$dev/statistics/tx_bytes" 2>/dev/null); t=${t:-0}
  rx=$((rx + r))
  tx=$((tx + t))
  iface="${iface:+$iface+}$name"
done

if [ -z "$iface" ]; then
  printf '\t0\t0\n'
  exit 0
fi

printf '%s\t%s\t%s\n' "$iface" "$rx" "$tx"
