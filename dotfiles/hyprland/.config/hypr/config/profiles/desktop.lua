local profile = {
    name = "desktop",
    outputs = { main = "DP-1", left = "HDMI-A-1", right = "DP-2" },
    autostart = { "kitty", "zen-browser", "mattermost-desktop" },
    devices = {
        { name = "compx-io-aurora-1", sensitivity = -0.4, accel_profile = "flat" },
        { name = "compx-io-aurora-receiver-1", sensitivity = -0.4, accel_profile = "flat" },
    },
}

function profile.monitors()
local outputs = { main = "DP-1", left = "HDMI-A-1", right = "DP-2" }

hl.config({
    render = {
        cm_enabled = true,
        cm_auto_hdr = 1,
    }
})

hl.monitor({
    output = outputs.main,
    mode = "3440x1440@360",
    position = "0x0",
    scale = 1,
    bitdepth = 10,
    cm = "srgb",
})

hl.monitor({
    output = outputs.right,
    mode = "2560x1440@120",
    position = "3440x-300",
    scale = 1,
    transform = 3,
    bitdepth = 8,
    cm = "srgb",
    vrr = 0,
})

hl.monitor({
    output = outputs.left,
    mode = "2560x1440@120",
    position = "-1440x-300",
    scale = 1,
    transform = 1,
    bitdepth = 8,
    cm = "srgb",
    vrr = 0,
})

end

function profile.workspaces()
local outputs = profile.outputs
local rule = hl.workspace_rule

--------------------------
-- Regular workspaces
--------------------------

-- Primary display

for _, id in ipairs({ 1, 2, 3, }) do
    rule({
        workspace = tostring(id),
        monitor = outputs.main,
        layout = "dwindle"
    })
end

-- Secondary display


for _, id in ipairs({ 5 }) do
    rule({
        workspace = tostring(id),
        monitor = outputs.right,
        layout = "scrolling",
        layout_opts = {
            direction = "up",
        },
    })
end

for _, id in ipairs({ 4 }) do
    rule({
        workspace = tostring(id),
        monitor = outputs.left,
        layout = "scrolling",
        layout_opts = {
            direction = "up",
        },
    })
end


-- TV
rule({
    workspace = 7,
    monitor = outputs.left,
    layout = "dwindle"
})


end

return profile
