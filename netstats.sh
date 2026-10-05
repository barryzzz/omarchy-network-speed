#!/usr/bin/env bash
# Print "<iface>\t<rx_bytes>\t<tx_bytes>" for the active route interface.
# Read by BarWidget.qml's sampler once per second. Kept tiny on purpose:
# no ping, no jq — just a route lookup and two sysfs counter reads.

iface=$(ip route get 1.1.1.1 2>/dev/null | sed -n 's/.* dev \([^ ]*\).*/\1/p')

if [ -z "$iface" ]; then
  printf '\t0\t0\n'
  exit 0
fi

rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null)
tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null)

printf '%s\t%s\t%s\n' "$iface" "${rx:-0}" "${tx:-0}"
