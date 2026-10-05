import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import "Model.js" as Model

// Live upload/download speed for the active route interface, shown in the bar
// with a details panel. netstats.sh samples the counters every second; the
// rate is the delta between successive samples.
BarWidget {
  id: root
  moduleName: "io.github.barryzzz.network-speed"

  property string iface: ""
  property real prevRxBytes: 0
  property real prevTxBytes: 0
  property real prevSampleTime: 0
  property string prevIface: ""
  property real downloadRate: 0   // bytes/sec
  property real uploadRate: 0     // bytes/sec
  property real totalRxBytes: 0
  property real totalTxBytes: 0

  readonly property string downloadText: Model.formatRateCompact(downloadRate)
  readonly property string uploadText: Model.formatRateCompact(uploadRate)

  // The bar shows one direction at a time, alternating, so the label stays
  // narrow and its width change stays small.
  property bool showDownload: true
  readonly property string barText: showDownload
    ? "↓ " + downloadText
    : "↑ " + uploadText

  // Panel lifecycle, forwarded to the Loader-loaded Panel.qml. The bar's
  // findPanelWidget resolves summon/hide by open/close/opened on this root.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  function sample(raw) {
    var next = Model.parseSample(raw)
    iface = next.iface
    totalRxBytes = next.rxBytes
    totalTxBytes = next.txBytes

    var state = Model.throughputState({
      prevIface: prevIface,
      prevRxBytes: prevRxBytes,
      prevTxBytes: prevTxBytes,
      prevSampleTime: prevSampleTime
    }, next, Date.now() / 1000)

    prevIface = state.prevIface
    prevRxBytes = state.prevRxBytes
    prevTxBytes = state.prevTxBytes
    prevSampleTime = state.prevSampleTime
    downloadRate = state.downloadRate
    uploadRate = state.uploadRate
  }

  // netstats.sh ships beside this file; resolve it relative to the QML so the
  // plugin works whether it is being developed in place or git-installed.
  readonly property string scriptPath: String(Qt.resolvedUrl("netstats.sh")).replace("file://", "")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  Component.onCompleted: if (!sampleProc.running) sampleProc.running = true

  Process {
    id: sampleProc
    command: ["bash", root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.sample(text)
    }
  }

  Timer {
    id: pollTimer
    interval: 1000
    repeat: true
    running: true
    onTriggered: if (!sampleProc.running) sampleProc.running = true
  }

  Timer {
    id: alternateTimer
    interval: 2000
    repeat: true
    running: true
    onTriggered: showDownload = !showDownload
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barText
    tooltipText: (root.iface ? root.iface + "  " : "")
      + "↓ " + Model.formatRate(root.downloadRate)
      + "  ↑ " + Model.formatRate(root.uploadRate)
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}
