local helpers = require("config.profiles.laptop.hotplug")

return function(outputs)
    local panel = outputs.main
    hl.monitor({ output = panel, mode = "preferred", scale = 2, position = "0x0", bitdepth = 8 })
    -- A newly connected output has a usable mode before its final position is calculated.
    hl.monitor({ output = "", mode = "preferred", scale = 1, position = "auto-right", bitdepth = 8 })

    helpers.setup_external_monitors(panel)
end
