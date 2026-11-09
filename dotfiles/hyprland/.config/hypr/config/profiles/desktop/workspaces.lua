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

    -- Vertical display
    hl.config({ scrolling = { column_width = 0.33, fullscreen_on_one_column = false, wrap_swapcol = false } })
    for _, id in ipairs({ 4, 5, 7 }) do
        rule({
            workspace = tostring(id),
            monitor = outputs.secondary,
            layout = "scrolling",
            layout_opts = { direction = "down" },
        })
    end

end
