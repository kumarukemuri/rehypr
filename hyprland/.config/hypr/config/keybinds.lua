local home = os.getenv("HOME")
local hostname = os.getenv("hostname")
local scriptDir = home .. "/.config/hypr/scripts"

-- Config
local mainMod = "SUPER"
local altMod = "ALT"

-- Scripts & Launchers
local color = scriptDir .. "/cpicker.sh"
local mute = scriptDir .. "/mute.sh"
local grimblaster = scriptDir .. "/grimblaster.sh"
local runner = [[rofi -show drun -run-command "uwsm app -- {cmd}"]]
local power = "bash " .. home .. "/.config/rofi/power.sh"
local lock = "hyprlock"
local wallpaper = "bash " .. home .. "/.config/rofi/wallpaper.sh"
local terminal = "uwsm app -- kitty"
local explore = "uwsm app -- nemo"

-- Helpers
local function exec(cmd) return hl.dsp.exec_cmd(cmd) end
local function bind(keys, dispatcher, flags) hl.bind(keys, dispatcher, flags or {}) end
local function bind_locked(keys, cmd) bind(keys, exec(cmd), { locked = true }) end
local function bind_locked_repeating(keys, cmd) bind(keys, exec(cmd), { locked = true, repeating = true }) end

local focusedMonitorCmd =
    [[hyprctl monitors -j | jq -er 'first(.[] | select(.focused) | .name)']]

local function osd(args)
    return [[swayosd-client --monitor "$(]] ..
        focusedMonitorCmd ..
        [[)" ]] ..
        args
end

-- Main keys ================================================
bind(mainMod .. " + ESCAPE", function()
    local workspace = hl.get_active_special_workspace()
    if not workspace then return end
    local name = workspace.name:match("^special:(.+)$") or ""
    hl.dispatch(hl.dsp.workspace.toggle_special(name))
end)

-- local shell = { { key = "RETURN" }, { key = "GRAVE" } }

-- for _, group in ipairs({ shell }) do
--     for _, ws in ipairs(group) do
--         bind(mainMod .. " + " .. ws.key, hl.dsp.workspace.toggle_special("shell"))
--     end
-- end

bind(mainMod .. " + C", hl.dsp.window.close())
-- bind(mainMod .. " + GRAVE", exec(terminal))
bind(mainMod .. " + SHIFT + C", exec(color))
bind(mainMod .. " + DELETE", exec(power))
bind(mainMod .. " + SHIFT + L", exec(lock))
bind(mainMod .. " + SHIFT + P", exec(wallpaper))
bind(mainMod .. " + RETURN", exec(runner))
bind(mainMod .. " + X", exec(explore))
bind(mainMod .. " + ESCAPE", exec(terminal))
bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Screenshot =================================================
local function screencutter(args) return exec(grimblaster .. " " .. args) end
bind("CTRL + Print", screencutter("active"))
bind("Print", screencutter("screen"))
bind(altMod .. " + SHIFT + S", screencutter("area"))

-- Instant replay: save the last 30 seconds from GPU Screen Recorder.
bind(mainMod .. " + R", exec(home .. "/.local/bin/save-gsr-replay"))

-- Window management ==========================================
hl.bind(mainMod .. " + V", function()
    local win = hl.get_active_window()
    if not win then return end
    if win.floating then
        hl.dispatch(hl.dsp.window.float({ action = "off" }))
    else
        hl.dispatch(hl.dsp.window.float({ action = "on" }))
        hl.timer(function()
            hl.dispatch(hl.dsp.window.resize({ x = 1400, y = 1000 }))
            hl.dispatch(hl.dsp.window.center())
        end, { timeout = 20, type = "oneshot" })
    end
end)

bind(
    mainMod .. " + Tab",
    hl.dsp.focus({ monitor = "+1" })
)

-- Vertical stack navigation
bind(mainMod .. " + W", hl.dsp.focus({ direction = "u" }))
bind(mainMod .. " + S", hl.dsp.focus({ direction = "d" }))
bind(mainMod .. " + D", hl.dsp.focus({ direction = "r" }))
bind(mainMod .. " + A", hl.dsp.focus({ direction = "l" }))
bind(mainMod .. " + SHIFT + UP", hl.dsp.window.swap({ direction = "u" }))
bind(mainMod .. " + SHIFT + DOWN", hl.dsp.window.swap({ direction = "d" }))
bind(mainMod .. " + SHIFT + LEFT", hl.dsp.window.swap({ direction = "l" }))
bind(mainMod .. " + SHIFT + RIGHT", hl.dsp.window.swap({ direction = "r" }))



bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspace navigation =======================================
local workspaces_left = { { key = "Q", id = 4 }, { key = "E", id = 5 } }
local workspaces_right = { { key = "1", id = 1 }, { key = "2", id = 2 }, { key = "3", id = 3 } }

for _, group in ipairs({ workspaces_left, workspaces_right }) do
    for _, ws in ipairs(group) do
        bind(mainMod .. " + " .. ws.key, hl.dsp.focus({ workspace = ws.id }))
        bind(mainMod .. " + SHIFT + " .. ws.key, hl.dsp.window.move({ workspace = ws.id }))
    end
end


-- Media control =============================================
local media_keys = {
    { keys = "XF86AudioNext",  cmd = "--playerctl next" },
    { keys = "XF86AudioPrev",  cmd = "--playerctl previous" },
    { keys = "XF86AudioPause", cmd = "--playerctl play-pause" },
    { keys = "XF86AudioPlay",  cmd = "--play-pause" },
}

for _, mk in ipairs(media_keys) do
    bind_locked(mk.keys, osd(mk.cmd))
end

-- Volume =====================================================
bind_locked_repeating("XF86AudioRaiseVolume", osd("--output-volume +5"))
bind_locked_repeating("XF86AudioLowerVolume", osd("--output-volume -5"))
bind_locked_repeating("SHIFT + XF86AudioRaiseVolume", osd("--output-volume +1"))
bind_locked_repeating("SHIFT + XF86AudioLowerVolume", osd("--output-volume -1"))
bind_locked_repeating("XF86AudioMute", osd("--output-volume mute-toggle"))

bind_locked_repeating(mainMod .. " + SHIFT + M", mute)

-- Mic mute ===================================================
bind_locked_repeating(mainMod .. " + XF86AudioRaiseVolume", mute)
bind_locked_repeating(mainMod .. " + XF86AudioLowerVolume", mute)
bind_locked_repeating(mainMod .. " + XF86AudioMute", mute)

-- Brightness ==================================================
bind_locked_repeating("XF86MonBrightnessUp", "swayosd-client --brightness raise")
bind_locked_repeating("XF86MonBrightnessDown", "swayosd-client --brightness lower")
