// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

/////////////////////////
// Row (single entry)
/////////////////////////
local ROW = {}

AccessorFunc(ROW, "Value", "Value", FORCE_STRING)
AccessorFunc(ROW, "Index", "Index", FORCE_NUMBER)

function ROW:Init()
    self:SetValue("")
    self:SetTall(Elib.Scale(30))
    self:DockMargin(0, 0, 0, Elib.Scale(4))
end

function ROW:DoRemove() end

function ROW:IsHoveringDelete(mx)
    local w = self:GetWide()
    local btnSize = Elib.Scale(22)
    return mx >= w - btnSize - Elib.Scale(4) and mx <= w - Elib.Scale(4)
end

function ROW:OnMousePressed(code)
    if code ~= MOUSE_LEFT then return end

    local mx = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
    if self:IsHoveringDelete(mx) then self:DoRemove() end
end

function ROW:Paint(w, h)
    local r = Elib.Scale(4)

    RNDX().Rect(0, 0, w, h)
        :Rad(r)
        :Color(Elib.OffsetColor(Elib.Colors.Background, 10))
        :Draw()

    draw.SimpleText(self:GetValue(),
        Elib.GetRealFont("Elib.Body") or "DermaDefault",
        Elib.Scale(10), h / 2,
        Elib.Colors.PrimaryText,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
    )

    local btnSize = Elib.Scale(22)
    local bx      = w - btnSize - Elib.Scale(4)
    local by      = (h - btnSize) / 2

    local mx = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
    local hovered = self:IsHovered() and self:IsHoveringDelete(mx)

    local btnCol = hovered and Elib.Colors.Negative or Elib.OffsetColor(Elib.Colors.Scroller, 5)
    RNDX().Rect(bx, by, btnSize, btnSize):Rad(Elib.Scale(3)):Color(btnCol):Draw()

    local inset = Elib.Scale(6)
    local lineCol = hovered and Elib.Colors.PrimaryText or Elib.Colors.SecondaryText
    surface.SetDrawColor(lineCol)
    surface.DrawLine(bx + inset,           by + inset,           bx + btnSize - inset, by + btnSize - inset)
    surface.DrawLine(bx + btnSize - inset, by + inset,           bx + inset,           by + btnSize - inset)
end

function ROW:Think()
    local mx = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
    if self:IsHovered() and self:IsHoveringDelete(mx) then
        self:SetCursor("hand")
    else
        self:SetCursor("arrow")
    end
end

vgui.Register("Elib.TableRow", ROW, "Panel")

/////////////////////////
// Table element
/////////////////////////
local PANEL = {}

AccessorFunc(PANEL, "Placeholder", "Placeholder", FORCE_STRING)
AccessorFunc(PANEL, "MaxEntries",  "MaxEntries",  FORCE_NUMBER)

function PANEL:Init()
    self:SetPlaceholder("New entry...")
    self:SetMaxEntries(0) -- 0 = unlimited

    self.Entries   = {}
    self.Validator = nil

    self.Scroll = vgui.Create("Elib.ScrollPanel", self)
    self.Scroll:Dock(FILL)

    self.AddBar = vgui.Create("Panel", self)
    self.AddBar:Dock(BOTTOM)
    self.AddBar:DockMargin(0, Elib.Scale(6), 0, 0)
    self.AddBar:SetTall(Elib.Scale(34))

    self.Input = vgui.Create("Elib.TextEntry", self.AddBar)
    self.Input:Dock(FILL)
    self.Input:DockMargin(0, 0, Elib.Scale(6), 0)
    self.Input:SetPlaceholder(self:GetPlaceholder())
    self.Input:SetUpdateOnType(false)

    self.Input.OnEnter = function(_, v)
        self:_tryAdd(v)
    end

    self.AddButton = vgui.Create("DButton", self.AddBar)
    self.AddButton:Dock(RIGHT)
    self.AddButton:SetWide(Elib.Scale(80))
    self.AddButton:SetText("")
    self.AddButton:SetCursor("hand")

    self.AddButton.Paint = function(s, w, h)
        local bg = s:IsHovered()
            and Elib.OffsetColor(Elib.Colors.Primary, 10)
            or Elib.Colors.Primary
        RNDX().Rect(0, 0, w, h):Rad(Elib.Scale(4)):Color(bg):Draw()

        draw.SimpleText(
            Elib.Lang and Elib.Lang.Get("elib.table.add") or "Add",
            Elib.GetRealFont("Elib.Body") or "DermaDefault",
            w / 2, h / 2,
            Elib.Colors.PrimaryText,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
        )
    end

    self.AddButton.DoClick = function()
        self:_tryAdd(self.Input:GetValue())
    end

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    -- no longer used but here incase I fucking lef tit somewhere.
end

