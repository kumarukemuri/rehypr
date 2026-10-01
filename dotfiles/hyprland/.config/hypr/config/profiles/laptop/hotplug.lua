local helpers = {}

-- Arrange external monitors to the right of the panel and rescue workspaces on disconnect.
-- State belongs to each setup call, including when the configuration is reloaded.
function helpers.setup_external_monitors(panel)
    local pending = false
    local applied = {}
    local owners = {}
    local rescue = {}
    local function remember_workspaces()
        for _, ws in ipairs(hl.get_workspaces()) do
            if not ws.special and ws.monitor then
                owners[ws.id] = ws.monitor.name
            end
        end
    end
    local function apply()
        pending = false
        local monitors = hl.get_monitors()
        local builtin, external
        external = {}
        local present = {}
        for _, m in ipairs(monitors) do
            present[m.name] = true
            if m.name == panel then builtin = m else external[#external + 1] = m end
        end
        if not builtin then return end
        table.sort(external, function(a, b) return a.name < b.name end)
        local x = math.floor(builtin.width / builtin.scale + 0.5)
        for _, m in ipairs(external) do
            local position = tostring(x) .. "x0"
            if applied[m.name] ~= position or m.x ~= x or m.y ~= 0 or m.scale ~= 1 then
                applied[m.name] = position -- Set before hl.monitor, which can emit layout events.
                hl.monitor({ output = m.name, mode = "preferred", scale = 1, position = position, bitdepth = 8 })
            end
            x = x + m.width -- External profiles use scale 1 and no rotation.
        end
        for name in pairs(applied) do if not present[name] then applied[name] = nil end end
        for _, ws in ipairs(hl.get_workspaces()) do
            if not ws.special and (rescue[ws.id] or (owners[ws.id] and not present[owners[ws.id]])) then
                hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(ws.id), monitor = panel }))
            end
        end
        rescue = {}
        remember_workspaces()
    end
    local function schedule()
        if not hl.get_monitor(panel) then return end -- No live outputs during --verify-config.
        if pending then return end
        pending = true
        hl.timer(apply, { timeout = 200, type = "oneshot" })
    end
    hl.on("monitor.added", schedule)
    hl.on("monitor.layout_changed", schedule)
    hl.on("monitor.removed", function(m)
        local name = m.name
        for id, owner in pairs(owners) do
            if owner == name then rescue[id] = true end
        end
        schedule()
    end)
    hl.on("workspace.created", remember_workspaces)
    hl.on("workspace.move_to_monitor", function(ws, m)
        -- Preserve the old owner when a disconnect makes Hyprland move the workspace first.
        local old = owners[ws.id]
        if old and not hl.get_monitor(old) then rescue[ws.id] = true end
        if m then owners[ws.id] = m.name end
    end)
    hl.on("hyprland.start", schedule)
    hl.on("config.reloaded", schedule) -- Also arrange already connected outputs.
end

return helpers
