
Elib.RegisterFont("PopupTitle", "Inter Semi Bold", 24, 600)
Elib.RegisterFont("PopupText", "Inter Medium", 18, 500)

local PANEL = {}

function PANEL:Init()
    self.Frame:SetTitle("")

    -- Body text
    self.Text = self.Frame:Add("DLabel")
    self.Text:SetFont(Elib.GetRealFont("Elib.PopupText"))
    self.Text:SetTextColor(Elib.Colors.SecondaryText)
    self.Text:Dock(TOP)
    self.Text:DockMargin(0, 6, 0, 0)

    -- Buttons container
    self.Buttons = self.Frame:Add("Panel")
    self.Buttons:Dock(TOP)
    self.Buttons:DockMargin(0, 12, 0, 0)
    self.Buttons:SetTall(36)

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
end

function PANEL:SetTitleText(text)
    self.Frame:SetTitle(text)
end

function PANEL:SetBodyText(text)
    self.Text:SetText(text)
end

function PANEL:AddButton(label, callback, style)
    local btn = self.Buttons:Add("Elib.Button")
    btn:SetText(label)
    btn:Dock(LEFT)
    btn:DockMargin(0, 0, 6, 0)
    btn:SetWide(120)

    if style == "outline" then
        btn:SetStyle("outline")
    elseif style == "ghost" then
        btn:SetStyle("ghost")
    end

    btn.DoClick = function()
        if callback then callback() end
        self:Remove()
    end

    return btn
end

function PANEL:UpdateColors()
    self.Title:SetTextColor(Elib.Colors.PrimaryText)
    self.Text:SetTextColor(Elib.Colors.SecondaryText)
end

vgui.Register("Elib.PopupQuery", PANEL, "Elib.PopupBase")
