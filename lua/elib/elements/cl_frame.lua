// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

local PANEL = {}

AccessorFunc(PANEL, "Title",          "Title",          FORCE_STRING)
AccessorFunc(PANEL, "Draggable",      "Draggable",      FORCE_BOOL)
AccessorFunc(PANEL, "ScreenLock",     "ScreenLock",     FORCE_BOOL)
AccessorFunc(PANEL, "RemoveOnClose",  "RemoveOnClose",  FORCE_BOOL)
AccessorFunc(PANEL, "Sizable",        "Sizable",        FORCE_BOOL)
AccessorFunc(PANEL, "MinWidth",       "MinWidth",       FORCE_NUMBER)
AccessorFunc(PANEL, "MinHeight",      "MinHeight",      FORCE_NUMBER)
AccessorFunc(PANEL, "Padding",        "Padding",        FORCE_NUMBER)
AccessorFunc(PANEL, "SidebarWidth",   "SidebarWidth",   FORCE_NUMBER)
AccessorFunc(PANEL, "HeaderHeight",   "HeaderHeight",   FORCE_NUMBER)
AccessorFunc(PANEL, "CornerRadius",   "CornerRadius",   FORCE_NUMBER)

function PANEL:Init()
    self:SetTitle("Elib Frame")
    self:SetDraggable(true)
    self:SetScreenLock(true)
    self:SetRemoveOnClose(true)
    self:SetSizable(false)

    self:SetPadding(6)
    self:SetSidebarWidth(200)
    self:SetHeaderHeight(40)
    self:SetCornerRadius(6)

    local minSize = Elib.Scale(200)
    self:SetMinWidth(minSize)
    self:SetMinHeight(minSize)

    self.ExtraButtons = {}

    local oldMakePopup = self.MakePopup
    function self:MakePopup()
        oldMakePopup(self)
        self:Open()
    end

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    self.BackgroundColor   = Elib.Colors.Background
    self.HeaderColor       = Elib.Colors.Header
    self.HeaderAccentColor = Elib.OffsetColor(Elib.Colors.Header, -5)
    self.TitleColor        = Elib.Colors.PrimaryText
    self.CloseColor        = Elib.Colors.SecondaryText
    self.CloseHoverColor   = Elib.Colors.Negative
end

/////////////////////////
// Sidebar integration
/////////////////////////
function PANEL:CreateSidebar(defaultItem)
    if IsValid(self.Sidebar) then return self.Sidebar end

    self.Sidebar = vgui.Create("Elib.Sidebar", self)

    if defaultItem then
        timer.Simple(0, function()
            if IsValid(self.Sidebar) then
                self.Sidebar:SelectItem(defaultItem)
            end
        end)
    end

    self:InvalidateLayout()
    return self.Sidebar
end

/////////////////////////
// Navbar integration
/////////////////////////
function PANEL:CreateNavbar(defaultItem)
    if IsValid(self.Navbar) then return self.Navbar end

    self.Navbar = vgui.Create("Elib.Navbar", self)

    if defaultItem then
        timer.Simple(0, function()
            if IsValid(self.Navbar) then
                self.Navbar:SelectItem(defaultItem)
            end
        end)
    end

    self:InvalidateLayout()
    return self.Navbar
end

function PANEL:GetNavbarHeight()
    return Elib.Scale(self.NavbarHeight or 36)
end

function PANEL:SetNavbarHeight(px)
    self.NavbarHeight = px
    self:InvalidateLayout()
end

/////////////////////////
// Extra header buttons
/////////////////////////
function PANEL:AddHeaderButton(btn, size)
    btn.HeaderIconSize = size or 0.6
    table.insert(self.ExtraButtons, btn)
    self:InvalidateLayout()
    return btn
end

/////////////////////////
// Dragging
/////////////////////////
function PANEL:OnMousePressed()
    if not self:GetDraggable() then return end

    local _, sy = self:LocalToScreen(0, 0)
    local my    = gui.MouseY()

    if my < sy + Elib.Scale(self:GetHeaderHeight()) then
        self.Dragging = { gui.MouseX() - self.x, my - self.y }
        self:MouseCapture(true)
    end
end

function PANEL:OnMouseReleased()
    self.Dragging = nil
    self:MouseCapture(false)
end

function PANEL:Think()
    if not self.Dragging then
        self:SetCursor("arrow")
        return
    end

    local scrw, scrh = ScrW(), ScrH()
    local mx = math.Clamp(gui.MouseX(), 1, scrw - 1)
    local my = math.Clamp(gui.MouseY(), 1, scrh - 1)

    local x = mx - self.Dragging[1]
    local y = my - self.Dragging[2]

    if self:GetScreenLock() then
        x = math.Clamp(x, 0, scrw - self:GetWide())
        y = math.Clamp(y, 0, scrh - self:GetTall())
    end

    self:SetPos(x, y)
    self:SetCursor("sizeall")
end

/////////////////////////
// Layout
/////////////////////////
function PANEL:LayoutContent(w, h) end

