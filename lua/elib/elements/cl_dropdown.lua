// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

/////////////////////////
// Menu Option Row
/////////////////////////
local OPTION = {}

AccessorFunc(OPTION, "Value", "Value", FORCE_STRING)
AccessorFunc(OPTION, "Data",  "Data")
AccessorFunc(OPTION, "Highlighted", "Highlighted", FORCE_BOOL)
AccessorFunc(OPTION, "IsSelected",  "IsSelected",  FORCE_BOOL)

function OPTION:Init()
    self:SetValue("")
    self:SetHighlighted(false)
    self:SetIsSelected(false)
    self:SetCursor("hand")
    self.Icon = nil
end

function OPTION:SetIcon(mat) self.Icon = mat end
function OPTION:DoClick() end
function OPTION:OnCursorEntered() self:SetHighlighted(true) end
function OPTION:OnCursorExited()  self:SetHighlighted(false) end

function OPTION:OnMousePressed(code)
    if code == MOUSE_LEFT then self:DoClick() end
end

function OPTION:Paint(w, h)
    if self:GetHighlighted() then
        RNDX().Rect(Elib.Scale(2), Elib.Scale(1), w - Elib.Scale(4), h - Elib.Scale(2))
            :Rad(Elib.Scale(3))
            :Color(Elib.Colors.Scroller)
            :Draw()
    end

    local textX = Elib.Scale(10)

    if self.Icon then
        local size = h * 0.6
        surface.SetMaterial(self.Icon)
        surface.SetDrawColor(Elib.Colors.PrimaryText)
        surface.DrawTexturedRect(Elib.Scale(8), (h - size) / 2, size, size)
        textX = Elib.Scale(12) + size
    end

    if self:GetIsSelected() then
        local dot = Elib.Scale(6)
        RNDX().Circle(w - Elib.Scale(12) - dot / 2, h / 2, dot)
            :Color(Elib.Colors.Primary):Draw()
    end

    draw.SimpleText(self:GetValue(),
        Elib.GetRealFont("Elib.Body") or "DermaDefault",
        textX, h / 2,
        self:GetIsSelected() and Elib.Colors.PrimaryText or Elib.Colors.SecondaryText,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
    )
end

vgui.Register("Elib.DropdownOption", OPTION, "Panel")

/////////////////////////
// Dropdown Menu (popup)
/////////////////////////
local MENU = {}

function MENU:Init()
    self:SetDrawOnTop(true)
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)

    self.Options          = {}
    self.HighlightedIndex = 0
    self.RowHeight        = Elib.Scale(32)
    self.MaxRows          = 8

    self.Scroll = vgui.Create("Elib.ScrollPanel", self)
    self.Scroll:Dock(FILL)
    self.Scroll:DockMargin(Elib.Scale(2), Elib.Scale(2), Elib.Scale(2), Elib.Scale(2))
end

function MENU:SetOptions(entries, selectedID)
    self.Scroll:Clear()
    self.Options = {}

    for i, entry in ipairs(entries) do
        local row = vgui.Create("Elib.DropdownOption", self.Scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, Elib.Scale(1))
        row:SetTall(self.RowHeight)
        row:SetValue(entry.value)
        row:SetData(entry.data)
        row:SetIsSelected(entry.id == selectedID)
        if entry.icon then row:SetIcon(entry.icon) end

        row.DoClick = function()
            if self.OnSelect then self:OnSelect(entry.id) end
        end

        row.OnCursorEntered = function(s)
            s:SetHighlighted(true)
            self.HighlightedIndex = i
        end

        self.Options[i] = row

        if entry.id == selectedID then
            self.HighlightedIndex = i
        end
    end
end

function MENU:SetHighlightedIndex(i)
    self.HighlightedIndex = i
    for idx, row in ipairs(self.Options) do
        row:SetHighlighted(idx == i)
    end

    local row = self.Options[i]
    if not IsValid(row) then return end

    self.Scroll:ScrollToChild(row)
end

function MENU:Think()
    if input.IsMouseDown(MOUSE_LEFT) then
        if not self:IsHovered() and not self:IsChildHovered(10) then
            if not (IsValid(self.Owner) and self.Owner:IsHovered()) then
                self:Close()
            end
        end
    end
