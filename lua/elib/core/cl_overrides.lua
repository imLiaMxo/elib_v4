// Made by Eve Haddox & imLiaMxo

///////////////////
// Popups Utilities
///////////////////
function Elib.CreateInfoPopup(message, title)
    local popup = vgui.Create("Elib.PopupInfo")
    if message then popup.Text:SetText(message) end
    if title then popup:SetTitle(title) end

    return popup
end

function Elib.CreateBoolPopup(message, OnComplete, title)
    local popup = vgui.Create("Elib.PopupBool")
    if message then popup.Text:SetText(message) end
    if title then popup:SetTitle(title) end
    popup:SetFunction(OnComplete)

    return popup
end

function Elib.CreateStringPopup(message, OnComplete, title, placeholder)
    local popup = vgui.Create("Elib.PopupString")
    if message then popup.Text:SetText(message) end
    if title then popup:SetTitle(title) end
    if placeholder then popup:SetPlaceholder(placeholder) end
    popup:SetFunction(OnComplete)

    return popup
end

function Elib.CreateQueryPopup(message, title, buttons)
    local popup = vgui.Create("Elib.PopupQuery")

    if message then popup:SetBodyText(message) end
    if title then popup:SetTitleText(title) end

    -- buttons = {
    --   { text = "Save", callback = fn, style = "solid" },
    --   { text = "Discard", callback = fn, style = "outline" },
    --   { text = "Cancel", callback = fn, style = "ghost" },
    -- }

    if istable(buttons) then
        for _, btn in ipairs(buttons) do
            popup:AddButton(
                btn.text or "Button",
                btn.callback,
                btn.style
            )
        end
    end

    return popup
end
