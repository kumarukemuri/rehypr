return function(outputs)
    hl.config({
        render = {
            cm_enabled = true,
            cm_auto_hdr = 1,
        }
    })

    hl.monitor({
        output = outputs.main,
        mode = "3440x1440@360",
        position = "2560x500",
        scale = 1,
        bitdepth = 10,
        cm = "srgb",
    })

    hl.monitor({
        output = outputs.up,
        mode = "2560x1440@120",
        position = "0x0",
        scale = 1,
        transform = 2,
        bitdepth = 8,
        cm = "srgb",
        vrr = 0,
    })

    hl.monitor({
        output = outputs.down,
        mode = "2560x1440@120",
        position = "0x1440",
        scale = 1,
        transform = 0,
        bitdepth = 8,
        cm = "srgb",
        vrr = 0,
    })
end
