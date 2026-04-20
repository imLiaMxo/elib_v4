// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX
local function L(key, ...) return Elib.Lang.Get(key, ...) end

/////////////////////////
// Helpers
/////////////////////////
local function valuesEqual(a, b)
    if a == b then return true end
    if type(a) ~= type(b) then return false end

    if type(a) == "table" then
        if IsColor(a) and IsColor(b) then
            return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a
        end

        local aCount, bCount = 0, 0
        for _ in pairs(a) do aCount = aCount + 1 end
        for _ in pairs(b) do bCount = bCount + 1 end
        if aCount ~= bCount then return false end

        for k, v in pairs(a) do
            if not valuesEqual(v, b[k]) then return false end
        end
        return true
    end

    return false
end

local function deepCopy(v)
    if type(v) ~= "table" then return v end
    if IsColor(v) then return Color(v.r, v.g, v.b, v.a) end

    local out = {}
    for k, val in pairs(v) do out[k] = deepCopy(val) end
    return out
end

/////////////////////////
// Value Row
/////////////////////////
local ROW = {}

AccessorFunc(ROW, "Addon",    "Addon",    FORCE_STRING)
AccessorFunc(ROW, "Realm",    "Realm",    FORCE_STRING)
AccessorFunc(ROW, "Category", "Category", FORCE_STRING)
AccessorFunc(ROW, "ValueID",  "ValueID",  FORCE_STRING)

function ROW:Init()
    self:SetTall(Elib.Scale(48))
    self:DockMargin(0, 0, 0, Elib.Scale(8))

    self.Label = vgui.Create("DLabel", self)
    self.Label:SetFont(Elib.GetRealFont("Elib.Body") or "DermaDefault")
    self.Label:SetTextColor(Elib.Colors.PrimaryText)

    self.Dirty         = false
    self.PendingValue  = nil
end

function ROW:_markDirty(newValue)
    self.PendingValue = deepCopy(newValue)
    self.Dirty = not valuesEqual(self.PendingValue, self.Entry.value)

    local menu = self.OwnerMenu
    if IsValid(menu) then menu:RefreshDirtyState() end
end

function ROW:IsDirty() return self.Dirty end

function ROW:CommitIfDirty()
    if not self.Dirty then return end

    Elib.Config.Save(
        self:GetAddon(),
        self:GetRealm(),
        self:GetCategory(),
        self:GetValueID(),
        self.PendingValue
    )

    self.Dirty        = false
    self.PendingValue = nil
end

function ROW:Revert()
    if not self.Dirty then return end
    self.Dirty        = false
    self.PendingValue = nil
    self:_syncEditorToSavedValue()
end

function ROW:Pervert() -- I kept putting Pervert not Revert. don't ask.
    self:Revert()
end

function ROW:_syncEditorToSavedValue()
    if not IsValid(self.Editor) or not self.Entry then return end

    local v     = self.Entry.value
    local vtype = self.Entry.type

    if vtype == "Boolean" or vtype == "Bool" then
        self.Editor:SetValue(v == true)
        if self.Editor.SnapToValue then self.Editor:SnapToValue() end
    elseif vtype == "Dropdown" or vtype == "Selection" then
        if not self.Editor:SelectData(v) then
            self.Editor:SelectValue(tostring(v))
        end
    elseif vtype == "Table" then
        self.Editor:SetValue(util.TableToJSON(v or {}, true))
    elseif vtype == "List" then
        self.Editor:SetEntries(v or {})
    elseif vtype == "Color" then
        local c = v
        if not IsColor(c) then c = Color(c.r or 255, c.g or 255, c.b or 255, c.a or 255) end
        self.Editor._color = c
    else
        self.Editor:SetValue(tostring(v or ""))
    end
end

