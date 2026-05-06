// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

local COLLAPSE_URL = "https://cdn.novarp.uk/uploads/1776454312690-r12cq8.png"
local EXPAND_URL   = "https://cdn.novarp.uk/uploads/1776454312700-gbxh2o.png"

/////////////////////////
// Helpers
/////////////////////////
local function getInitials(name)
    local initials = ""
    for word in name:gmatch("%S+") do
        initials = initials .. word:sub(1, 1):upper()
    end
    return initials ~= "" and initials or "?"
end

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
    self._elibSidebar    = nil  -- injected by AddItem
end

function ITEM:Paint(w, h)
    local sidebar     = self._elibSidebar
    local collapseAmt = (sidebar and sidebar.CollapseAmount) or 0

    // ---- Background / accent ----
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

    // ---- Icon / Text ----
    local image    = self:GetImageURL()
    local hasImage = image and image ~= ""

    // Expanded view: text fades out during the first half of collapse
    if collapseAmt < 0.99 then
        local textAlpha = math.Clamp((1 - collapseAmt * 2) * 255, 0, 255)
        local textX     = Elib.Scale(10)

        if hasImage then
            local iconSize = h * 0.6
            Elib.WebImages.Draw(Elib.Scale(10), (h - iconSize) / 2, iconSize, iconSize, image, ColorAlpha(self.TextColor, textAlpha))
            textX = Elib.Scale(20) + iconSize
        end

        if textAlpha > 1 then
            draw.SimpleText(self:GetName(),
                Elib.GetRealFont("Elib.Medium") or "DermaDefaultBold",
                textX, h / 2,
                ColorAlpha(self.TextColor, textAlpha),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
            )
        end
    end

    // Collapsed view: initials/icon fades in during the second half
    if collapseAmt > 0.01 then
        local colAlpha = math.Clamp((collapseAmt * 2 - 1) * 255, 0, 255)

        if hasImage then
            local iconSize = h * 0.6
            Elib.WebImages.Draw((w - iconSize) / 2, (h - iconSize) / 2, iconSize, iconSize, image, ColorAlpha(self.TextColor, colAlpha))
        elseif colAlpha > 1 then
            draw.SimpleText(
                getInitials(self:GetName()),
                Elib.GetRealFont("Elib.Medium") or "DermaDefaultBold",
                w / 2, h / 2,
                ColorAlpha(self.TextColor, colAlpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
            )
        end
    end
end

vgui.Register("Elib.SidebarItem", ITEM, "DButton")

/////////////////////////
// Sidebar Container
/////////////////////////
local PANEL = {}

AccessorFunc(PANEL, "HeaderImageURL",    "HeaderImageURL",    FORCE_STRING)
AccessorFunc(PANEL, "HeaderImageSize",   "HeaderImageSize",   FORCE_NUMBER)
AccessorFunc(PANEL, "HeaderImageOffset", "HeaderImageOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "Collapsible",       "Collapsible",       FORCE_BOOL)

local COLLAPSED_W  = 52   -- px (pre-scale) when collapsed
local COLLAPSE_BTN = 34   -- px (pre-scale) button height
local ANIM_SPEED   = 10

function PANEL:Init()
    self.Items    = {}
    self.ItemList = {}

    self:SetHeaderImageSize(0.6)
    self:SetHeaderImageOffset(0)
    self:SetCollapsible(true)   -- collapsible by default

    // Collapse state
    self.Collapsed      = false
    self.CollapseAmount = 0   -- 0 = expanded, 1 = collapsed
    self.ExpandedWidth  = nil
    self.Animating      = false

    // Scroller created FIRST - rendered first (behind the button)
    self.Scroller = vgui.Create("Elib.ScrollPanel", self)

    // Collapse button created AFTER - rendered on top of the scroller
    self.CollapseBtn = vgui.Create("DButton", self)
    self.CollapseBtn:SetText("")
    self.CollapseBtn._hoverAlpha = 0
    self.CollapseBtn._sidebar    = self

    self.CollapseBtn.DoClick = function(btn)
        btn._sidebar:ToggleCollapse()
    end

    self.CollapseBtn.Paint = function(btn, bw, bh)
        local ft = FrameTime() * 12
        btn._hoverAlpha = Lerp(ft, btn._hoverAlpha, btn:IsHovered() and 60 or 0)
        if btn._hoverAlpha > 1 then
            RNDX().Rect(0, 0, bw, bh)
                :Rad(Elib.Scale(6))
                :Color(ColorAlpha(Elib.Colors.Primary, btn._hoverAlpha))
                :Draw()
        end

        local icon     = btn._sidebar.Collapsed and EXPAND_URL or COLLAPSE_URL
        local iconSize = math.min(bw, bh) * 0.55
        Elib.WebImages.Draw(
            (bw - iconSize) / 2, (bh - iconSize) / 2,
            iconSize, iconSize,
            icon,
            Elib.Colors.SecondaryText
        )
    end

    Elib.Tooltip.Attach(self.CollapseBtn, function()
        return self.Collapsed and "Expand sidebar" or "Collapse sidebar"
    end)

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    self.BackgroundColor = Elib.OffsetColor(Elib.Colors.Header, -5)
end

function PANEL:ToggleCollapse()
    if not self:GetCollapsible() then return end
    self.Collapsed = not self.Collapsed
end

/////////////////////////
// Width animation
/////////////////////////
function PANEL:Think()
    local target = (self:GetCollapsible() and self.Collapsed) and 1 or 0
    self.CollapseAmount = Lerp(FrameTime() * ANIM_SPEED, self.CollapseAmount, target)
    self.Animating      = math.abs(self.CollapseAmount - target) > 0.002

    if self.ExpandedWidth then
        local collW = Elib.Scale(COLLAPSED_W)
        local w     = math.Round(Lerp(self.CollapseAmount, self.ExpandedWidth, collW))

        if w ~= self:GetWide() then
            self:SetWide(w)
            local p = self:GetParent()
            if IsValid(p) then p:InvalidateLayout(true) end
        end
    end

    // Show tooltip on items only when collapsed / collapsing
    for _, item in pairs(self.Items) do
        if IsValid(item) then
            item._ElibTooltipText = self.CollapseAmount > 0.3 and item:GetName() or nil
        end
    end
end

/////////////////////////
// Item management
/////////////////////////
function PANEL:AddItem(id, name, imageURL, doClick, order)
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

    btn._elibSidebar = self

    btn.OnSelect = doClick
    btn.DoClick  = function() self:SelectItem(id) end

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
        if v == id then table.remove(self.ItemList, i) break end
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

    for _, other in pairs(self.Items) do other:SetSelected(false) end

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
    local pad  = Elib.Scale(7)
    local btnH = Elib.Scale(COLLAPSE_BTN)

    // Top padding: leave room for header image if present
    local topPad = pad
    if self:GetHeaderImageURL() and self:GetHeaderImageURL() ~= "" then
        topPad = w * self:GetHeaderImageSize() + self:GetHeaderImageOffset() + pad * 2
    end

    local collapsible = self:GetCollapsible()

    if collapsible then
        // Scroller fills the top region, leaving the bottom for the button
        self.Scroller:SetPos(pad, topPad)
        self.Scroller:SetSize(w - pad * 2, h - topPad - btnH - pad * 2)

        // Button sits at the very bottom
        self.CollapseBtn:SetPos(pad, h - btnH - pad)
        self.CollapseBtn:SetSize(w - pad * 2, btnH)
        self.CollapseBtn:SetVisible(true)
    else
        // No button - scroller takes everything
        self.Scroller:SetPos(pad, topPad)
        self.Scroller:SetSize(w - pad * 2, h - topPad - pad)
        self.CollapseBtn:SetVisible(false)
    end
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
