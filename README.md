# Elib v4

A standalone UI & systems library for Garry's Mod.
Made by **Eve Haddox & imLiaMxo**.

---

## Framework

| Module | What it does |
|---|---|
| **Autoloader** | `lua/autorun/elib_init.lua` – loads everything in order |
| **Logging** | `Elib.NewLogger(name, opts)` – levelled logging (Debug/Info/Success/Warn/Error), per-instance debug flag, optional file output |
| **Promises** | `Elib.Deferred` – A+ compliant, `:next()` chaining, `all()`, `first()`, `map()` |
| **Scaling** | `Elib.Scale(n)`, named scaled constants, auto-updates on resolution change |
| **Colors** | Hex/HSL conversions, lerping, copying, offset, rainbow, Color metatable helpers |
| **Fonts** | `Elib.RegisterFont(name, font, size, weight)` – auto re-scales on resolution change |
| **Themes** | `Elib.RegisterTheme` / `Elib.SetTheme` – 11 presets bundled (Default, Blue, Green, Purple, Orange, Gray, Arctic Neon, Bloodsteel, Obsidian Magenta, Royal Gold, Toxic Reactor) |
| **Languages** | `Elib.Lang.Register` / `L(key, ...)` – fallback chain, printf-style formatting, English + Polish bundled |
| **Web Images** | `Elib.WebImages.Get(url)` returns a promise; sync `Draw`/`DrawRotated`/`DrawImgur` helpers; progress spinner; disk cache |
| **UUID** | `Elib.UUID.Generate()` – RFC 4122 v4, collision tracking, validate/mark/unmark |
| **Animations** | `Elib.Anim.Tween(opts)` – arbitrary value tweening; `Elib.Anim.New(panel)` – chainable panel builder (`:To()`, `:Wait()`, `:Then()`); 30+ easing functions; `panel:Anim()` shorthand |
| **Time** | `Elib.Time.Ago/Until/Duration/Countdown/Format` – relative time, duration formatting, server↔client clock sync, `Stopwatch`, `Cooldown` (with progress fraction), `RateLimit` (token bucket per-key), `Every` (lightweight repeating check) |
| **Discord** | `Elib.SendWebhook(url, content, pureText)` – embed or plain text |
| **Effects** | `Elib.DrawLineAnim`, `Elib.DrawRoundedLineAnim` – animated diagonal stripe fill; `DrawBoxParticleAnim`, `DrawRoundedBoxParticleAnim` – floating square particles; `DrawMovingBoxAnim`, `DrawRoundedMovingBoxAnim` – rotating scaled cubes; all stencil-clipped |

### Database

`Elib.NewDatabase("Addon")` wrapping SQLite and MySQLoo.

- **Connection** – `driver = "sqlite" | "mysql"`, auto-queues while connecting, debug mode
- **Query builder** – `db:Table(name):Select/Where/WhereIn/WhereNull/Join/OrderBy/GroupBy/Limit/Offset/Count/Exists/First/Get`
- **Mutations** – `Insert`, `Update`, `Delete`, `Upsert` (ON CONFLICT / ON DUPLICATE KEY)
- **Schema** – `db.Schema:Create(name, definer)` with typed columns, indexes, composite primary keys; `Drop`, `Rename`, `Has`
- **Migrations** – `db:LoadMigrations(path)` – file-based, tracks applied in `elib_migrations` table
- **Models** – `db:DefineModel(name, config)` – `Find`, `FindOrFail`, `Where`, `All`, `Create`, `Save`, `Delete`, `Refresh`; auto timestamps, cast system (json/boolean/number/string)
- **Transactions** – `db:Transaction(body)`; legacy `BeginTransaction/Commit/Rollback`
- **Escape / Bind** – safe `?` parameter binding, raw expression support

---

## UI Elements

| Element | Notes |
|---|---|
| `Elib.Frame` | Draggable window, open/close animation, sidebar + navbar integration, extra header buttons, sizable |
| `Elib.Sidebar` | Vertical nav rail, collapsible with animation, header image, scroll panel, accent bar |
| `Elib.Navbar` | Horizontal tab strip, animated underline, image support |
| `Elib.ScrollPanel` | Smooth scroll with velocity, drag grip, `ScrollToChild`, back-to-top button |
| `Elib.TextEntry` | Single/multi-line, placeholder, numeric, float, validator chain (min/max length, pattern, number range), animated focus outline |
| `Elib.Boolean` | Animated checkbox with checkmark image and border lerp |
| `Elib.Dropdown` | Styled select with animated chevron, keyboard navigation, sorted mode, placeholder |
| `Elib.Button` | Solid / outline / ghost styles, icon left/right/only, custom colour, enabled state, press sink animation |
| `Elib.Table` | Editable list with per-entry delete, validator, max entries, `OnChange` |
| `Elib.Tooltip` | Hover-delay tooltip attached to any panel via `Elib.Tooltip.Attach` |
| `Elib.Notification` | Toast system – `Elib.Notify(opts)` – info/success/warn/error, position config, max 5 active, slide + fade |
| `Elib.HorizontalScrollPanel` | Horizontal scroll with momentum and snap-back |
| `Elib.InfinitePanel` | Pannable 2D canvas with bounds and scroll-wheel support |
| `Elib.Toggle` | Sliding on/off toggle (v3 import) |
| `Elib.MenuV2` | Context menu with sections, icons, swatches, keybinds, checkable items, submenus, keyboard nav |
| `Elib.BarChart` | Bar chart with grid, Y-axis labels, gradient fill |
| `Elib.LineGraph` | Catmull-Rom spline graph with gradient fill, X/Y ticks, axis labels |
| `Elib.PieChart` | Pie chart with stencil donut cutout, percentage labels, legend |
| `Elib.PopupInfo` | Informational popup |
| `Elib.PopupBool` | Confirm / cancel popup |
| `Elib.PopupString` | Text input popup |
| `Elib.PopupQuery` | Multi-button query popup |