/////////////////////////
// Build editor widget
/////////////////////////
function ROW:Build()
    local entry = Elib.Config.Addons[self:GetAddon()]
                   and Elib.Config.Addons[self:GetAddon()][self:GetRealm()]
                   and Elib.Config.Addons[self:GetAddon()][self:GetRealm()][self:GetCategory()]
                   and Elib.Config.Addons[self:GetAddon()][self:GetRealm()][self:GetCategory()][self:GetValueID()]

    if not entry then return end

    self.Entry = entry
    self.Label:SetText(entry.name or self:GetValueID())

    if entry.description or entry.tooltip then
        Elib.Tooltip.Attach(self, entry.description or entry.tooltip)
    end

    local vtype = entry.type

    if vtype == "Text" or vtype == "String" then
        local te = vgui.Create("Elib.TextEntry", self)
        te:SetUpdateOnType(true)
        te:SetValue(entry.value or entry.default or "")
        te.OnChange = function(_, v) self:_markDirty(v) end

        if entry.validator then te:SetValidator(entry.validator) end
        if entry.minLength then te:SetMinLength(entry.minLength) end
        if entry.maxLength then te:SetMaxInputLength(entry.maxLength) end
        if entry.pattern   then te:SetPattern(entry.pattern, entry.patternError) end

        self.Editor = te

    elseif vtype == "Number" then
        local te = vgui.Create("Elib.TextEntry", self)
        te:SetUpdateOnType(true)
        te:SetFloatOnly(true)
        te:SetValue(tostring(entry.value or entry.default or 0))
        te.OnChange = function(_, v)
            self:_markDirty(tonumber(v) or 0)
        end

        if entry.min or entry.max then te:SetNumberRange(entry.min, entry.max) end

        self.Editor = te

    elseif vtype == "Boolean" or vtype == "Bool" then
        local bool = vgui.Create("Elib.Boolean", self)
        bool:SetValue(entry.value == true)
        if bool.SnapToValue then bool:SnapToValue() end
        bool.OnChange = function(_, v) self:_markDirty(v) end
        self.Editor = bool

    elseif vtype == "Dropdown" or vtype == "Selection" then
        local dd = vgui.Create("Elib.Dropdown", self)

        for _, choice in ipairs(entry.table or {}) do
            dd:AddChoice(tostring(choice), choice)
        end

        if entry.value ~= nil then
            if not dd:SelectData(entry.value) then
                dd:SelectValue(tostring(entry.value))
            end
        end

        dd.OnSelect = function(_, _, value, data)
            self:_markDirty(data ~= nil and data or value)
        end

        self.Editor = dd

    elseif vtype == "Table" then
        local te = vgui.Create("Elib.TextEntry", self)
        te:SetMultiline(true)
        te:SetUpdateOnType(false)
        self:SetTall(Elib.Scale(130))

        local initial = entry.value or entry.default or {}
        te:SetValue(util.TableToJSON(initial, true))

        te:SetValidator(function(v)
            if v == "" then return true end
            if not util.JSONToTable(v) then return false, "Invalid JSON" end
            return true
        end)

        te.OnChange = function(_, v)
            local decoded = util.JSONToTable(v or "")
            if not decoded then return end
            self:_markDirty(decoded)
        end

        self.Editor = te

    elseif vtype == "List" then
        local tbl = vgui.Create("Elib.Table", self)

        if entry.placeholder then tbl:SetPlaceholder(entry.placeholder) end
        if entry.maxEntries  then tbl:SetMaxEntries(entry.maxEntries) end
        if entry.validator   then tbl:SetValidator(entry.validator) end

        tbl:SetEntries(entry.value or entry.default or {})

        self:SetTall(Elib.Scale(180))

        tbl.OnChange = function(_, list) self:_markDirty(list) end

        self.Editor = tbl

    elseif vtype == "Color" then
        local swatch = vgui.Create("DButton", self)
        swatch:SetText("")
        swatch:SetCursor("hand")

        local col = entry.value or entry.default or Color(255, 255, 255)
        if not IsColor(col) then col = Color(col.r or 255, col.g or 255, col.b or 255, col.a or 255) end
        swatch._color = col

        swatch.Paint = function(s, w, h)
            local outline = Elib.OffsetColor(Elib.Colors.Scroller, 10)
            RNDX().Rect(0, 0, w, h):Rad(Elib.Scale(4)):Color(outline):Outline(Elib.Scale(1)):Draw()
            RNDX().Rect(Elib.Scale(1), Elib.Scale(1), w - Elib.Scale(2), h - Elib.Scale(2))
                :Rad(Elib.Scale(3)):Color(s._color):Draw()
        end

        swatch.DoClick = function(s)
            local frame = vgui.Create("DFrame")
            frame:SetTitle(L("elib.colorpicker.title"))
            frame:SetSize(Elib.Scale(280), Elib.Scale(320))
            frame:Center()
            frame:MakePopup()

            local picker = vgui.Create("DColorMixer", frame)
            picker:Dock(FILL)
            picker:SetColor(s._color)
            picker.ValueChanged = function(_, c)
                s._color = Color(c.r, c.g, c.b, c.a)
                self:_markDirty(s._color)
            end
        end

        self.Editor = swatch
    end
