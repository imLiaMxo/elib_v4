// Made by Eve Haddox & imLiaMxo
//
//   :GetCanvas() -> the inner container panel 
//   :SetBackToTop(bool) -> show a "back to top" button when scrolled
//   :ScrollToTop(smooth?) -> scroll to y=0
//   :ScrollToChild(panel) -> scroll so `panel` is visible
//   :SetScrollSpeed(n) -> px per wheel tick
//   :GetCurrentScroll() -> current visible y offset
//   :GetTargetScroll() -> where we're animating toward

local RNDX = Elib.RNDX

local PANEL = {}

AccessorFunc(PANEL, "ScrollSpeed", "ScrollSpeed", FORCE_NUMBER)  -- px per mouse-wheel tick (pre-scale)
AccessorFunc(PANEL, "BackToTop",   "BackToTop",   FORCE_BOOL)
AccessorFunc(PANEL, "BarWidth",    "BarWidth",    FORCE_NUMBER)

function PANEL:Init()
    self:SetScrollSpeed(60)
    self:SetBackToTop(false)
    self:SetBarWidth(4)

    self.Canvas = vgui.Create("Panel", self)
    self.Canvas:SetMouseInputEnabled(true)
    self.Canvas.PerformLayout = function(c)
        self:InvalidateLayout()
    end

    self.TargetScroll  = 0
    self.CurrentScroll = 0
    self._backBtn      = nil
    self._backBtnAlpha = 0
    self._dragging     = false
end

function PANEL:GetCanvas() return self.Canvas end

function PANEL:AddItem(pnl)
    pnl:SetParent(self.Canvas)
    return pnl
end

function PANEL:OnChildAdded(child)
    if not IsValid(self.Canvas) then return end
    if child._elib_internal then return end  -- ignore internal children
    if child == self.Canvas or child == self._backBtn then return end

    child:SetParent(self.Canvas)
end

function PANEL:Clear()
    self.Canvas:Clear()
    self:ScrollToTop(false)
end

/////////////////////////
// Sizing helpers
/////////////////////////
function PANEL:GetMaxScroll()
    local canvasH = self.Canvas:GetTall()
    local visibleH = self:GetTall()
    return math.max(0, canvasH - visibleH)
end

function PANEL:GetCurrentScroll() return self.CurrentScroll end
function PANEL:GetTargetScroll()  return self.TargetScroll  end

/////////////////////////
// Scroll operations
/////////////////////////
function PANEL:SetScroll(y, smooth)
    y = math.Clamp(y, 0, self:GetMaxScroll())
    self.TargetScroll = y
    if smooth == false then
        self.CurrentScroll = y
    end
end

function PANEL:ScrollToTop(smooth)
    self:SetScroll(0, smooth)
end

function PANEL:ScrollToChild(target)
    if not IsValid(target) then return end

    local _, y = target:GetPos()
    local h    = target:GetTall()
    local viewH = self:GetTall()
    local cur  = self.CurrentScroll

    if y < cur then
        self:SetScroll(y) -- above
    elseif y + h > cur + viewH then
        self:SetScroll(y + h - viewH)-- below
    end
end

/////////////////////////
// Mouse wheel
/////////////////////////
function PANEL:OnMouseWheeled(delta)
    if self:GetMaxScroll() <= 0 then return false end

    local step = Elib.Scale(self:GetScrollSpeed())
    self:SetScroll(self.TargetScroll - delta * step)
    return true
end

-- honestly without this it just fucking breaks... so lets just keep it. if work dont touch it
function PANEL:Think()
    self:_layoutBackButton()
end

/////////////////////////
// Animation
/////////////////////////
function PANEL:AnimationThink()
    -- credit where its due: GlorifiedPig. Big man ting.
    if math.abs(self.CurrentScroll - self.TargetScroll) > 0.5 then
        self.CurrentScroll = Lerp(FrameTime() * 15, self.CurrentScroll, self.TargetScroll)
    else
        self.CurrentScroll = self.TargetScroll
    end

    self.Canvas:SetPos(0, -math.Round(self.CurrentScroll))

    if self:GetBackToTop() and IsValid(self._backBtn) then
        local shouldShow = self.CurrentScroll > self:GetTall() * 0.5
        local target     = shouldShow and 255 or 0
        self._backBtnAlpha = Lerp(FrameTime() * 8, self._backBtnAlpha, target)
        self._backBtn:SetAlpha(self._backBtnAlpha)
        self._backBtn:SetMouseInputEnabled(self._backBtnAlpha > 50)
        self._backBtn:SetVisible(self._backBtnAlpha > 1)
    end

    --self:_layoutBackButton()-- didnt work here fuck
end