end

function MENU:OnKeyCodePressed(key)
    if key == KEY_ESCAPE then
        self:Close()
    elseif key == KEY_DOWN then
        local next = math.min(self.HighlightedIndex + 1, #self.Options)
        if next > 0 then self:SetHighlightedIndex(next) end
    elseif key == KEY_UP then
        local prev = math.max(self.HighlightedIndex - 1, 1)
        if #self.Options > 0 then self:SetHighlightedIndex(prev) end
    elseif key == KEY_ENTER or key == KEY_PAD_ENTER then
        local row = self.Options[self.HighlightedIndex]
        if IsValid(row) then row:DoClick() end
    end
end

function MENU:Close()
    if IsValid(self.Owner) and self.Owner.Menu == self then
        self.Owner.Menu = nil
    end
    self:Remove()
end

function MENU:Paint(w, h)
    local r = Elib.Scale(4)

    RNDX().Rect(0, 0, w, h)
        :Rad(r)
        :Color(Elib.OffsetColor(Elib.Colors.Header, 5))
        :Draw()

    RNDX().Rect(Elib.Scale(1), Elib.Scale(1), w - Elib.Scale(2), h - Elib.Scale(2))
        :Rad(r - 1)
        :Color(Elib.Colors.Header)
        :Draw()
end

vgui.Register("Elib.DropdownMenu", MENU, "EditablePanel")

/////////////////////////
// Dropdown Button
/////////////////////////
local PANEL = {}

AccessorFunc(PANEL, "Placeholder",  "Placeholder",  FORCE_STRING)
AccessorFunc(PANEL, "SortItems",    "SortItems",    FORCE_BOOL)
AccessorFunc(PANEL, "CornerRadius", "CornerRadius", FORCE_NUMBER)

function PANEL:Init()
    self:SetPlaceholder("")
    self:SetSortItems(false)
    self:SetCornerRadius(4)
    self:SetText("")
    self:SetCursor("hand")

    self.Choices    = {}  -- { { value, data, icon } }
    self.SelectedID = nil

    self.OutlineColor = Color(0, 0, 0, 0)
    self.ArrowAngle   = 0   -- 0 = closed (down), 1 = open (up)

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    self.BackgroundColor  = Elib.OffsetColor(Elib.Colors.Background, 8)
    self.HoverColor       = Elib.OffsetColor(Elib.Colors.Background, 14)
    self.OutlineRestColor = Elib.OffsetColor(Elib.Colors.Scroller, 10)
    self.OutlineFocusCol  = Elib.Colors.Primary
    self.PlaceholderColor = Elib.OffsetColor(Elib.Colors.SecondaryText, -80)
    self.TextColor        = Elib.Colors.PrimaryText
    self.ArrowColor       = Elib.Colors.PrimaryText
end

/////////////////////////
// Choices
/////////////////////////
function PANEL:Clear()
    self.Choices    = {}
    self.SelectedID = nil
    if IsValid(self.Menu) then self.Menu:Close() end
end

function PANEL:AddChoice(value, data, select, icon)
    table.insert(self.Choices, {
        value = tostring(value),
        data  = data,
        icon  = icon,
    })

    local id = #self.Choices
    if select then self:ChooseOptionID(id) end
    return id
end

function PANEL:ChooseOptionID(id)
    local c = self.Choices[id]
    if not c then return end

    self.SelectedID = id
    if self.OnSelect then self:OnSelect(id, c.value, c.data) end
end

function PANEL:SelectValue(value)
    for id, c in ipairs(self.Choices) do
        if c.value == value then self:ChooseOptionID(id); return true end
    end
    return false
end

function PANEL:SelectData(data)
    for id, c in ipairs(self.Choices) do
        if c.data == data then self:ChooseOptionID(id); return true end
    end
    return false
end

function PANEL:GetSelectedID() return self.SelectedID end

function PANEL:GetSelected()
    local c = self.Choices[self.SelectedID]
    if not c then return nil, nil end
    return c.value, c.data
end

/////////////////////////
// Callbacks (override)
/////////////////////////
function PANEL:OnSelect(id, value, data) end

/////////////////////////
// Menu control
/////////////////////////
function PANEL:IsMenuOpen()
    return IsValid(self.Menu)
end

function PANEL:OpenMenu()
    if #self.Choices == 0 then return end

    if IsValid(self.Menu) then
        self.Menu:Close()
        return
    end

    local entries = {}
    for id, c in ipairs(self.Choices) do
        entries[#entries + 1] = {
            id    = id,
            value = c.value,
            data  = c.data,
            icon  = c.icon,
        }
    end

    if self:GetSortItems() then
        table.sort(entries, function(a, b) return a.value < b.value end)
    end

    local rowH    = Elib.Scale(32)
    local padding = Elib.Scale(4)
    local visible = math.min(#entries, 8)
    local menuW   = self:GetWide()
    local menuH   = visible * (rowH + Elib.Scale(1)) + padding * 2

    local menu = vgui.Create("Elib.DropdownMenu")
    menu:SetSize(menuW, menuH)
    menu.Owner = self

    menu:SetOptions(entries, self.SelectedID)

    local sx, sy = self:LocalToScreen(0, 0)
    local posX   = sx
    local posY   = sy + self:GetTall() + Elib.Scale(4)

    if posY + menuH > ScrH() and sy - menuH - Elib.Scale(4) >= 0 then
        posY = sy - menuH - Elib.Scale(4)
    end

    menu:SetPos(posX, posY)
    menu:MakePopup()
    menu:RequestFocus()

    menu.OnSelect = function(_, id)
        self:ChooseOptionID(id)
        menu:Close()
    end

    self.Menu = menu
end

function PANEL:CloseMenu()
    if IsValid(self.Menu) then self.Menu:Close() end
end

function PANEL:DoClick()
    if self:IsMenuOpen() then
        self:CloseMenu()
    else
        self:OpenMenu()
    end
end

/////////////////////////
// Paint
/////////////////////////
function PANEL:Paint(w, h)
    local r = Elib.Scale(self:GetCornerRadius())

    local bg = self:IsHovered() and self.HoverColor or self.BackgroundColor
    RNDX().Rect(0, 0, w, h):Rad(r):Color(bg):Draw()

    local target = self:IsMenuOpen() and self.OutlineFocusCol or self.OutlineRestColor
    self.OutlineColor = Elib.LerpColor(FrameTime() * 8, self.OutlineColor, target)

    RNDX().Rect(0, 0, w, h)
        :Rad(r)
        :Color(self.OutlineColor)
        :Outline(Elib.Scale(1))
        :Draw()

    self.ArrowAngle = Lerp(FrameTime() * 10, self.ArrowAngle, self:IsMenuOpen() and 1 or 0)

    local selected = self.Choices[self.SelectedID]
    local text, col

    if selected then
        text, col = selected.value, self.TextColor
    else
        text, col = self:GetPlaceholder(), self.PlaceholderColor
    end

    local chevSize = Elib.Scale(8)
    local chevGap  = Elib.Scale(10)
    local textPad  = Elib.Scale(10)

    draw.SimpleText(text or "",
        Elib.GetRealFont("Elib.Body") or "DermaDefault",
        textPad, h / 2,
        col,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
    )

    local cx = w - chevGap - chevSize / 2
    local cy = h / 2
    local angle = 180 * self.ArrowAngle   -- degrees
    local rad   = math.rad(angle)
    local cos, sin = math.cos(rad), math.sin(rad)

    // Triangle points, centred on origin - pointing down initially.
    local pts = {
        { x = -chevSize / 2, y = -chevSize / 4 }, --tl
        { x =  chevSize / 2, y = -chevSize / 4 }, -- b
        { x =  0,            y =  chevSize / 2 }, -- tr  .. fuck I think? I forgot
    }

    surface.SetDrawColor(self.ArrowColor)

    local rotated = {}
    for i, p in ipairs(pts) do
        rotated[i] = {
            x = cx + (p.x * cos - p.y * sin),
            y = cy + (p.x * sin + p.y * cos),
        }
    end

    for i = 1, 3 do
        local a, b = rotated[i], rotated[i % 3 + 1]
        surface.DrawLine(a.x, a.y, b.x, b.y)
    end
end

vgui.Register("Elib.Dropdown", PANEL, "DButton")