end

function ROW:PerformLayout(w, h)
    if not IsValid(self.Editor) then return end
    
    local isBool  = self.Editor:GetClassName() == "Elib.Boolean"
    local isWide  = self.Entry and (self.Entry.type == "Table" or self.Entry.type == "List")

    if isWide then
        // Label across top, editor underneath.
        local labelH = Elib.Scale(20)
        self.Label:SetPos(Elib.Scale(8), 0)
        self.Label:SetSize(w - Elib.Scale(16), labelH)
        self.Editor:SetPos(Elib.Scale(8), labelH + Elib.Scale(4))
        self.Editor:SetSize(w - Elib.Scale(16), h - labelH - Elib.Scale(8))
        return
    end

    local editorW, editorH
    if isBool then
        editorH = Elib.Scale(22)
        editorW = editorH * 1.9 
    else
        editorH = h - Elib.Scale(8)
        editorW = math.min(Elib.Scale(260), w * 0.45)
    end

    self.Label:SetPos(Elib.Scale(8), 0)
    self.Label:SetSize(w - editorW - Elib.Scale(16), h)

    self.Editor:SetPos(w - editorW - Elib.Scale(8), (h - editorH) / 2)
    self.Editor:SetSize(editorW, editorH)
end

function ROW:Paint(w, h)
    local bg = self.Dirty
        and Elib.OffsetColor(Elib.Colors.Primary, -80)
        or Elib.OffsetColor(Elib.Colors.Background, 6)

    RNDX().Rect(0, 0, w, h):Rad(Elib.Scale(6)):Color(bg):Draw()

    if self.Dirty then
        -- actaully this looks shit :D but incase I want it back here it is
        --RNDX().Circle(Elib.Scale(10), Elib.Scale(10), Elib.Scale(6))
        --    :Color(Elib.Colors.Primary):Draw()
        
    end
end

vgui.Register("Elib.ConfigValueRow", ROW, "Panel")

/////////////////////////
// Category Header
/////////////////////////
local HEADER = {}

AccessorFunc(HEADER, "Title",    "Title",    FORCE_STRING)
AccessorFunc(HEADER, "Subtitle", "Subtitle", FORCE_STRING)

function HEADER:Init()
    self:SetTall(Elib.Scale(40))
    self:DockMargin(0, Elib.Scale(8), 0, Elib.Scale(6))
    self:SetTitle("")
    self:SetSubtitle("")
end

function HEADER:Paint(w, h)
    local titleFont    = Elib.GetRealFont("Elib.Large") or "DermaDefaultBold"
    local subtitleFont = Elib.GetRealFont("Elib.Small") or "DermaDefault"

    local titleX = 0
    local titleY = h / 2 - Elib.Scale(4)

    surface.SetFont(titleFont)
    local titleW = surface.GetTextSize(self:GetTitle())

    draw.SimpleText(self:GetTitle(),
        titleFont,
        titleX, titleY,
        Elib.Colors.PrimaryText,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
    )

    if self:GetSubtitle() ~= "" then
        draw.SimpleText(self:GetSubtitle(),
            subtitleFont,
            titleX + titleW + Elib.Scale(10), titleY + Elib.Scale(2),
            Elib.Colors.SecondaryText,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
        )
    end

    surface.SetDrawColor(Elib.OffsetColor(Elib.Colors.Scroller, 10))
    surface.DrawRect(0, h - 1, w, 1)
end

vgui.Register("Elib.ConfigCategoryHeader", HEADER, "Panel")

/////////////////////////
// Addon Page
/////////////////////////
local PAGE = {}

function PAGE:Init()
    self.Rows = {}

    self.Scroll = vgui.Create("Elib.ScrollPanel", self)
    self.Scroll:Dock(FILL)
    self.Scroll:SetBackToTop(false)
end

