-- Apply geometry in the same rule that makes a window floating: float matching
-- alone can run before that rule's initial floating state has been applied.
local function rule(config)
    local excluded =
        config.tag == "+steam_app"

    if config.float == true and not excluded then
        config.center = true
        config.size = { 1400, 1000 }
    end

    return hl.window_rule(config)
end


-- Windows that are already floating by default (dialogs, utility windows).
rule({
    match = { float = true },
    center = true,
    size = { 1400, 1000 },
})

-- Browsers
rule({
    match = {
        initial_class = "^(zen|chromium)$",
    },
    tag = "+browser",
    workspace = "1",
})

-- Telegram
rule({
    match = {
        initial_class = "^(org.telegram.desktop)$",
    },
    tag = "+chat",
    workspace = "5",
})

-- Telegram Media Viewer
rule({
    match = {
        title = "^(Media viewer)$",
        initial_class = "^(org.telegram.desktop)$",
    },
    tag = "+tg_media_viewer",
    float = true,
})


-- Mattermost
rule({
    match = {
        initial_class = "^(Mattermost|Mattermost.Desktop)$",
    },
    tag = "+mattermost",
    workspace = "4",
})

-- Voice apps
rule({
    match = {
        initial_class = "^(discord|vesktop|TeamSpeak.*|WebCord|stoat-desktop)$",
    },
    tag = "+voice",
    workspace = "5",
    no_initial_focus = true,
})

-- IDE
rule({
    match = {
        initial_class = "^(codium|VSCodium|vscodium|jetbrains-pycharm|jetbrains-idea|dev.zed.Zed)$",
    },
    tag = "+ide",
    workspace = "2",
})

-- Spotify
rule({
    match = {
        initial_class = "Spotify",
    },
    tag = "+Spotify",
    workspace = "5",
})

-- MPV
rule({
    match = {
        initial_class = "mpv",
    },
    tag = "+mpv",
    -- workspace = "3",
})

-- Games

rule({
    match = {
        class = "(?i)^steam_app_([0-9]+|default)$",
    },
    fullscreen = true,
    idle_inhibit = "focus",
    tag = "+steam_app",
    workspace = "6",
})

-- Steam
rule({
    match = {
        class = "steam",
        initial_class = "steam",
    },
    workspace = "3",
    tag = "+steam"
})

-- Terminal tools
rule({
    match = {
        class = "^(kitty)$",
    },
    tag = "+shell",
    workspace = "4",
    float = false,
    pin = true,
})

-- Explorer

rule({
    match = {
        initial_class = "^(Nemo|nemo)$",
    },
    tag = "+explorer",
    float = true,
})

-- Popups

rule({
    match = {
        initial_class = "^(xdg-desktop-portal-gtk|org.gnome.FileRoller|org.openrgb.OpenRGB)$",
    },
    tag = "+popup",
    float = true,
    pin = true,
})

-- Polkit

rule({
    match = {
        initial_class = "^(polkit-gnome-authentication-agent-1)$",
    },
    tag = "+polkit",
    float = true,
    pin = true,
})


-- Obsidian

rule({
    match = {
        initial_class = "^(md.obsidian.Obsidian)$",
    },
    tag = "+note",
    workspace = "3",
})
