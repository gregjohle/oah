-- Run upstream Omarchy's Hyprland binding modules with a recording `hl` stub
-- and print every binding they register, one per line:
--
--   keys <TAB> description <TAB> kind <TAB> action <TAB> flags
--
--   kind   cmd       action is a shell command
--          dsp       action is a Hyprland dispatcher call (hl.dsp.*(...))
--          global    action is a Hyprland global shortcut name
--          expr      action is an upstream Lua helper call (e.g. o.workspaces.focus(3))
--          function  a Lua function with no command equivalent
--   flags  comma-separated: release, locked, repeating, mouse, ignore_mods
--
-- Usage: OMARCHY_PATH=<upstream> lua collect-bindings.lua <upstream>
-- The modules load in the order upstream's default/hypr/omarchy.lua uses.

local root = assert(arg[1], "usage: collect-bindings.lua <omarchy checkout>")
package.path = root .. "/?.lua;" .. package.path

local function serialize(value)
  local t = type(value)
  if t == "string" then
    return string.format("%q", value)
  elseif t == "table" then
    local keys = {}
    for k in pairs(value) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do
      if type(k) == "number" then
        parts[#parts + 1] = serialize(value[k])
      else
        parts[#parts + 1] = k .. " = " .. serialize(value[k])
      end
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
  end
  return tostring(value)
end

local function dispatcher(path)
  return setmetatable({}, {
    __index = function(_, key)
      return dispatcher(path == "" and key or (path .. "." .. key))
    end,
    __call = function(_, ...)
      local args, parts = { ... }, {}
      for i = 1, select("#", ...) do parts[#parts + 1] = serialize(args[i]) end
      return { __dsp = true, name = path, args = args, call = "hl.dsp." .. path .. "(" .. table.concat(parts, ", ") .. ")" }
    end,
  })
end

local records = {}
local noop = function() end

hl = setmetatable({
  dsp = dispatcher(""),
  bind = function(keys, action, opts) records[#records + 1] = { keys = keys, action = action, opts = opts or {} } end,
  unbind = function(keys)
    for i = #records, 1, -1 do
      if records[i].keys == keys then table.remove(records, i) end
    end
  end,
  get_active_window = function() return nil end,
}, {
  -- Everything else upstream touches (hl.config, hl.on, hl.timer, ...) is a no-op.
  __index = function() return noop end,
})

require("default.hypr.helpers")
require("default.hypr.monitor-workspaces")
local require_optional = require("default.hypr.require_optional")

if _G.omarchy_default_bindings ~= false then
  for _, name in ipairs({ "media", "clipboard", "input-method", "jis", "tiling", "utilities", "dictation" }) do
    require("default.hypr.bindings." .. name)
  end
  require_optional.module("default.hypr.bindings.applications")
end

local function clean(s)
  return (tostring(s or ""):gsub("[\t\n]", " "))
end

for _, r in ipairs(records) do
  local kind, action = "function", ""
  local a = r.action
  if type(a) == "table" and a.__dsp then
    if a.name == "exec_cmd" then
      kind, action = "cmd", a.args[1]
    elseif a.name == "global" then
      kind, action = "global", a.args[1]
    else
      kind, action = "dsp", a.call
    end
  elseif type(a) == "function" then
    local command = o.bind_commands and o.bind_commands[a]
    local expression = o.bind_expressions and o.bind_expressions[a]
    if command then
      kind, action = "cmd", command
    elseif expression then
      kind, action = "expr", expression
    end
  elseif type(a) == "string" then
    kind, action = "cmd", a
  end

  local flags = {}
  for _, f in ipairs({ "release", "locked", "repeating", "mouse", "ignore_mods" }) do
    if r.opts[f] then flags[#flags + 1] = f end
  end

  print(table.concat({ clean(r.keys), clean(r.opts.description), kind, clean(action), table.concat(flags, ",") }, "\t"))
end
