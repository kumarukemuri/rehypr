return function(outputs)
    local rule = hl.workspace_rule

    --------------------------
    -- Regular workspaces
    --------------------------

    -- Primary display

    for _, id in ipairs({ 1, 2, 3 }) do
        rule({
            workspace = tostring(id),
            monitor = outputs.main,
            layout = "dwindle"
        })
    end

    for _, id in ipairs({6}) do
        rule({
            workspace = tostring(id),
            monitor = outputs.main,
            layout = "master",
        })
    end

    for _, id in ipairs({ 4 }) do
        rule({
            workspace = tostring(id),
            monitor = outputs.up,
            layout = "dwindle",
        })
    end

    for _, id in ipairs({ 5 }) do
        rule({
            workspace = tostring(id),
            monitor = outputs.down,
            layout = "dwindle",
        })
    end




    -- TV
    rule({
        workspace = 7,
        monitor = outputs.left,
        layout = "dwindle"
    })
end
