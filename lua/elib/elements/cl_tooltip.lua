// Made by Eve Haddox & imLiaMxo

Elib.Tooltip = Elib.Tooltip or {}

local RNDX = Elib.RNDX
local activeTooltip
local activePanel
local HOVER_DELAY = 0.4

/////////////////////////
// Tooltip Panel
/////////////////////////
local TIP = {}

function TIP:Init()
    self:SetDrawOnTop(true)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)
    self:SetText("")
    self.Alpha = 0
end

function TIP:SetText(text)
    self.Text = text or ""

    surface.SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
    local tw, th = surface.GetTextSize(self.Text)

    local padX = Elib.Scale(10)
    local padY = Elib.Scale(6)

    self:SetSize(tw + padX * 2, th + padY * 2)
end

function TIP:Think()
    self.Alpha = math.min(self.Alpha + RealFrameTime() * 600, 255)
end

function TIP:Paint(w, h)
    local r = Elib.Scale(4)
    local bg = Elib.SetColorAlpha(Elib.OffsetColor(Elib.Colors.Header, 10), self.Alpha)
    local fg = Elib.SetColorAlpha(Elib.Colors.PrimaryText, self.Alpha)

    RNDX().Rect(0, 0, w, h):Rad(r):Color(bg):Draw()

    draw.SimpleText(self.Text,
        Elib.GetRealFont("Elib.Small") or "DermaDefault",
        w / 2, h / 2,
        fg,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
    )
end

vgui.Register("Elib.Tooltip", TIP, "EditablePanel")

/////////////////////////
// Positioning
/////////////////////////
local function positionTooltip(tip, panel)
    if not (IsValid(tip) and IsValid(panel)) then return end

    local sx, sy  = panel:LocalToScreen(0, 0)
    local pw, ph  = panel:GetSize()
    local tw, th  = tip:GetSize()
    local gap     = Elib.Scale(6)

    local x = sx + (pw - tw) / 2
    local y = sy - th - gap

    -- flip if above is above above :D
    if y < 0 then
        y = sy + ph + gap
    end

    x = math.Clamp(x, 0, ScrW() - tw)

    tip:SetPos(x, y)
end

/////////////////////////
// Public API
/////////////////////////
function Elib.Tooltip.Attach(panel, text)
    if not IsValid(panel) then return end

    panel._ElibTooltipText = text
    panel._ElibTooltipHoverStart = nil

    local oldEnter  = panel.OnCursorEntered
    local oldExit   = panel.OnCursorExited

    panel.OnCursorEntered = function(s, ...)
        s._ElibTooltipHoverStart = SysTime()
        if oldEnter then oldEnter(s, ...) end
    end

    panel.OnCursorExited = function(s, ...)
        s._ElibTooltipHoverStart = nil

        if activePanel == s and IsValid(activeTooltip) then
            activeTooltip:Remove()
            activeTooltip = nil
            activePanel   = nil
        end

        if oldExit then oldExit(s, ...) end
    end
end

function Elib.Tooltip.Detach(panel)
    if not IsValid(panel) then return end

    panel._ElibTooltipText = nil
    panel._ElibTooltipHoverStart = nil
end

/////////////////////////
// Poll Think
/////////////////////////
hook.Add("Think", "Elib.Tooltip.Poll", function()
    if IsValid(activeTooltip) then
        if not IsValid(activePanel) or not activePanel:IsHovered() then
            activeTooltip:Remove()
            activeTooltip = nil
            activePanel   = nil
        else
            positionTooltip(activeTooltip, activePanel)
        end
        return
    end

    local hovered = vgui.GetHoveredPanel()
    if not IsValid(hovered) then return end
    if not hovered._ElibTooltipText then return end
    if not hovered._ElibTooltipHoverStart then
        hovered._ElibTooltipHoverStart = SysTime()
        return
    end

    if SysTime() - hovered._ElibTooltipHoverStart < HOVER_DELAY then return end

    local text = hovered._ElibTooltipText
    if type(text) == "function" then
        local ok, result = pcall(text, hovered)
        text = ok and result or ""
    end

    if not text or text == "" then return end

    activeTooltip = vgui.Create("Elib.Tooltip")
    activeTooltip:SetText(text)
    activePanel   = hovered

    positionTooltip(activeTooltip, hovered)
end)