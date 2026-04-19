// Made by Eve Haddox & imLiaMxo
//
// This shit was fully whipped up by AI. Big up Claude Opus model for scanning the whole fucking ZIP and spitting this shit out!
// It even got our comment styling too :D

CreateClientConVar("elib_demo_enabled", "0", true, false,
    "Enable the Elib v4 demo addon (requires rejoin).")

if CreateConVar and SERVER then
    // Server-side convar for enabling server realm demo values.
    CreateConVar("elib_demo_enabled_sv", "0", FCVAR_ARCHIVE,
        "Enable the Elib v4 demo addon server-side.")
end

// Bail out if not explicitly enabled.
if CLIENT and GetConVar("elib_demo_enabled"):GetInt() ~= 1 then return end
if SERVER and GetConVar("elib_demo_enabled_sv"):GetInt() ~= 1 then return end

/////////////////////////
// Config values demo
/////////////////////////
// Register on FullyLoaded so the config menu's core values exist first and
// we end up sorted after them.
hook.Add("Elib.FullyLoaded", "Elib.Demo.RegisterConfig", function()
    Elib.Config:AddAddon("Elib Demo", {
        order       = 100,
        author      = { name = "Eve Haddox & imLiaMxo", steamid = "" },
        description = "A demo addon showcasing every config value type.",
    })

    Elib.Config:AddValue("Elib Demo", "client", "general", "greeting", {
        name    = "Greeting",
        default = "Hello, world!",
        type    = "Text",
        order   = 1,
        onComplete = function(v) print("[Demo] greeting ->", v) end,
    })

    Elib.Config:AddValue("Elib Demo", "client", "general", "max_items", {
        name    = "Max Items",
        default = 10,
        type    = "Number",
        order   = 2,
        onComplete = function(v) print("[Demo] max_items ->", v) end,
    })

    Elib.Config:AddValue("Elib Demo", "client", "general", "show_hud", {
        name    = "Show HUD",
        default = true,
        type    = "Boolean",
        order   = 3,
        onComplete = function(v) print("[Demo] show_hud ->", tostring(v)) end,
    })

    Elib.Config:AddValue("Elib Demo", "client", "general", "difficulty", {
        name    = "Difficulty",
        default = "Normal",
        type    = "Dropdown",
        order   = 4,
        table   = { "Easy", "Normal", "Hard", "Insane" },
        onComplete = function(v) print("[Demo] difficulty ->", v) end,
    })

    Elib.Config:AddValue("Elib Demo", "client", "general", "accent_color", {
        name    = "Accent Color",
        default = Color(60, 130, 220),
        type    = "Color",
        order   = 5,
        onComplete = function(v) print("[Demo] accent_color ->", v) end,
    })

    Elib.Config:AddValue("Elib Demo", "client", "general", "tag_list", {
        name    = "Tag List (JSON)",
        default = { "red", "blue", "green" },
        type    = "Table",
        order   = 6,
        onComplete = function(v) print("[Demo] tag_list ->", table.concat(v, ", ")) end,
    })

    Elib.Config:AddValue("Elib Demo", "client", "general", "favorite_maps", {
        name        = "Favorite Maps",
        default     = { "gm_construct", "gm_flatgrass" },
        type        = "List",
        order       = 7,
        placeholder = "Enter map name...",
        maxEntries  = 10,
        validator   = function(value, all)
            if #value < 3 then return false, "Too short" end
            for _, existing in ipairs(all) do
                if existing == value then return false, "Duplicate" end
            end
            return true
        end,
        onComplete = function(v) print("[Demo] favorite_maps ->", table.concat(v, ", ")) end,
    })

    // Server-side examples (only visible to admins in the config menu).
    Elib.Config:AddValue("Elib Demo", "server", "network", "welcome_msg", {
        name    = "Welcome Message",
        default = "Welcome to the server!",
        type    = "Text",
        order   = 1,
        network = true,
    })

    Elib.Config:AddValue("Elib Demo", "server", "network", "pvp_enabled", {
        name    = "PvP Enabled",
        default = false,
        type    = "Boolean",
        order   = 2,
        network = true,
    })

    local log = Elib.NewLogger("Elib.Demo")
    log:Success("Demo config values registered.")
end)

