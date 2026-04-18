import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  readonly property string fontUI: "Jost"
  readonly property string fontCJK: "Noto Sans CJK JP"
  readonly property string fontNerd: "JetBrainsMono Nerd Font"
  readonly property color bgBar: "#8c141419"
  readonly property color bgCard: "#0dffffff"
  readonly property color borderColor: "#14ffffff"
  readonly property color textPrimary: "#e0ffffff"
  readonly property color textDim: "#80ffffff"
  readonly property color textVeryDim: "#33ffffff"
  readonly property color accentBlue: "#78a0ff"

  // Workspace kanji labels
  readonly property var wsKanji: ["一", "二", "三"]

  // MPRIS active player
  property var activePlayer: {
    const players = Mpris.players.values;
    if (!players || players.length === 0) return null;
    for (const p of players)
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    return players[0];
  }

  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      anchors { top: true; left: true; right: true }
      margins { top: 6; left: 18; right: 18 }
      implicitHeight: 30
      color: "transparent"

      // Background with border
      Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.bgBar
        border.width: 1
        border.color: root.borderColor
      }

      Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        // ── LEFT: Workspaces + Media ──
        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 100

          // Workspaces (kanji)
          Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
              model: 3

              Text {
                required property int index
                property int wsId: {
                  // split-monitor-workspaces: monitor 0 = ws 1-3, monitor 1 = ws 4-6
                  const monIdx = Quickshell.screens.indexOf(panel.modelData);
                  return monIdx * 3 + index + 1;
                }
                property bool isActive: {
                  const ws = Hyprland.workspaces.values.find(w => w.id === wsId);
                  return ws ? ws.focused : false;
                }
                property bool isOccupied: {
                  return Hyprland.workspaces.values.some(w => w.id === wsId);
                }

                text: root.wsKanji[index]
                font.family: root.fontCJK
                font.pixelSize: 14
                color: "white"
                opacity: isActive ? 0.95 : isOccupied ? 0.40 : 0.20

                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Hyprland.dispatch("split-workspace " + (parent.index + 1))
                }
              }
            }
          }

          // Media controls
          MouseArea {
            height: 30
            width: mediaRow.width
            anchors.verticalCenter: parent.verticalCenter
            visible: root.activePlayer !== null
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mediaShowProc.running = true
            onExited: mediaHideProc.running = true

          Row {
            id: mediaRow
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            // Cava
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: CavaVis.bars
              font.family: "monospace"
              font.pixelSize: 8
              color: "#8cffffff"
              visible: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
            }

            // Album cover
            Rectangle {
              width: 20; height: 20
              radius: 4
              anchors.verticalCenter: parent.verticalCenter
              color: "transparent"
              visible: root.activePlayer && root.activePlayer.trackArtUrl !== ""
              clip: true

              Image {
                anchors.fill: parent
                source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
              }
            }

            // Prev
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "󰒮"
              font.family: root.fontNerd; font.pixelSize: 14
              color: root.textVeryDim
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: parent.color = root.textPrimary
                onExited: parent.color = root.textVeryDim
                onClicked: root.activePlayer.previous()
              }
            }

            // Play/Pause
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
              font.family: root.fontNerd; font.pixelSize: 16
              color: "#47ffffff"
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: parent.color = root.textPrimary
                onExited: parent.color = "#47ffffff"
                onClicked: root.activePlayer.togglePlaying()
              }
            }

            // Next
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "󰒭"
              font.family: root.fontNerd; font.pixelSize: 14
              color: root.textVeryDim
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: parent.color = root.textPrimary
                onExited: parent.color = root.textVeryDim
                onClicked: root.activePlayer.next()
              }
            }

            // Title · Artist
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: {
                if (!root.activePlayer) return "";
                const t = root.activePlayer.trackTitle || "";
                const a = root.activePlayer.trackArtist || "";
                return a ? t + "  ·  " + a : t;
              }
              font.family: root.fontUI; font.pixelSize: 11
              color: root.textDim
              elide: Text.ElideRight
              width: Math.min(implicitWidth, 350)
            }
          }
          } // close MouseArea wrapper
        }

        // ── CENTER: Date 󰣇 Time  (hover → hotkeys panel) ──
        MouseArea {
          id: hotkeysHover
          anchors.centerIn: parent
          width: hotkeysRow.implicitWidth + 24
          height: parent.height
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: hotkeysShowProc.running = true
          onExited:  hotkeysHideProc.running = true

          Row {
            id: hotkeysRow
            anchors.centerIn: parent
            spacing: 6

            Text {
              text: Time.dateString
              font.family: root.fontUI; font.pixelSize: 12
              color: root.textDim
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: "󰣇"
              font.family: root.fontNerd; font.pixelSize: 16
              color: "#d9ffffff"
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: Time.timeString
              font.family: root.fontUI; font.pixelSize: 13; font.weight: Font.Medium
              color: root.textPrimary
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        // ── RIGHT: Systray | Network | Volume | 電 ──
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 12

          // System Tray
          Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
              model: SystemTray.items

              MouseArea {
                id: trayItem
                required property SystemTrayItem modelData
                width: 18; height: 18
                anchors.verticalCenter: parent.verticalCenter
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                  if (mouse.button === Qt.LeftButton) modelData.activate();
                  else if (mouse.button === Qt.RightButton && modelData.hasMenu) trayMenu.open();
                  else if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate();
                }

                IconImage {
                  anchors.centerIn: parent
                  source: trayItem.modelData.icon
                  implicitSize: 16
                }

                QsMenuAnchor {
                  id: trayMenu
                  menu: trayItem.modelData.menu
                  anchor.window: trayItem.QsWindow.window
                  anchor.adjustment: PopupAdjustment.Flip
                  anchor.onAnchoring: {
                    const window = trayItem.QsWindow.window;
                    const r = window.contentItem.mapFromItem(trayItem, 0, trayItem.height, trayItem.width, trayItem.height);
                    trayMenu.anchor.rect = r;
                  }
                }
              }
            }
          }

          // Separator
          Text {
            text: "│"; font.pixelSize: 12
            color: "#1fffffff"
            anchors.verticalCenter: parent.verticalCenter
          }

          // Special workspace toggle (魔 = magic)
          Text {
            id: specialText
            text: "魔"
            font.family: root.fontCJK
            font.pixelSize: 13
            color: root.textDim
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: parent.color = root.textPrimary
              onExited: parent.color = root.textDim
              onClicked: specialToggleProc.running = true
            }
          }

          // Separator
          Text {
            text: "│"; font.pixelSize: 12
            color: "#1fffffff"
            anchors.verticalCenter: parent.verticalCenter
          }

          // Network (有線/無線/切断)
          Text {
            text: NetworkInfo.networkText
            font.family: root.fontCJK; font.pixelSize: 12
            color: root.textDim
            anchors.verticalCenter: parent.verticalCenter
          }

          // Volume (音: XX%)
          Text {
            id: volText
            text: {
              const sink = Pipewire.defaultAudioSink;
              if (!sink || !sink.audio) return "音: 0%";
              const vol = Math.round(sink.audio.volume * 100);
              return "音: " + vol + "%";
            }
            font.family: root.fontCJK; font.pixelSize: 12
            color: root.textDim
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
              anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onEntered: parent.color = root.textPrimary
              onClicked: audioShowProc.running = true
              onExited: { parent.color = root.textDim; audioHideProc.running = true; }
              onWheel: wheel => {
                const sink = Pipewire.defaultAudioSink;
                if (!sink || !sink.audio) return;
                sink.audio.volume = Math.max(0, Math.min(1.0, sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
              }
            }
          }

          // Separator
          Text {
            text: "│"; font.pixelSize: 12
            color: "#1fffffff"
            anchors.verticalCenter: parent.verticalCenter
          }

          // Power kanji
          Text {
            text: "電"
            font.family: root.fontCJK; font.pixelSize: 13
            color: root.textDim
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
              anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onEntered: parent.color = root.textPrimary
              onClicked: powerShowProc.running = true
              onExited: { parent.color = root.textDim; powerHideProc.running = true; }
            }
          }
        }
      }

      // IPC trigger processes
      Process { id: audioShowProc; command: ["qs", "msg", "audio", "show"]; running: false }
      Process { id: audioHideProc; command: ["qs", "msg", "audio", "hide"]; running: false }
      Process { id: powerShowProc; command: ["qs", "msg", "power", "show"]; running: false }
      Process { id: powerHideProc; command: ["qs", "msg", "power", "hide"]; running: false }
      Process { id: mediaShowProc; command: ["qs", "msg", "media", "show"]; running: false }
      Process { id: specialToggleProc; command: ["hyprctl", "dispatch", "togglespecialworkspace", "magic"]; running: false }
      Process { id: mediaHideProc; command: ["qs", "msg", "media", "hide"]; running: false }
      Process { id: hotkeysShowProc; command: ["qs", "msg", "hotkeys", "show"]; running: false }
      Process { id: hotkeysHideProc; command: ["qs", "msg", "hotkeys", "hide"]; running: false }
    }
  }
}
