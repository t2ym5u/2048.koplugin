local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
package.path = _dir .. "?.lua;" .. _dir .. "common/?.lua;" .. package.path

local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local PluginBase  = require("plugin_base")
local _           = require("gettext")

require("i18n").extend(lrequire("i18n_fr"))
local Game2048Screen = lrequire("screen")

local Game2048 = PluginBase:extend{
    name      = "2048",
    menu_text = _("2048"),
    menu_hint = "tools",
}

function Game2048:createScreen()
    return Game2048Screen:new{ plugin = self }
end

return Game2048