/////////////////////////
// UI Showcase
/////////////////////////
// Only the client side builds the frame.
if SERVER then return end

local RNDX = Elib.RNDX

// Namespace for demo state - declared up here so the opener function can
// safely read Elib.Demo.Frame before assigning to it.
Elib.Demo = Elib.Demo or {}

// Opens the demo frame. Each sidebar tab swaps out the content panel.
function Elib.Demo_OpenShowcase()
    if IsValid(Elib.Demo.Frame) then Elib.Demo.Frame:Remove() end

    local f = vgui.Create("Elib.Frame")
    Elib.Demo.Frame = f

    f:SetTitle("Elib v4 UI Showcase")
    f:SetSize(Elib.Scale(900), Elib.Scale(600))
    f:Center()
    f:MakePopup()

    local content = vgui.Create("Elib.ScrollPanel", f)
    content:Dock(FILL)
    content:SetBackToTop(true)

    local function swapTo(builder)
        content:Clear()
        builder(content)
    end

    local bar = f:CreateSidebar()

    /////////////////////////
    // Tab: TextEntry
    /////////////////////////
    bar:AddItem("text", "Text Entry", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.TextEntry")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            // Single line
            local single = vgui.Create("Elib.TextEntry", parent)
            single:Dock(TOP)
            single:DockMargin(0, 0, 0, Elib.Scale(8))
            single:SetTall(Elib.Scale(40))
            single:SetPlaceholder("Type something here...")
            single.OnChange = function(_, v) print("[Demo] single ->", v) end
            single.OnEnter  = function(_, v) print("[Demo] single ENTER ->", v) end

            // Numeric
            local num = vgui.Create("Elib.TextEntry", parent)
            num:Dock(TOP)
            num:DockMargin(0, 0, 0, Elib.Scale(8))
            num:SetTall(Elib.Scale(40))
            num:SetNumeric(true)
            num:SetPlaceholder("Numbers only...")
            num.OnChange = function(_, v) print("[Demo] num ->", tonumber(v)) end

            // Multiline
            local multi = vgui.Create("Elib.TextEntry", parent)
            multi:Dock(TOP)
            multi:DockMargin(0, 0, 0, Elib.Scale(8))
            multi:SetTall(Elib.Scale(140))
            multi:SetMultiline(true)
            multi:SetPlaceholder("A longer piece of text...\nLine 2.\nLine 3.")

            // Disabled (shows the grey "disabled" state)
            local disabled = vgui.Create("Elib.TextEntry", parent)
            disabled:Dock(TOP)
            disabled:DockMargin(0, 0, 0, Elib.Scale(8))
            disabled:SetTall(Elib.Scale(40))
            disabled:SetEnabled(false)
        end)
    end)

    /////////////////////////
    // Tab: Boolean
    /////////////////////////
    bar:AddItem("boolean", "Boolean", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.Boolean")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            // Row with label + toggle on the right.
            local function makeRow(labelText, initial)
                local row = vgui.Create("Panel", parent)
                row:Dock(TOP)
                row:DockMargin(0, 0, 0, Elib.Scale(8))
                row:SetTall(Elib.Scale(36))

                local l = vgui.Create("DLabel", row)
                l:Dock(FILL)
                l:SetFont(Elib.GetRealFont("Elib.Body") or "DermaDefault")
                l:SetText(labelText)
                l:SetTextColor(Elib.Colors.PrimaryText)

                local t = vgui.Create("Elib.Boolean", row)
                t:Dock(RIGHT)
                t:DockMargin(Elib.Scale(8), Elib.Scale(6), 0, Elib.Scale(6))
                t:SetValue(initial)
                t.OnChange = function(_, v) print("[Demo]", labelText, "->", tostring(v)) end
                return t
            end

            makeRow("Enable notifications",        true)
            makeRow("Auto-save",                   false)
            makeRow("Play sounds",                 true)
            makeRow("Show advanced options",       false)
        end)
    end)

    /////////////////////////
    // Tab: Dropdown
    /////////////////////////
    bar:AddItem("dropdown", "Dropdown", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.Dropdown")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            // Simple dropdown
            local dd1 = vgui.Create("Elib.Dropdown", parent)
            dd1:Dock(TOP)
            dd1:DockMargin(0, 0, 0, Elib.Scale(8))
            dd1:SetTall(Elib.Scale(40))
            dd1:SetPlaceholder("Pick a colour...")
            dd1:AddChoice("Red",   "r")
            dd1:AddChoice("Green", "g")
            dd1:AddChoice("Blue",  "b", true)   -- pre-selected
            dd1.OnSelect = function(_, id, value, data) print("[Demo] dd1 ->", data) end

            // Sorted dropdown
            local dd2 = vgui.Create("Elib.Dropdown", parent)
            dd2:Dock(TOP)
            dd2:DockMargin(0, 0, 0, Elib.Scale(8))
            dd2:SetTall(Elib.Scale(40))
            dd2:SetSortItems(true)
            dd2:SetPlaceholder("Pick a theme (sorted)...")
            for _, name in ipairs(Elib.GetThemeNames()) do
                dd2:AddChoice(name, name)
            end
            dd2.OnSelect = function(_, _, value) Elib.SetTheme(value) end

            // Live language switcher
            local dd3 = vgui.Create("Elib.Dropdown", parent)
            dd3:Dock(TOP)
            dd3:DockMargin(0, 0, 0, Elib.Scale(8))
            dd3:SetTall(Elib.Scale(40))
            dd3:SetPlaceholder("Language...")
            for _, entry in ipairs(Elib.Lang.GetLanguages()) do
                dd3:AddChoice(entry.name, entry.code, entry.code == Elib.Lang.Active)
            end
            dd3.OnSelect = function(_, _, _, code) Elib.Lang.SetActive(code) end
        end)
    end)

    /////////////////////////
    // Tab: Table (list element)
    /////////////////////////
    bar:AddItem("table", "Table", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.Table")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            local info = vgui.Create("DLabel", parent)
            info:Dock(TOP)
            info:DockMargin(0, 0, 0, Elib.Scale(8))
            info:SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
            info:SetTextColor(Elib.Colors.SecondaryText)
            info:SetText("Add entries with the input at the bottom or by pressing Enter. Click the X on any row to remove it.")
            info:SetWrap(true)
            info:SetAutoStretchVertical(true)

            // Basic table
            local basicLabel = vgui.Create("DLabel", parent)
            basicLabel:Dock(TOP)
            basicLabel:DockMargin(0, Elib.Scale(8), 0, Elib.Scale(4))
            basicLabel:SetFont(Elib.GetRealFont("Elib.Medium") or "DermaDefaultBold")
            basicLabel:SetTextColor(Elib.Colors.PrimaryText)
            basicLabel:SetText("Basic - unrestricted")

            local basic = vgui.Create("Elib.Table", parent)
            basic:Dock(TOP)
            basic:SetTall(Elib.Scale(180))
            basic:SetEntries({ "apple", "banana", "cherry" })
            basic.OnChange = function(_, list)
                print("[Demo] basic table ->", table.concat(list, ", "))
            end

            // Validated table
            local valLabel = vgui.Create("DLabel", parent)
            valLabel:Dock(TOP)
            valLabel:DockMargin(0, Elib.Scale(12), 0, Elib.Scale(4))
            valLabel:SetFont(Elib.GetRealFont("Elib.Medium") or "DermaDefaultBold")
            valLabel:SetTextColor(Elib.Colors.PrimaryText)
            valLabel:SetText("Validated - no duplicates, 3+ chars, max 5 entries")

            local validated = vgui.Create("Elib.Table", parent)
            validated:Dock(TOP)
            validated:SetTall(Elib.Scale(180))
            validated:SetPlaceholder("e.g. STEAM_0:0:1234")
            validated:SetMaxEntries(5)
            validated:SetValidator(function(value, entries)
                if #value < 3 then return false, "Too short (min 3)" end
                for _, existing in ipairs(entries) do
                    if existing == value then return false, "Already in list" end
                end
                return true
            end)
            validated:SetEntries({ "STEAM_0:0:1111" })
            validated.OnChange = function(_, list)
                print("[Demo] validated table ->", table.concat(list, ", "))
            end
        end)
    end)

    /////////////////////////
    // Tab: Sidebar
    /////////////////////////
    bar:AddItem("sidebar", "Sidebar", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.Sidebar (nested example)")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            // Demo a second sidebar inside the panel.
            local wrap = vgui.Create("Panel", parent)
            wrap:Dock(FILL)

            local nested = vgui.Create("Elib.Sidebar", wrap)
            nested:Dock(LEFT)
            nested:SetWide(Elib.Scale(180))

            local right = vgui.Create("DLabel", wrap)
            right:Dock(FILL)
            right:DockMargin(Elib.Scale(12), 0, 0, 0)
            right:SetFont(Elib.GetRealFont("Elib.Body") or "DermaDefault")
            right:SetTextColor(Elib.Colors.SecondaryText)
            right:SetContentAlignment(5)
            right:SetText("Pick an item on the left.")

            nested:AddItem("a", "Dashboard",   nil, function() right:SetText("You picked Dashboard.")   end)
            nested:AddItem("b", "Users",       nil, function() right:SetText("You picked Users.")       end)
            nested:AddItem("c", "Settings",    nil, function() right:SetText("You picked Settings.")    end)
            nested:AddItem("d", "Audit Log",   nil, function() right:SetText("You picked Audit Log.")   end)
            nested:SelectItem("a")
        end)
    end)

    /////////////////////////
    // Tab: Web Images
    /////////////////////////
    bar:AddItem("images", "Web Images", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.WebImages (promise-based)")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            local info = vgui.Create("DLabel", parent)
            info:Dock(TOP)
            info:DockMargin(0, 0, 0, Elib.Scale(12))
            info:SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
            info:SetText("Images load async and cache to data/" .. Elib.DownloadPath .. ". First load shows a spinner; subsequent loads are instant.")
            info:SetTextColor(Elib.Colors.SecondaryText)
            info:SetTall(Elib.Scale(30))
            info:SetWrap(true)
            info:SetAutoStretchVertical(true)

            local urls = {
                "https://construct-cdn.physgun.com/images/bb26c4a0-cf84-4043-ab87-bff0cc9af57f.png",
                "https://construct-cdn.physgun.com/images/299b15c9-d403-44f9-bf4a-0b4dce07baf1.png",
                "https://construct-cdn.physgun.com/images/204e6270-1a86-4af6-9350-66cfd5dd8b5a.png",
                "https://construct-cdn.physgun.com/images/b3531bb5-c708-4d40-a263-48350672ea91.png",
            }

            local grid = vgui.Create("Panel", parent)
            grid:Dock(TOP)
            grid:SetTall(Elib.Scale(200))

            grid.Paint = function(_, w, h)
                local cell = w / #urls
                local pad  = Elib.Scale(8)
                local size = math.min(cell - pad * 2, h - pad * 2)

                for i, url in ipairs(urls) do
                    local x = (i - 1) * cell + (cell - size) / 2
                    local y = (h - size) / 2
                    Elib.WebImages.Draw(x, y, size, size, url, color_white)
                end
            end

            // Also demonstrate explicit promise-based loading.
            local status = vgui.Create("DLabel", parent)
            status:Dock(TOP)
            status:DockMargin(0, Elib.Scale(12), 0, 0)
            status:SetFont(Elib.GetRealFont("Elib.Body") or "DermaDefault")
            status:SetText("Promise status: waiting...")
            status:SetTextColor(Elib.Colors.SecondaryText)
            status:SetTall(Elib.Scale(24))

            Elib.WebImages.Get(urls[1])
                :next(function(mat)
                    if IsValid(status) then
                        status:SetText("Promise status: resolved (" .. tostring(mat) .. ")")
                        status:SetTextColor(Elib.Colors.Positive)
                    end
                end, function(err)
                    if IsValid(status) then
                        status:SetText("Promise status: rejected (" .. tostring(err) .. ")")
                        status:SetTextColor(Elib.Colors.Negative)
                    end
                end)
        end)
    end)

    /////////////////////////
    // Tab: Logging
    /////////////////////////
    bar:AddItem("logging", "Logging", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.NewLogger")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            local info = vgui.Create("DLabel", parent)
            info:Dock(TOP)
            info:DockMargin(0, 0, 0, Elib.Scale(12))
            info:SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
            info:SetText("Click the buttons below - output goes to your console.")
            info:SetTextColor(Elib.Colors.SecondaryText)
            info:SetTall(Elib.Scale(24))

            local log = Elib.NewLogger("DemoUI", { debug = true })

            // Helper that makes an Elib.Button styled like a compact row button.
            local function makeBtn(text, onClick)
                local b = vgui.Create("Elib.Button", parent)
                b:Dock(TOP)
                b:DockMargin(0, 0, 0, Elib.Scale(6))
                b:SetTall(Elib.Scale(36))
                b:SetText(text)
                b:SetStyle("ghost")
                b.DoClick = onClick
                return b
            end

            makeBtn("log:Debug(\"hello\")",   function() log:Debug("hello") end)
            makeBtn("log:Info(\"info\")",     function() log:Info("info")   end)
            makeBtn("log:Success(\"done\")",  function() log:Success("done") end)
            makeBtn("log:Warn(\"hmm\")",      function() log:Warn("hmm")    end)
            makeBtn("log:Error(\"broke\")",   function() log:Error("broke") end)
        end)
    end)

    /////////////////////////
    // Tab: Button
    /////////////////////////
    bar:AddItem("button", "Button", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.Button")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            local info = vgui.Create("DLabel", parent)
            info:Dock(TOP)
            info:DockMargin(0, 0, 0, Elib.Scale(12))
            info:SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
            info:SetTextColor(Elib.Colors.SecondaryText)
            info:SetText("Click any button - output goes to your console. Icons are loaded asynchronously via Elib.WebImages.")
            info:SetWrap(true)
            info:SetAutoStretchVertical(true)

            // Helper to build one labelled row with a button in it.
            local function makeRow(labelText, configureBtn)
                local row = vgui.Create("Panel", parent)
                row:Dock(TOP)
                row:DockMargin(0, 0, 0, Elib.Scale(8))
                row:SetTall(Elib.Scale(44))

                local l = vgui.Create("DLabel", row)
                l:Dock(LEFT)
                l:SetWide(Elib.Scale(220))
                l:SetFont(Elib.GetRealFont("Elib.Body") or "DermaDefault")
                l:SetText(labelText)
                l:SetTextColor(Elib.Colors.SecondaryText)

                local b = vgui.Create("Elib.Button", row)
                b:Dock(LEFT)
                b:SetWide(Elib.Scale(180))
                b:DockMargin(Elib.Scale(8), Elib.Scale(6), 0, Elib.Scale(6))
                configureBtn(b)

                return b
            end

            makeRow("Solid (default)", function(b)
                b:SetText("Save changes")
                b.DoClick = function() print("[Demo] solid clicked") end
            end)

            makeRow("Outline", function(b)
                b:SetText("Cancel")
                b:SetStyle("outline")
                b.DoClick = function() print("[Demo] outline clicked") end
            end)

            makeRow("Ghost", function(b)
                b:SetText("Learn more")
                b:SetStyle("ghost")
                b.DoClick = function() print("[Demo] ghost clicked") end
            end)

            makeRow("With icon (left)", function(b)
                b:SetText("Upload")
                // Using the same gmod-CDN icons the frame demo uses.
                b:SetIcon("https://construct-cdn.physgun.com/images/b3531bb5-c708-4d40-a263-48350672ea91.png", "left")
                b.DoClick = function() print("[Demo] upload clicked") end
            end)

            makeRow("With icon (right)", function(b)
                b:SetText("Next")
                b:SetIcon("https://construct-cdn.physgun.com/images/b3531bb5-c708-4d40-a263-48350672ea91.png", "right")
                b.DoClick = function() print("[Demo] next clicked") end
            end)

            makeRow("Icon-only", function(b)
                b:SetStyle("ghost")
                b:SetIcon("https://construct-cdn.physgun.com/images/204e6270-1a86-4af6-9350-66cfd5dd8b5a.png", "only")
                b:SetWide(Elib.Scale(44))
                b.DoClick = function() print("[Demo] icon-only clicked") end
            end)

            makeRow("Custom colour", function(b)
                b:SetText("Delete")
                b:SetColor(Elib.Colors.Negative)
                b.DoClick = function() print("[Demo] delete clicked") end
            end)

            makeRow("Disabled", function(b)
                b:SetText("Not available")
                b:SetEnabled(false)
            end)
        end)
    end)

    /////////////////////////
    // Tab: Navbar
    /////////////////////////
    bar:AddItem("navbar", "Navbar", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.Navbar")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            local info = vgui.Create("DLabel", parent)
            info:Dock(TOP)
            info:DockMargin(0, 0, 0, Elib.Scale(12))
            info:SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
            info:SetTextColor(Elib.Colors.SecondaryText)
            info:SetText("Horizontal tab strip - the underline animates between items on selection.")
            info:SetWrap(true)
            info:SetAutoStretchVertical(true)

            local wrap = vgui.Create("Panel", parent)
            wrap:Dock(TOP)
            wrap:SetTall(Elib.Scale(260))
            wrap:DockMargin(0, Elib.Scale(8), 0, 0)

            local nav = vgui.Create("Elib.Navbar", wrap)
            nav:Dock(TOP)
            nav:SetTall(Elib.Scale(36))

            local content = vgui.Create("DLabel", wrap)
            content:Dock(FILL)
            content:DockMargin(0, Elib.Scale(12), 0, 0)
            content:SetFont(Elib.GetRealFont("Elib.Body") or "DermaDefault")
            content:SetTextColor(Elib.Colors.SecondaryText)
            content:SetContentAlignment(5)   -- centre
            content:SetText("Pick a tab above.")

            nav:AddItem("overview", "Overview", nil, function() content:SetText("Overview selected.")   end)
            nav:AddItem("members",  "Members",  nil, function() content:SetText("Members selected.")    end)
            nav:AddItem("settings", "Settings", nil, function() content:SetText("Settings selected.")   end)
            nav:AddItem("logs",     "Logs",     nil, function() content:SetText("Logs selected.")       end)
            nav:SelectItem("overview")

            // Open-in-frame demonstration button.
            local openFrame = vgui.Create("Elib.Button", parent)
            openFrame:Dock(TOP)
            openFrame:DockMargin(0, Elib.Scale(16), 0, 0)
            openFrame:SetTall(Elib.Scale(40))
            openFrame:SetText("Open a frame with a navbar + sidebar")
            openFrame.DoClick = function()
                local f = vgui.Create("Elib.Frame")
                f:SetTitle("Navbar + Sidebar frame")
                f:SetSize(Elib.Scale(800), Elib.Scale(500))
                f:Center()
                f:MakePopup()

                local sb = f:CreateSidebar("dashboard")
                local nb = f:CreateNavbar("overview")

                local content2 = vgui.Create("DLabel", f)
                content2:Dock(FILL)
                content2:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
                content2:SetTextColor(Elib.Colors.PrimaryText)
                content2:SetContentAlignment(5)
                content2:SetText("Dashboard / Overview")

                // Keep content text in sync with current sidebar + navbar selection.
                local sidebarLabel, navbarLabel = "Dashboard", "Overview"
                local function refresh() content2:SetText(sidebarLabel .. " / " .. navbarLabel) end

                sb:AddItem("dashboard", "Dashboard", nil, function() sidebarLabel = "Dashboard"; refresh() end)
                sb:AddItem("reports",   "Reports",   nil, function() sidebarLabel = "Reports";   refresh() end)
                sb:AddItem("admin",     "Admin",     nil, function() sidebarLabel = "Admin";     refresh() end)

                nb:AddItem("overview", "Overview", nil, function() navbarLabel = "Overview"; refresh() end)
                nb:AddItem("details",  "Details",  nil, function() navbarLabel = "Details";  refresh() end)
                nb:AddItem("history",  "History",  nil, function() navbarLabel = "History";  refresh() end)
            end
        end)
    end)

    /////////////////////////
    // Tab: Notifications (toasts)
    /////////////////////////
    bar:AddItem("notifications", "Notifications", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.Notify")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            local info = vgui.Create("DLabel", parent)
            info:Dock(TOP)
            info:DockMargin(0, 0, 0, Elib.Scale(12))
            info:SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
            info:SetTextColor(Elib.Colors.SecondaryText)
            info:SetText("Click a button to fire a toast. Click the toast itself to dismiss early.")
            info:SetWrap(true)
            info:SetAutoStretchVertical(true)

            local function makeFireBtn(label, builder)
                local b = vgui.Create("Elib.Button", parent)
                b:Dock(TOP)
                b:DockMargin(0, Elib.Scale(6), 0, 0)
                b:SetTall(Elib.Scale(40))
                b:SetText(label)
                b.DoClick = builder
                return b
            end

            makeFireBtn("Fire info toast", function()
                Elib.Notify({
                    title = "Heads up",
                    text  = "This is an informational toast.",
                    type  = "info",
                })
            end)

            makeFireBtn("Fire success toast", function()
                Elib.Notify({
                    title = "Done!",
                    text  = "Operation completed successfully.",
                    type  = "success",
                })
            end)

            makeFireBtn("Fire warning toast", function()
                Elib.Notify({
                    title = "Warning",
                    text  = "Something might need your attention.",
                    type  = "warn",
                })
            end)

            local dangerBtn = makeFireBtn("Fire error toast", function()
                Elib.Notify({
                    title = "Error",
                    text  = "Something went wrong - this toast sticks around longer.",
                    type  = "error",
                    duration = 8,
                })
            end)
            dangerBtn:SetColor(Elib.Colors.Negative)

            makeFireBtn("Fire 5 at once (caps at 5 active)", function()
                for i = 1, 5 do
                    Elib.Notify({
                        title = "Message " .. i,
                        text  = "One of a batch of five notifications.",
                        type  = "info",
                    })
                end
            end)

            makeFireBtn("Short-form (text only, no title)", function()
                Elib.Notify("Settings saved")
            end)
        end)
    end)

    /////////////////////////
    // Tab: Scroll Panel
    /////////////////////////
    bar:AddItem("scroll", "Scroll Panel", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("Elib.ScrollPanel")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            local info = vgui.Create("DLabel", parent)
            info:Dock(TOP)
            info:DockMargin(0, 0, 0, Elib.Scale(8))
            info:SetFont(Elib.GetRealFont("Elib.Small") or "DermaDefault")
            info:SetTextColor(Elib.Colors.SecondaryText)
            info:SetText(
                "Smooth velocity-based scrolling. After scrolling down a bit, " ..
                "a circular 'back to top' button slides in at the bottom right. " ..
                "Click-drag the scrollbar grip for precise positioning."
            )
            info:SetWrap(true)
            info:SetAutoStretchVertical(true)

            local controls = vgui.Create("Panel", parent)
            controls:Dock(TOP)
            controls:DockMargin(0, Elib.Scale(12), 0, Elib.Scale(8))
            controls:SetTall(Elib.Scale(40))

            local scroll

            local toTopBtn = vgui.Create("Elib.Button", controls)
            toTopBtn:Dock(LEFT)
            toTopBtn:SetWide(Elib.Scale(140))
            toTopBtn:DockMargin(0, 0, Elib.Scale(8), 0)
            toTopBtn:SetText("Scroll to top")
            toTopBtn:SetStyle("outline")
            toTopBtn.DoClick = function()
                if IsValid(scroll) then scroll:ScrollToTop(true) end
            end

            local jumpBtn = vgui.Create("Elib.Button", controls)
            jumpBtn:Dock(LEFT)
            jumpBtn:SetWide(Elib.Scale(180))
            jumpBtn:SetText("Jump to row 50")
            jumpBtn:SetStyle("outline")
            jumpBtn.DoClick = function()
                if IsValid(scroll) and scroll._demoRow50 then
                    scroll:ScrollToChild(scroll._demoRow50)
                end
            end

            scroll = vgui.Create("Elib.ScrollPanel", parent)
            scroll:Dock(TOP)
            scroll:SetTall(Elib.Scale(380))
            scroll:SetBackToTop(true)

            for i = 1, 80 do
                local row = vgui.Create("Panel", scroll)
                row:Dock(TOP)
                row:DockMargin(Elib.Scale(4), 0, Elib.Scale(4), Elib.Scale(6))
                row:SetTall(Elib.Scale(38))

                row.Paint = function(s, w, h)
                    Elib.RNDX().Rect(0, 0, w, h)
                        :Rad(Elib.Scale(4))
                        :Color(Elib.OffsetColor(Elib.Colors.Background, 8))
                        :Draw()

                    draw.SimpleText("Row " .. i,
                        Elib.GetRealFont("Elib.Body") or "DermaDefault",
                        Elib.Scale(12), h / 2,
                        Elib.Colors.PrimaryText,
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
                    )

                    draw.SimpleText("This is a sample row in the Elib.ScrollPanel",
                        Elib.GetRealFont("Elib.Small") or "DermaDefault",
                        w - Elib.Scale(12), h / 2,
                        Elib.Colors.SecondaryText,
                        TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER
                    )
                end

                if i == 50 then scroll._demoRow50 = row end
            end
        end)
    end)

    /////////////////////////
    // Tab: Config
    /////////////////////////
    bar:AddItem("config", "Config Menu", nil, function()
        swapTo(function(parent)
            local lbl = vgui.Create("DLabel", parent)
            lbl:Dock(TOP)
            lbl:SetFont(Elib.GetRealFont("Elib.Large") or "DermaLarge")
            lbl:SetText("In-game Config Menu")
            lbl:SetTextColor(Elib.Colors.PrimaryText)
            lbl:SetTall(Elib.Scale(40))

            local info = vgui.Create("DLabel", parent)
            info:Dock(TOP)
            info:DockMargin(0, 0, 0, Elib.Scale(12))
            info:SetFont(Elib.GetRealFont("Elib.Body") or "DermaDefault")
            info:SetText("The demo registers one value of each type under an 'Elib Demo' addon. Open the config menu to see them.")
            info:SetTextColor(Elib.Colors.SecondaryText)
            info:SetWrap(true)
            info:SetAutoStretchVertical(true)

            local b = vgui.Create("Elib.Button", parent)
            b:Dock(TOP)
            b:DockMargin(0, Elib.Scale(12), 0, 0)
            b:SetTall(Elib.Scale(40))
            b:SetText("Open Config Menu")
            b.DoClick = function() Elib.Config.OpenMenu() end
        end)
    end)

    // Start on the first tab.
    bar:SelectItem("text")
end

concommand.Add("elib_demo", Elib.Demo_OpenShowcase)

// Friendly hint in the console once the client loads.
hook.Add("Elib.FullyLoaded", "Elib.Demo.Hint", function()
    if CLIENT then
        MsgC(Color(207, 144, 49), "[Elib Demo] ",
             Color(230, 230, 230), "Type 'elib_demo' to open the showcase, or 'elib_config' for the config menu.\n")
    end
end)