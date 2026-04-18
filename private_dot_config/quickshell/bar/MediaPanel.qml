import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Scope {
  id: root
  property bool panelVisible: false
  property bool barHovered: false
  property bool panelHovered: false

  property var activePlayer: {
    const players = Mpris.players.values;
    if (!players || players.length === 0) return null;
    for (const p of players)
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    return players[0];
  }

  IpcHandler {
    target: "media"
    function show(): void { root.barHovered = true; root.updateVisibility(); }
    function hide(): void { root.barHovered = false; root.updateVisibility(); }
  }

  Timer {
    id: closeTimer; interval: 1000
    onTriggered: { if (!root.barHovered && !root.panelHovered) root.panelVisible = false; }
  }

  Timer {
    id: posTimer; interval: 1000
    running: root.panelVisible && root.activePlayer !== null && root.activePlayer.playbackState === MprisPlaybackState.Playing
    repeat: true; onTriggered: posTimer.running = running
  }

  function updateVisibility() {
    if (barHovered || panelHovered) { closeTimer.stop(); panelVisible = true; }
    else { closeTimer.restart(); }
  }

  function formatTime(seconds) {
    if (!seconds || seconds < 0) return "0:00";
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return m + ":" + (s < 10 ? "0" : "") + s;
  }

  Variants {
    model: Quickshell.screens.filter((s, i) => i === 0)

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.panelVisible
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "quickshell-media"
      exclusionMode: ExclusionMode.Ignore

      anchors { top: true; left: true }
      margins { top: 48; left: 200 }
      implicitWidth: 320
      implicitHeight: 240

      HoverHandler {
        id: mediaHover
        onHoveredChanged: { root.panelHovered = hovered; root.updateVisibility(); }
      }

      Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#c0121216"
        border.width: 1
        border.color: "#0fffffff"

        ColumnLayout {
          id: mediaCol
          anchors.fill: parent
          anchors.margins: 12
          spacing: 4

          // ── Cover + Info ──
          RowLayout {
            Layout.fillWidth: true; spacing: 12

            Rectangle {
              width: 60; height: 60; radius: 10
              color: "#0affffff"; clip: true

              Image {
                anchors.fill: parent
                source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
              }

              Text {
                anchors.centerIn: parent; text: "󰎆"
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28; color: "#33ffffff"
                visible: !root.activePlayer || root.activePlayer.trackArtUrl === ""
              }
            }

            ColumnLayout {
              spacing: 2
              Layout.fillWidth: true

              Text { text: root.activePlayer ? root.activePlayer.trackTitle : "No media"; font.family: "Jost"; font.pixelSize: 14; font.weight: Font.Medium; color: "#e0ffffff"; elide: Text.ElideRight; Layout.fillWidth: true }
              Text { text: root.activePlayer ? root.activePlayer.trackArtist : ""; font.family: "Jost"; font.pixelSize: 12; color: "#80ffffff"; elide: Text.ElideRight; Layout.fillWidth: true; visible: text !== "" }
              Text { text: root.activePlayer ? (root.activePlayer.identity || "") : ""; font.family: "Jost"; font.pixelSize: 9; color: "#40ffffff"; visible: text !== "" }
            }
          }

          // ── Seek Bar ──
          ColumnLayout {
            id: seekCol
            Layout.fillWidth: true; spacing: 2
            visible: root.activePlayer !== null && root.activePlayer.length > 0
            property bool seeking: false

            Slider {
              id: seekSlider
              Layout.fillWidth: true; height: 16
              from: 0; to: root.activePlayer ? root.activePlayer.length : 1
              value: seekCol.seeking ? value : (root.activePlayer ? root.activePlayer.position : 0)
              live: true
              onPressedChanged: seekCol.seeking = pressed
              onMoved: { if (root.activePlayer) root.activePlayer.position = value; }

              background: Rectangle {
                x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                width: parent.availableWidth; height: 3; radius: 2; color: "#0fffffff"
                Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 2; color: "#66ffffff" }
              }
              handle: Rectangle {
                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                width: 8; height: 8; radius: 4; color: "#bfffffff"
              }
            }

            RowLayout {
              Layout.fillWidth: true
              Text { text: root.formatTime(seekSlider.value); font.family: "Jost"; font.pixelSize: 9; color: "#40ffffff" }
              Item { Layout.fillWidth: true }
              Text { text: root.formatTime(root.activePlayer ? root.activePlayer.length : 0); font.family: "Jost"; font.pixelSize: 9; color: "#40ffffff" }
            }
          }

          // ── Playback Controls ──
          RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 20

            Text {
              text: "󰒮"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28
              color: prevArea.containsMouse ? "#f0ffffff" : "#33ffffff"
              MouseArea { id: prevArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activePlayer?.previous() }
            }

            Text {
              text: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
              font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 36
              color: playArea.containsMouse ? "#f0ffffff" : "#4dffffff"
              MouseArea { id: playArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activePlayer?.togglePlaying() }
            }

            Text {
              text: "󰒭"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28
              color: nextArea.containsMouse ? "#f0ffffff" : "#33ffffff"
              MouseArea { id: nextArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activePlayer?.next() }
            }
          }

          // ── Player Volume ──
          RowLayout {
            Layout.fillWidth: true; spacing: 8

            Text { text: ""; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: "#4dffffff" }

            Slider {
              Layout.fillWidth: true; height: 16
              from: 0; to: 1; live: true
              value: root.activePlayer ? root.activePlayer.volume : 0
              onMoved: { if (root.activePlayer) root.activePlayer.volume = value; }

              background: Rectangle {
                x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                width: parent.availableWidth; height: 3; radius: 2; color: "#0fffffff"
                Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 2; color: "#59ffffff" }
              }
              handle: Rectangle {
                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                width: 8; height: 8; radius: 4; color: "#a6ffffff"
              }
            }

            Text { text: Math.round((root.activePlayer ? root.activePlayer.volume : 0) * 100) + "%"; font.family: "Jost"; font.pixelSize: 9; color: "#4dffffff"; Layout.preferredWidth: 28 }
          }

        }
      }
    }
  }
}
