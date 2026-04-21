// Made by Eve Haddox & imLiaMxo

Elib.DownloadPath = "elib/images/"

Elib.ProgressImageURL = "https://construct-cdn.physgun.com/images/5fa7c9c8-d9d5-4c77-aed6-975b4fb039b5.png"

/////////////////////////
// Behaviour Flags
/////////////////////////
// Whether Elib should override the default derma popups with its own reskins.
//   0 = no, forced off
//   1 = no, but users can opt in via convar "elib_override_popups"
//   2 = yes, but users can opt out via that convar
//   3 = yes, forced on
Elib.OverrideDermaMenus = 0

/////////////////////////
// Defaults
/////////////////////////
// Defaults for Elib.ActiveTheme and Elib.Lang.Active - these get overridden by
// the config menu at runtime once a user picks a preference.
Elib.ActiveTheme   = Elib.ActiveTheme or "Default"
Elib.Lang.Active   = Elib.Lang.Active or "en"
Elib.Lang.Fallback = Elib.Lang.Fallback or "en"
Elib.PopupOverride = Elib.PopupOverride or true
