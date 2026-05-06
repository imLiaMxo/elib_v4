// Made by Eve Haddox & imLiaMxo

local log = Elib.Config.Log
local TABLE_NAME = "elib_config_server"

/////////////////////////
// Permission check
/////////////////////////
local function canEdit(ply)
    if not IsValid(ply) then return false end

    if Elib.Papi and Elib.Papi.PlayerHasPermission then
        local ok, has = pcall(Elib.Papi.PlayerHasPermission, ply, "elib.config.edit")
        if ok and has ~= nil then return has end
    end

    return ply:IsSuperAdmin()
end

Elib.Config.CanEdit = canEdit

/////////////////////////
// Database
/////////////////////////
local db = Elib.NewDatabase("Elib.Config")
db:Connect()
Elib.Config.DB = db

/////////////////////////
// Schema
/////////////////////////
db:CreateTable(TABLE_NAME, {
    addon    = "TEXT",
    category = "TEXT",
    id       = "TEXT",
    value    = "TEXT",
    vtype    = "TEXT",
    PRIMARY  = "KEY(addon, category, id)",
})

/////////////////////////
// Serialization
/////////////////////////
local function serialize(value)
    local t = type(value)

    if t == "table" then
        if IsColor and IsColor(value) then
            return util.TableToJSON({ r = value.r, g = value.g, b = value.b, a = value.a }), "color"
        end
        return util.TableToJSON(value), "table"

    elseif t == "boolean" then
        return value and "1" or "0", "boolean"

    elseif t == "number" then
        return tostring(value), "number"

    elseif t == "string" then
        return value, "string"
    end

    return tostring(value), "string"
end

local function deserialize(value, vtype)
    if vtype == "boolean" then
        return tobool(value)

    elseif vtype == "number" then
        return tonumber(value)

    elseif vtype == "table" then
        return util.JSONToTable(value or "") or {}

    elseif vtype == "color" then
        local t = util.JSONToTable(value or "")
        if t then return Color(t.r or 255, t.g or 255, t.b or 255, t.a or 255) end
        return Color(255, 255, 255)
    end

    return value
end

/////////////////////////
// Persistence
/////////////////////////
local function persist(addon, category, id, value)
    local strValue, vtype = serialize(value)

    local q = db:Format(
        "INSERT OR REPLACE INTO " .. TABLE_NAME .. " (addon, category, id, value, vtype) VALUES ('%s', '%s', '%s', '%s', '%s')",
        addon, category, id, strValue, vtype
    )

    db:Query(q, nil, function(err)
        log:Error("Save failed: " .. tostring(err))
    end)
end

function Elib.Config.LoadSavedSettings()
    db:Select(TABLE_NAME, "*", nil, function(rows)
        if not rows then return end

        for _, row in ipairs(rows) do
            local value = deserialize(row.value, row.vtype)

            local addon = Elib.Config.Addons[row.addon]
            if addon and addon.server and addon.server[row.category] and addon.server[row.category][row.id] then
                addon.server[row.category][row.id].value = value
            end
        end
    end)
end

/////////////////////////
// Networking
/////////////////////////
util.AddNetworkString("Elib.Config.Save")
util.AddNetworkString("Elib.Config.SendToAdmins")
util.AddNetworkString("Elib.Config.SendToClient")

local function buildNetworkedSnapshot()
    local out = {}

    for name, addon in pairs(Elib.Config.Addons) do
        if addon.server then
            for catName, cat in pairs(addon.server) do
                for id, entry in pairs(cat) do
                    if entry.network then
                        out[name] = out[name] or { server = {} }
                        out[name].server[catName] = out[name].server[catName] or {}
                        out[name].server[catName][id] = { value = entry.value }
                    end
                end
            end
        end
    end

    return out
end

function Elib.Config.BroadcastToAdmins()
    local targets = {}
    for _, ply in ipairs(player.GetAll()) do
        if canEdit(ply) then targets[#targets + 1] = ply end
    end

    if #targets == 0 then return end

    net.Start("Elib.Config.SendToAdmins")
        net.WriteTable(Elib.Config.Addons)
    net.Send(targets)
end

local function sendNetworkedTo(ply)
    local snapshot = buildNetworkedSnapshot()
    if not next(snapshot) then return end

    net.Start("Elib.Config.SendToClient")
        net.WriteTable(snapshot)
    net.Send(ply)
end

/////////////////////////
// Receive: client asking to save
/////////////////////////
net.Receive("Elib.Config.Save", function(_, ply)
    if not canEdit(ply) then
        log:Warn(ply:Nick() .. " tried to save config without permission")
        return
    end

    local addon    = net.ReadString()
    local category = net.ReadString()
    local id       = net.ReadString()
    local value    = net.ReadType()

    local a = Elib.Config.Addons[addon]
    local entry = a and a.server and a.server[category] and a.server[category][id]

    // If the entry isn't registered on this server (e.g. demo addon enabled client-side
    // but not server-side), still persist the raw value so it's not silently discarded.
    // We skip SetValue/onComplete/broadcast since we have no local metadata for it.
    if not entry then
        log:Debug(string.format("Save: persisting unregistered entry %s.%s.%s from %s (addon may be disabled server-side)", addon, category, id, ply:Nick()))
        persist(addon, category, id, value)
        return
    end

    persist(addon, category, id, value)
    Elib.Config:SetValue(addon, "server", category, id, value)

    log:Info(string.format("%s saved %s.%s.%s", ply:Nick(), addon, category, id))

    Elib.Config.BroadcastToAdmins()

    if entry.network then
        local snapshot = {
            [addon] = {
                server = {
                    [category] = {
                        [id] = { value = entry.value },
                    },
                },
            },
        }

        for _, target in ipairs(player.GetAll()) do
            if not canEdit(target) then
                net.Start("Elib.Config.SendToClient")
                    net.WriteTable(snapshot)
                net.Send(target)
            end
        end
    end
end)

/////////////////////////
// Initial load & join hooks
/////////////////////////
timer.Simple(0.1, function()
    Elib.Config.LoadSavedSettings()
    Elib.Config.BroadcastToAdmins()
end)

hook.Add("PlayerInitialSpawn", "Elib.Config.PushOnJoin", function(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end

        if canEdit(ply) then
            net.Start("Elib.Config.SendToAdmins")
                net.WriteTable(Elib.Config.Addons)
            net.Send(ply)
        else
            sendNetworkedTo(ply)
        end
    end)
end)