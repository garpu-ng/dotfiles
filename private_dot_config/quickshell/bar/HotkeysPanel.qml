import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Scope {
  id: root
  property bool panelVisible: false
  property bool barHovered: false
  property bool panelHovered: false
  property var bindsList: []

  IpcHandler {
    target: "hotkeys"
    function show(): void { root.barHovered = true; root.updateVisibility(); refreshProc.running = true; }
    function hide(): void { root.barHovered = false; root.updateVisibility(); }
  }

  Timer {
    id: closeTimer
    interval: 1000
    onTriggered: { if (!root.barHovered && !root.panelHovered) root.panelVisible = false; }
  }

  function updateVisibility() {
    if (barHovered || panelHovered) { closeTimer.stop(); panelVisible = true; }
    else { closeTimer.restart(); }
  }

  function modsFromMask(mask) {
    const mods = [];
    if (mask & 64) mods.push("Super");
    if (mask & 4)  mods.push("Ctrl");
    if (mask & 8)  mods.push("Alt");
    if (mask & 1)  mods.push("Shift");
    return mods;
  }

  function prettyAction(dispatcher, arg) {
    if (dispatcher === "exec") return "▸ " + arg;
    if (arg && arg.length > 0) return dispatcher + " " + arg;
    return dispatcher;
  }

  Process {
    id: refreshProc
    command: ["hyprctl", "binds", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const data = JSON.parse(text);
          const out = [];
          for (const b of data) {
            if (!b.key || b.mouse) continue;
            const mods = root.modsFromMask(b.modmask);
            out.push({
              combo: mods.concat([b.key]).join(" + "),
              action: root.prettyAction(b.dispatcher, b.arg || "")
            });
          }
          root.bindsList = out;
        } catch (e) { /* ignore */ }
      }
    }
  }

  Variants {
    model: Quickshell.screens.filter((s, i) => i === 0)

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.panelVisible
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "quickshell-hotkeys"
      exclusionMode: ExclusionMode.Ignore

      anchors { top: true; left: true; right: true }
      margins.top: 48
      implicitHeight: 480

      MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 440
        height: 480
        hoverEnabled: true
        onEntered: { root.panelHovered = true; root.updateVisibility(); }
        onExited:  { root.panelHovered = false; root.updateVisibility(); }

        Rectangle {
          anchors.fill: parent
          radius: 14
          color: "#c0121216"
          border.width: 1
          border.color: "#0fffffff"

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Text {
              text: "HOTKEYS"
              font.family: "Jost"; font.pixelSize: 9; font.weight: Font.DemiBold
              font.letterSpacing: 1
              color: "#40ffffff"
              Layout.fillWidth: true
            }

            ListView {
              id: listView
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              model: root.bindsList
              spacing: 2
              boundsBehavior: Flickable.StopAtBounds

              delegate: Rectangle {
                width: listView.width
                height: 26
                radius: 6
                color: mouse.containsMouse ? "#12ffffff" : "transparent"

                MouseArea {
                  id: mouse
                  anchors.fill: parent
                  hoverEnabled: true
                }

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  spacing: 10

                  Text {
                    text: modelData.combo
                    font.family: "Jost"; font.pixelSize: 11; font.weight: Font.Medium
                    color: "#e0ffffff"
                    width: 150
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    text: modelData.action
                    font.family: "Jost"; font.pixelSize: 11
                    color: "#a0ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
