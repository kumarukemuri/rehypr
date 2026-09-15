local outputs = require("config.outputs")

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
