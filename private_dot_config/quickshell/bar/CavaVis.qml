pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root
  property string bars: "▁▁▁▁▁▁▁▁▁▁"

  Process {
    id: cavaProc
    command: ["sh", "-c", "~/.config/quickshell/bar/scripts/cava-bars"]
    running: true
    stdout: SplitParser {
      onRead: data => { root.bars = data.trim() }
    }
  }
}
