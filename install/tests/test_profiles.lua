-- Run from repository root: lua install/tests/test_profiles.lua
package.path = "dotfiles/hyprland/.config/hypr/?.lua;" .. package.path
local calls, events, timers, moves, launches = {}, {}, {}, {}, {}
local panel = { name="eDP-1", width=2880, height=1800, scale=2, x=0, y=0 }
local hdmi = { name="HDMI-A-1", width=1920, height=1080, scale=1, x=0, y=0 }
local dp = { name="DP-1", width=2560, height=1440, scale=1, x=0, y=0 }
local monitors = {panel, hdmi, dp}
local workspaces = {{id=1,monitor=panel},{id=6,monitor=hdmi}}
local rules = {}
hl = {
    config=function() end,
    monitor=function(spec)
        calls[#calls+1]=spec
        for _,m in ipairs(monitors) do
            if m.name==spec.output and spec.position:match("^%d+x%d+$") then
                local x,y=spec.position:match("^(%d+)x(%d+)$")
                m.x,m.y,m.scale=tonumber(x),tonumber(y),spec.scale
            end
        end
    end,
    workspace_rule=function(spec) rules[#rules+1]=spec end,
    on=function(event,fn) events[event]=fn end,
    timer=function(fn) timers[#timers+1]=fn end,
    get_monitors=function() return monitors end,
    get_monitor=function(name) for _,m in ipairs(monitors) do if m.name==name then return m end end end,
    get_workspaces=function() return workspaces end,
    dispatch=function(spec) moves[#moves+1]=spec end,
    exec_cmd=function(cmd) launches[#launches+1]=cmd end,
    dsp={workspace={move=function(spec) return spec end}},
}
local function flush()
    while #timers>0 do local pending=timers;timers={};for _,fn in ipairs(pending) do fn() end end
end
local laptop=require('config.profiles.laptop')
laptop.monitors();laptop.workspaces()
assert(calls[1].output=='eDP-1' and calls[1].scale==2 and calls[1].bitdepth==8)
assert(calls[1].mode=='preferred' and calls[1].position=='0x0')
assert(#rules==6)
for _,rule in ipairs(rules) do assert(rule.monitor=='eDP-1' and rule.layout=='dwindle') end
package.loaded['config.profile']=laptop
require('config.autostart');events['hyprland.start']()
assert(#launches==0)
events['config.reloaded']();flush()
assert(dp.x==1440 and hdmi.x==4000, 'sort externals by name and use logical panel width')
local count=#calls
events['monitor.layout_changed']();events['monitor.added']();flush()
assert(#calls==count,'identical events must not reapply monitor rules')
monitors={panel,dp};events['monitor.removed'](hdmi);flush()
assert(#moves==1 and moves[1].workspace=='6' and moves[1].monitor=='eDP-1')
monitors={panel};workspaces={{id=1,monitor=panel}}
events['monitor.removed'](dp);flush()
monitors={panel,hdmi};hdmi.x=0
events['monitor.added']();flush();assert(hdmi.x==1440)
assert(#launches==0)
package.loaded['config.profile']=require('config.profiles.desktop');package.loaded['config.autostart']=nil
require('config.autostart');events['hyprland.start']()
assert(table.concat(launches,',')=='uwsm app -- kitty,uwsm app -- zen-browser,uwsm app -- mattermost-desktop')
print('PASS: panel settings, workspace mapping, deterministic hotplug, no event loop, workspace rescue and profile autostart.')
