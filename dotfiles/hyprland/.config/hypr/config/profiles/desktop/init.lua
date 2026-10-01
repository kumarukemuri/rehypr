local prefix = "config.profiles.desktop."
local outputs = require(prefix .. "outputs")
local monitors = require(prefix .. "monitors")
local workspaces = require(prefix .. "workspaces")

return {
    name = "desktop",
    outputs = outputs,
    devices = require(prefix .. "input"),
    autostart = require(prefix .. "autostart"),
    monitors = function() monitors(outputs) end,
    workspaces = function() workspaces(outputs) end,
}
