# Elib v4

A standalone UI & systems library for Garry's Mod.

This version (v4) is fully self-contained and no longer depends on Pixel UI.
Made by **Eve Haddox & imLiaMxo**.

## What's in this release

This is the framework scaffolding. No UI elements yet.

- **Autoloader** – `lua/autorun/elib_init.lua`
- **Logging** – `Elib.NewLogger("Addon")` with levels, per-instance debug flag, optional file logging
- **Scaling** – `Elib.Scale(n)` and named scaled constants
- **Colors** – conversions, lerping, copying, metatable helpers
- **Fonts** – `Elib.RegisterFont(name, font, size, weight)` with auto re-scale on resolution change
- **Themes** – `Elib.RegisterTheme(name, colors)` / `Elib.SetTheme(name)`, with 11 presets bundled
- **Languages** – `Elib.Lang.Register(code, displayName, strings)` / `Elib.Lang.Get(key, ...)` with fallbacks and printf-style formatting, plus a global `L(key, ...)` shorthand
- **Database** – `Elib.NewDatabase("Addon")` wrapping SQLite and MySQLoo
- **RNDX** and **PAPI** – bundled as in v3

Not in this release yet: networking module, in-game config menu UI, panels, popups, notifications. Those come next.

## Folder layout

```
lua/
├── autorun/
│   └── elib_init.lua           -- main loader
├── elib/
│   ├── sh_config.lua           -- framework-wide settings
│   ├── core/
│   │   ├── sh_logging.lua
│   │   ├── cl_scaling.lua
│   │   ├── sh_colors.lua
│   │   ├── cl_fonts.lua
│   │   ├── cl_themes.lua
│   │   ├── sh_languages.lua
│   │   └── sv_database.lua
│   ├── themes/                 -- one file per theme, add your own freely
│   │   ├── cl_default.lua
│   │   └── ...
│   └── languages/              -- one file per language
│       └── sh_english.lua
├── rndx.lua
└── papi.lua
```

## Quickstart

### Logging

```lua
local log = Elib.NewLogger("MyAddon", { debug = true })
log:Info("Booting up.")
log:Success("Connected to database.")
log:Warn("Missing config value, using default.")
log:Error("Something broke.")
log:Debug("Only shown when debug = true.")
```

### Themes

```lua
Elib.RegisterTheme("Sunset", {
    Primary    = Color(235, 110, 60),
    Background = Color(25, 15, 20),
})

Elib.SetTheme("Sunset")

hook.Add("Elib.ThemeChanged", "MyAddon.RefreshColours", function(name)
    -- rebuild any cached colours here
end)
```

### Languages

```lua
Elib.Lang.Register("en", "English", {
    ["myaddon.welcome"] = "Welcome, %s!",
    ["myaddon.coins"]   = "You have %d coins.",
})

Elib.Lang.Get("myaddon.welcome", ply:Nick())
-- or use the L() shorthand
L("myaddon.coins", 42)

Elib.Lang.SetActive("fr")   -- swap language at runtime
```

### Database

```lua
local db = Elib.NewDatabase("MyAddon")
-- db:UseMySQL(true)
-- db:Connect("127.0.0.1", "user", "pass", "mydb")
db:Connect()

db:CreateTable("myaddon_users", {
    steamid = "TEXT NOT NULL",
    coins   = "INTEGER DEFAULT 0",
    PRIMARY = "KEY(steamid)",
})

db:Insert("myaddon_users", { steamid = "STEAM_0:0:1", coins = 100 })
db:Select("myaddon_users", "*", "coins > 50", function(rows) PrintTable(rows) end)
```

### Fonts

```lua
Elib.RegisterFont("MyAddon.Body", "Space Grotesk", 16)
Elib.RegisterFont("MyAddon.Title", "Space Grotesk", 32, 700)

Elib.SetFont("MyAddon.Body")
-- or
surface.SetFont(Elib.GetRealFont("MyAddon.Title"))
```
