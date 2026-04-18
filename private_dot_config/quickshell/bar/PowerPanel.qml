import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  property bool panelVisible: false

  property bool barHovered: false
  property bool panelHovered: false

  IpcHandler {
    target: "power"
    function show(): void { root.barHovered = true; root.updateVisibility(); }
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

  readonly property var actions: [
    { icon: "󰐥", label: "Shut Down", desc: "Power off the system", color: "#d9ff6464", bgColor: "#14ff6464", cmd: ["systemctl", "poweroff"] },
    { icon: "󰜉", label: "Restart", desc: "Reboot the system", color: "#d9ffb450", bgColor: "#14ffb450", cmd: ["systemctl", "reboot"] },
    { icon: "󰌾", label: "Lock", desc: "Lock the screen", color: "#d978a0ff", bgColor: "#1478a0ff", cmd: ["hyprlock"] },
    { icon: "󰤄", label: "Sleep", desc: "Suspend to RAM", color: "#d9b482ff", bgColor: "#14b482ff", cmd: ["systemctl", "suspend"] },
    { icon: "󰍃", label: "Log Out", desc: "Return to login screen", color: "#73ffffff", bgColor: "#0affffff", cmd: ["hyprctl", "dispatch", "exit"] },
    { icon: "󰘚", label: "Firmware", desc: "Reboot to UEFI setup", color: "#d960d0e0", bgColor: "#1460d0e0", cmd: ["systemctl", "reboot", "--firmware-setup"] }
  ]

  Variants {
    model: Quickshell.screens.filter((s, i) => i === 0)

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.panelVisible
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "quickshell-power"
      exclusionMode: ExclusionMode.Ignore

      anchors { top: true; right: true }
      margins { top: 48; right: 17 }
      implicitWidth: 220
      implicitHeight: pwCol.implicitHeight + 24

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: { root.panelHovered = true; root.updateVisibility(); }
        onExited: { root.panelHovered = false; root.updateVisibility(); }

        Rectangle {
          anchors.fill: parent
          radius: 14
          color: "#c0121216"
          border.width: 1
          border.color: "#0fffffff"

          ColumnLayout {
            id: pwCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text { text: "SYSTEM"; font.family: "Jost"; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 1; color: "#40ffffff"; Layout.preferredWidth: 200 }

            Repeater {
              model: root.actions

              Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 44; radius: 10; color: "transparent"

                Rectangle {
                  x: 8; y: 6; width: 32; height: 32; radius: 10
                  color: modelData.bgColor

                  Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                    color: modelData.color
                  }
                }

                Column {
                  x: 50; anchors.verticalCenter: parent.verticalCenter
                  spacing: 0
                  Text { text: modelData.label; font.family: "Jost"; font.pixelSize: 12; font.weight: Font.Medium; color: "#e0ffffff" }
                  Text { text: modelData.desc; font.family: "Jost"; font.pixelSize: 10; color: "#4dffffff" }
                }

                MouseArea {
                  anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  hoverEnabled: true
                  onEntered: parent.color = "#0fffffff"
                  onExited: parent.color = "transparent"
                  onClicked: { actionProc.command = modelData.cmd; actionProc.running = true; }
                }
              }
            }
          }
        }
      }
    }
  }

  Process { id: actionProc; running: false }
}
