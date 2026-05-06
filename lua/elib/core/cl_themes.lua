// Made by Eve Haddox & imLiaMxo

Elib.Themes      = Elib.Themes or {}
Elib.Colors      = Elib.Colors or {}
Elib.ActiveTheme = Elib.ActiveTheme or "Default"

/////////////////////////
// Registration
/////////////////////////
function Elib.RegisterTheme(name, colors)
    if type(name) ~= "string" or type(colors) ~= "table" then
        Elib.Logger:Warn("RegisterTheme: invalid arguments")
        return
    end

    Elib.Themes[name] = colors
end

function Elib.GetThemeNames()
    local names = {}
    for name in pairs(Elib.Themes) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function Elib.GetTheme(name)
    return Elib.Themes[name]
end

/////////////////////////
// Activation
/////////////////////////
function Elib.SetTheme(name, silent)
    local theme = Elib.Themes[name]
    if not theme then
        Elib.Logger:Warn("SetTheme: theme '" .. tostring(name) .. "' not found")
        return false
    end

    local fallback = Elib.Themes["Default"] or {}

    local seen = {}
    for key, col in pairs(theme) do
        Elib.Colors[key] = Elib.CopyColor(col)
        seen[key] = true
    end
    for key, col in pairs(fallback) do
        if not seen[key] then
            Elib.Colors[key] = Elib.CopyColor(col)
        end
    end

    Elib.ActiveTheme = name

    if not silent then
        hook.Run("Elib.ThemeChanged", name)
    end

    return true
end

/////////////////////////
// Config Integration
/////////////////////////
hook.Add("Elib.FullyLoaded", "Elib.RegisterThemeConfig", function()
    if Elib.Themes[Elib.ActiveTheme] then
        Elib.SetTheme(Elib.ActiveTheme, true)
    elseif Elib.Themes["Default"] then
        Elib.SetTheme("Default", true)
    end

    if Elib.Config and Elib.Config.AddValue then
        Elib.Config:AddAddon("Elib", {
            order = 1,
            icon  = "https://cdn.novarp.uk/uploads/1777660733991-d4wtqf.png",
        })

        Elib.Config:AddValue(
            "Elib", "client", "general",
            "theme", "Theme Preset",
            Elib.ActiveTheme, "Dropdown",
            0,
            function(value)
                if value then Elib.SetTheme(value) end
            end,
            true,
            Elib.GetThemeNames()
        )
    end
end)