---

## In-game Config Menu

Open with `elib_config` or `Elib.Config.OpenMenu()`.

```lua
Elib.Config:AddAddon("MyAddon", { order = 1, icon = "https://..." })

Elib.Config:AddValue("MyAddon", "server", "general", "welcome", {
    name    = "Welcome Message",
    default = "Hello!",
    type    = "Text",
    network = true,
})
```

**Value types:** `Text`, `Number`, `Boolean`, `Dropdown`, `Color`, `Table`, `List`

- Server values stored in `elib_config_server` (SQLite), client values in `elib_config_client`
- Networked values pushed to all clients automatically; admin-only values stay server-side
- Permission via PAPI (`elib.config.edit`) with `IsSuperAdmin()` fallback
- Unsaved-changes bar, switch-away prompt, per-addon sections

---

## Folder layout

```
lua/
├── autorun/
│   └── elib_init.lua
├── elib/
│   ├── sh_config.lua
│   ├── core/
│   │   ├── sh_logging.lua
│   │   ├── sh_promises.lua
│   │   ├── sh_uuid.lua
│   │   ├── sh_languages.lua
│   │   ├── sh_colors.lua
│   │   ├── sh_time.lua
│   │   ├── cl_scaling.lua
│   │   ├── cl_fonts.lua
│   │   ├── cl_themes.lua
│   │   ├── cl_webimages.lua
│   │   ├── cl_anim.lua
│   │   ├── cl_effects.lua
│   │   ├── sv_database.lua
│   │   ├── sv_discord.lua
│   │   └── database/
│   │       ├── sv_connection.lua
│   │       ├── sv_schema.lua
│   │       ├── sv_query.lua
│   │       ├── sv_migration.lua
│   │       └── sv_model.lua
│   ├── themes/
│   ├── languages/
│   └── elements/
│       ├── cl_frame.lua
│       ├── cl_sidebar.lua
│       ├── cl_navbar.lua
│       ├── cl_scrollpanel.lua
│       ├── cl_textentry.lua
│       ├── cl_boolean.lua
│       ├── cl_dropdown.lua
│       ├── cl_button.lua
│       ├── cl_table.lua
│       ├── cl_tooltip.lua
│       ├── cl_toasts.lua
│       └── v3_imports/
│           ├── cl_toggle.lua
│           ├── cl_menu_v2.lua
│           ├── cl_horizontal_scrollbar.lua
│           ├── cl_horizontal_scrollpanel.lua
│           ├── cl_infinite_panel.lua
│           ├── graphs/
│           │   ├── cl_bar_chart.lua
│           │   ├── cl_line_graph.lua
│           │   └── cl_pie_chart.lua
│           └── popups/
│               ├── cl_base.lua
│               ├── cl_info.lua
│               ├── cl_bool.lua
│               ├── cl_string.lua
│               └── cl_query.lua
├── elib_config/
│   ├── sh_loader.lua
│   ├── sh_api.lua
│   ├── sv_saving.lua
│   ├── cl_saving.lua
│   └── cl_menu.lua
├── rndx.lua
└── papi.lua
```

---

## Quickstart

```lua
-- Logging
local log = Elib.NewLogger("MyAddon", { debug = true })
log:Info("hello")

-- Promises
Elib.WebImages.Get("https://example.com/logo.png")
    :next(function(mat) end, function(err) end)

-- Database
local db = Elib.NewDatabase("MyAddon"):Configure({ driver = "sqlite" })
db:Connect():next(function()
    db:Table("players"):Where("steamid", ply:SteamID()):First():next(function(row) end)
end)

-- Animations
myPanel:Anim()
    :To({ alpha = 0, y = myPanel:GetY() + 20 }, 0.25, "OutQuart")
    :Then(function() myPanel:Remove() end)
    :Play()

-- Time
print(Elib.Time.Ago(os.time() - 3700))   -- "1 hour ago"
print(Elib.Time.Duration(3661))           -- "1h 1m 1s"

local cd = Elib.Time.Cooldown(30)
cd:Trigger()
print(cd:IsReady(), cd:Remaining())

-- Themes / languages
Elib.SetTheme("Arctic Neon")
Elib.Lang.SetActive("pl")
print(L("elib.save"))   -- "Zapisz"

-- Notify
Elib.Notify({ title = "Done", text = "Saved.", type = "success" })
```