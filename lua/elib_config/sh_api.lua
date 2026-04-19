// Made by Eve Haddox & imLiaMxo

Elib.Config        = Elib.Config or {}
Elib.Config.Addons = Elib.Config.Addons or {} -- structure: Addons[addonName][realm][category][id] = { name, value, default, type, order, onComplete, resetMenu, table, network }

local log = Elib.NewLogger("Elib.Config")
Elib.Config.Log = log

/////////////////////////
// Addon registration
/////////////////////////
local addonCount = 0

function Elib.Config:AddAddon(name, options, legacyAuthor)
    addonCount = addonCount + 1

    if type(options) == "number" or options == nil then
        options = {
            order  = options,
            author = legacyAuthor and {
                name    = legacyAuthor[1] or "Unknown",
                steamid = legacyAuthor[2] or "",
            } or nil,
        }
    end

    local addon = self.Addons[name] or {}
    self.Addons[name] = addon

    addon.name        = name
    addon.order       = options.order or addon.order or addonCount
    addon.author      = options.author or addon.author
    addon.description = options.description or addon.description
    addon.icon        = options.icon or addon.icon

    return addon
end

/////////////////////////
// Value registration
/////////////////////////
local valueCount = 0

local function buildOpts(a1, a2, a3, a4, a5, a6, a7, a8)
    if type(a1) == "table" then return a1 end

    return {
        name       = a1,
        default    = a2,
        type       = a3,
        order      = a4,
        onComplete = a5,
        resetMenu  = a6,
        table      = a7,
        network    = a8,
    }
end

function Elib.Config:AddValue(addon, realm, category, id, ...)
    valueCount = valueCount + 1

    realm    = string.lower(realm)
    category = string.lower(category)

    if not self.Addons[addon] then
        self:AddAddon(addon)
    end

    local addonTbl = self.Addons[addon]
    addonTbl[realm] = addonTbl[realm] or {}
    addonTbl[realm][category] = addonTbl[realm][category] or {}

    if realm == "client" and SERVER then return end

    local opts = buildOpts(...)

    addonTbl[realm][category][id] = {
        name       = opts.name or id,
        value      = opts.default,
        default    = opts.default,
        type       = opts.type or "Text",
        order      = opts.order or valueCount,
        onComplete = opts.onComplete,
        resetMenu  = opts.resetMenu == true,
        table      = opts.table,
        network    = opts.network == true,
        fullscreen = opts.fullscreen == true,
    }

    return addonTbl[realm][category][id]
end

/////////////////////////
// Value retrieval
/////////////////////////
function Elib.Config:GetValue(addon, realm, category, id, fallback)
    realm    = string.lower(realm)
    category = string.lower(category)

    if SERVER and realm == "client" then return fallback end

    local a = self.Addons[addon]
    if not a then
        log:Warn(string.format("GetValue: addon '%s' not registered", addon))
        return fallback
    end

    local r = a[realm]
    if not r then return fallback end

    local c = r[category]
    if not c then return fallback end

    local entry = c[id]
    if not entry then return fallback end

    local v = entry.value
    if v == nil then return fallback end
    return v
end

function Elib.Config:SetValue(addon, realm, category, id, value)
    realm    = string.lower(realm)
    category = string.lower(category)

    local a = self.Addons[addon]
    if not a or not a[realm] or not a[realm][category] or not a[realm][category][id] then
        return false
    end

    local entry = a[realm][category][id]
    entry.value = value

    if entry.onComplete then
        local ok, err = pcall(entry.onComplete, value)
        if not ok then
            log:Warn("onComplete error for " .. addon .. "." .. realm .. "." .. category .. "." .. id .. ": " .. tostring(err))
        end
    end

    return true
end

/////////////////////////
// Iteration helpers
/////////////////////////
function Elib.Config:GetAddonsSorted()
    local list = {}
    for name, addon in pairs(self.Addons) do
        list[#list + 1] = addon
    end
    table.sort(list, function(a, b)
        return (a.order or 0) < (b.order or 0)
    end)
    return list
end

-- we like to be civil and provide them properly don't we :) Nie ma za co :)

function Elib.Config:GetAddonLayout(addonName)
    local addon = self.Addons[addonName]
    if not addon then return {} end

    local out = {}

    for _, realm in ipairs({ "server", "client" }) do
        local realmData = addon[realm]
        if type(realmData) == "table" then

            for catName, catEntries in pairs(realmData) do
                local entries = {}
                for id, entry in pairs(catEntries) do
                    entries[#entries + 1] = {
                        id    = id,
                        entry = entry,
                    }
                end
                table.sort(entries, function(a, b)
                    return (a.entry.order or 0) < (b.entry.order or 0)
                end)

                out[#out + 1] = {
                    realm    = realm,
                    category = catName,
                    entries  = entries,
                }
            end
        end
    end

    table.sort(out, function(a, b)
        if a.realm ~= b.realm then return a.realm == "server" end
        return a.category < b.category
    end)

    return out
end
