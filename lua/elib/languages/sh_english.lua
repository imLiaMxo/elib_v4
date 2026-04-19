// Made by Eve Haddox & imLiaMxo

Elib.Lang.Register("en", "English", {

    ////////////////////////////
    // Generic actions & labels
    ////////////////////////////
    ["elib.save"]            = "Save",
    ["elib.save_changes"]    = "Save changes",
    ["elib.cancel"]          = "Cancel",
    ["elib.confirm"]         = "Confirm",
    ["elib.close"]           = "Close",
    ["elib.reset"]           = "Reset",
    ["elib.revert"]          = "Revert",
    ["elib.default"]         = "Default",
    ["elib.apply"]           = "Apply",
    ["elib.delete"]          = "Delete",
    ["elib.edit"]            = "Edit",
    ["elib.back"]            = "Back",
    ["elib.next"]            = "Next",
    ["elib.search"]          = "Search",
    ["elib.loading"]         = "Loading...",
    ["elib.disabled"]        = "Disabled",
    ["elib.yes"]             = "Yes",
    ["elib.no"]              = "No",
    ["elib.ok"]              = "OK",

    ////////////////////////////
    // Table / List element
    ////////////////////////////
    ["elib.table.add"]       = "Add",
    ["elib.table.placeholder"] = "New entry...",

    ////////////////////////////
    // Frame
    ////////////////////////////
    ["elib.frame.default_title"] = "Elib Frame",

    ////////////////////////////
    // Config menu
    ////////////////////////////
    ["elib.config.title"]          = "Elib Configuration",
    ["elib.config.general"]        = "General",
    ["elib.config.colors"]         = "Colors",
    ["elib.config.network"]        = "Network",
    ["elib.config.theme"]          = "Theme Preset",
    ["elib.config.language"]       = "Language",
    ["elib.config.addons"]         = "Addons",
    ["elib.config.empty"]          = "No configurable values for this addon.",

    // Category subtitles shown under each header.
    ["elib.config.subtitle.server"] = "Server-wide (admin only)",
    ["elib.config.subtitle.client"] = "Clientside",

    ////////////////////////////
    // Config menu - dirty / save bar
    ////////////////////////////
    ["elib.config.unsaved"]        = "You have unsaved changes.",
    // {count} is substituted by the menu code - expects a single %d.
    ["elib.config.unsaved_one"]    = "%d unsaved change",
    ["elib.config.unsaved_many"]   = "%d unsaved changes",

    ////////////////////////////
    // Config menu - switch-away prompt
    ////////////////////////////
    ["elib.config.switch.title"]    = "Unsaved changes",
    ["elib.config.switch.body"]     = "You have unsaved changes. Switch anyway?",
    ["elib.config.switch.save"]     = "Save and switch",
    ["elib.config.switch.discard"]  = "Discard and switch",
    ["elib.config.switch.cancel"]   = "Cancel",

    ////////////////////////////
    // Config menu - notifications
    ////////////////////////////
    ["elib.config.notify.saved_title"]      = "Configuration",
    ["elib.config.notify.saved_body"]       = "Saved changes.",
    ["elib.config.notify.reverted_title"]   = "Configuration",
    ["elib.config.notify.reverted_body"]    = "Reverted changes.",
    ["elib.config.notify.discarded_title"]  = "Configuration",
    ["elib.config.notify.discarded_body"]   = "Closed menu with unsaved changes discarded.",

    ////////////////////////////
    // Color picker (placeholder Derma dialog)
    ////////////////////////////
    ["elib.colorpicker.title"] = "Pick a colour",

    ////////////////////////////
    // Validation messages (text entry)
    ////////////////////////////
    // These use sprintf-style placeholders so translations can reorder or
    // pluralise as needed.
    ["elib.validation.min_length"]  = "Must be at least %d characters",
    ["elib.validation.max_length"]  = "Must be at most %d characters",
    ["elib.validation.invalid_format"] = "Invalid format",
    ["elib.validation.not_a_number"]= "Must be a number",
    ["elib.validation.min_value"]   = "Must be at least %s",
    ["elib.validation.max_value"]   = "Must be at most %s",
    ["elib.validation.invalid_json"]= "Invalid JSON",

    ////////////////////////////
    // Notifications (generic)
    ////////////////////////////
    ["elib.notify.info"]    = "Info",
    ["elib.notify.success"] = "Success",
    ["elib.notify.warning"] = "Warning",
    ["elib.notify.error"]   = "Error",

    ////////////////////////////
    // Permissions / generic errors
    ////////////////////////////
    ["elib.error.no_permission"] = "You don't have permission to do that.",
    ["elib.error.invalid_value"] = "Invalid value.",
    ["elib.error.unknown"]       = "Something went wrong.",
})