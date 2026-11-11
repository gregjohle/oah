pragma Singleton

// OAH(x11): bspwm-backed stand-in for Quickshell.Hyprland's `Hyprland`
// singleton. The import tool rewrites upstream's `Hyprland.` uses to
// `Compositor.`, so the shell keeps calling the same API it calls on
// Hyprland:
//
//   workspaces.values  { id, name, monitor, active, focused, urgent, toplevels.values }
//   monitors.values    { id, name, focused, activeWorkspace, x, y, width, height, scale, lastIpcObject }
//   toplevels.values   { address, title, appId, workspace, monitor, lastIpcObject }
//   focusedMonitor, focusedWorkspace, monitorFor(screen)
//   refreshMonitors(), refreshWorkspaces(), refreshToplevels(), dispatch(request)
//
// State comes from `bspc wm -d` (one JSON dump of monitors, desktops and the
// window tree), re-read whenever `bspc subscribe` reports a change. Desktops
// are Omarchy's workspaces: a desktop named "3" is workspace 3.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var workspaces: ({ values: [] })
  property var monitors: ({ values: [] })
  property var toplevels: ({ values: [] })
  property var focusedMonitor: null
  property var focusedWorkspace: null

  function monitorFor(screen) {
    if (!screen) return null
    var values = root.monitors.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].name === screen.name) return values[i]
    }
    // A single-monitor session whose X screen name differs from bspwm's
    // RandR output name still has exactly one monitor to offer.
    return values.length === 1 ? values[0] : null
  }

  function refreshMonitors() { root.refresh() }
  function refreshWorkspaces() { root.refresh() }
  function refreshToplevels() { root.refresh() }

  // Hyprland dispatchers the shell sends. Only the ones upstream's QML uses
  // are translated; anything else is logged so it shows up during porting.
  function dispatch(request) {
    var text = String(request || "")
    var address = /address:(0x[0-9a-fA-F]+)/.exec(text)
    if (address && text.indexOf("focus") !== -1) {
      Quickshell.execDetached(["bspc", "node", address[1], "-f"])
      return
    }
    var workspace = /workspace\s*=\s*"?([0-9]+)"?/.exec(text)
    if (workspace && text.indexOf("focus") !== -1) {
      Quickshell.execDetached(["bspc", "desktop", "-f", workspace[1]])
      return
    }
    console.warn("OAH Compositor: unsupported Hyprland dispatch:", text)
  }

  function refresh() {
    if (stateProc.running) {
      root.refreshPending = true
      return
    }
    stateProc.running = true
  }

  property bool refreshPending: false

  function hex(id) {
    return "0x" + Number(id).toString(16)
  }

  function workspaceId(name, index) {
    var n = parseInt(name, 10)
    return isNaN(n) ? index + 1 : n
  }

  // Window titles aren't in bspwm's dump, so the state command appends one
  // "id<TAB>title" line per window after the JSON.
  function apply(text) {
    var lines = String(text || "").split("\n")
    var state
    try {
      state = JSON.parse(lines[0])
    } catch (e) {
      console.warn("OAH Compositor: unreadable bspwm state:", e)
      return
    }
    var titles = {}
    for (var l = 1; l < lines.length; l++) {
      var tab = lines[l].indexOf("\t")
      if (tab > 0) titles[parseInt(lines[l].slice(0, tab), 10)] = lines[l].slice(tab + 1)
    }

    var monitors = [], workspaces = [], toplevels = []
    var focusedMonitor = null, focusedWorkspace = null

    for (var m = 0; m < state.monitors.length; m++) {
      var bm = state.monitors[m]
      var rect = bm.rectangle || { x: 0, y: 0, width: 0, height: 0 }
      var monitor = {
        id: m,
        name: bm.name,
        focused: bm.id === state.focusedMonitorId,
        activeWorkspace: null,
        x: rect.x, y: rect.y, width: rect.width, height: rect.height,
        scale: 1,
        lastIpcObject: {
          id: m, name: bm.name, focused: bm.id === state.focusedMonitorId,
          x: rect.x, y: rect.y, width: rect.width, height: rect.height,
          scale: 1, transform: 0,
          reserved: [bm.padding.left, bm.padding.top, bm.padding.right, bm.padding.bottom]
        }
      }

      for (var d = 0; d < bm.desktops.length; d++) {
        var bd = bm.desktops[d]
        var workspace = {
          id: root.workspaceId(bd.name, workspaces.length),
          name: bd.name,
          monitor: monitor,
          active: bd.id === bm.focusedDesktopId,
          focused: bd.id === bm.focusedDesktopId && monitor.focused,
          urgent: false,
          toplevels: { values: [] },
          lastIpcObject: { id: root.workspaceId(bd.name, workspaces.length), name: bd.name, monitor: bm.name, windows: 0 }
        }
        root.collectClients(bd.root, workspace, monitor, titles, toplevels)
        workspace.lastIpcObject.windows = workspace.toplevels.values.length
        // Hyprland only has a workspace while it's shown or has windows;
        // bspwm desktops always exist. Report Hyprland's view, which is what
        // the bar's "first five plus any others that exist" logic expects.
        if (workspace.active || workspace.toplevels.values.length > 0) workspaces.push(workspace)
        if (workspace.active) monitor.activeWorkspace = workspace
        if (workspace.focused) focusedWorkspace = workspace
      }

      monitor.lastIpcObject.activeWorkspace = monitor.activeWorkspace
        ? { id: monitor.activeWorkspace.id, name: monitor.activeWorkspace.name } : null
      monitors.push(monitor)
      if (monitor.focused) focusedMonitor = monitor
    }

    root.monitors = { values: monitors }
    root.workspaces = { values: workspaces }
    root.toplevels = { values: toplevels }
    root.focusedMonitor = focusedMonitor
    root.focusedWorkspace = focusedWorkspace
  }

  function collectClients(node, workspace, monitor, titles, out) {
    if (!node) return
    if (node.client) {
      var c = node.client
      var rect = c.state === "floating" ? c.floatingRectangle : c.tiledRectangle
      rect = rect || node.rectangle || { x: 0, y: 0, width: 0, height: 0 }
      var fullscreen = c.state === "fullscreen" ? 2 : 0
      var toplevel = {
        address: root.hex(node.id),
        title: titles[node.id] || "",
        appId: c.className || "",
        workspace: workspace,
        monitor: monitor,
        urgent: !!c.urgent,
        lastIpcObject: {
          address: root.hex(node.id),
          class: c.className || "",
          initialClass: c.className || "",
          title: titles[node.id] || "",
          floating: c.state === "floating",
          fullscreen: fullscreen,
          fullscreenClient: fullscreen,
          hidden: !!node.hidden,
          pinned: !!node.sticky,
          workspace: { id: workspace.id, name: workspace.name },
          monitor: monitor.id,
          at: [rect.x, rect.y],
          size: [rect.width, rect.height]
        }
      }
      workspace.toplevels.values.push(toplevel)
      if (toplevel.urgent) workspace.urgent = true
      out.push(toplevel)
    }
    root.collectClients(node.firstChild, workspace, monitor, titles, out)
    root.collectClients(node.secondChild, workspace, monitor, titles, out)
  }

  Process {
    id: stateProc
    command: ["bash", "-c",
      "bspc wm -d | tr -d '\\n'; echo; " +
      "for n in $(bspc query -N -n .window 2>/dev/null); do " +
      "printf '%d\\t%s\\n' \"$n\" \"$(xdotool getwindowname \"$n\" 2>/dev/null | tr -d '\\n\\t')\"; done"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.apply(text)
    }
    onExited: {
      if (root.refreshPending) {
        root.refreshPending = false
        stateProc.running = true
      }
    }
  }

  // Coalesce bursts of bspwm events (a window opening reports several).
  Timer {
    id: debounce
    interval: 30
    onTriggered: root.refresh()
  }

  Process {
    id: subscribe
    running: true
    command: ["bspc", "subscribe", "monitor", "desktop", "node"]
    stdout: SplitParser {
      onRead: function(line) { debounce.restart() }
    }
    // bspwm restarting (bspc wm -r) ends the subscription; pick it back up.
    onExited: resubscribe.start()
  }

  Timer {
    id: resubscribe
    interval: 1000
    onTriggered: subscribe.running = true
  }

  Component.onCompleted: root.refresh()
}
