hl.device({
    name = "compx-io-aurora-1", -- Mouse via wire
    sensitivity = -0.4,
    accel_profile = "flat",
})

hl.device({
    name = "compx-io-aurora-receiver-1", -- Mouse receiver
    sensitivity = -0.4,
    accel_profile = "flat",
})

hl.device({
    name = "gxt7863:00-27c6:01e0-touchpad", -- Touchpad
    sensitivity = 0.4,
    accel_profile = "adaptive",
})

hl.config({
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:caps_toggle",

        numlock_by_default = true,
        follow_mouse = 1,
        mouse_refocus = false,
        repeat_rate = 25,
        repeat_delay = 300,

        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.6,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
