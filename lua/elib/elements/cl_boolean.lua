// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

local PANEL = {}

AccessorFunc(PANEL, "Value", "Value", FORCE_BOOL)

local HANDLE_SCALE = 0.84

function PANEL:Init()
    self:SetValue(false)
    self:SetText("")

    local size = Elib.Scale(20)
    self:SetSize(size * 1.9, size)

    self.BackgroundColor = Elib.CopyColor(Elib.Colors.Negative)
    self.HandleColor     = Elib.OffsetColor(Elib.Colors.Header, 40)
    self.HandleProgress  = 0 -- 0 = left/off, 1 = right/on

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    self.HandleColor = Elib.OffsetColor(Elib.Colors.Header, 40)
end

function PANEL:DoClick()
    self:SetValue(not self:GetValue())
    if self.OnChange then self:OnChange(self:GetValue()) end
end

function PANEL:OnChange(value) end

function PANEL:SetValueSilent(v)
    self:SetValue(v == true)
end

function PANEL:SnapToValue()
    self.HandleProgress = self:GetValue() and 1 or 0
end

function PANEL:Paint(w, h)
    local ft = FrameTime() * 12

    local target = self:GetValue() and 1 or 0
    self.HandleProgress = Lerp(ft, self.HandleProgress, target)

    local targetBg = self:GetValue() and Elib.Colors.Positive or Elib.Colors.Negative
    self.BackgroundColor = Elib.LerpColor(ft, self.BackgroundColor, targetBg)

    RNDX().Rect(0, 0, w, h):Rad(h / 2):Color(self.BackgroundColor):Draw()

    local handleD = h * HANDLE_SCALE
    local inset   = (h - handleD) / 2

    local leftX   = inset
    local rightX  = w - inset - handleD
    local handleX = Lerp(self.HandleProgress, leftX, rightX)

    RNDX().Circle(handleX + handleD / 2, h / 2, handleD):Color(self.HandleColor):Draw()
end

vgui.Register("Elib.Boolean", PANEL, "DButton")