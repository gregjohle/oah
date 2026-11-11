// OAH(x11): stand-in for Quickshell.Wayland's IdleMonitor (ext-idle-notify,
// Wayland only). The import tool rewrites upstream's `IdleMonitor {` to this
// type. Same API: set `timeout` (seconds) and `enabled`, read `isIdle`.
// Idle time comes from the X server via bin/oah-x11-idle.
//
// `respectInhibitors` is accepted for API compatibility; X11 idle inhibitors
// (apps suspending the screensaver) aren't consulted yet.

import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property bool enabled: true
  property real timeout: 300
  property bool respectInhibitors: true
  readonly property bool isIdle: root.idle

  property bool idle: false

  property Process watcher: Process {
    running: root.enabled && root.timeout > 0
    command: ["oah-x11-idle", String(Math.max(1, root.timeout))]
    stdout: SplitParser {
      onRead: function(line) { root.idle = String(line).trim() === "idle" }
    }
    // A stopped or failed watcher can't report idleness.
    onRunningChanged: if (!running) root.idle = false
  }

  // A new timeout means a new watcher; the old one's state no longer applies.
  onTimeoutChanged: {
    if (!root.watcher.running) return
    root.watcher.running = false
    root.watcher.running = Qt.binding(function() { return root.enabled && root.timeout > 0 })
  }
}
