// Made by Eve Haddox & imLiaMxo

Elib.RegisteredFonts = Elib.RegisteredFonts or {}
Elib.SharedFonts     = Elib.SharedFonts or {}
Elib.ScaledFonts     = Elib.ScaledFonts or {}

local registeredFonts = Elib.RegisteredFonts
local sharedFonts     = Elib.SharedFonts
local scaledFonts     = Elib.ScaledFonts

/////////////////////////
// Unscaled Registration
/////////////////////////
function Elib.RegisterFontUnscaled(name, font, size, weight)
    weight = weight or 500

    local identifier = font .. size .. ":" .. weight
    local fontName   = "Elib:" .. identifier

    registeredFonts[name] = fontName

    if sharedFonts[identifier] then return end
    sharedFonts[identifier] = true

    surface.CreateFont(fontName, {
        font      = font,
        size      = size,
        weight    = weight,
        extended  = true,
        antialias = true,
    })
end

/////////////////////////
// Scaled Registration
/////////////////////////
function Elib.RegisterFont(name, font, size, weight)
    scaledFonts[name] = {
        font   = font,
        size   = size,
        weight = weight,
    }

    Elib.RegisterFontUnscaled(name, font, Elib.Scale(size), weight)
end

hook.Add("OnScreenSizeChanged", "Elib.ReRegisterFonts", function()
    for name, data in pairs(scaledFonts) do
        Elib.RegisterFont(name, data.font, data.size, data.weight)
    end
end)

/////////////////////////
// Lookup / Helpers
/////////////////////////
function Elib.GetRealFont(name)
    return registeredFonts[name]
end

do
    local setFont     = surface.SetFont
    local getTextSize = surface.GetTextSize

    function Elib.SetFont(name)
        local real = registeredFonts[name]
        if real then
            setFont(real)
        else
            setFont(name)
        end
    end

    function Elib.GetTextSize(text, font)
        if font then Elib.SetFont(font) end
        return getTextSize(text)
    end
end

/////////////////////////
// Default Fonts
/////////////////////////
hook.Add("Elib.FullyLoaded", "Elib.RegisterDefaultFonts", function()
    Elib.RegisterFont("Elib.Tiny",    "Space Grotesk", 12)
    Elib.RegisterFont("Elib.Small",   "Space Grotesk", 14)
    Elib.RegisterFont("Elib.Body",    "Space Grotesk", 16)
    Elib.RegisterFont("Elib.Medium",  "Space Grotesk", 18, 500)
    Elib.RegisterFont("Elib.Large",   "Space Grotesk", 22, 600)
    Elib.RegisterFont("Elib.Header",  "Space Grotesk", 28, 600)
    Elib.RegisterFont("Elib.Title",   "Space Grotesk", 36, 700)
    Elib.RegisterFont("Elib.Display", "Space Grotesk", 48, 700)
end)
