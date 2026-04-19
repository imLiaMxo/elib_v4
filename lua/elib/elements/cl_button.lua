// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

local PANEL = {}

AccessorFunc(PANEL, "Text",          "Text",          FORCE_STRING)
AccessorFunc(PANEL, "Style",         "Style",         FORCE_STRING)
AccessorFunc(PANEL, "CornerRadius",  "CornerRadius",  FORCE_NUMBER)
AccessorFunc(PANEL, "Font",          "Font")
AccessorFunc(PANEL, "IconPosition",  "IconPosition",  FORCE_STRING)
AccessorFunc(PANEL, "IconSize",      "IconSize",      FORCE_NUMBER)

function PANEL:Init()
    self:SetText("")
    self:SetStyle("solid")
    self:SetCornerRadius(4)
    self:SetFont("Elib.Body")
    self:SetIconPosition("left")
    self:SetIconSize(0.5)
    self:SetCursor("hand")
    self:SetMouseInputEnabled(true)

    self.BackgroundColor = Color(0, 0, 0, 0)
    self.TextColor       = Color(255, 255, 255)
    self.BorderColor     = Color(0, 0, 0, 0)
    self.DownProgress = 0
    self._iconMat = nil
    self._iconURL = nil
    self._enabled = true

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    self.AccentColor = self.CustomColor or Elib.Colors.Primary
end

function PANEL:SetColor(col)
    self.CustomColor = col
    self:UpdateColors()
end

/////////////////////////
// Enabled state
/////////////////////////
function PANEL:IsEnabled() return self._enabled end

function PANEL:SetEnabled(enabled)
    self._enabled = enabled == true
    self:SetCursor(self._enabled and "hand" or "arrow")
end

/////////////////////////
// Icon
/////////////////////////
function PANEL:SetIcon(iconOrURL, position)
    if position then self:SetIconPosition(position) end

    if type(iconOrURL) == "string" then
        local url = iconOrURL
        if url:match("^[a-zA-Z0-9]+$") then
            url = "https://i.imgur.com/" .. url .. ".png"
        end

        self._iconURL = url
        self._iconMat = Elib.WebImages.GetCached(url)

        if not self._iconMat then
            Elib.WebImages.Get(url):next(function(mat)
                if IsValid(self) and self._iconURL == url then
                    self._iconMat = mat
                end
            end, function() end) -- shhh im fed up of you spammign my shit
        end

        return
    end

    self._iconMat = iconOrURL
    self._iconURL = nil
end

function PANEL:GetIcon() return self._iconMat end

/////////////////////////
// Click handling
/////////////////////////
function PANEL:DoClick() end

function PANEL:OnMousePressed(code)
    if not self._enabled then return end
    if code ~= MOUSE_LEFT then return end

    self._pressed = true
end

function PANEL:OnMouseReleased(code)
    if code ~= MOUSE_LEFT then return end
    if not self._pressed then return end
    self._pressed = false

    if self._enabled and self:IsHovered() then
        self:DoClick()
    end
end

function PANEL:OnCursorExited()
    self._pressed = false
end

/////////////////////////
// Paint
/////////////////////////
function PANEL:_resolveTargetColors()
    local disabled = not self._enabled
    local hovered  = self:IsHovered() and self._enabled
    local pressed  = self._pressed  and self._enabled

    local bg, border, text

    if disabled then
        bg     = Elib.Colors.Disabled
        border = Elib.Colors.Disabled
        text   = Elib.Colors.DisabledText
    elseif self:GetStyle() == "outline" then
        bg     = hovered and Elib.SetColorAlpha(self.AccentColor, 40) or Elib.SetColorAlpha(self.AccentColor, 0)
        border = self.AccentColor
        text   = self.AccentColor
    elseif self:GetStyle() == "ghost" then
        bg     = hovered and Elib.OffsetColor(Elib.Colors.Background, 14) or Elib.SetColorAlpha(Elib.Colors.Background, 0)
        border = Elib.SetColorAlpha(Elib.Colors.Background, 0)
        text   = hovered and Elib.Colors.PrimaryText or Elib.Colors.SecondaryText
    else
        bg     = pressed and Elib.OffsetColor(self.AccentColor, -20)
                or (hovered and Elib.OffsetColor(self.AccentColor, 10) or self.AccentColor)
        border = Elib.SetColorAlpha(Elib.Colors.Background, 0)
        text   = Elib.Colors.PrimaryText
    end

    return bg, border, text
end

function PANEL:Paint(w, h)
    local ft = FrameTime() * 12

    local targetBg, targetBorder, targetText = self:_resolveTargetColors()
    self.BackgroundColor = Elib.LerpColor(ft, self.BackgroundColor, targetBg)
    self.BorderColor     = Elib.LerpColor(ft, self.BorderColor, targetBorder)
    self.TextColor       = Elib.LerpColor(ft, self.TextColor, targetText)

    local targetDown = self._pressed and 1 or 0
    self.DownProgress = Lerp(ft, self.DownProgress, targetDown)

    local sinkY = self.DownProgress * Elib.Scale(1)

    local r = Elib.Scale(self:GetCornerRadius())

    RNDX().Rect(0, sinkY, w, h):Rad(r):Color(self.BackgroundColor):Draw()

    if self.BorderColor.a > 0 then
        RNDX().Rect(0, sinkY, w, h):Rad(r):Color(self.BorderColor):Outline(Elib.Scale(1)):Draw()
    end

    local font = Elib.GetRealFont(self:GetFont()) or self:GetFont() or "DermaDefault"
    surface.SetFont(font)
    local tw, th = surface.GetTextSize(self:GetText() or "")

    local iconSize = h * self:GetIconSize()
    local gap      = Elib.Scale(6)
    local pos      = self:GetIconPosition()

    if pos == "only" and self._iconMat then
        surface.SetMaterial(self._iconMat)
        surface.SetDrawColor(self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a)
        surface.DrawTexturedRect((w - iconSize) / 2, (h - iconSize) / 2 + sinkY, iconSize, iconSize)
        return
    end

    local hasIcon = self._iconMat and self:GetText() ~= ""
    local groupW  = tw + (hasIcon and (iconSize + gap) or 0)
    local startX  = (w - groupW) / 2

    if hasIcon and pos == "left" then
        surface.SetMaterial(self._iconMat)
        surface.SetDrawColor(self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a)
        surface.DrawTexturedRect(startX, (h - iconSize) / 2 + sinkY, iconSize, iconSize)

        draw.SimpleText(self:GetText(), font,
            startX + iconSize + gap, h / 2 + sinkY,
            self.TextColor,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
        )
    elseif hasIcon and pos == "right" then
        draw.SimpleText(self:GetText(), font,
            startX, h / 2 + sinkY,
            self.TextColor,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
        )

        surface.SetMaterial(self._iconMat)
        surface.SetDrawColor(self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a)
        surface.DrawTexturedRect(startX + tw + gap, (h - iconSize) / 2 + sinkY, iconSize, iconSize)
    else
        draw.SimpleText(self:GetText() or "", font,
            w / 2, h / 2 + sinkY,
            self.TextColor,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
        )
    end
end

vgui.Register("Elib.Button", PANEL, "Panel")