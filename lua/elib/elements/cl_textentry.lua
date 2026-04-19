// Made by Eve Haddox & imLiaMxo

local RNDX = Elib.RNDX

local PANEL = {}

AccessorFunc(PANEL, "Placeholder",    "Placeholder",    FORCE_STRING)
AccessorFunc(PANEL, "Numeric",        "Numeric",        FORCE_BOOL)
AccessorFunc(PANEL, "FloatOnly",      "FloatOnly",      FORCE_BOOL)
AccessorFunc(PANEL, "UpdateOnType",   "UpdateOnType",   FORCE_BOOL)
AccessorFunc(PANEL, "CornerRadius",   "CornerRadius",   FORCE_NUMBER)
AccessorFunc(PANEL, "ShowError",      "ShowError",      FORCE_BOOL)

function PANEL:Init()
    self:SetPlaceholder("")
    self:SetNumeric(false)
    self:SetFloatOnly(false)
    self:SetUpdateOnType(true)
    self:SetCornerRadius(4)
    self:SetShowError(true)

    self.Validator      = nil
    self.Validators     = {}
    self.IsValidValue   = true
    self.ValidationError = nil

    self.Entry = vgui.Create("DTextEntry", self)
    self.Entry:SetDrawBackground(false)
    self.Entry:SetPaintBackgroundEnabled(false)
    self.Entry:SetFont(Elib.GetRealFont("Elib.Body") or "DermaDefault")

    self.Entry.OnChange = function(s)
        self:_runValidation(s:GetValue())

        if self:GetUpdateOnType() and self.OnChange then
            self:OnChange(s:GetValue())
        end

        if self:GetUpdateOnType() and self.IsValidValue and self.OnValidChange then
            self:OnValidChange(s:GetValue())
        end
    end

    self.Entry.OnEnter = function(s)
        if self.OnEnter then self:OnEnter(s:GetValue()) end

        if not self:GetUpdateOnType() then
            if self.OnChange then self:OnChange(s:GetValue()) end
            if self.IsValidValue and self.OnValidChange then
                self:OnValidChange(s:GetValue())
            end
        end
    end

    self.Entry.OnLoseFocus = function(s)
        if not self:GetUpdateOnType() then
            if self.OnChange then self:OnChange(s:GetValue()) end
            if self.IsValidValue and self.OnValidChange then
                self:OnValidChange(s:GetValue())
            end
        end
        if self.OnLoseFocus then self:OnLoseFocus(s:GetValue()) end
    end

    self.Entry.OnGetFocus = function(s)
        if self.OnGetFocus then self:OnGetFocus() end
    end

    self.OutlineColor = Color(0, 0, 0, 0)

    hook.Add("Elib.ThemeChanged", self, function(s) s:UpdateColors() end)
    self:UpdateColors()
end

function PANEL:UpdateColors()
    self.BackgroundColor  = Elib.OffsetColor(Elib.Colors.Background, 8)
    self.DisabledColor    = Elib.OffsetColor(Elib.Colors.Background, 4)
    self.OutlineRestColor = Elib.OffsetColor(Elib.Colors.Scroller, 10)
    self.OutlineFocusCol  = Elib.Colors.PrimaryText
    self.OutlineErrorCol  = Elib.Colors.Negative
    self.PlaceholderColor = Elib.OffsetColor(Elib.Colors.SecondaryText, -80)
    self.TextColor        = Elib.Colors.PrimaryText
    self.ErrorColor       = Elib.Colors.Negative

    if IsValid(self.Entry) then
        self.Entry:SetTextColor(self.TextColor)
    end
end

/////////////////////////
// Validation
/////////////////////////
function PANEL:_runValidation(value)
    for _, v in ipairs(self.Validators) do
        local ok, err = v(value)
        if not ok then
            self.IsValidValue    = false
            self.ValidationError = err or "Invalid"
            if self.OnValidityChanged then self:OnValidityChanged(false, self.ValidationError) end
            return
        end
    end

    if self.Validator then
        local ok, err = self.Validator(value)
        if not ok then
            self.IsValidValue    = false
            self.ValidationError = err or "Invalid"
            if self.OnValidityChanged then self:OnValidityChanged(false, self.ValidationError) end
            return
        end
    end

    local wasInvalid = not self.IsValidValue
    self.IsValidValue    = true
    self.ValidationError = nil
    if wasInvalid and self.OnValidityChanged then self:OnValidityChanged(true) end
end

function PANEL:SetValidator(fn)
    self.Validator = fn
    self:_runValidation(self:GetValue())
end

function PANEL:IsValid()
    return self.IsValidValue, self.ValidationError
end

function PANEL:OnValidityChanged(valid, err) end

function PANEL:SetMinLength(n)
    table.insert(self.Validators, function(v)
        if #v < n then return false, "Must be at least " .. n .. " characters" end
        return true
    end)
    self:_runValidation(self:GetValue())
end

function PANEL:SetMaxInputLength(n)
    table.insert(self.Validators, function(v)
        if #v > n then return false, "Must be at most " .. n .. " characters" end
        return true
    end)
    self:_runValidation(self:GetValue())
end

function PANEL:SetPattern(pattern, errMsg)
    errMsg = errMsg or "Invalid format"
    table.insert(self.Validators, function(v)
        if v == "" then return true end
        if not v:match(pattern) then return false, errMsg end
        return true
    end)
    self:_runValidation(self:GetValue())
