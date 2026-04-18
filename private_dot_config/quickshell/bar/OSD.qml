import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io

Scope {
  id: root

  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  // ── State ──
  property bool showOsd: false
  property string osdIcon: ""
  property string osdLabel: ""
  property real osdValue: -1  // -1 = no bar, 0-1 = bar

  Timer {
    id: hideTimer
    interval: 1500
    onTriggered: root.showOsd = false
  }

  function showPopup(icon: string, label: string, value: real): void {
    osdIcon = icon;
    osdLabel = label;
    osdValue = value;
    showOsd = true;
    hideTimer.restart();
  }

  // ── Volume change listener ──
  property bool initialized: false
  property real lastVolume: -1
  property bool lastMuted: false

  Timer {
    id: initDelay; interval: 2000; running: true
    onTriggered: {
      root.lastVolume = Pipewire.defaultAudioSink?.audio?.volume ?? -1;
      root.lastMuted = Pipewire.defaultAudioSink?.audio?.muted ?? false;
      root.initialized = true;
    }
  }

  Connections {
    target: Pipewire.defaultAudioSink?.audio ?? null

    function onVolumeChanged() {
      if (!root.initialized) return;
      const vol = Pipewire.defaultAudioSink.audio.volume;
      if (Math.abs(vol - root.lastVolume) > 0.001) {
        const pct = Math.round(vol * 100);
        const icon = vol <= 0 ? "婢" : vol < 0.33 ? "" : vol < 0.66 ? "墳" : "";
        root.showPopup(icon, pct + "%", Math.min(vol, 1.0));
      }
      root.lastVolume = vol;
    }

    function onMutedChanged() {
      if (!root.initialized) return;
      const muted = Pipewire.defaultAudioSink.audio.muted;
      if (muted === root.lastMuted) return;
      root.lastMuted = muted;
      const vol = Pipewire.defaultAudioSink.audio.volume;
      root.showPopup(muted ? "婢" : "", muted ? "Muted" : Math.round(vol * 100) + "%", muted ? 0 : Math.min(vol, 1.0));
    }
  }

  // ── Capslock / Numlock listener ──
  Process {
    id: lockWatcher
    command: ["sh", "-c", "while true; do echo \"$(cat /sys/class/leds/input20::capslock/brightness 2>/dev/null),$(cat /sys/class/leds/input20::numlock/brightness 2>/dev/null)\"; sleep 0.3; done"]
    running: true

    property int readCount: 0
    property string lastState: ""

    stdout: SplitParser {
      onRead: data => {
        const state = data.trim();
        lockWatcher.readCount++;

        // Skip first 2 reads to establish baseline
        if (lockWatcher.readCount <= 2) {
          lockWatcher.lastState = state;
          return;
        }

        if (lockWatcher.lastState !== state) {
          const parts = state.split(",");
          const oldParts = lockWatcher.lastState.split(",");
          if (parts.length >= 2 && oldParts.length >= 2) {
            if (parts[0] !== oldParts[0]) {
              root.showPopup(parts[0] === "1" ? "" : "", parts[0] === "1" ? "Caps Lock ON" : "Caps Lock OFF", -1);
            }
            if (parts[1] !== oldParts[1]) {
              root.showPopup(parts[1] === "1" ? "" : "", parts[1] === "1" ? "Num Lock ON" : "Num Lock OFF", -1);
            }
          }
          lockWatcher.lastState = state;
        }
      }
    }
  }

  // ── OSD Window ──
  LazyLoader {
    active: true

    PanelWindow {
      visible: root.showOsd
      anchors { bottom: true; left: true; right: true }
      margins.bottom: 80
      implicitWidth: 220
      implicitHeight: root.osdValue >= 0 ? 64 : 44
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "quickshell-osd"
      exclusionMode: ExclusionMode.Ignore

      Rectangle {
        anchors.centerIn: parent
        width: 250
        height: parent.height
        radius: 14
        color: "#c0121216"
        border.width: 1
        border.color: "#0fffffff"

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 10
          spacing: 6

          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Text {
              text: root.osdIcon
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 18
              color: "#e0ffffff"
            }

            Text {
              text: root.osdLabel
              font.family: "Jost"
              font.pixelSize: 14
              font.weight: Font.Medium
              color: "#e0ffffff"
            }
          }

          // Volume bar (only for volume changes)
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: "#14ffffff"
            visible: root.osdValue >= 0

            Rectangle {
              width: parent.width * Math.min(root.osdValue, 1.0)
              height: parent.height
              radius: 2
              color: "#a6ffffff"

              Behavior on width { NumberAnimation { duration: 100 } }
            }
          }
        }
      }
    }
  }
}
