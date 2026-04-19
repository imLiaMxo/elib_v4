// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

Elib.Notifications          = Elib.Notifications or {}
Elib.Notifications.Active   = Elib.Notifications.Active or {}
Elib.Notifications.Position = Elib.Notifications.Position or "top_right"   -- "top_left", "top_right", "bottom_left", "bottom_right"

local TYPES = {
    info    = { color = Color(49, 149, 207), label = "Info"    },
    success = { color = Color(70, 175, 70),  label = "Success" },
    warn    = { color = Color(230, 170, 30), label = "Warning" },
    error   = { color = Color(192, 27, 27),  label = "Error"   },
}

/////////////////////////
// Notification Panel
/////////////////////////
local PANEL = {}

function PANEL:Init()
    self:SetDrawOnTop(true)
    self:SetMouseInputEnabled(true)
    self:SetSize(Elib.Scale(320), Elib.Scale(60))

    // Animation state.
    self.Alpha     = 0
    self.OffsetX   = Elib.Scale(40)
    self.Closing   = false
    self.BornAt    = SysTime()
    self.Lifetime  = 4

    self.AccentColor = TYPES.info.color
    self.Title       = ""
    self.Text        = ""
    self.Icon        = nil
end

function PANEL:Configure(data)
    self.Title      = data.title or ""
    self.Text       = data.text or ""
    self.Icon       = data.icon
    self.Lifetime   = data.duration or 4
    self.AccentColor = (TYPES[data.type] or TYPES.info).color

    surface.SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
    local _, lineH = surface.GetTextSize(self.Text ~= "" and self.Text or "A")

    local approxLines = math.max(1, math.ceil(#self.Text / 40))
    local textH       = lineH * math.min(approxLines, 3)
    local titleH      = self.Title ~= "" and Elib.Scale(20) or 0

    local pad = Elib.Scale(12)
    self:SetSize(Elib.Scale(320), titleH + textH + pad * 2 + Elib.Scale(4))
end

function PANEL:OnMousePressed(code)
    if code == MOUSE_LEFT then self:StartClose() end
end

function PANEL:StartClose()
    if self.Closing then return end
    self.Closing   = true
    self.ClosedAt  = SysTime()
end

function PANEL:Think()
    local now = SysTime()

    if self.Closing then
        // Slide out and fade.
        self.OffsetX = Lerp(FrameTime() * 8, self.OffsetX, Elib.Scale(40))
        self.Alpha   = Lerp(FrameTime() * 8, self.Alpha, 0)

        if now - self.ClosedAt > 0.3 then
            // Clean up.
            for i, n in ipairs(Elib.Notifications.Active) do
                if n == self then
                    table.remove(Elib.Notifications.Active, i)
                    break
                end
            end
            Elib.Notifications.Relayout()
            self:Remove()
        end
        return
    end

    self.OffsetX = Lerp(FrameTime() * 8, self.OffsetX, 0)
    self.Alpha   = Lerp(FrameTime() * 8, self.Alpha, 255)

    if now - self.BornAt > self.Lifetime then self:StartClose() end
end

function PANEL:PerformLayout(w, h)
    -- its text... just fucking use paint? yeah that worked :D
end

function PANEL:Paint(w, h)
    local a = math.Clamp(self.Alpha, 0, 255)

    local bg = Elib.SetColorAlpha(Elib.OffsetColor(Elib.Colors.Header, 8), a)
    RNDX().Rect(0, 0, w, h):Rad(Elib.Scale(6)):Color(bg):Draw()

    local accent = Elib.SetColorAlpha(self.AccentColor, a)
    RNDX().Rect(0, 0, Elib.Scale(4), h):Radii(Elib.Scale(6), 0, Elib.Scale(6), 0):Color(accent):Draw()

    local pad = Elib.Scale(12)
    local y   = pad

    if self.Title ~= "" then
        draw.SimpleText(self.Title,
            Elib.GetRealFont("Elib.Medium") or "DermaDefaultBold",
            pad + Elib.Scale(4), y,
            Elib.SetColorAlpha(Elib.Colors.PrimaryText, a),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
        )
        y = y + Elib.Scale(20)
    end

    surface.SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
    local maxLineW = w - pad * 2 - Elib.Scale(4)

    local words = string.Explode(" ", self.Text)
    local line  = ""

    for _, word in ipairs(words) do
        local test = line == "" and word or (line .. " " .. word)
        local tw   = surface.GetTextSize(test)

        if tw > maxLineW and line ~= "" then
            draw.SimpleText(line,
                Elib.GetRealFont("Elib.Small") or "DermaDefault",
                pad + Elib.Scale(4), y,
                Elib.SetColorAlpha(Elib.Colors.SecondaryText, a),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
            )
            y = y + select(2, surface.GetTextSize(test))
            line = word
        else
            line = test
        end
    end

    if line ~= "" then
        draw.SimpleText(line,
            Elib.GetRealFont("Elib.Small") or "DermaDefault",
            pad + Elib.Scale(4), y,
            Elib.SetColorAlpha(Elib.Colors.SecondaryText, a),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
        )
    end
end

vgui.Register("Elib.Notification", PANEL, "EditablePanel")

/////////////////////////
// Layout manager
/////////////////////////
function Elib.Notifications.Relayout()
    local margin = Elib.Scale(16)
    local spacing = Elib.Scale(8)

    local yCursor
    local anchorRight = Elib.Notifications.Position:find("right") ~= nil
    local anchorTop   = Elib.Notifications.Position:find("top") ~= nil

    yCursor = anchorTop and margin or (ScrH() - margin)

    for i, n in ipairs(Elib.Notifications.Active) do
        if not IsValid(n) then continue end

        local w, h = n:GetSize()

        local x
        if anchorRight then
            x = ScrW() - w - margin + (n.OffsetX or 0)
        else
            x = margin - (n.OffsetX or 0)
        end

        local y
        if anchorTop then
            y = yCursor
            yCursor = yCursor + h + spacing
        else
            yCursor = yCursor - h
            y = yCursor
            yCursor = yCursor - spacing
        end

        n:SetPos(x, y)
    end
end

hook.Add("Think", "Elib.Notifications.Relayout", function()
    if #Elib.Notifications.Active > 0 then Elib.Notifications.Relayout() end
end)

/////////////////////////
// Public API
/////////////////////////
function Elib.Notify(textOrOpts, ntype, duration)
    local opts

    if type(textOrOpts) == "table" then
        opts = textOrOpts
    else
        opts = {
            text     = textOrOpts,
            type     = ntype,
            duration = duration,
        }
    end

    local n = vgui.Create("Elib.Notification")
    n:Configure(opts)

    table.insert(Elib.Notifications.Active, n)
    Elib.Notifications.Relayout()

    while #Elib.Notifications.Active > 5 do
        local oldest = table.remove(Elib.Notifications.Active, 1)
        if IsValid(oldest) then oldest:Remove() end
    end

    return n
end