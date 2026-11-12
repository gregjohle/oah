-- OAH(x11): run upstream Omarchy's window rules (default/hypr/windows.lua,
-- which loads every default/hypr/apps/*.lua) with a recording `hl` stub and
-- print every hl.window_rule() call as one JSON object per line, in order.
--
-- Usage: OMARCHY_PATH=<root> lua collect-window-rules.lua <root>
-- tools/oah-gen-window-rules turns the output into bspwm rules.

local root = assert(arg[1], "usage: collect-window-rules.lua <omarchy root>")
package.path = root .. "/?.lua;" .. package.path

local function json(value)
  local t = type(value)
  if t == "string" then
    return '"' .. value:gsub('[%c"\\]', function(c)
      local named = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\t"] = "\\t" }
      return named[c] or string.format("\\u%04x", c:byte())
    end) .. '"'
  elseif t == "number" or t == "boolean" then
    return tostring(value)
  elseif t == "table" then
    if #value > 0 then
      local parts = {}
      for _, v in ipairs(value) do parts[#parts + 1] = json(v) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local keys = {}
    for k in pairs(value) do keys[#keys + 1] = tostring(k) end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = json(k) .. ":" .. json(value[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "null"
end

local noop = function() end

hl = setmetatable({
  window_rule = function(rule) print(json(rule)) end,
}, {
  -- Everything else upstream touches (hl.layer_rule, hl.config, hl.on, ...) is a no-op.
  __index = function() return noop end,
})

require("default.hypr.helpers")
require("default.hypr.windows")
