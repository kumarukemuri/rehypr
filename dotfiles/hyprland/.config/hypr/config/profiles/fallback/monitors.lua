return function()
    -- Match any output without assuming connector names or display capabilities.
    hl.monitor({ output = "", mode = "preferred", scale = 1, position = "auto", bitdepth = 8 })
end