/////////////////////////
// Layout
/////////////////////////
function PANEL:PerformLayout(w, h)
    local barW = Elib.Scale(self:GetBarWidth())
    local needsBar = self.Canvas:GetTall() > h
    local canvasW = needsBar and (w - barW - Elib.Scale(2)) or w

    if self:GetBackToTop() and not IsValid(self._backBtn) then
        self:_buildBackToTop()
        self._backBtn:SetParent(self) -- breaks without I didn';t querstion as to why
    end

    self.Canvas:SetWide(canvasW)
    self.Canvas:SizeToChildren(false, true)

    self.TargetScroll  = math.Clamp(self.TargetScroll,  0, self:GetMaxScroll())
    self.CurrentScroll = math.Clamp(self.CurrentScroll, 0, self:GetMaxScroll())


    self:_layoutBackButton()
end

/////////////////////////
// Back to Top button
/////////////////////////
function PANEL:_buildBackToTop()
    local btn = vgui.Create("DButton", self)
    btn._elib_internal = true
    self._backBtn = btn

    
    btn:SetText("")
    btn:SetCursor("hand")
    btn:SetAlpha(0)
    btn:SetMouseInputEnabled(true)
    btn:SetKeyboardInputEnabled(false)
    btn:SetVisible(false)
    btn:SetDrawOnTop(true)
    btn:SetSize(Elib.Scale(40), Elib.Scale(40))
    btn:SetZPos(1000)
    btn:SetPaintedManually(false)

    -- do not ask why all this is here. it just is. if it aint broke dont fix it.

    btn.DoClick = function()
        self:ScrollToTop(true)
    end

    btn.Paint = function(s, w, h)
        local bgCol = s:IsHovered() and Elib.OffsetColor(Elib.Colors.Primary, 10) or Elib.Colors.Primary
        RNDX().Circle(w / 2, h / 2, math.min(w, h)):Color(bgCol):Draw()
        local cx, cy = w / 2, h / 2
        local arm    = Elib.Scale(6)

        surface.SetDrawColor(Elib.Colors.PrimaryText)
        surface.DrawLine(cx,       cy - arm / 2, cx - arm, cy + arm / 2)
        surface.DrawLine(cx,       cy - arm / 2, cx + arm, cy + arm / 2)
        -- make it bolder. I wanted to use a webimage but it looked like shit.
        surface.DrawLine(cx + 1,   cy - arm / 2, cx - arm + 1, cy + arm / 2)
        surface.DrawLine(cx,       cy - arm / 2 + 1, cx + arm, cy + arm / 2 + 1)
    end

end

function PANEL:_layoutBackButton()
    if not IsValid(self._backBtn) then return end

    local size = Elib.Scale(40)
    local pad  = Elib.Scale(16)
    local w, h = self:GetSize()

    self._backBtn:SetPos(w - size - pad, h - size - pad)
end

/////////////////////////
// Scrollbar
/////////////////////////
function PANEL:_scrollbarRect()
    local w, h = self:GetSize()
    local barW = Elib.Scale(self:GetBarWidth())
    local pad  = Elib.Scale(2)

    local maxScroll = self:GetMaxScroll()
    if maxScroll <= 0 then return nil end

    local canvasH = self.Canvas:GetTall()
    local gripH   = math.max(Elib.Scale(24), h * (h / canvasH))
    local gripY   = (self.CurrentScroll / maxScroll) * (h - gripH)

    return w - barW - pad, gripY, barW, gripH
end

function PANEL:OnMousePressed(code)
    if code ~= MOUSE_LEFT then return end

    local rx, ry, rw, rh = self:_scrollbarRect()
    if not rx then return end

    local mx, my = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
    if mx < rx then return end 

    if my >= ry and my <= ry + rh then
        self._dragging    = true
        self._dragOffsetY = my - ry
        self:MouseCapture(true)
    else
        local h = self:GetTall()
        local maxScroll = self:GetMaxScroll()
        local pct = math.Clamp((my - rh / 2) / (h - rh), 0, 1)
        self:SetScroll(pct * maxScroll, false)
    end
end

function PANEL:OnMouseReleased(code)
    if code ~= MOUSE_LEFT then return end
    if not self._dragging then return end

    self._dragging = false
    self:MouseCapture(false)
end

function PANEL:OnCursorMoved(mx, my)
    if not self._dragging then return end

    local _, _, _, rh = self:_scrollbarRect()
    if not rh then return end

    local h = self:GetTall()
    local maxScroll = self:GetMaxScroll()
    local gripY = math.Clamp(my - self._dragOffsetY, 0, h - rh)
    local pct   = gripY / (h - rh)

    self:SetScroll(pct * maxScroll, false)
end

/////////////////////////
// Paint
/////////////////////////
function PANEL:Paint(w, h)
    self:AnimationThink()
    
    local rx, ry, rw, rh = self:_scrollbarRect()
    if rx then
        RNDX().Rect(rx, ry, rw, rh)
            :Rad(rw / 2)
            :Color(self._dragging and Elib.Colors.Primary or Elib.Colors.Scroller)
            :Draw()
    end
end

vgui.Register("Elib.ScrollPanel", PANEL, "Panel")