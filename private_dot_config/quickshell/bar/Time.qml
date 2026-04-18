pragma Singleton
import Quickshell
import QtQuick

Singleton {
  readonly property string timeString: Qt.formatDateTime(clock.date, "HH:mm")

  readonly property var jpMonths: ["一月","二月","三月","四月","五月","六月","七月","八月","九月","十月","十一月","十二月"]
  readonly property var jpWeekdays: ["日","月","火","水","木","金","土"]

  function toKanjiNum(n) {
    const ones = ["","一","二","三","四","五","六","七","八","九"];
    if (n === 10) return "十";
    if (n < 10) return ones[n];
    if (n < 20) return "十" + (n > 10 ? ones[n - 10] : "");
    const tens = Math.floor(n / 10);
    const rem = n % 10;
    return ones[tens] + "十" + (rem === 0 ? "" : ones[rem]);
  }

  readonly property string dateString: {
    const d = clock.date;
    return jpMonths[d.getMonth()] + toKanjiNum(d.getDate()) + "日 (" + jpWeekdays[d.getDay()] + ")";
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
