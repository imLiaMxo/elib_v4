// Made by Eve Haddox & imLiaMxo (rewritten to use gmod sql)

local log = Elib.Config.Log
local TABLE_NAME = "elib_config_client"

/////////////////////////
// Database Init
/////////////////////////
sql.Query([[
    CREATE TABLE IF NOT EXISTS ]] .. TABLE_NAME .. [[ (
        addon TEXT,
        category TEXT,
        id TEXT,
        value TEXT,
        vtype TEXT,
        PRIMARY KEY (addon, category, id)
    )
]])

/////////////////////////
// serialization
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
    if vtype == "boolean" then return tobool(value) end
    if vtype == "number"  then return tonumber(value) end
    if vtype == "table"   then return util.JSONToTable(value or "") or {} end

    if vtype == "color" then
        local t = util.JSONToTable(value or "")
        if t then return Color(t.r or 255, t.g or 255, t.b or 255, t.a or 255) end
        return Color(255, 255, 255)
    end

    return value
end

/////////////////////////
// Persistence
/////////////////////////
local function persistClient(addon, category, id, value)
    local strValue, vtype = serialize(value)

    local query = string.format(
        "INSERT OR REPLACE INTO %s (addon, category, id, value, vtype) VALUES (%s, %s, %s, %s, %s)",
        TABLE_NAME,
        sql.SQLStr(addon),
        sql.SQLStr(category),
        sql.SQLStr(id),
        sql.SQLStr(strValue),
        sql.SQLStr(vtype)
    )

    local result = sql.Query(query)
    if result == false then
        log:Error("Client save failed: " .. sql.LastError())
    end
end

/////////////////////////
// Public Save
/////////////////////////
function Elib.Config.Save(addon, realm, category, id, value)
    realm    = string.lower(realm)
    category = string.lower(category)

    if realm == "client" then
        Elib.Config:SetValue(addon, realm, category, id, value)
        persistClient(addon, category, id, value)
    else
        net.Start("Elib.Config.Save")
            net.WriteString(addon)
            net.WriteString(category)
            net.WriteString(id)
            net.WriteType(value)
        net.SendToServer()
    end
end

/////////////////////////
// Load from disk on boot
/////////////////////////
function Elib.Config.LoadClientSettings()
    local rows = sql.Query("SELECT * FROM " .. TABLE_NAME)

    if not rows then return end

    for _, row in ipairs(rows) do
        local value = deserialize(row.value, row.vtype)

        local a = Elib.Config.Addons[row.addon]
        if a and a.client and a.client[row.category] and a.client[row.category][row.id] then
            local entry = a.client[row.category][row.id]
            entry.value = value

            if entry.onComplete then
                local ok, err = pcall(entry.onComplete, value)
                if not ok then
                    log:Warn("onComplete error (client load): " .. tostring(err))
                end
            end
        end
    end
end

hook.Add("Elib.FullyLoaded", "Elib.Config.LoadClientSettings", function()
    Elib.Config.LoadClientSettings()
end)

hook.Add("InitPostEntity", "Elib.Config.LoadClientSettings", function()
    Elib.Config.LoadClientSettings()
end)

/////////////////////////
// Network receivers (unchanged)
/////////////////////////
local function applyUpdate(updated)
    for addonName, addonData in pairs(updated) do
        local localAddon = Elib.Config.Addons[addonName]
        if not localAddon then continue end

        for _, realm in ipairs({ "server", "client" }) do
            local realmData = addonData[realm]
            if type(realmData) ~= "table" then continue end

            local localRealm = localAddon[realm]
            if type(localRealm) ~= "table" then continue end

            for category, entries in pairs(realmData) do
                if type(entries) ~= "table" then continue end

                local localCat = localRealm[category]
                if type(localCat) ~= "table" then continue end

                for id, entryData in pairs(entries) do
                    local localEntry = localCat[id]
                    if type(entryData) == "table" and localEntry then
                        localEntry.value = entryData.value

                        if localEntry.onComplete then
                            local ok, err = pcall(localEntry.onComplete, entryData.value)
                            if not ok then
                                log:Warn("onComplete error (net update): " .. tostring(err))
                            end
                        end
                    end
                end
            end
        end
    end

    hook.Run("Elib.Config.OnReceived", updated)
end

net.Receive("Elib.Config.SendToAdmins", function()
    applyUpdate(net.ReadTable())
end)

net.Receive("Elib.Config.SendToClient", function()
    applyUpdate(net.ReadTable())
end)
