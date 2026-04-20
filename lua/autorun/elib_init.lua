// Made by Eve Haddox & imLiaMxo
//
// Elib v4 - a standalone UI & systems library for Garry's Mod.
// This version is fully self-contained and no longer depends on Pixel UI.

Elib         = Elib or {}
Elib.Version = "4.0.0-alpha"

Elib._SecureClientQueue    = Elib._SecureClientQueue or {}
Elib._SecureClientQueueSet = Elib._SecureClientQueueSet or {}
Elib._SecureBootPending    = Elib._SecureBootPending or CLIENT

local function queueClientFile(path)
    if not SERVER then return end
    if not path or path == "" then return end

    local filePath = string.EndsWith(path, ".lua") and path or (path .. ".lua")
    if Elib._SecureClientQueueSet[filePath] then return end

    Elib._SecureClientQueueSet[filePath] = true
    Elib._SecureClientQueue[#Elib._SecureClientQueue + 1] = filePath
end

local function markFullyLoaded()
    if Elib.FullyLoaded then return end

    hook.Run("Elib.FullyLoaded")
    Elib.FullyLoaded = true
end

/////////////////////////
// Automatic Loader
/////////////////////////
function Elib.LoadDirectory(path)
    local files, folders = file.Find(path .. "/*", "LUA")

    for _, fileName in ipairs(files) do
        local filePath = path .. "/" .. fileName

        if CLIENT then
            if not Elib._SecureBootPending then
                include(filePath)
            end
        else
            if fileName:StartWith("cl_") then
                queueClientFile(filePath)
            elseif fileName:StartWith("sh_") then
                queueClientFile(filePath)
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
        if not Elib._SecureBootPending then
            include(str)
        end
    elseif SERVER then
        queueClientFile(str)
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
if CLIENT then
    local ADDON_READY = false
    local SESSION_KEY = nil

    local function xor_str(str, key)
        local out = {}
        local klen = #key
        if klen == 0 then return str end

        for i = 1, #str do
            local c = string.byte(str, i)
            local k = string.byte(key, (i - 1) % klen + 1)
            out[i] = string.char(bit.bxor(c, k))
        end

        return table.concat(out)
    end

    net.Receive("Elib.Secure.Auth", function()
        if ADDON_READY then return end

        local ok = net.ReadBool()
        if not ok then return end

        SESSION_KEY = net.ReadString() or ""
        if SESSION_KEY == "" then return end

        net.Start("Elib.Secure.Request")
            net.WriteString(SESSION_KEY)
        net.SendToServer()
    end)

    net.Receive("Elib.Secure.Boot", function()
        if ADDON_READY then return end
        if not SESSION_KEY or SESSION_KEY == "" then return end

        local len = net.ReadUInt(24)
        if not len or len <= 0 or len > 16000000 then return end

        local encoded = net.ReadData(len)
        if not encoded or #encoded ~= len then return end

        local compressed = xor_str(encoded, SESSION_KEY)
        local ok_decompress, json = pcall(util.Decompress, compressed)
        if not ok_decompress or not json or json == "" then return end

        local ok_decode, payload = pcall(util.JSONToTable, json)
        if not ok_decode or not istable(payload) or not istable(payload.files) then return end

        Elib._SecureBootPending = true

        for _, entry in ipairs(payload.files) do
            if istable(entry) and isstring(entry.path) and isstring(entry.code) and entry.code ~= "" then
                local chunk = CompileString(entry.code, entry.path, false)
                if isfunction(chunk) then
                    local ok_run, err = pcall(chunk)
                    if not ok_run then
                        ErrorNoHalt("[Elib] secure load runtime error in " .. tostring(entry.path) .. ": " .. tostring(err) .. "\n")
                    end
                else
                    ErrorNoHalt("[Elib] secure load compile error in " .. tostring(entry.path) .. ": " .. tostring(chunk) .. "\n")
                end
            end
        end

        Elib._SecureBootPending = false
        markFullyLoaded()
        ADDON_READY = true
    end)

    return
end

util.AddNetworkString("Elib.Secure.Auth")
util.AddNetworkString("Elib.Secure.Request")
util.AddNetworkString("Elib.Secure.Boot")

local SECURE_COMPRESSED

local function xor_str(str, key)
    local out = {}
    local klen = #key
    if klen == 0 then return str end

    for i = 1, #str do
        local c = string.byte(str, i)
        local k = string.byte(key, (i - 1) % klen + 1)
        out[i] = string.char(bit.bxor(c, k))
    end

    return table.concat(out)
end

local function buildSecurePayload()
    if SECURE_COMPRESSED then return true end

    local files = {}

    for _, filePath in ipairs(Elib._SecureClientQueue) do
        local code = file.Read(filePath, "LUA")

        if not code or code == "" then
            MsgC(Color(207, 144, 49), "[Elib] ", Color(230, 230, 230), "Missing secure file: " .. tostring(filePath) .. "\n")
        else
            files[#files + 1] = {
                path = filePath,
                code = code,
            }
        end
    end

    local json = util.TableToJSON({
        version = 1,
        files = files,
    })

    if not json or json == "" then return false end

    SECURE_COMPRESSED = util.Compress(json)
    if not SECURE_COMPRESSED then return false end

    return true
end

hook.Add("PlayerInitialSpawn", "Elib.Secure.Auth", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not buildSecurePayload() then return end

    local steam64 = ply:SteamID64() or "0"
    local seed = steam64 .. os.time() .. tostring(math.random(1, 1000000000))
    local sessionKey = util.CRC(seed)

    ply.ElibSecureSessionKey = sessionKey

    net.Start("Elib.Secure.Auth")
        net.WriteBool(true)
        net.WriteString(sessionKey)
    net.Send(ply)
end)

net.Receive("Elib.Secure.Request", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not buildSecurePayload() then return end

    local key = net.ReadString() or ""
    if key == "" or not ply.ElibSecureSessionKey or key ~= ply.ElibSecureSessionKey then return end

    local encoded = xor_str(SECURE_COMPRESSED, key)
    local len = #encoded
    if len <= 0 or len > 16000000 then return end

    net.Start("Elib.Secure.Boot")
        net.WriteUInt(len, 24)
        net.WriteData(encoded, len)
    net.Send(ply)
end)

markFullyLoaded()

MsgC(Color(207, 144, 49), "\n[Elib] ", Color(230, 230, 230), "version " .. Elib.Version .. " loaded\n")

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

        MsgC(colBrand, "\n[Elib] ", colText, "Update available\n")
        MsgC(colDim,  "──────────────────────────────\n")
        MsgC(colBrand, "➤ ", colText, "Current: ", colDim, Elib.Version, "\n")
        MsgC(colBrand, "➤ ", colText, "Latest:  ", colBrand, remote, "\n")
        MsgC(colBrand, "➤ ", colText, "Get it: ", colDim, "https://github.com/imLiaMxo/elib_v4\n")
        MsgC(colDim,  "──────────────────────────────\n\n")

    end)
end)