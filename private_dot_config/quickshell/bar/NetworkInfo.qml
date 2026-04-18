pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root
  property string networkText: "  Offline"

  Process {
    id: netProc
    command: ["sh", "-c", "if nmcli -t -f TYPE,STATE d 2>/dev/null | grep -q 'ethernet:connected'; then echo '  Wired'; elif nmcli -t -f TYPE,STATE d 2>/dev/null | grep -q 'wifi:connected'; then ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2); echo \"  $ssid\"; else echo '  Offline'; fi"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.networkText = text.trim() }
  }

  Timer {
    interval: 5000; running: true; repeat: true
    onTriggered: netProc.running = true
  }
}
