// Made by Eve Haddox & imLiaMxo

Elib.Lang           = Elib.Lang or {}
Elib.Lang.Languages = Elib.Lang.Languages or {} // code -> { name = "...", strings = { ... } }
Elib.Lang.Active    = Elib.Lang.Active or "en"
Elib.Lang.Fallback  = Elib.Lang.Fallback or "en"

/////////////////////////
// Small string utility
/////////////////////////
function Elib.Capitalize(str)
    if type(str) ~= "string" or str == "" then return str end
    return str:sub(1, 1):upper() .. str:sub(2)
end

/////////////////////////
// Registration
/////////////////////////
function Elib.Lang.Register(code, displayName, strings)
    if type(code) ~= "string" or code == "" then
        Elib.Logger:Warn("Lang.Register: invalid code")
        return
    end

    strings = strings or {}

    local lang = Elib.Lang.Languages[code]
    if not lang then
        lang = { name = displayName or code, strings = {} }
        Elib.Lang.Languages[code] = lang
    elseif displayName and displayName ~= code then
        lang.name = displayName
    end

    for key, value in pairs(strings) do
        lang.strings[key] = value
    end

    return lang
end

function Elib.Lang.AddStrings(code, strings)
    return Elib.Lang.Register(code, nil, strings)
end

/////////////////////////
// Activation
/////////////////////////
function Elib.Lang.SetActive(code, silent)
    if not Elib.Lang.Languages[code] then
        Elib.Logger:Warn("Lang.SetActive: language '" .. tostring(code) .. "' not registered")
        return false
    end

    Elib.Lang.Active = code

    if not silent then
        hook.Run("Elib.LanguageChanged", code)
    end

    return true
end

function Elib.Lang.SetFallback(code)
    Elib.Lang.Fallback = code
end

/////////////////////////
// Lookup
/////////////////////////
function Elib.Lang.Get(key, ...)
    local active   = Elib.Lang.Languages[Elib.Lang.Active]
    local fallback = Elib.Lang.Languages[Elib.Lang.Fallback]

    local str =
        (active   and active.strings[key]) or
        (fallback and fallback.strings[key]) or
        key

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then return formatted end
    end

    return str
end

function Elib.Lang.Exists(key)
    local active   = Elib.Lang.Languages[Elib.Lang.Active]
    local fallback = Elib.Lang.Languages[Elib.Lang.Fallback]
    return (active and active.strings[key] ~= nil)
        or (fallback and fallback.strings[key] ~= nil)
        or false
end

/////////////////////////
// Listing
/////////////////////////
function Elib.Lang.GetLanguages()
    local list = {}
    for code, data in pairs(Elib.Lang.Languages) do
        list[#list + 1] = { code = code, name = data.name }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

function Elib.Lang.GetLanguageNames()
    local names = {}
    for _, entry in ipairs(Elib.Lang.GetLanguages()) do
        names[#names + 1] = entry.name
    end
    return names
end

function Elib.Lang.GetCodeByName(displayName)
    for code, data in pairs(Elib.Lang.Languages) do
        if data.name == displayName then return code end
    end
end

/////////////////////////
// Global Shorthand
/////////////////////////
if L == nil then
    L = Elib.Lang.Get
end

/////////////////////////
// Config Integration
/////////////////////////
hook.Add("Elib.FullyLoaded", "Elib.RegisterLanguageConfig", function()
    if CLIENT and Elib.Config and Elib.Config.AddValue then
        local names = Elib.Lang.GetLanguageNames()
        local activeLang = Elib.Lang.Languages[Elib.Lang.Active]
        local defaultName = activeLang and activeLang.name or "English"

        Elib.Config:AddValue(
            "Elib", "client", "general",
            "language", "Language",
            defaultName, "Dropdown",
            1,
            function(value)
                local code = Elib.Lang.GetCodeByName(value)
                if code then Elib.Lang.SetActive(code) end
            end,
            true,
            names
        )
    end
end)
