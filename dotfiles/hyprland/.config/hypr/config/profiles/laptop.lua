local helpers = require("config.profiles.helpers")

local profile = {
    name = "laptop",
    outputs = { main = "eDP-1" },
    autostart = {},
    devices = {
        { name = "gxt7863:00-27c6:01e0-touchpad", sensitivity = 0.4, accel_profile = "adaptive" },
    },
}

function profile.workspaces()
    for _, id in ipairs({ 1, 2, 3, 4, 5, 6 }) do
        hl.workspace_rule({ workspace = tostring(id), monitor = profile.outputs.main, layout = "dwindle" })
    end
end

function profile.monitors()
    local panel = profile.outputs.main
    hl.monitor({ output = panel, mode = "preferred", scale = 2, position = "0x0", bitdepth = 8 })
    -- A newly connected output has a usable mode before its final position is calculated.
    hl.monitor({ output = "", mode = "preferred", scale = 1, position = "auto-right", bitdepth = 8 })

    helpers.setup_external_monitors(panel)
end

return profile
