return function(outputs)
    hl.config({
        render = {
            cm_enabled = true,
            cm_auto_hdr = 0,
        }
    })

    hl.monitor({
        output = outputs.main,
        mode = "3440x1440@360",
        position = "0x0",
        scale = 1,
        bitdepth = 10,
        cm = "srgb",
        vrr = 3,
    })

    hl.monitor({
        output = outputs.secondary,
        mode = "2560x1440@165",
        position = "-1440x-400",
        scale = 1,
        transform = 1,
        bitdepth = 8,
        cm = "srgb",
        vrr = 0,
    })
end
