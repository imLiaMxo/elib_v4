// Made by Eve Haddox & imLiaMxo
local createColor = Color

/////////////////////////
// Conversions
/////////////////////////
do
    local format = string.format

    function Elib.DecToHex(dec, zeros)
        return format("%0" .. (zeros or 2) .. "x", dec)
    end

    function Elib.ColorToHex(col)
        return format("#%02X%02X%02X",
            math.Clamp(col.r, 0, 255),
            math.Clamp(col.g, 0, 255),
            math.Clamp(col.b, 0, 255)
        )
    end

    function Elib.HexToColor(hex)
        local r, g, b = hex:match("#?(..)(..)(..)")
        if not r then return createColor(255, 255, 255) end

        return createColor(
            tonumber(r, 16) or 0,
            tonumber(g, 16) or 0,
            tonumber(b, 16) or 0
        )
    end
end

/////////////////////////
// HSL Conversions
/////////////////////////
function Elib.ColorToHSL(col)
    local r = col.r / 255
    local g = col.g / 255
    local b = col.b / 255

    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local sum    = mx + mn
    local l      = sum / 2

    if mx == mn then return 0, 0, l end

    local d = mx - mn
    local s = l > 0.5 and d / (2 - sum) or d / sum
    local h

    if mx == r then
        h = (g - b) / d + (g < b and 6 or 0)
    elseif mx == g then
        h = (b - r) / d + 2
    else
        h = (r - g) / d + 4
    end

    return h * (1 / 6), s, l
end

do
    local function hueToRgb(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1 / 6 then return p + (q - p) * 6 * t end
        if t < 1 / 2 then return q end
        if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
        return p
    end

    function Elib.HSLToColor(h, s, l, a)
        local r, g, b
        local t = h / (2 * math.pi)

        if s == 0 then
            r, g, b = l, l, l
        else
            local q = l < 0.5 and (l * (1 + s)) or (l + s - l * s)
            local p = 2 * l - q

            r = hueToRgb(p, q, t + 1 / 3)
            g = hueToRgb(p, q, t)
            b = hueToRgb(p, q, t - 1 / 3)
        end

        return createColor(r * 255, g * 255, b * 255, (a or 1) * 255)
    end
end

/////////////////////////
// Manipulation
/////////////////////////
function Elib.CopyColor(col)
    return createColor(col.r, col.g, col.b, col.a)
end

function Elib.OffsetColor(col, offset)
    return createColor(col.r + offset, col.g + offset, col.b + offset, col.a)
end

function Elib.SetColorAlpha(col, alpha)
    return createColor(col.r, col.g, col.b, alpha)
end

function Elib.LerpColor(t, from, to)
    return createColor(
        Lerp(t, from.r, to.r),
        Lerp(t, from.g, to.g),
        Lerp(t, from.b, to.b),
        Lerp(t, from.a, to.a)
    )
end

function Elib.IsColorEqualTo(a, b)
    return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a
end

function Elib.IsColorLight(col)
    local _, _, lightness = Elib.ColorToHSL(col)
    return lightness >= 0.5
end

/////////////////////////
// Rainbow
/////////////////////////
do
    local lastUpdate = 0
    local lastColor  = createColor(0, 0, 0)

    function Elib.GetRainbowColor()
        local t = CurTime()
        if t == lastUpdate then return lastColor end

        lastUpdate = t
        lastColor  = HSVToColor((t * 50) % 360, 1, 1)
        return lastColor
    end
end

/////////////////////////
// Color Metatable Extensions
/////////////////////////
local colorMeta = FindMetaTable("Color")

colorMeta.Copy    = Elib.CopyColor
colorMeta.IsLight = Elib.IsColorLight
colorMeta.EqualTo = Elib.IsColorEqualTo

function colorMeta:Offset(offset)
    self.r = self.r + offset
    self.g = self.g + offset
    self.b = self.b + offset
    return self
end

if not colorMeta.Lerp then
    function colorMeta:Lerp(target, fraction)
        self.r = Lerp(fraction, self.r, target.r)
        self.g = Lerp(fraction, self.g, target.g)
        self.b = Lerp(fraction, self.b, target.b)
        self.a = Lerp(fraction, self.a, target.a)
        return self
    end
end
