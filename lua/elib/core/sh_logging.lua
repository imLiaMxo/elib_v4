// Made by Eve Haddox & imLiaMxo

Elib.Log         = Elib.Log or {}
Elib.Log.Loggers = Elib.Log.Loggers or {}

local REALM_COLOR = SERVER and Color(49, 149, 207) or Color(207, 144, 49)
local TEXT_COLOR  = Color(230, 230, 230)

Elib.Log.Levels = {
    DEBUG   = { tag = "DEBUG",   color = Color(150, 150, 150), priority = 1 },
    INFO    = { tag = "INFO",    color = Color(49, 149, 207),  priority = 2 },
    SUCCESS = { tag = "OK",      color = Color(35, 172, 35),   priority = 2 },
    WARN    = { tag = "WARN",    color = Color(230, 170, 30),  priority = 3 },
    ERROR   = { tag = "ERROR",   color = Color(192, 27, 27),   priority = 4 },
}

/////////////////////////
// Logger Object
/////////////////////////
local LOGGER = {}
LOGGER.__index = LOGGER

//  options:
//   debug        (bool) default: false
//   prefix       (string) default: "[Name]"
//   color        (Color) default: realm colour
//   writeToFile  (bool) default: false
//   filePath     (string) default: "elib/logs/<name>.txt"
function Elib.NewLogger(name, options)
    name    = name or "Unknown"
    options = options or {}

    local logger = setmetatable({}, LOGGER)
    logger.name        = name
    logger.prefix      = options.prefix or ("[" .. name .. "]")
    logger.color       = options.color or REALM_COLOR
    logger.debug       = options.debug == true
    logger.writeToFile = options.writeToFile == true
    logger.filePath    = options.filePath or ("elib/logs/" .. string.lower(name) .. ".txt")

    if logger.writeToFile then
        file.CreateDir(string.GetPathFromFilename(logger.filePath))
    end

    Elib.Log.Loggers[name] = logger
    return logger
end

function Elib.GetLogger(name)
    return Elib.Log.Loggers[name] or Elib.NewLogger(name)
end

function LOGGER:SetDebug(enabled)
    self.debug = enabled == true
end

function LOGGER:SetFileLogging(enabled, path)
    self.writeToFile = enabled == true
    if path then self.filePath = path end

    if self.writeToFile then
        file.CreateDir(string.GetPathFromFilename(self.filePath))
    end
end

local function joinArgs(args)
    local parts = {}
    for i = 1, #args do
        parts[i] = tostring(args[i])
    end
    return table.concat(parts, " ")
end

local function writeLine(logger, levelTag, text)
    if not logger.writeToFile then return end

    local stamp = os.date("[%Y-%m-%d %H:%M:%S]")
    file.Append(logger.filePath, stamp .. " [" .. levelTag .. "] " .. text .. "\n")
end

function LOGGER:Log(level, ...)
    local levelData = Elib.Log.Levels[level] or Elib.Log.Levels.INFO

    if level == "DEBUG" and not self.debug then return end

    local message = joinArgs({ ... })

    MsgC(
        self.color,     self.prefix .. " ",
        levelData.color, "[" .. levelData.tag .. "] ",
        TEXT_COLOR,      message, "\n"
    )

    writeLine(self, levelData.tag, message)
end

function LOGGER:Debug(...)   self:Log("DEBUG",   ...) end
function LOGGER:Info(...)    self:Log("INFO",    ...) end
function LOGGER:Success(...) self:Log("SUCCESS", ...) end
function LOGGER:Warn(...)    self:Log("WARN",    ...) end
function LOGGER:Error(...)   self:Log("ERROR",   ...) end

/////////////////////////
// Default Elib Logger
/////////////////////////
Elib.Logger = Elib.Logger or Elib.NewLogger("Elib", {
    color = REALM_COLOR,
    debug = false,
})
