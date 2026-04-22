// Made by Eve Haddox & imLiaMxo


// This file is just for compatibility with v3. For example functions we no longer use yet still want to be able to use in older scripts.
// This file is not meant to be used in new scripts, and will eventually be removed.

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