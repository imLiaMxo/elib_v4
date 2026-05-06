// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

// Checkmark image loaded via Elib.WebImages.
local CHECK_URL = "https://construct-cdn.physgun.com/images/6e86bf57-f087-48e2-b1e5-dde678fcaf1e.png"

local PANEL = {}

AccessorFunc(PANEL, "Value", "Value", FORCE_BOOL)

function PANEL:Init()
    self:SetValue(false)
    self:SetText("")

    local size = Elib.Scale(20)
    self:SetSize(size, size)

    self.CheckAlpha  = 0  -- 0 = unchecked, 1 = checked (animated)
    self.BorderColor = Elib.CopyColor(Elib.Colors.SecondaryText)

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    self.BorderColor = Elib.CopyColor(Elib.Colors.SecondaryText)
end

function PANEL:DoClick()
    self:SetValue(not self:GetValue())
    if self.OnChange then self:OnChange(self:GetValue()) end
end

function PANEL:OnChange(value) end

function PANEL:SetValueSilent(v)
    self:SetValue(v == true)
end

// Snap immediately to the current value without lerping.
function PANEL:SnapToValue()
    self.CheckAlpha = self:GetValue() and 1 or 0
end

function PANEL:Paint(w, h)
    local ft      = FrameTime() * 12
    local checked = self:GetValue()

    // Animate checkmark alpha
    local targetAlpha = checked and 1 or 0
    self.CheckAlpha = Lerp(ft, self.CheckAlpha, targetAlpha)

    // Animate border colour toward Primary when checked
    local targetBorder = checked and Elib.Colors.Primary or Elib.Colors.SecondaryText
    self.BorderColor   = Elib.LerpColor(ft, self.BorderColor, targetBorder)

    local r = Elib.Scale(4)
    local b = Elib.Scale(2)   -- border thickness

    // Outer rect acts as the border
    RNDX().Rect(0, 0, w, h):Rad(r):Color(self.BorderColor):Draw()

    // Inner background
    local innerBg = checked
        and ColorAlpha(Elib.Colors.Primary, 40)
        or  Elib.Colors.Background
    RNDX().Rect(b, b, w - b * 2, h - b * 2):Rad(r - b):Color(innerBg):Draw()

    // Checkmark image fades in when checked
    if self.CheckAlpha > 0.01 then
        local pad   = Elib.Scale(4)
        local alpha = math.Clamp(self.CheckAlpha * 255, 0, 255)
        Elib.WebImages.Draw(
            pad, pad, w - pad * 2, h - pad * 2,
            CHECK_URL,
            Color(255, 255, 255, alpha)
        )
    end
end

vgui.Register("Elib.Boolean", PANEL, "DButton")
