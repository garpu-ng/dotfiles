pragma Singleton
import Quickshell
import QtQuick

Singleton {
  readonly property string timeString: Qt.formatDateTime(clock.date, "HH:mm")
  readonly property string dateString: Qt.formatDateTime(clock.date, "ddd MMM d")

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
