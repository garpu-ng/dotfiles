import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Scope {
  id: root
  property bool panelVisible: false
  property bool barHovered: false
  property bool panelHovered: false

  // Per-app audio from script (reliable)
  property var appList: []

  Process {
    id: appProc
    command: ["sh", "-c", "~/.config/quickshell/bar/scripts/audio-apps.sh"]
    running: true
    stdout: SplitParser {
      onRead: data => { try { root.appList = JSON.parse(data.trim()); } catch(e) {} }
    }
  }

  IpcHandler {
    target: "audio"
    function show(): void { root.barHovered = true; root.updateVisibility(); }
    function hide(): void { root.barHovered = false; root.updateVisibility(); }
  }

  Timer {
    id: closeTimer; interval: 1000
    onTriggered: { if (!root.barHovered && !root.panelHovered) root.panelVisible = false; }
  }

  function updateVisibility() {
    if (barHovered || panelHovered) { closeTimer.stop(); panelVisible = true; }
    else { closeTimer.restart(); }
  }

  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  // Sinks for output device list
  readonly property var audioSinks: {
    const nodes = Pipewire.nodes.values;
    return nodes.filter(n => !n.isStream && n.isSink && n.audio);
  }

  Variants {
    model: Quickshell.screens.filter((s, i) => i === 0)

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.panelVisible
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "quickshell-audio"
      exclusionMode: ExclusionMode.Ignore

      anchors { top: true; right: true }
      margins { top: 48; right: 50 }
      implicitWidth: 300
      implicitHeight: contentCol.implicitHeight + 28

      MouseArea {
        anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
        onEntered: { root.panelHovered = true; root.updateVisibility(); }
        onExited: { root.panelHovered = false; root.updateVisibility(); }

        Rectangle {
          anchors.fill: parent; radius: 14
          color: "#c0121216"; border.width: 1; border.color: "#0fffffff"

          ColumnLayout {
            id: contentCol
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top; anchors.margins: 12
            spacing: 8

            // ── Master Volume ──
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: masterContent.implicitHeight + 20
              radius: 12; color: "#0affffff"

              ColumnLayout {
                id: masterContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 10; anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                RowLayout {
                  spacing: 10

                  Rectangle {
                    width: 32; height: 32; radius: 10
                    color: (Pipewire.defaultAudioSink?.audio?.muted ?? false) ? "#0fffffff" : "#14ffffff"

                    Text {
                      anchors.centerIn: parent
                      text: (Pipewire.defaultAudioSink?.audio?.muted ?? false) ? "婢" : ""
                      font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                      color: (Pipewire.defaultAudioSink?.audio?.muted ?? false) ? "#4dffffff" : "#c0ffffff"
                    }

                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { const sink = Pipewire.defaultAudioSink; if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
                    }
                  }

                  ColumnLayout {
                    spacing: 0
                    Text { text: "Volume"; font.family: "Jost"; font.pixelSize: 12; font.weight: Font.Medium; color: "#e0ffffff" }
                    Text { text: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"; font.family: "Jost"; font.pixelSize: 10; color: "#80ffffff" }
                  }
                }

                Slider {
                  Layout.fillWidth: true; height: 20
                  from: 0; to: 1.0; live: true
                  value: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                  onMoved: { const sink = Pipewire.defaultAudioSink; if (sink?.audio) sink.audio.volume = value; }

                  background: Rectangle {
                    x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    width: parent.availableWidth; height: 5; radius: 3; color: "#14ffffff"
                    Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 3; color: "#a6ffffff" }
                  }
                  handle: Rectangle {
                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    width: 14; height: 14; radius: 7; color: "white"
                  }
                }
              }
            }

            // ── Per-App Volumes ──
            Text {
              text: "APPS"; font.family: "Jost"; font.pixelSize: 9; font.weight: Font.DemiBold
              font.letterSpacing: 1; color: "#40ffffff"; Layout.fillWidth: true
              visible: root.appList.length > 0
            }

            Repeater {
              model: root.appList

              RowLayout {
                id: appRow
                required property var modelData
                Layout.fillWidth: true; spacing: 6

                property real appVol: 100
                property bool dragging: false

                // Poll volume for this app
                Process {
                  id: volPoll
                  command: ["wpctl", "get-volume", String(appRow.modelData.id)]
                  running: true
                  stdout: StdioCollector {
                    onStreamFinished: {
                      if (!appRow.dragging) {
                        const match = text.match(/Volume:\s+([\d.]+)/);
                        if (match) appRow.appVol = Math.round(parseFloat(match[1]) * 100);
                      }
                    }
                  }
                }

                Timer {
                  interval: 1000; running: true; repeat: true
                  onTriggered: volPoll.running = true
                }

                Text { text: ""; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#4dffffff" }
                Text {
                  text: appRow.modelData.name || "?"
                  font.family: "Jost"; font.pixelSize: 11; color: "#a6ffffff"
                  Layout.preferredWidth: 65; elide: Text.ElideRight
                }

                Slider {
                  id: appSlider
                  Layout.fillWidth: true; height: 16
                  from: 0; to: 100; live: true
                  value: appRow.appVol
                  onPressedChanged: appRow.dragging = pressed
                  onMoved: {
                    appRow.appVol = value;
                    volSetProc.command = ["wpctl", "set-volume", String(appRow.modelData.id), (value / 100).toFixed(2)];
                    volSetProc.startDetached();
                  }

                  background: Rectangle {
                    x: appSlider.leftPadding; y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                    width: appSlider.availableWidth; height: 3; radius: 2; color: "#0fffffff"
                    Rectangle { width: appSlider.visualPosition * parent.width; height: parent.height; radius: 2; color: "#59ffffff" }
                  }
                  handle: Rectangle {
                    x: appSlider.leftPadding + appSlider.visualPosition * (appSlider.availableWidth - width)
                    y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                    width: 10; height: 10; radius: 5; color: "#a6ffffff"
                  }
                }

                Text {
                  text: Math.round(appRow.appVol) + "%"
                  font.family: "Jost"; font.pixelSize: 9; color: "#4dffffff"; Layout.preferredWidth: 26
                }
              }
            }

            // ── Output Devices ──
            Text {
              text: "OUTPUT"; font.family: "Jost"; font.pixelSize: 9; font.weight: Font.DemiBold
              font.letterSpacing: 1; color: "#40ffffff"; Layout.fillWidth: true
            }

            Repeater {
              model: root.audioSinks

              Rectangle {
                required property var modelData
                Layout.fillWidth: true; implicitHeight: 28; radius: 8
                property bool isDefault: modelData === Pipewire.defaultAudioSink
                color: isDefault ? "#14ffffff" : "transparent"

                Text {
                  anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                  text: (parent.isDefault ? " " : " ") + (modelData.description || modelData.name || "")
                  font.family: "Jost"; font.pixelSize: 11
                  color: parent.isDefault ? "#e0ffffff" : "#73ffffff"
                  elide: Text.ElideRight; width: parent.width - 16
                }

                MouseArea {
                  anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                  onEntered: if (!parent.isDefault) parent.color = "#0affffff"
                  onExited: parent.color = parent.isDefault ? "#14ffffff" : "transparent"
                  onClicked: Pipewire.preferredDefaultAudioSink = parent.modelData
                }
              }
            }

            // ── Settings ──
            Rectangle {
              Layout.fillWidth: true; implicitHeight: 28; radius: 8; color: "transparent"
              Text { anchors.centerIn: parent; text: "  Audio Settings"; font.family: "Jost"; font.pixelSize: 11; color: "#59ffffff" }
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onEntered: parent.color = "#0affffff"; onExited: parent.color = "transparent"
                onClicked: pavuProc.running = true
              }
            }
          }
        }
      }
    }
  }

  Process { id: volSetProc; running: false }
  Process { id: pavuProc; command: ["pavucontrol"]; running: false }
}
