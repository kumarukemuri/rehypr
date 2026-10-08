local C = require("config.colors")

hl.env("XCURSOR_SIZE", "24")

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },

    debug = {
        suppress_errors = false,
    },

    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 0,
        resize_on_border = true,
        allow_tearing = false,
    },

    misc = {
        disable_hyprland_logo      = true,
        force_default_wallpaper    = 0,
        disable_splash_rendering   = true,
        initial_workspace_tracking = 1,
        on_focus_under_fullscreen  = 1,
        allow_session_lock_restore = true,
        vrr                        = 2,
    },

    cursor = {
        inactive_timeout = 2,
    },

    decoration = {
        rounding = 0,
        rounding_power = 2,

        blur = {
            enabled = false,
        },

        shadow = {
            enabled = false,

        },
    },

    animations = {
        enabled = false,
    },

    master = {
        new_status = "inherit",
        new_on_top = true
    },

    dwindle = {
        smart_split                  = true,
    },

    gestures = {
        scrolling = {
            move_snap_to_grid = true,
            move_snap_cursor = true,
        }
    }
})

--------------------------------------------------------------------------------
-- Animation Curves (Bezier)
--------------------------------------------------------------------------------
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("md3_standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })
hl.curve("crazyshot", { type = "bezier", points = { { 0.1, 1.5 }, { 0.76, 0.92 } } })
hl.curve("hyprnostretch", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })
hl.curve("fluent_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("easeInOutCirc", { type = "bezier", points = { { 0.85, 0 }, { 0.15, 1 } } })
hl.curve("easeOutCirc", { type = "bezier", points = { { 0, 0.55 }, { 0.45, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })

--------------------------------------------------------------------------------
-- Animation Rules
--------------------------------------------------------------------------------
hl.animation({ leaf = "windows", enabled = true, speed = 1.8, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.8, bezier = "md3_decel" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1.8, bezier = "md3_decel", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "md3_decel", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.5, bezier = "md3_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.5, bezier = "md3_decel" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.5, bezier = "md3_decel" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 1.8, bezier = "md3_decel", style = "slidevert" })

--------------------------------------------------------------------------------
-- Match the window pop-in style for all Rofi menus.
--------------------------------------------------------------------------------

hl.layer_rule({
    match = { namespace = "^rofi$" },
    animation = "popin 60%",
})
