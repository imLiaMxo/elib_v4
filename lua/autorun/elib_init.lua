// Made by Eve Haddox & imLiaMxo
//
// Elib v4 - a standalone UI & systems library for Garry's Mod.
// This version is fully self-contained and no longer depends on Pixel UI.

Elib         = Elib or {}
Elib.Version = "4.0.0-alpha"

/////////////////////////
// Automatic Loader
/////////////////////////
function Elib.LoadDirectory(path)
    local files, folders = file.Find(path .. "/*", "LUA")

    for _, fileName in ipairs(files) do
        local filePath = path .. "/" .. fileName

        if CLIENT then
            include(filePath)
        else
            if fileName:StartWith("cl_") then
                AddCSLuaFile(filePath)
            elseif fileName:StartWith("sh_") then
                AddCSLuaFile(filePath)
                include(filePath)
            else
                include(filePath)
            end
        end
    end

    return files, folders
end

function Elib.LoadDirectoryRecursive(basePath)
    local _, folders = Elib.LoadDirectory(basePath)

    for _, folderName in ipairs(folders) do
        Elib.LoadDirectoryRecursive(basePath .. "/" .. folderName)
    end
end

/////////////////////////
// Manual Include Helpers
/////////////////////////

function Elib.IncludeClient(path)
    local str = path .. ".lua"

    if CLIENT then
        include(str)
    elseif SERVER then
        AddCSLuaFile(str)
    end
end

function Elib.IncludeServer(path)
    if SERVER then
        include(path .. ".lua")
    end
end

function Elib.IncludeShared(path)
    Elib.IncludeServer(path)
    Elib.IncludeClient(path)
end

/////////////////////////
// Boot Sequence
/////////////////////////
// 3rd-party libs used by the framework. Loaded first so every module can use them.
Elib.RNDX = include("rndx.lua")
Elib.Papi = include("papi.lua")

local corePath = "elib/core/"

Elib.IncludeShared(corePath .. "sh_logging")
Elib.IncludeShared(corePath .. "sh_promises")
Elib.IncludeClient(corePath .. "cl_scaling")
Elib.IncludeShared(corePath .. "sh_colors")
Elib.IncludeClient(corePath .. "cl_fonts")
Elib.IncludeClient(corePath .. "cl_themes")
Elib.IncludeShared(corePath .. "sh_languages")
Elib.IncludeServer(corePath .. "sv_database")
Elib.IncludeShared("elib/sh_config")
Elib.IncludeClient(corePath .. "cl_webimages")

Elib.LoadDirectory("elib/themes")
Elib.LoadDirectory("elib/languages")

Elib.LoadDirectory("elib/elements")
Elib.IncludeShared("elib_config/sh_loader")

Elib.IncludeShared("elib_demo/sh_demo")

/////////////////////////
// Finalize
/////////////////////////
hook.Run("Elib.FullyLoaded")
Elib.FullyLoaded = true // set after so late Elib.FullyLoaded hooks still fire once

if CLIENT then return end

MsgC(Color(207, 144, 49), "\n[Elib] ",
     Color(230, 230, 230), "version " .. Elib.Version .. " loaded\n")

// Workshop content
resource.AddWorkshop("2468112758")

hook.Add("Think", "Elib.VersionChecker", function()
    hook.Remove("Think", "Elib.VersionChecker")

    http.Fetch("https://raw.githubusercontent.com/imLiaMxo/elib_v4/master/version", function(body)
        if not body then return end

        local remote = string.Trim(body)
        if remote == "" or remote == Elib.Version then return end

        local colBrand = Color(207, 144, 49)
        local colText  = Color(230, 230, 230)
        local colDim   = Color(180, 180, 180)

        MsgC(colBrand, "\n[Elib] ",
             colText, "Update available\n")

        MsgC(colDim,  "──────────────────────────────\n")

        MsgC(colBrand, "➤ ",
             colText, "Current: ", colDim, Elib.Version, "\n")

        MsgC(colBrand, "➤ ",
             colText, "Latest:  ", colBrand, remote, "\n")

        MsgC(colBrand, "➤ ",
             colText, "Get it: ",
             colDim, "https://github.com/imLiaMxo/elib_v4\n")

        MsgC(colDim,  "──────────────────────────────\n\n")

    end)
end)
