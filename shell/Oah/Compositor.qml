pragma Singleton

// OAH(x11): bspwm-backed stand-in for Quickshell.Hyprland's `Hyprland`
// singleton. The import tool rewrites upstream's `Hyprland.` uses to
// `Compositor.`, so the shell keeps calling the API it calls on Hyprland:
//
//   workspaces.values  { id, name, monitor, active, focused, urgent, hasFullscreen, toplevels.values, lastIpcObject }
//   monitors.values    { id, name, focused, activeWorkspace, x, y, width, height, scale, lastIpcObject }
//   toplevels.values   { address, title, appId, workspace, monitor, urgent, activated, lastIpcObject }
//   focusedMonitor, focusedWorkspace, monitorFor(screen), rawEvent(event)
//   refreshMonitors(), refreshWorkspaces(), refreshToplevels(), dispatch(request)
//
// Like Quickshell's Hyprland module, every monitor, workspace and window is
// one long-lived QObject, kept by its bspwm id and updated in place, so
// bindings and `Connections { target: monitor }` see change signals instead
// of replaced objects, and a `values` list is only reassigned when its
// membership changes. State comes from `bspc wm -d`, re-read when
// `bspc subscribe` reports a change. A desktop named "3" is workspace 3, and
// as on Hyprland a workspace only exists while it's shown or has windows.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // Hyprland-style raw events for upstream's
  // `Connections { target: Hyprland; function onRawEvent(event) }`:
  // { name, data, parse(n) }, where data is Hyprland's comma-separated payload
  // and parse(n) splits it into n fields, the last keeping any commas.
  signal rawEvent(var event)

  function emitEvent(name, data) {
    var payload = String(data || "")
    root.rawEvent({
      name: name,
      data: payload,
      parse: function(count) {
        var parts = payload.split(",")
        if (!count || parts.length <= count) return parts
        return parts.slice(0, count - 1).concat([parts.slice(count - 1).join(",")])
      }
    })
  }

  property bool primed: false

  readonly property QtObject workspaces: QtObject { property var values: [] }
  readonly property QtObject monitors: QtObject { property var values: [] }
  readonly property QtObject toplevels: QtObject { property var values: [] }
  property QtObject focusedMonitor: null
  property QtObject focusedWorkspace: null

  component MonitorObject: QtObject {
    property int id
    property string name
    property bool focused
    property QtObject activeWorkspace: null
    property int x
    property int y
    property int width
    property int height
    property real scale: 1
    property var lastIpcObject: ({})
  }

  component WorkspaceObject: QtObject {
    property int id
    property string name
    property QtObject monitor: null
    property bool active
    property bool focused
    property bool urgent
    property bool hasFullscreen
    readonly property QtObject toplevels: QtObject { property var values: [] }
    property var lastIpcObject: ({})
  }

  component ToplevelObject: QtObject {
    property string address
    property string title
    property string appId
    property QtObject workspace: null
    property QtObject monitor: null
    property bool urgent
    property bool activated
    property var lastIpcObject: ({})
  }

  Component { id: monitorComponent; MonitorObject {} }
  Component { id: workspaceComponent; WorkspaceObject {} }
  Component { id: toplevelComponent; ToplevelObject {} }

  // Live objects by key (monitor name, workspace id, window address).
  property var monitorObjects: ({})
  property var workspaceObjects: ({})
  property var toplevelObjects: ({})

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

  // Hyprland dispatchers the shell sends itself. Only the ones upstream's QML
  // uses are translated; anything else is logged so it shows up while porting.
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

  property bool refreshPending: false

  function refresh() {
    if (stateProc.running) {
      root.refreshPending = true
      return
    }
    stateProc.running = true
  }

  function hex(id) {
    return "0x" + Number(id).toString(16)
  }

  function workspaceId(name, index) {
    var n = parseInt(name, 10)
    return isNaN(n) ? index + 1 : n
  }

  // Assign only real changes, so unchanged state emits no change signals.
  function set(obj, prop, value) {
    if (obj[prop] !== value) obj[prop] = value
  }
  function setIpc(obj, value) {
    if (JSON.stringify(obj.lastIpcObject) !== JSON.stringify(value)) obj.lastIpcObject = value
  }
  function sameMembers(list, next) {
    if (list.length !== next.length) return false
    for (var i = 0; i < list.length; i++) if (list[i] !== next[i]) return false
    return true
  }

  function obtain(store, key, component) {
    var obj = store[key]
    if (!obj) {
      obj = component.createObject(root)
      store[key] = obj
    }
    return obj
  }

  function retire(store, live) {
    for (var key in store) {
      if (!live[key]) {
        store[key].destroy()
        delete store[key]
      }
    }
  }

  // The state command prints bspwm's JSON on line 1, then one
  // "id<TAB>pid<TAB>title" line per window (titles and pids aren't in it).
  function apply(text) {
    var lines = String(text || "").split("\n")
    var state
    try {
      state = JSON.parse(lines[0])
    } catch (e) {
      console.warn("OAH Compositor: unreadable bspwm state:", e)
      return
    }
    var extra = {}
    for (var l = 1; l < lines.length; l++) {
      var f = lines[l].split("\t")
      if (f.length >= 3) extra[parseInt(f[0], 10)] = { pid: parseInt(f[1], 10) || -1, title: f.slice(2).join("\t") }
    }

    // Hyprland's focusHistoryID: 0 for the most recently focused window.
    var history = {}
    var order = 0
    var fh = state.focusHistory || []
    for (var h = fh.length - 1; h >= 0; h--) {
      var nid = fh[h].nodeId
      if (nid && history[nid] === undefined) history[nid] = order++
    }

    var liveMonitors = {}, liveWorkspaces = {}, liveToplevels = {}
    var monitorList = [], workspaceList = [], toplevelList = []
    var focusedMonitor = null, focusedWorkspace = null

    for (var m = 0; m < state.monitors.length; m++) {
      var bm = state.monitors[m]
      var rect = bm.rectangle || { x: 0, y: 0, width: 0, height: 0 }
      var mon = root.obtain(root.monitorObjects, bm.name, monitorComponent)
      liveMonitors[bm.name] = true
      var monFocused = bm.id === state.focusedMonitorId
      root.set(mon, "id", m)
      root.set(mon, "name", bm.name)
      root.set(mon, "focused", monFocused)
      root.set(mon, "x", rect.x)
      root.set(mon, "y", rect.y)
      root.set(mon, "width", rect.width)
      root.set(mon, "height", rect.height)
      var activeWs = null

      for (var d = 0; d < bm.desktops.length; d++) {
        var bd = bm.desktops[d]
        var wsId = root.workspaceId(bd.name, workspaceList.length)
        var active = bd.id === bm.focusedDesktopId
        var clients = []
        root.collectClients(bd.root, clients)
        if (!active && clients.length === 0) continue  // Hyprland semantics

        var ws = root.obtain(root.workspaceObjects, wsId, workspaceComponent)
        liveWorkspaces[wsId] = true
        root.set(ws, "id", wsId)
        root.set(ws, "name", bd.name)
        root.set(ws, "monitor", mon)
        root.set(ws, "active", active)
        root.set(ws, "focused", active && monFocused)

        var wsToplevels = [], urgent = false, hasFullscreen = false, lastWindow = null
        for (var c = 0; c < clients.length; c++) {
          var node = clients[c]
          var client = node.client
          var address = root.hex(node.id)
          var info = extra[node.id] || { pid: -1, title: "" }
          var r = (client.state === "floating" ? client.floatingRectangle : client.tiledRectangle) || node.rectangle
          var fullscreen = client.state === "fullscreen" ? 2 : 0
          var tl = root.obtain(root.toplevelObjects, address, toplevelComponent)
          liveToplevels[address] = true
          root.set(tl, "address", address)
          root.set(tl, "title", info.title)
          root.set(tl, "appId", client.className || "")
          root.set(tl, "workspace", ws)
          root.set(tl, "monitor", mon)
          root.set(tl, "urgent", !!client.urgent)
          root.set(tl, "activated", node.id === bd.focusedNodeId && active && monFocused)
          root.setIpc(tl, {
            address: address, mapped: true, hidden: !!node.hidden,
            at: [r.x, r.y], size: [r.width, r.height],
            workspace: { id: wsId, name: bd.name },
            floating: client.state === "floating", pseudo: client.state === "pseudo_tiled",
            monitor: m, class: client.className || "", title: info.title,
            initialClass: client.className || "", initialTitle: info.title,
            pid: info.pid, xwayland: false, pinned: !!node.sticky,
            fullscreen: fullscreen, fullscreenClient: fullscreen,
            focusHistoryID: history[node.id] !== undefined ? history[node.id] : -1
          })
          wsToplevels.push(tl)
          toplevelList.push(tl)
          if (client.urgent) urgent = true
          if (fullscreen) hasFullscreen = true
          if (node.id === bd.focusedNodeId) lastWindow = tl
        }
        if (!root.sameMembers(ws.toplevels.values, wsToplevels)) ws.toplevels.values = wsToplevels
        root.set(ws, "urgent", urgent)
        root.set(ws, "hasFullscreen", hasFullscreen)
        root.setIpc(ws, {
          id: wsId, name: bd.name, monitor: bm.name, monitorID: m, windows: wsToplevels.length,
          hasfullscreen: hasFullscreen,
          lastwindow: lastWindow ? lastWindow.address : "0x0",
          lastwindowtitle: lastWindow ? lastWindow.title : ""
        })

        workspaceList.push(ws)
        if (active) activeWs = ws
        if (active && monFocused) focusedWorkspace = ws
      }

      root.set(mon, "activeWorkspace", activeWs)
      root.setIpc(mon, {
        id: m, name: bm.name, focused: monFocused,
        x: rect.x, y: rect.y, width: rect.width, height: rect.height, scale: 1, transform: 0,
        reserved: [bm.padding.left, bm.padding.top, bm.padding.right, bm.padding.bottom],
        activeWorkspace: activeWs ? { id: activeWs.id, name: activeWs.name } : null
      })
      monitorList.push(mon)
      if (monFocused) focusedMonitor = mon
    }

    if (!root.sameMembers(root.monitors.values, monitorList)) root.monitors.values = monitorList
    if (!root.sameMembers(root.workspaces.values, workspaceList)) root.workspaces.values = workspaceList
    if (!root.sameMembers(root.toplevels.values, toplevelList)) root.toplevels.values = toplevelList
    root.set(root, "focusedMonitor", focusedMonitor)
    root.set(root, "focusedWorkspace", focusedWorkspace)

    // Window open/close events in Hyprland's shapes (openwindow:
    // ADDRESS,WORKSPACE,CLASS,TITLE; closewindow: ADDRESS, addresses without
    // 0x), diffed here because bspwm's own events carry different payloads.
    // Like Hyprland, nothing is reported for windows open at startup.
    var opened = [], closed = []
    if (root.primed) {
      for (var t = 0; t < toplevelList.length; t++) {
        if (root.knownAddresses.indexOf(toplevelList[t].address) === -1) opened.push(toplevelList[t])
      }
      for (var k = 0; k < root.knownAddresses.length; k++) {
        if (!liveToplevels[root.knownAddresses[k]]) closed.push(root.knownAddresses[k])
      }
    }
    root.knownAddresses = toplevelList.map(function(x) { return x.address })
    root.primed = true

    // Objects that left are destroyed only after the lists stop naming them.
    root.retire(root.toplevelObjects, liveToplevels)
    root.retire(root.workspaceObjects, liveWorkspaces)
    root.retire(root.monitorObjects, liveMonitors)

    for (var o = 0; o < opened.length; o++) {
      var w = opened[o]
      root.emitEvent("openwindow", [w.address.replace(/^0x/, ""), w.workspace ? w.workspace.name : "", w.appId, w.title].join(","))
    }
    for (var c2 = 0; c2 < closed.length; c2++) root.emitEvent("closewindow", closed[c2].replace(/^0x/, ""))
  }

  // Addresses of the windows the last update reported, for open/close events.
  property var knownAddresses: []

  function collectClients(node, out) {
    if (!node) return
    if (node.client) out.push(node)
    root.collectClients(node.firstChild, out)
    root.collectClients(node.secondChild, out)
  }

  // bspwm event -> the Hyprland raw event upstream listens for.
  function translate(line) {
    var name = String(line).split(" ")[0]
    if (name === "desktop_focus") return "workspacev2"
    if (name === "desktop_transfer") return "moveworkspacev2"
    if (name === "desktop_rename") return "renameworkspace"
    if (name === "node_focus") return "activewindowv2"
    if (name === "node_state" && line.indexOf("fullscreen") !== -1) return "fullscreen"
    // openwindow/closewindow come from apply(), with Hyprland payloads.
    if (name === "node_transfer") return "movewindowv2"
    if (name === "monitor_add") return "monitoraddedv2"
    if (name === "monitor_remove") return "monitorremovedv2"
    if (name === "monitor_focus") return "focusedmonv2"
    return ""
  }

  Process {
    id: stateProc
    command: ["bash", "-c",
      "bspc wm -d | tr -d '\\n'; echo; " +
      "for n in $(bspc query -N -n .window 2>/dev/null); do " +
      "printf '%d\\t%s\\t%s\\n' \"$n\" \"$(xdotool getwindowpid \"$n\" 2>/dev/null)\" " +
      "\"$(xdotool getwindowname \"$n\" 2>/dev/null | tr -d '\\n\\t')\"; done"]
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
      onRead: function(line) {
        var name = root.translate(line)
        // Events only checked by name; their bspwm payload rides along.
        if (name) root.emitEvent(name, String(line))
        debounce.restart()
      }
    }
    // bspwm restarting (bspc wm -r) ends the subscription; pick it back up.
    onExited: resubscribe.start()
  }

  Timer {
    id: resubscribe
    interval: 1000
    onTriggered: {
      subscribe.running = true
      // Changes during the gap produced no events; read the state again.
      root.refresh()
    }
  }

  Component.onCompleted: root.refresh()
}
