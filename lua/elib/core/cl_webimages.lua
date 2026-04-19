// Made by Eve Haddox & imLiaMxo

Elib.WebImages = Elib.WebImages or {}

local log          = Elib.NewLogger("Elib.WebImages")
Elib.WebImages.Log = log

// Hard cap on image size (bytes) to stop a giant download from eating memory.
local MAX_IMAGE_SIZE = 2 * 1024 * 1024 -- 2 MB
local useProxy = false
local materialCache = {}
local promiseCache  = {}
local drawing = {}
local DEFAULT_MAT_SETTINGS = "noclamp smooth mips"

file.CreateDir(Elib.DownloadPath)

/////////////////////////
// Internal Helpers
/////////////////////////
local function endsWithExtension(str)
    local fileName = str:match(".+/(.-)$")
    if not fileName then return false end

    local ext = fileName:match("^.+(%..+)$")
    return ext ~= nil and string.sub(str, -#ext) == ext
end

local function resolvePaths(url)
    local protocol = url:match("^([%a]+://)") -- dziekuje stackoverflow: https://stackoverflow.com/a/3809435
    local withoutProtocol = url

    if protocol then
        withoutProtocol = url:gsub(protocol, "", 1)
    else
        protocol = "http://"
    end

    local fileNameStart = url:find("[^/]+$")
    if not fileNameStart then return end

    local dirOnly = url:sub(#protocol + 1, fileNameStart - 1)

    local dirPath  = Elib.DownloadPath .. dirOnly
    local filePath = Elib.DownloadPath .. withoutProtocol

    return dirPath, filePath
end

/////////////////////////
// Promise-based Fetch
/////////////////////////
function Elib.WebImages.Get(url, matSettings)
    if type(url) ~= "string" or url == "" then
        local p = Elib.Deferred.new()
        p:reject("invalid url")
        return p
    end

    matSettings = matSettings or DEFAULT_MAT_SETTINGS

    local cached = materialCache[url]
    if cached then
        local p = Elib.Deferred.new()
        p:resolve(cached)
        return p
    end

    if promiseCache[url] then
        return promiseCache[url]
    end

    local dirPath, filePath = resolvePaths(url)
    if not filePath then
        local p = Elib.Deferred.new()
        p:reject("could not parse url: " .. url)
        return p
    end

    file.CreateDir(dirPath)

    local readFilePath = filePath
    if not endsWithExtension(filePath) and file.Exists(filePath .. ".png", "DATA") then
        readFilePath = filePath .. ".png"
    end

    if file.Exists(readFilePath, "DATA") then
        local mat = Material("../data/" .. readFilePath, matSettings)
        materialCache[url] = mat

        local p = Elib.Deferred.new()
        p:resolve(mat)
        return p
    end

    local promise = Elib.Deferred.new()
    promiseCache[url] = promise

    local function doFetch(viaProxy)
        local fetchUrl = viaProxy and ("https://proxy.duckduckgo.com/iu/?u=" .. url) or url -- you know what I don't even know if this still fucking works.

        http.Fetch(fetchUrl,
            function(body, len, _, code)
                if len > MAX_IMAGE_SIZE or code ~= 200 then
                    log:Warn("Fetch failed (code=" .. tostring(code) .. ", len=" .. tostring(len) .. "): " .. url)

                    local nilMat = Material("nil")
                    materialCache[url] = nilMat
                    promiseCache[url]  = nil
                    promise:reject("bad response")
                    return
                end

                local writePath = filePath
                if not endsWithExtension(filePath) then
                    writePath = filePath .. ".png"
                end

                file.Write(writePath, body)

                local mat = Material("../data/" .. writePath, matSettings)
                materialCache[url] = mat
                promiseCache[url]  = nil
                promise:resolve(mat)
            end,
            function(err)
                if not viaProxy then
                    useProxy = true
                    doFetch(true)
                    return
                end

                log:Warn("Fetch error for " .. url .. ": " .. tostring(err))

                local nilMat = Material("nil")
                materialCache[url] = nilMat
                promiseCache[url]  = nil
                promise:reject(err or "http error")
            end
        )
    end

    doFetch(useProxy)
    return promise
end

function Elib.WebImages.GetImgur(id, matSettings)
    return Elib.WebImages.Get("https://i.imgur.com/" .. id .. ".png", matSettings)
end

function Elib.WebImages.GetCached(url)
    return materialCache[url]
end

/////////////////////////
// Progress Wheel
/////////////////////////
local progressMat

local function drawProgressWheel(x, y, w, h, col)
    if not progressMat then return end

    local size = math.min(w, h)
    surface.SetMaterial(progressMat)
    surface.SetDrawColor(col.r, col.g, col.b, col.a)
    surface.DrawTexturedRectRotated(x + w * 0.5, y + h * 0.5, size, size, -CurTime() * 100)
end

Elib.WebImages.DrawProgressWheel = drawProgressWheel

hook.Add("Elib.FullyLoaded", "Elib.WebImages.LoadProgress", function()
    Elib.WebImages.Get(Elib.ProgressImageURL)
        :next(function(mat)
            progressMat = mat
        end, function(err)
            log:Warn("Could not load progress wheel image: " .. tostring(err))
        end)
end)

/////////////////////////
// Synchronous Draw Helpers
/////////////////////////
local COLOR_WHITE = Color(255, 255, 255)

function Elib.WebImages.Draw(x, y, w, h, url, col)
    col = col or COLOR_WHITE

    if not url or url == "" then
        drawProgressWheel(x, y, w, h, col)
        return
    end

    local mat = materialCache[url]

    if not mat then
        drawProgressWheel(x, y, w, h, col)

        if not drawing[url] then
            drawing[url] = true
            Elib.WebImages.Get(url):next(function() drawing[url] = nil end,
                                         function() drawing[url] = nil end)
        end
        return
    end

    surface.SetMaterial(mat)
    surface.SetDrawColor(col.r, col.g, col.b, col.a)
    surface.DrawTexturedRect(x, y, w, h)
end

function Elib.WebImages.DrawRotated(x, y, w, h, rotation, url, col)
    col = col or COLOR_WHITE

    if not url or url == "" then
        drawProgressWheel(x - w * 0.5, y - h * 0.5, w, h, col)
        return
    end

    local mat = materialCache[url]

    if not mat then
        drawProgressWheel(x - w * 0.5, y - h * 0.5, w, h, col)

        if not drawing[url] then
            drawing[url] = true
            Elib.WebImages.Get(url):next(function() drawing[url] = nil end,
                                         function() drawing[url] = nil end)
        end
        return
    end

    surface.SetMaterial(mat)
    surface.SetDrawColor(col.r, col.g, col.b, col.a)
    surface.DrawTexturedRectRotated(x, y, w, h, rotation)
end

function Elib.WebImages.DrawImgur(x, y, w, h, id, col)
    Elib.WebImages.Draw(x, y, w, h, "https://i.imgur.com/" .. id .. ".png", col)
end

function Elib.WebImages.DrawImgurRotated(x, y, w, h, rotation, id, col)
    Elib.WebImages.DrawRotated(x, y, w, h, rotation, "https://i.imgur.com/" .. id .. ".png", col)
end

/////////////////////////
// Legacy Aliases
/////////////////////////
function Elib.GetImage(url, callback, matSettings)
    local p = Elib.WebImages.Get(url, matSettings)
    if callback then
        p:next(callback, function() callback(Material("nil")) end)
    end
    return p
end

function Elib.GetImgur(id, callback, _, matSettings)
    return Elib.GetImage("https://i.imgur.com/" .. id .. ".png", callback, matSettings)
end

Elib.DrawImage          = Elib.WebImages.Draw
Elib.DrawImageRotated   = Elib.WebImages.DrawRotated
Elib.DrawImgur          = Elib.WebImages.DrawImgur
Elib.DrawImgurRotated   = Elib.WebImages.DrawImgurRotated
Elib.DrawProgressWheel  = drawProgressWheel