function PANEL:PerformLayout(w, h)
    local headerH   = Elib.Scale(self:GetHeaderHeight())
    local btnPad    = Elib.Scale(6)
    local btnSpace  = Elib.Scale(6)

    for _, btn in ipairs(self.ExtraButtons) do
        if IsValid(btn) then
            local size = headerH * (btn.HeaderIconSize or 0.6)
            btn:SetSize(size, size)
            btn:SetPos(w - size - btnPad, (headerH - size) / 2)
            btnPad = btnPad + size + btnSpace
        end
    end

    local sidebarW = 0
    if IsValid(self.Sidebar) then
        local fullW = Elib.Scale(self:GetSidebarWidth())

        // Store the intended full width so the sidebar Think can lerp correctly.
        // Only update ExpandedWidth when not mid-collapse so we do not corrupt the target.
        if not self.Sidebar.Collapsed and self.Sidebar.CollapseAmount < 0.05 then
            self.Sidebar.ExpandedWidth = fullW
        end

        // While animating, only set height; the sidebar Think owns width.
        if self.Sidebar.Animating then
            self.Sidebar:SetPos(0, headerH)
            self.Sidebar:SetTall(h - headerH)
        else
            self.Sidebar:SetPos(0, headerH)
            self.Sidebar:SetSize(self.Sidebar.ExpandedWidth or fullW, h - headerH)
        end

        sidebarW = self.Sidebar:GetWide()
    end

    local navbarH = 0
    if IsValid(self.Navbar) then
        navbarH = self:GetNavbarHeight()
        self.Navbar:SetPos(sidebarW, headerH)
        self.Navbar:SetSize(w - sidebarW, navbarH)
    end

    local padding    = Elib.Scale(self:GetPadding())
    local leftOffset = IsValid(self.Sidebar) and sidebarW + padding or padding
    local topOffset  = headerH + navbarH + padding

    self:DockPadding(leftOffset, topOffset, padding, padding)

    self:LayoutContent(w, h)
end

/////////////////////////
// Open / Close animations
/////////////////////////
function PANEL:Open()
    local w, h = self:GetSize()

    timer.Simple(0, function()
        if not IsValid(self) then return end
        self:SetAlpha(0)
        self:SetVisible(true)
        self:AlphaTo(255, 0.25, 0)

        self:SetSize(35, 35)
        self:SizeTo(w, 35, 0.25)
        self:SizeTo(w, h, 0.25, 0.25)

        self:SetPos(ScrW() / 2, ScrH() / 2 - 35 / 2)
        self:MoveTo(ScrW() / 2 - w / 2, ScrH() / 2 - 35 / 2, 0.25)
        self:MoveTo(ScrW() / 2 - w / 2, ScrH() / 2 - h / 2, 0.25, 0.25)
    end)
end

function PANEL:Close()
    self:AlphaTo(0, 0.25, 0, function(_, pnl)
        if not IsValid(pnl) then return end
        pnl:SetVisible(false)
        pnl:OnClose()
        if pnl:GetRemoveOnClose() then pnl:Remove() end
    end)
end

function PANEL:OnClose() end

/////////////////////////
// Close button
/////////////////////////
local function closeBounds(self, w)
    local headerH = Elib.Scale(self:GetHeaderHeight())
    local size    = headerH * 0.45
    local pad     = Elib.Scale(8)
    local x       = w - size - pad
    local y       = (headerH - size) / 2
    return x, y, size, size
end

function PANEL:IsHoveringClose()
    if not self:IsHovered() then return false end
    local mx, my = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
    local cx, cy, cw, ch = closeBounds(self, self:GetWide())
    return mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch -- well... i fucked up so tar Co-Pilot for this :D
end

local wrappedMousePressed = PANEL.OnMousePressed
function PANEL:OnMousePressed(code)
    if code == MOUSE_LEFT and self:IsHoveringClose() then
        self:Close()
        return
    end
    wrappedMousePressed(self, code)
end

/////////////////////////
// Painting
/////////////////////////
function PANEL:PaintHeader(w, h)
    local r = Elib.Scale(self:GetCornerRadius())

    RNDX().Rect(0, 0, w, h)
        :Radii(r, r, 0, 0)
        :Color(self.HeaderColor)
        :Draw()

    surface.SetDrawColor(self.HeaderAccentColor)
    surface.DrawRect(0, h - 1, w, 1)

    draw.SimpleText(self:GetTitle() or "",
        Elib.GetRealFont("Elib.Large") or "DermaLarge",
        Elib.Scale(10), h / 2,
        self.TitleColor,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
    )

    local cx, cy, cw, ch = closeBounds(self, w)

    local col = self:IsHoveringClose() and self.CloseHoverColor or self.CloseColor
    self:SetCursor(self:IsHoveringClose() and "hand" or "arrow")
    surface.SetDrawColor(col)

    surface.DrawLine(cx,      cy,      cx + cw, cy + ch)
    surface.DrawLine(cx + cw, cy,      cx,      cy + ch)
    surface.DrawLine(cx + 1,  cy,      cx + cw + 1, cy + ch)
    surface.DrawLine(cx + cw - 1, cy,  cx - 1,  cy + ch)
end

function PANEL:Paint(w, h)
    local r = Elib.Scale(self:GetCornerRadius())

    RNDX().Rect(0, 0, w, h)
        :Rad(r)
        :Color(self.BackgroundColor)
        :Draw()

    self:PaintHeader(w, Elib.Scale(self:GetHeaderHeight()))
end

vgui.Register("Elib.Frame", PANEL, "EditablePanel")