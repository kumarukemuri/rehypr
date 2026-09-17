for _, device in ipairs(require("config.profile").devices) do
    hl.device(device)
end

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
