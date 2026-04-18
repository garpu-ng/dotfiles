//@ pragma UseQApplication
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import QtQuick
import "bar"

Scope {
  Bar {}
  AudioPanel { id: audioPanel }
  PowerPanel { id: powerPanel }
  MediaPanel { id: mediaPanel }
  HotkeysPanel { id: hotkeysPanel }
  OSD {}
}
