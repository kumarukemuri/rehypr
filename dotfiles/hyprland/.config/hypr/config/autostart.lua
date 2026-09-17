local profile = require("config.profile")
hl.on("hyprland.start", function()
    for _, cmd in ipairs(profile.autostart) do
        hl.exec_cmd("uwsm app -- " .. cmd)
    end
end)
