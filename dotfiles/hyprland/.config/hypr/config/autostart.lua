local function app(cmd)
    hl.exec_cmd("uwsm app -- " .. cmd)
end

hl.on("hyprland.start", function()
    local user_apps = {
        "kitty",
        "zen-browser",
        "mattermost-desktop",
    }

    for _, cmd in ipairs(user_apps) do
        app(cmd)
    end
end)
