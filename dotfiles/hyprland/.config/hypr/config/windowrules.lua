local rule = hl.window_rule

-- Browsers
rule({
    match = {
        initial_class = "^(firefox|brave-browser|librewolf|zen)$",
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
    opacity = "1",
    float = true,
})


-- Mattermost
rule({
    match = {
        initial_class = "^(Mattermost|Mattermost.Desktop)$",
    },
    tag = "+mattermost",
    workspace = "5",
})

-- Voice apps
rule({
    match = {
        initial_class = "^(discord|vesktop|TeamSpeak.*|WebCord)$",
    },
    tag = "+voice",
    workspace = "5",
    no_initial_focus = true,
})

-- IDE
rule({
    match = {
        initial_class = "^(codium|VSCodium|vscodium|dev.zed.Zed|jetbrains-pycharm|jetbrains-idea)$",
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
    workspace = "4",
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
        initial_class = "^(steam_app_.*|gamescope)$",
    },
    workspace = "3",
    fullscreen = true,
    float = true,
    center = true,
    idle_inhibit = "always",
})

-- Steam
rule({
    match = {
        initial_class = "^steam$",
    },
    workspace = "3",
    tag = "+steam",
})

-- Terminal tools
rule({
    match = {
        initial_class = "^(kitty|wiremix|btop|impala|bluetui)$",
    },
    tag = "+shell",
    workspace = "4",
})

-- Explorer

rule({
    match = {
        initial_class = "^(Nemo|nemo)$",
    },
    tag = "+explorer",
    float = true,
    center = true,
    size = { 800, 600 },
})

-- Popups

rule({
    match = {
        initial_class = "^(xdg-desktop-portal-gtk|org.gnome.FileRoller)$",
    },
    tag = "+popup",
    float = true,
    center = true,
    pin = true,
    size = { 800, 600 },
})

-- Polkit authentication

rule({
    match = {
        initial_class = "^(polkit-gnome-authentication-agent-1)$",
    },
    tag = "+polkit",
    float = true,
    center = true,
    pin = true,
})


-- Obsidian

rule({
    match = {
        initial_class = "^(obsidian)$",
    },
    tag = "+note",
    workspace = "4",
})

-- org.pulseaudio.pavucontrol

rule({
    match = {
        initial_class = "^(org.pulseaudio.pavucontrol)$",
    },
    tag = "+pavucontrol",
    workspace = "special:shell",
})

-- GSR

-- hl.layer_rule({
--     match = {
--         namespace = "^gsr-(notify|ui)$",
--     },

--     no_anim = true,
-- })

-- Opacity for fullscreen windows

hl.window_rule({
    match = { fullscreen = true },
    opacity = "1.0 override 1.0 override 1.0 override",
})
