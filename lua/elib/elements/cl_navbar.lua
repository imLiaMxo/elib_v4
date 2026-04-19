// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

/////////////////////////
// Navbar Item
/////////////////////////
local ITEM = {}

AccessorFunc(ITEM, "Name",     "Name",     FORCE_STRING)
AccessorFunc(ITEM, "ImageURL", "ImageURL", FORCE_STRING)
AccessorFunc(ITEM, "Selected", "Selected", FORCE_BOOL)

function ITEM:Init()
    self:SetName("")
    self:SetText("")
    self:SetSelected(false)
    self:SetCursor("hand")

    self.TextColor = Elib.CopyColor(Elib.Colors.SecondaryText)
end

function ITEM:Paint(w, h)
    local targetText = (self:IsHovered() or self:GetSelected())
        and Elib.Colors.PrimaryText
        or Elib.Colors.SecondaryText

    local ft = FrameTime() * 12
    self.TextColor = Elib.LerpColor(ft, self.TextColor, targetText)

    if self:IsHovered() and not self:GetSelected() then
        RNDX().Rect(Elib.Scale(2), Elib.Scale(4), w - Elib.Scale(4), h - Elib.Scale(8))
            :Rad(Elib.Scale(4))
            :Color(ColorAlpha(Elib.Colors.Scroller, 60))
            :Draw()
    end

    local textX = w / 2
    local align = TEXT_ALIGN_CENTER

    local image = self:GetImageURL()
    if image and image ~= "" then
        local iconSize = h * 0.5
        local font = Elib.GetRealFont("Elib.Medium") or "DermaDefault"

        surface.SetFont(font)
        local tw = surface.GetTextSize(self:GetName())

        local gap    = Elib.Scale(6)
        local groupW = iconSize + gap + tw
        local startX = (w - groupW) / 2

        Elib.WebImages.Draw(startX, (h - iconSize) / 2, iconSize, iconSize, image, self.TextColor)

        draw.SimpleText(self:GetName(), font,
            startX + iconSize + gap, h / 2,
            self.TextColor,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
        )
        return
    end

    draw.SimpleText(self:GetName(),
        Elib.GetRealFont("Elib.Medium") or "DermaDefault",
        textX, h / 2,
        self.TextColor,
        align, TEXT_ALIGN_CENTER
    )
end

function ITEM:DoClick() end

vgui.Register("Elib.NavbarItem", ITEM, "DButton")

/////////////////////////
// Navbar Container
/////////////////////////
local PANEL = {}

AccessorFunc(PANEL, "ItemSpacing", "ItemSpacing", FORCE_NUMBER)
AccessorFunc(PANEL, "ItemPadding", "ItemPadding", FORCE_NUMBER)
AccessorFunc(PANEL, "ShowDivider", "ShowDivider", FORCE_BOOL)

function PANEL:Init()
    self.Items    = {}
    self.ItemList = {}

    self:SetItemSpacing(4)
    self:SetItemPadding(18)
    self:SetShowDivider(true)

    self._underlineX = nil
    self._underlineW = 0

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    self.BackgroundColor = Elib.SetColorAlpha(Elib.Colors.Background, 0) -- transparent bg since we sit on top of the frame's bg
    self.DividerColor    = Elib.OffsetColor(Elib.Colors.Scroller, 5)
end

/////////////////////////
// Item management
/////////////////////////
function PANEL:AddItem(id, name, imageURL, doClick, order)
    if imageURL and imageURL:match("^[a-zA-Z0-9]+$") then -- dziekuje stackoverflo
        imageURL = "https://i.imgur.com/" .. imageURL .. ".png"
    end

    local btn = vgui.Create("Elib.NavbarItem", self)
    btn:SetName(name or id)
    btn:SetZPos(order or (#self.ItemList + 1))
    if imageURL then btn:SetImageURL(imageURL) end

    btn.OnSelect = doClick
    btn.DoClick  = function() self:SelectItem(id) end

    self.Items[id] = btn
    table.insert(self.ItemList, id)

    self:InvalidateLayout()
    return btn
end

function PANEL:RemoveItem(id)
    local item = self.Items[id]
    if not IsValid(item) then return end

    item:Remove()
    self.Items[id] = nil

    for i, v in ipairs(self.ItemList) do
        if v == id then
            table.remove(self.ItemList, i)
            break
        end
    end

    if self.SelectedItem == id then
        self.SelectedItem = nil
        local next = self.ItemList[1]
        if next then self:SelectItem(next) end
    end

    self:InvalidateLayout()
end

function PANEL:SelectItem(id)
    local item = self.Items[id]
    if not IsValid(item) then return end
    if self.SelectedItem == id then return end

    for _, other in pairs(self.Items) do other:SetSelected(false) end

    item:SetSelected(true)
    self.SelectedItem = id

    if self._underlineX == nil then
        self._underlineX = item:GetX()
        self._underlineW = item:GetWide()
    end

    if item.OnSelect then item.OnSelect(item) end
end

function PANEL:GetSelectedItem()
    return self.SelectedItem, self.Items[self.SelectedItem]
end

/////////////////////////
// Layout
/////////////////////////
function PANEL:PerformLayout(w, h)
    local spacing = Elib.Scale(self:GetItemSpacing())
    local padding = Elib.Scale(self:GetItemPadding())
    local cursorX = spacing

    local font = Elib.GetRealFont("Elib.Medium") or "DermaDefault"
    surface.SetFont(font)

    for _, id in ipairs(self.ItemList) do
        local item = self.Items[id]
        if IsValid(item) then
            local tw = surface.GetTextSize(item:GetName() or "")

            local iconW = 0
            if item:GetImageURL() and item:GetImageURL() ~= "" then
                local iconSize = h * 0.5
                iconW = iconSize + Elib.Scale(6)
            end

            local itemW = tw + iconW + padding * 2

            item:SetPos(cursorX, 0)
            item:SetSize(itemW, h)
            cursorX = cursorX + itemW + spacing
        end
    end
end

/////////////////////////
// Paint
/////////////////////////
function PANEL:Paint(w, h)
    if self:GetShowDivider() then
        surface.SetDrawColor(self.DividerColor)
        surface.DrawRect(0, h - 1, w, 1)
    end

    local selected = self.Items[self.SelectedItem]
    if not IsValid(selected) then return end

    local targetX = selected:GetX()
    local targetW = selected:GetWide()

    if self._underlineX == nil then
        self._underlineX = targetX
        self._underlineW = targetW
    else
        local ft = FrameTime() * 10
        self._underlineX = Lerp(ft, self._underlineX, targetX)
        self._underlineW = Lerp(ft, self._underlineW, targetW)
    end

    local pad  = Elib.Scale(10)
    local ux   = self._underlineX + pad
    local uw   = self._underlineW - pad * 2
    local uy   = h - Elib.Scale(3)
    local uh   = Elib.Scale(2)

    RNDX().Rect(ux, uy, uw, uh):Rad(Elib.Scale(2)):Color(Elib.Colors.Primary):Draw()
end

vgui.Register("Elib.Navbar", PANEL, "Panel")