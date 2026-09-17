-- Use the same resolver as Fish and session helpers.
local home = assert(os.getenv("HOME"), "HOME is missing")
local path = home .. "/.config/hypr/scripts/profile.sh"
local quoted = "'" .. path:gsub("'", "'\"'\"'") .. "'"
local pipe = assert(io.popen("bash " .. quoted, "r"))
local name = pipe:read("*a"):gsub("%s+$", "")
pipe:close() -- Hyprland may reap the child before Lua closes its pipe.
assert(name == "desktop" or name == "laptop",
    "Invalid rehypr profile; check ~/.config/rehypr/profile")
return require("config.profiles." .. name)
