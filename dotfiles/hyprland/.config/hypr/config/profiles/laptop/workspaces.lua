return function(outputs)
    for _, id in ipairs({ 1, 2, 3, 4, 5, 6 }) do
        hl.workspace_rule({ workspace = tostring(id), monitor = outputs.main, layout = "dwindle" })
    end
end
