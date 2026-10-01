return function()
    for id = 1, 9 do
        hl.workspace_rule({ workspace = tostring(id), layout = "dwindle" })
    end
end
