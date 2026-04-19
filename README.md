# Elib v4

A standalone UI & systems library for Garry's Mod.

This version (v4) is fully self-contained and no longer depends on Pixel UI.
Made by **Eve Haddox & imLiaMxo**.

## What's in this release

The framework plus a first set of UI elements and the in-game config menu.

### Framework
- **Autoloader** – `lua/autorun/elib_init.lua`
- **Logging** – `Elib.NewLogger("Addon")` with levels, per-instance debug flag, optional file logging
- **Promises** – `Elib.Deferred` (A+ compliant), supports `:next()` chaining, `all()`, `first()`, `map()`
- **Scaling** – `Elib.Scale(n)` and named scaled constants
- **Colors** – conversions, lerping, copying, metatable helpers
- **Fonts** – `Elib.RegisterFont(name, font, size, weight)` with auto re-scale on resolution change
- **Themes** – `Elib.RegisterTheme(name, colors)` / `Elib.SetTheme(name)`, with 11 presets bundled
- **Languages** – `Elib.Lang.Register(code, displayName, strings)` / `Elib.Lang.Get(key, ...)` with fallbacks and printf-style formatting, plus a global `L(key, ...)` shorthand
- **Web images** – `Elib.WebImages.Get(url)` returns a promise; sync `Draw/DrawRotated/DrawImgur` helpers for common cases; legacy `Elib.DrawImage` etc. aliases for v3 code
- **Database** – `Elib.NewDatabase("Addon")` wrapping SQLite and MySQLoo
- **RNDX** and **PAPI** – bundled as in v3

### UI Elements
- **`Elib.Frame`** – draggable window with title, close button, sidebar integration, open/close animation
- **`Elib.Sidebar`** – vertical nav rail with animated accent bar
- **`Elib.TextEntry`** – single/multi-line text entry with placeholder, numeric mode, animated focus
- **`Elib.Boolean`** – sliding on/off toggle
- **`Elib.Dropdown`** – select-style dropdown with a styled menu

### In-game Config Menu
- Console command: `elib_config` (or `Elib.Config.OpenMenu()`)
- `Elib.Config:AddAddon(name, { order, author, description, icon })` (also accepts v3's positional form)
- `Elib.Config:AddValue(addon, realm, category, id, { name, default, type, order, onComplete, network, table })` (also accepts v3's positional form)
- `Elib.Config:GetValue(addon, realm, category, id, fallback)`
- Types: `Text`, `Number`, `Boolean`, `Dropdown`, `Table`, `Color` (basic picker)
- Persistence: server values in `elib_config_server` (sv.db), client values in `elib_config_client`
- Admin permission via **PAPI** (`elib.config.edit`) with `IsSuperAdmin()` fallback
- Networked values automatically pushed to all clients; admin-only values stay with admins

Not in this release yet: color picker (placeholder using Derma), notifications, popups, scrollbar themes, networking module. Those come next.

## Folder layout

```
lua/
├── autorun/
│   └── elib_init.lua                -- main loader
├── elib/
│   ├── sh_config.lua                -- framework-wide settings
│   ├── core/
│   │   ├── sh_logging.lua
│   │   ├── sh_promises.lua
│   │   ├── cl_scaling.lua
│   │   ├── sh_colors.lua
│   │   ├── cl_fonts.lua
│   │   ├── cl_themes.lua
│   │   ├── sh_languages.lua
│   │   ├── cl_webimages.lua
│   │   └── sv_database.lua
│   ├── themes/                      -- one file per theme, add your own freely
│   ├── languages/                   -- one file per language
│   └── elements/
│       ├── cl_frame.lua
│       ├── cl_sidebar.lua
│       ├── cl_textentry.lua
│       ├── cl_boolean.lua
│       └── cl_dropdown.lua
├── elib_config/
│   ├── sh_loader.lua
│   ├── sh_api.lua                   -- AddAddon, AddValue, GetValue
│   ├── sv_saving.lua                -- SQLite on server + networking
│   ├── cl_saving.lua                -- SQLite on client + net receivers
│   └── cl_menu.lua                  -- the UI
├── rndx.lua
└── papi.lua
```

## Quickstart

### Web images with promises

```lua
Elib.WebImages.Get("https://example.com/logo.png")
    :next(function(material)
        -- material is ready
    end, function(err)
        print("failed:", err)
    end)

-- Or just draw it (caches and shows a loading spinner on first call):
hook.Add("HUDPaint", "MyHUD", function()
    Elib.WebImages.Draw(100, 100, 64, 64, "https://example.com/logo.png", color_white)
end)
```

### Config values

```lua
Elib.Config:AddAddon("MyAddon", { order = 1 })

Elib.Config:AddValue("MyAddon", "server", "general", "welcome", {
    name    = "Welcome Message",
    default = "Welcome!",
    type    = "Text",
    network = true,  -- all clients get this value
})

Elib.Config:AddValue("MyAddon", "client", "visuals", "show_hud", {
    name    = "Show HUD",
    default = true,
    type    = "Boolean",
})

-- Later:
local msg = Elib.Config:GetValue("MyAddon", "server", "general", "welcome")
```

### Frames + sidebars

```lua
local f = vgui.Create("Elib.Frame")
f:SetTitle("My Window")
f:SetSize(700, 500)
f:Center()
f:MakePopup()

local bar = f:CreateSidebar("home")
bar:AddItem("home",     "Home",     nil, function() ... end)
bar:AddItem("settings", "Settings", nil, function() ... end)
```

### Other element quickstarts

```lua
local te = vgui.Create("Elib.TextEntry", parent)
te:SetPlaceholder("Your name")
te.OnChange = function(s, v) print("typed:", v) end

local bool = vgui.Create("Elib.Boolean", parent)
bool:SetValue(true)
bool.OnChange = function(s, v) print("now:", v) end

local dd = vgui.Create("Elib.Dropdown", parent)
dd:AddChoice("Red",   "r")
dd:AddChoice("Green", "g", true)  -- pre-selected
dd:AddChoice("Blue",  "b")
dd.OnSelect = function(s, id, value, data) print("picked:", data) end
```

### Themes, languages, logging

```lua
Elib.RegisterTheme("Sunset", { Primary = Color(235, 110, 60) })
Elib.SetTheme("Sunset")

Elib.Lang.Register("en", "English", { ["my.greet"] = "Hello, %s!" })
print(L("my.greet", "world"))

local log = Elib.NewLogger("MyAddon", { debug = true })
log:Info("Booting.")
log:Success("Ready.")
```
