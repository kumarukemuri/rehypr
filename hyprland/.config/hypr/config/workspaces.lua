local rule = hl.workspace_rule

--------------------------
-- Regular workspaces
--------------------------

-- Primary display

for _, id in ipairs({ 1, 2, 3, }) do
    rule({
        workspace = tostring(id),
        monitor = "DP-1",
        layout = "dwindle"
    })
end

-- Secondary display


for _, id in ipairs({ 5 }) do
    rule({
        workspace = tostring(id),
        monitor = "DP-2",
        layout = "scrolling",
        layout_opts = {
            direction = "down",
        },
    })
end

for _, id in ipairs({ 4 }) do
    rule({
        workspace = tostring(id),
        monitor = "HDMI-A-1",
        layout = "scrolling",
        layout_opts = {
            direction = "down",
        },
    })
end


-- TV
rule({
    workspace = 7,
    monitor = "HDMI-A-1",
    layout = "dwindle"
})

-- hl.workspace_rule({
--     workspace = "special:shell",
--     on_created_empty = "uwsm app -- kitty",
--     layout = "dwindle"
-- })