function PAGE:LoadAddon(addonName)
    self.Scroll:Clear()
    self.Rows      = {}
    self.AddonName = addonName

    local layout = Elib.Config:GetAddonLayout(addonName)
    if #layout == 0 then
        local empty = vgui.Create("DLabel", self.Scroll)
        empty:SetText(L("elib.config.empty"))
        empty:SetTextColor(Elib.Colors.SecondaryText)
        empty:Dock(TOP)
        empty:DockMargin(0, Elib.Scale(20), 0, 0)
        empty:SetContentAlignment(5)
        empty:SetTall(Elib.Scale(40))
        return
    end

    for _, group in ipairs(layout) do
        local header = vgui.Create("Elib.ConfigCategoryHeader", self.Scroll)
        header:Dock(TOP)

        local catKey = "elib.config." .. group.category
        local catTitle = Elib.Lang.Exists(catKey) and L(catKey) or Elib.Capitalize(group.category)
        header:SetTitle(catTitle)

        header:SetSubtitle(
            group.realm == "server"
                and L("elib.config.subtitle.server")
                or  L("elib.config.subtitle.client")
        )

        for _, item in ipairs(group.entries) do
            local row = vgui.Create("Elib.ConfigValueRow", self.Scroll)
            row:Dock(TOP)
            row:SetAddon(addonName)
            row:SetRealm(group.realm)
            row:SetCategory(group.category)
            row:SetValueID(item.id)
            row.OwnerMenu = self.OwnerMenu
            row:Build()

            table.insert(self.Rows, row)
        end
    end
end

function PAGE:CommitAllDirty()
    for _, row in ipairs(self.Rows) do
        if IsValid(row) and row:IsDirty() then row:CommitIfDirty() end
    end
end

function PAGE:RevertAllDirty()
    for _, row in ipairs(self.Rows) do
        if IsValid(row) and row:IsDirty() then row:Revert() end
    end
end

function PAGE:HasDirtyRows()
    for _, row in ipairs(self.Rows) do
        if IsValid(row) and row:IsDirty() then return true end
    end
    return false
end

function PAGE:Paint(w, h) end

vgui.Register("Elib.ConfigPage", PAGE, "Panel")

/////////////////////////
// Save Bar
/////////////////////////
local SAVEBAR = {}

function SAVEBAR:Init()
    self:SetTall(Elib.Scale(56))
    self.Visible    = false
    self.SlideAmount = 0 -- 0 = hidden, 1 = visible

    self.StatusLabel = vgui.Create("DLabel", self)
    self.StatusLabel:SetFont(Elib.GetRealFont("Elib.Body") or "DermaDefault")
    self.StatusLabel:SetTextColor(Elib.Colors.PrimaryText)
    self.StatusLabel:SetText(L("elib.config.unsaved"))

    self.SaveBtn   = self:_makeBtn(L("elib.save_changes"), Elib.Colors.Primary)
    self.RevertBtn = self:_makeBtn(L("elib.revert"),       Elib.OffsetColor(Elib.Colors.Background, 20))
end

function SAVEBAR:_makeBtn(text, bgColor)
    local b = vgui.Create("DButton", self)
    b:SetText("")
    b:SetCursor("hand")
    b._label   = text
    b._bgColor = bgColor

    b.Paint = function(s, w, h)
        local bg = s:IsHovered() and Elib.OffsetColor(s._bgColor, 10) or s._bgColor
        RNDX().Rect(0, 0, w, h):Rad(Elib.Scale(4)):Color(bg):Draw()

        draw.SimpleText(s._label,
            Elib.GetRealFont("Elib.Body") or "DermaDefault",
            w / 2, h / 2,
            Elib.Colors.PrimaryText,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
        )
    end

    return b
end

function SAVEBAR:SetVisible(v)
    self.Visible = v
end

function SAVEBAR:SetDirtyCount(n)
    if n > 0 then
        local key = n == 1 and "elib.config.unsaved_one" or "elib.config.unsaved_many"
        self.StatusLabel:SetText(L(key, n))
    end
end

function SAVEBAR:Think()
    local target = self.Visible and 1 or 0
    self.SlideAmount = Lerp(FrameTime() * 10, self.SlideAmount, target)
end

function SAVEBAR:PerformLayout(w, h)
    local pad = Elib.Scale(12)
    local btnW = Elib.Scale(140)
    local btnH = h - pad * 2

    self.StatusLabel:SetPos(pad, 0)
    self.StatusLabel:SetSize(w - pad * 3 - btnW * 2, h)

    self.RevertBtn:SetPos(w - pad * 2 - btnW * 2, pad)
    self.RevertBtn:SetSize(btnW, btnH)

    self.SaveBtn:SetPos(w - pad - btnW, pad)
    self.SaveBtn:SetSize(btnW, btnH)
end

function SAVEBAR:Paint(w, h)
    local a = math.Clamp(self.SlideAmount * 255, 0, 255)

    local bg = Elib.SetColorAlpha(Elib.OffsetColor(Elib.Colors.Header, 8), a)
    RNDX().Rect(0, 0, w, h):Color(bg):Draw()

    surface.SetDrawColor(Elib.SetColorAlpha(Elib.OffsetColor(Elib.Colors.Scroller, 10), a))
    surface.DrawRect(0, 0, w, 1)
