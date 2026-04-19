// Made by Eve Haddox & imLiaMxo

local BASE_WIDTH  = 1920
local BASE_HEIGHT = 1080

function Elib.Scale(value)
    local sw = math.max(value * (ScrW() / BASE_WIDTH), 1)
    local sh = math.max(value * (ScrH() / BASE_HEIGHT), 1)
    return math.min(sw, sh)
end

local rawConstants    = {}
local scaledConstants = {}

function Elib.RegisterScaledConstant(name, size)
    rawConstants[name]    = size
    scaledConstants[name] = Elib.Scale(size)
end

function Elib.GetScaledConstant(name)
    return scaledConstants[name]
end

hook.Add("OnScreenSizeChanged", "Elib.UpdateScaledConstants", function()
    for name, size in pairs(rawConstants) do
        scaledConstants[name] = Elib.Scale(size)
    end
end)
