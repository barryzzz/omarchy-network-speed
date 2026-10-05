import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Details panel for the network speed widget. Left click on the bar label
// toggles this surface; Escape closes it. The live values are owned by the
// BarWidget sampler and reached through hostWidget.
Panel {
  id: root
  moduleName: "io.github.barryzzz.network-speed"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property var host: hostWidget || null

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(240))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(8)

        Text {
          width: parent.width
          text: root.host && root.host.iface ? root.host.iface : "Network"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          text: "↓ " + (root.host ? Model.formatRate(root.host.downloadRate) : "--")
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        Text {
          width: parent.width
          text: "↑ " + (root.host ? Model.formatRate(root.host.uploadRate) : "--")
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        Text {
          width: parent.width
          text: (root.host ? "↓ " + Model.formatBytes(root.host.totalRxBytes) + " total" : "")
            + (root.host ? "   ↑ " + Model.formatBytes(root.host.totalTxBytes) + " total" : "")
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          opacity: 0.7
        }
      }
    }
  }
}
