local profile = require("config.profiles.init")
hl.on("hyprland.start", function()
    for _, cmd in ipairs(profile.autostart) do
        hl.exec_cmd("uwsm app -- " .. cmd)
    end
end)
