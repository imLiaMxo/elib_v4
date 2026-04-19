// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

/////////////////////////
// Sidebar Item
/////////////////////////
local ITEM = {}

AccessorFunc(ITEM, "Name",     "Name",     FORCE_STRING)
AccessorFunc(ITEM, "ImageURL", "ImageURL", FORCE_STRING)
AccessorFunc(ITEM, "Selected", "Selected", FORCE_BOOL)

function ITEM:Init()
    self:SetName("")
    self:SetText("")
    self:SetSelected(false)

    self.TextColor       = Elib.CopyColor(Elib.Colors.SecondaryText)
    self.BackgroundColor = Color(0, 0, 0, 0)
    self.AccentHeight    = 0
end

function ITEM:UpdateColors()
    if not self:IsHovered() and not self:GetSelected() then
        self.TextColor = Elib.CopyColor(Elib.Colors.SecondaryText)
    end
end

function ITEM:Paint(w, h)
    local targetText = Elib.Colors.SecondaryText
    local targetBg   = Color(0, 0, 0, 0)
    local animate    = false

    if self:IsHovered() or self:GetSelected() then
        targetText = Elib.Colors.PrimaryText
        targetBg   = ColorAlpha(Elib.Colors.Scroller, 80)
        animate    = true
    end

    local ft = FrameTime() * 12
    self.TextColor       = Elib.LerpColor(ft, self.TextColor, targetText)
    self.BackgroundColor = Elib.LerpColor(ft, self.BackgroundColor, targetBg)

    local targetAccentH = animate and h or 0
    if self.AccentHeight ~= targetAccentH then
        self.AccentHeight = math.Clamp(Lerp(ft, self.AccentHeight, targetAccentH), 0, h)
    end

    RNDX().Rect(0, 0, w, h):Rad(Elib.Scale(6)):Color(self.BackgroundColor):Draw()

    local ah = self.AccentHeight
    if ah > 0 then
        RNDX().Rect(0, (h - ah) / 2, Elib.Scale(3), ah)
            :Rad(Elib.Scale(6))
            :Color(Elib.Colors.Primary)
            :Draw()
    end

    local textX = Elib.Scale(10)
    local image = self:GetImageURL()

    if image and image ~= "" then
        local iconSize = h * 0.6
        Elib.WebImages.Draw(Elib.Scale(10), (h - iconSize) / 2, iconSize, iconSize, image, self.TextColor)
        textX = Elib.Scale(20) + iconSize
    end

    draw.SimpleText(self:GetName(),
        Elib.GetRealFont("Elib.Medium") or "DermaDefaultBold",
        textX, h / 2,
        self.TextColor,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
    )
end

vgui.Register("Elib.SidebarItem", ITEM, "DButton")

/////////////////////////
// Sidebar Container
/////////////////////////
local PANEL = {}

AccessorFunc(PANEL, "HeaderImageURL",    "HeaderImageURL",    FORCE_STRING)
AccessorFunc(PANEL, "HeaderImageSize",   "HeaderImageSize",   FORCE_NUMBER)
AccessorFunc(PANEL, "HeaderImageOffset", "HeaderImageOffset", FORCE_NUMBER)

function PANEL:Init()
    self.Items    = {}
    self.ItemList = {}

    self:SetHeaderImageSize(0.6)
    self:SetHeaderImageOffset(0)

    self.Scroller = vgui.Create("Elib.ScrollPanel", self)
    self.Scroller:Dock(FILL)

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    self.BackgroundColor = Elib.OffsetColor(Elib.Colors.Header, -5)
end

/////////////////////////
// Item management
/////////////////////////
function PANEL:AddItem(id, name, imageURL, doClick, order)
    // Allow bare imgur IDs as a shortcut, same as v3.
    if imageURL and imageURL:match("^[a-zA-Z0-9]+$") then
        imageURL = "https://i.imgur.com/" .. imageURL .. ".png"
    end

    local btn = vgui.Create("Elib.SidebarItem", self.Scroller)
    btn:SetName(name or id)
    btn:SetZPos(order or (#self.ItemList + 1))
    btn:Dock(TOP)
    btn:DockMargin(0, 0, 0, Elib.Scale(8))
    btn:SetTall(Elib.Scale(35))
    if imageURL then btn:SetImageURL(imageURL) end

    btn.OnSelect = doClick

    btn.DoClick = function() self:SelectItem(id) end

    self.Items[id] = btn
    table.insert(self.ItemList, id)
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
        local nextId = self.ItemList[1]
        if nextId then self:SelectItem(nextId) end
    end
end

function PANEL:SelectItem(id)
    local item = self.Items[id]
    if not IsValid(item) then return end
    if self.SelectedItem == id then return end

    for _, other in pairs(self.Items) do
        other:SetSelected(false)
    end

    item:SetSelected(true)
    self.SelectedItem = id

    if item.OnSelect then item.OnSelect(item) end
end

function PANEL:GetSelectedItem()
    return self.SelectedItem, self.Items[self.SelectedItem]
end

/////////////////////////
// Layout / Paint
/////////////////////////
function PANEL:PerformLayout(w, h)
    local pad = Elib.Scale(7)

    local topPad = pad
    if self:GetHeaderImageURL() and self:GetHeaderImageURL() ~= "" then
        topPad = w * self:GetHeaderImageSize() + self:GetHeaderImageOffset() + pad * 2
    end

    self:DockPadding(pad, topPad, pad, pad)
end

function PANEL:Paint(w, h)
    local r = Elib.Scale(6)
    RNDX().Rect(0, 0, w, h)
        :Radii(r, 0, r, 0)
        :Color(self.BackgroundColor)
        :Draw()

    local url = self:GetHeaderImageURL()
    if url and url ~= "" then
        local size = w * self:GetHeaderImageSize()
        Elib.WebImages.Draw(
            (w - size) / 2,
            self:GetHeaderImageOffset() + Elib.Scale(15),
            size, size, url,
            Color(255, 255, 255)
        )
    end
end

vgui.Register("Elib.Sidebar", PANEL, "Panel")