end

function PANEL:SetNumberRange(minVal, maxVal)
    table.insert(self.Validators, function(v)
        if v == "" then return true end
        local n = tonumber(v)
        if not n then return false, "Must be a number" end
        if minVal and n < minVal then return false, "Must be at least " .. minVal end
        if maxVal and n > maxVal then return false, "Must be at most " .. maxVal end
        return true
    end)
    self:_runValidation(self:GetValue())
end

function PANEL:ClearValidators()
    self.Validators = {}
    self.Validator  = nil
    self:_runValidation(self:GetValue())
end

/////////////////////////
// Proxy methods
/////////////////////////
function PANEL:GetValue()          return self.Entry:GetValue() end
function PANEL:SetValue(v)
    self.Entry:SetValue(tostring(v or ""))
    self:_runValidation(self.Entry:GetValue())
end
function PANEL:GetInt()             return tonumber(self.Entry:GetValue()) or 0 end
function PANEL:GetFloat()           return tonumber(self.Entry:GetValue()) or 0 end

function PANEL:SetMultiline(b)      self.Entry:SetMultiline(b == true) end
function PANEL:IsMultiline()        return self.Entry:IsMultiline() end

function PANEL:SetEditable(b)       self.Entry:SetEditable(b) end
function PANEL:IsEditing()          return self.Entry:IsEditing() end

function PANEL:SetNumeric(b)
    self.Numeric = b == true
    if IsValid(self.Entry) then self.Entry:SetNumeric(b) end
end

function PANEL:SetFloatOnly(b)
    self.FloatOnly = b == true

    if b and IsValid(self.Entry) then
        self.Entry.AllowInput = function(s, char)
            local cur = s:GetValue()
            if char:match("%d") then return false end
            if char == "." and not cur:find("%.", 1, true) then return false end
            if char == "-" and cur == "" then return false end
            return true
        end
    elseif IsValid(self.Entry) then
        self.Entry.AllowInput = nil
    end
end

function PANEL:SetMaxLength(n)      self.Entry:SetMaxLength(n) end
function PANEL:SetFont(font)
    local real = Elib.GetRealFont(font) or font
    self.Entry:SetFont(real)
end

function PANEL:RequestFocus()       self.Entry:RequestFocus() end
function PANEL:HasFocus()           return self.Entry:HasFocus() end

/////////////////////////
// Callbacks (override)
/////////////////////////
function PANEL:OnChange(value) end
function PANEL:OnValidChange(value) end -- validator passed.
function PANEL:OnEnter(value) end
function PANEL:OnGetFocus() end
function PANEL:OnLoseFocus(value) end

/////////////////////////
// Layout / Paint
/////////////////////////
function PANEL:PerformLayout(w, h)
    local errorH = (self:GetShowError() and not self.IsValidValue) and Elib.Scale(14) or 0

    local xPad = Elib.Scale(8)
    local yPad = self.Entry:IsMultiline() and Elib.Scale(6) or 0

    self.Entry:SetPos(xPad, yPad)
    self.Entry:SetSize(w - xPad * 2, h - yPad * 2 - errorH)
end

function PANEL:Paint(w, h)
    local r      = Elib.Scale(self:GetCornerRadius())
    local errorH = (self:GetShowError() and not self.IsValidValue) and Elib.Scale(14) or 0
    local boxH   = h - errorH

    if not self:IsEnabled() then
        RNDX().Rect(0, 0, w, boxH):Rad(r):Color(self.DisabledColor):Draw()

        draw.SimpleText("Disabled",
            Elib.GetRealFont("Elib.Body") or "DermaDefault",
            Elib.Scale(8), boxH / 2,
            self.PlaceholderColor,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
        )
        return
    end

    RNDX().Rect(0, 0, w, boxH):Rad(r):Color(self.BackgroundColor):Draw() -- background! haha I remembered finally

    local target
    if not self.IsValidValue then
        target = self.OutlineErrorCol
    elseif self.Entry:IsEditing() then
        target = self.OutlineFocusCol
    else
        target = self.OutlineRestColor
    end

    self.OutlineColor = Elib.LerpColor(FrameTime() * 8, self.OutlineColor, target)

    RNDX().Rect(0, 0, w, boxH)
        :Rad(r)
        :Color(self.OutlineColor)
        :Outline(Elib.Scale(1))
        :Draw()

    if self:GetValue() == "" and self:GetPlaceholder() ~= "" then
        local font = Elib.GetRealFont("Elib.Body") or "DermaDefault"

        if self.Entry:IsMultiline() then
            draw.SimpleText(self:GetPlaceholder(), font,
                Elib.Scale(8), Elib.Scale(6),
                self.PlaceholderColor,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
            )
        else
            draw.SimpleText(self:GetPlaceholder(), font,
                Elib.Scale(8), boxH / 2,
                self.PlaceholderColor,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
            )
        end
    end

    if errorH > 0 and self.ValidationError then
        draw.SimpleText(self.ValidationError,
            Elib.GetRealFont("Elib.Small") or "DermaDefault",
            Elib.Scale(4), boxH + 1,
            self.ErrorColor,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
        )
    end
end

vgui.Register("Elib.TextEntry", PANEL, "Panel")