local prefix = "config.profiles.laptop."
local outputs = require(prefix .. "outputs")
local monitors = require(prefix .. "monitors")
local workspaces = require(prefix .. "workspaces")

return {
    name = "laptop",
    outputs = outputs,
    devices = require(prefix .. "input"),
    autostart = require(prefix .. "autostart"),
    monitors = function() monitors(outputs) end,
    workspaces = function() workspaces(outputs) end,
}