end

vgui.Register("Elib.ConfigSaveBar", SAVEBAR, "Panel")

/////////////////////////
// Main Menu
/////////////////////////
local MENU = {}

function MENU:Init()
    self:SetTitle(L("elib.config.title"))
    self:SetSize(Elib.Scale(900), Elib.Scale(600))
    self:Center()
    self:SetSizable(false)

    self.Sidebar = self:CreateSidebar()

    self.Body = vgui.Create("Panel", self)
    self.Body:Dock(FILL)

    self.SaveBar = vgui.Create("Elib.ConfigSaveBar", self.Body)
    self.SaveBar:Dock(BOTTOM)
    self.SaveBar:SetVisible(false)
    self.SaveBar:SetAlpha(0)

    self.SaveBar.SaveBtn.DoClick   = function() self:SaveAll() end
    self.SaveBar.RevertBtn.DoClick = function() self:RevertAll() end

    self.Page = vgui.Create("Elib.ConfigPage", self.Body)
    self.Page:Dock(FILL)
    self.Page.OwnerMenu = self

    self:Populate()
end

function MENU:Populate()
    for id in pairs(self.Sidebar.Items) do
        self.Sidebar:RemoveItem(id)
    end

    local addons = Elib.Config:GetAddonsSorted()

    for _, addon in ipairs(addons) do
        local btn = self.Sidebar:AddItem(
            addon.name,
            addon.name,
            addon.icon,
            function()
                if self.Page:HasDirtyRows() then
                    self:_promptSwitchWithDirty(addon.name)
                    return
                end
                if IsValid(self.Page) then self.Page:LoadAddon(addon.name) end
            end,
            addon.order
        )

        if addon.description then
            Elib.Tooltip.Attach(btn, addon.description)
        end
    end

    if addons[1] then
        self.Sidebar:SelectItem(addons[1].name)
    end
end

function MENU:RefreshDirtyState()
    local count = 0
    for _, row in ipairs(self.Page.Rows) do
        if IsValid(row) and row:IsDirty() then count = count + 1 end
    end

    self.SaveBar:SetVisible(count > 0)
    self.SaveBar:SetDirtyCount(count)

    if count > 0 then
        self.SaveBar:AlphaTo(255, 0.2, 0)
    else
        self.SaveBar:AlphaTo(0, 0.2, 0)
    end
end

function MENU:SaveAll()
    self.Page:CommitAllDirty()
    self:RefreshDirtyState()
    Elib.Notify({
        title = L("elib.config.notify.saved_title"),
        text  = L("elib.config.notify.saved_body"),
        type  = "success",
    })
end

function MENU:RevertAll()
    self.Page:RevertAllDirty()
    self:RefreshDirtyState()
    Elib.Notify({
        title = L("elib.config.notify.reverted_title"),
        text  = L("elib.config.notify.reverted_body"),
        type  = "info",
    })
end

function MENU:_promptSwitchWithDirty(targetAddon)
    Derma_Query(
        L("elib.config.switch.body"),
        L("elib.config.switch.title"),
        L("elib.config.switch.save"), function()
            self:SaveAll()
            self.Page:LoadAddon(targetAddon)
        end,
        L("elib.config.switch.discard"), function()
            self:RevertAll()
            self.Page:LoadAddon(targetAddon)
        end,
        L("elib.config.switch.cancel"), function() end
    )
end

function MENU:OnClose()
    if IsValid(self.Page) and self.Page:HasDirtyRows() then
        Elib.Notify({
            title    = L("elib.config.notify.discarded_title"),
            text     = L("elib.config.notify.discarded_body"),
            type     = "warn",
            duration = 5,
        })
    end
end

vgui.Register("Elib.ConfigMenu", MENU, "Elib.Frame")

/////////////////////////
// Public entry points
/////////////////////////
function Elib.Config.OpenMenu()
    if IsValid(Elib.Config.ActiveMenu) then
        Elib.Config.ActiveMenu:Remove()
    end

    Elib.Config.ActiveMenu = vgui.Create("Elib.ConfigMenu")
    Elib.Config.ActiveMenu:MakePopup()
    return Elib.Config.ActiveMenu
end

concommand.Add("elib_config", function() Elib.Config.OpenMenu() end)