function PANEL:SetValidator(fn) self.Validator = fn end

/////////////////////////
// Entry management
/////////////////////////
function PANEL:GetEntries()
    local out = {}
    for i, v in ipairs(self.Entries) do out[i] = v end
    return out
end

function PANEL:SetEntries(list)
    self.Entries = {}
    if type(list) == "table" then
        for _, v in ipairs(list) do
            self.Entries[#self.Entries + 1] = tostring(v)
        end
    end
    self:_rebuildRows()
    if self.OnChange then self:OnChange(self:GetEntries()) end
end

function PANEL:Clear()
    self:SetEntries({})
end

function PANEL:AddEntry(value)
    value = tostring(value or ""):Trim()
    if value == "" then return false, "Empty" end

    local max = self:GetMaxEntries()
    if max > 0 and #self.Entries >= max then
        return false, "Max " .. max .. " entries"
    end

    if self.Validator then
        local ok, err = self.Validator(value, self.Entries)
        if not ok then return false, err end
    end

    table.insert(self.Entries, value)
    self:_rebuildRows()
    if self.OnChange then self:OnChange(self:GetEntries()) end
    return true
end

function PANEL:RemoveEntry(index)
    if not self.Entries[index] then return end
    table.remove(self.Entries, index)
    self:_rebuildRows()
    if self.OnChange then self:OnChange(self:GetEntries()) end
end

/////////////////////////
// Internal
/////////////////////////
function PANEL:_tryAdd(value)
    local ok, err = self:AddEntry(value)

    if ok then
        self.Input:SetValue("")
    else
        self.Input:SetValidator(function(v)
            if v == "" then return true end
            return true
        end)

        self.Input.IsValidValue    = false
        self.Input.ValidationError = err or "Invalid"
        self.Input:InvalidateLayout()
    end
end

function PANEL:_rebuildRows()
    self.Scroll:Clear()

    for i, value in ipairs(self.Entries) do
        local row = vgui.Create("Elib.TableRow", self.Scroll)
        row:Dock(TOP)
        row:SetValue(value)
        row:SetIndex(i)

        local capturedIndex = i
        row.DoRemove = function()
            self:RemoveEntry(capturedIndex)
        end
    end
end

/////////////////////////
// Callbacks (override)
/////////////////////////
function PANEL:OnChange(entries) end

/////////////////////////
// Paint
/////////////////////////
function PANEL:Paint(w, h)
    RNDX().Rect(0, 0, w, h)
        :Rad(Elib.Scale(4))
        :Color(Elib.OffsetColor(Elib.Colors.Background, 4))
        :Outline(Elib.Scale(1))
        :Draw()

    RNDX().Rect(Elib.Scale(1), Elib.Scale(1), w - Elib.Scale(2), h - Elib.Scale(2))
        :Rad(Elib.Scale(3))
        :Color(Elib.OffsetColor(Elib.Colors.Background, 2))
        :Draw()
end

function PANEL:PerformLayout(w, h)
    self.Scroll:DockMargin(Elib.Scale(6), Elib.Scale(6), Elib.Scale(6), 0)
    self.AddBar:DockMargin(Elib.Scale(6), Elib.Scale(6), Elib.Scale(6), Elib.Scale(6))
end

vgui.Register("Elib.Table", PANEL, "Panel")