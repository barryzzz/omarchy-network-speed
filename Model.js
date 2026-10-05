// Sampling and formatting helpers for the network speed widget. Pure JS so it
// can be exercised under node during development.

function parseSample(raw) {
  // netstats.sh prints "<iface>\t<rx_bytes>\t<tx_bytes>".
  var parts = String(raw || "").replace(/\r?\n+$/, "").split("\t")
  return {
    iface: parts[0] || "",
    rxBytes: parseFloat(parts[1] || "0"),
    txBytes: parseFloat(parts[2] || "0")
  }
}

// Turn two counter samples into a bytes/sec rate. The first sample after load
// or after an interface switch returns zero rather than manufacturing a spike.
function throughputState(previous, next, now) {
  var prev = previous || {}
  var sample = next || {}
  var iface = sample.iface || ""
  var rx = Number(sample.rxBytes) || 0
  var tx = Number(sample.txBytes) || 0
  var previousTime = Number(prev.prevSampleTime || 0)

  if (iface !== (prev.prevIface || "") || previousTime === 0) {
    return {
      prevIface: iface,
      prevRxBytes: rx,
      prevTxBytes: tx,
      prevSampleTime: now,
      downloadRate: 0,
      uploadRate: 0
    }
  }

  var dt = now - previousTime
  var downloadRate = 0
  var uploadRate = 0
  if (dt > 0) {
    downloadRate = Math.max(0, (rx - Number(prev.prevRxBytes || 0)) / dt)
    uploadRate = Math.max(0, (tx - Number(prev.prevTxBytes || 0)) / dt)
  }

  return {
    prevIface: iface,
    prevRxBytes: rx,
    prevTxBytes: tx,
    prevSampleTime: now,
    downloadRate: downloadRate,
    uploadRate: uploadRate
  }
}

function formatBytes(n) {
  n = Number(n)
  if (!isFinite(n) || n < 0) n = 0
  if (n < 1024) return Math.round(n) + " B"
  if (n < 1024 * 1024) return (n / 1024).toFixed(1) + " KB"
  if (n < 1024 * 1024 * 1024) return (n / (1024 * 1024)).toFixed(1) + " MB"
  return (n / (1024 * 1024 * 1024)).toFixed(2) + " GB"
}

function formatRate(bytesPerSec) {
  return formatBytes(bytesPerSec) + "/s"
}

// Compact rate for the bar: "0B", "300K", "1.2M", "3.5G". Keeps one decimal
// only below ten of the unit so the label stays narrow.
function formatRateCompact(bytesPerSec) {
  var n = Number(bytesPerSec)
  if (!isFinite(n) || n < 0) n = 0
  if (n < 1024) return Math.round(n) + "B"
  if (n < 1024 * 1024) return (n / 1024).toFixed(n < 10 * 1024 ? 1 : 0) + "K"
  if (n < 1024 * 1024 * 1024) return (n / (1024 * 1024)).toFixed(n < 10 * 1024 * 1024 ? 1 : 0) + "M"
  return (n / (1024 * 1024 * 1024)).toFixed(2) + "G"
}

if (typeof module !== "undefined") {
  module.exports = {
    parseSample: parseSample,
    throughputState: throughputState,
    formatBytes: formatBytes,
    formatRate: formatRate,
    formatRateCompact: formatRateCompact
  }
}
