// Made by Eve Haddox & imLiaMxo

Elib.Database = Elib.Database or {}

local log = Elib.Database.Logger

/////////////////////////
// MySQL Module Loading
/////////////////////////
local MYSQLOO_AVAILABLE = false
do
    if mysqloo then
        MYSQLOO_AVAILABLE = true
    elseif util.IsBinaryModuleInstalled and util.IsBinaryModuleInstalled("mysqloo") then
        local ok = pcall(require, "mysqloo")
        if ok and mysqloo then MYSQLOO_AVAILABLE = true end
    end
end

Elib.Database.MySQLAvailable = MYSQLOO_AVAILABLE

/////////////////////////
// CONN class
/////////////////////////
local CONN = {}
CONN.__index = CONN

function Elib.Database.NewConnection(config)
    config = config or {}

    local self = setmetatable({}, CONN)
    self.config       = config
    self.driver       = string.lower(config.driver or "sqlite")
    self.connected    = false
    self.handle       = nil
    self.queue        = {}
    self.debug        = config.debug == true
    self.label        = config.label or "Database"

    if self.driver ~= "sqlite" and self.driver ~= "mysql" then
        error("Elib.Database: invalid driver '" .. tostring(self.driver) .. "' (must be 'sqlite' or 'mysql')")
    end

    if self.driver == "mysql" and not MYSQLOO_AVAILABLE then
        error("Elib.Database: mysqloo is not installed - cannot use MySQL driver")
    end

    return self
end

function CONN:IsMySQL()      return self.driver == "mysql" end
function CONN:IsSQLite()     return self.driver == "sqlite" end
function CONN:IsConnected()  return self.connected end
function CONN:Driver()       return self.driver end
function CONN:SetDebug(b)    self.debug = b == true end

/////////////////////////
// Identifier quoting
/////////////////////////
function CONN:Quote(name)
    if type(name) ~= "string" then return tostring(name) end
    if name:find("`", 1, true) then return name end

    if name:find(".", 1, true) then
        local parts = {}
        for part in name:gmatch("[^%.]+") do
            parts[#parts + 1] = "`" .. part .. "`"
        end
        return table.concat(parts, ".")
    end

    return "`" .. name .. "`"
end

/////////////////////////
// Value escaping
/////////////////////////
function CONN:Escape(value)
    if value == nil then return "NULL" end

    if type(value) == "table" and value.__raw then
        return tostring(value.__raw)
    end

    local t = type(value)

    if t == "boolean" then
        return value and "1" or "0"

    elseif t == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return "NULL"
        end
        if value == math.floor(value) and math.abs(value) < 1e15 then
            return string.format("%d", value)
        end
        return tostring(value)

    elseif t == "string" then
        if self:IsMySQL() and self.handle then
            return "'" .. self.handle:escape(value) .. "'"
        end
        return sql.SQLStr(value)

    end

    return self:Escape(tostring(value))
end

function Elib.Database.Raw(expr)
    return { __raw = expr }
end

/////////////////////////
// Parameter binding
/////////////////////////
function CONN:Bind(query, params)
    if not params or #params == 0 then return query end

    local out, i, n = {}, 1, #query
    local pIdx = 0
    local inSingle, inDouble, inBacktick = false, false, false

    while i <= n do
        local c = query:sub(i, i)

        if inSingle then
            out[#out + 1] = c
            if c == "'" then
                if query:sub(i + 1, i + 1) == "'" then
                    out[#out + 1] = "'"
                    i = i + 1
                else
                    inSingle = false
                end
            end
        elseif inDouble then
            out[#out + 1] = c
            if c == '"' then inDouble = false end
        elseif inBacktick then
            out[#out + 1] = c
            if c == "`" then inBacktick = false end
        else
            if c == "'" then
                inSingle = true
                out[#out + 1] = c
            elseif c == '"' then
                inDouble = true
                out[#out + 1] = c
            elseif c == "`" then
                inBacktick = true
                out[#out + 1] = c
            elseif c == "?" then
                pIdx = pIdx + 1
                if pIdx > #params then
                    error("Elib.Database: too few parameters for query (placeholder #" .. pIdx .. ", got " .. #params .. ")")
                end
                out[#out + 1] = self:Escape(params[pIdx])
            else
                out[#out + 1] = c
            end
        end

        i = i + 1
    end

    return table.concat(out)
end

/////////////////////////
// Connect / Disconnect
/////////////////////////
function CONN:Connect()
    local p = Elib.Deferred.new()

    if self:IsSQLite() then
        self.connected = true
        if log then log:Info(self.label .. " using SQLite (no connection required)") end
        p:resolve(self)
        return p
    end

    if not MYSQLOO_AVAILABLE then
        p:reject("mysqloo not installed")
        return p
    end

    local cfg = self.config
    local handle = mysqloo.connect(
        cfg.host or "localhost",
        cfg.username or "",
        cfg.password or "",
        cfg.database or "",
        cfg.port or 3306
    )
    self.handle = handle

    handle.onConnected = function()
        self.connected = true
        if log then log:Success(self.label .. " connected to MySQL @ " .. (cfg.host or "?") .. ":" .. (cfg.port or 3306)) end
        self:_flushQueue()
        p:resolve(self)
    end

    handle.onConnectionFailed = function(_, err)
        self.connected = false
        if log then log:Error(self.label .. " MySQL connection failed: " .. tostring(err)) end

        local queued = self.queue
        self.queue = {}
        for _, entry in ipairs(queued) do
            entry.promise:reject(err or "connection failed")
        end

        p:reject(err or "connection failed")
    end

    handle:connect()
    return p
end

function CONN:Disconnect()
    if self.handle then
        pcall(self.handle.disconnect, self.handle)
        self.handle = nil
    end
    self.connected = false
end

/////////////////////////
// Query execution
/////////////////////////
local function normalizeRows(rows)
    if rows == nil then return {} end
    return rows
end

function CONN:_runSQLite(query, p)
    local lastErrBefore = sql.LastError() or ""

    local rows = sql.Query(query)

    if rows == false then
        local err = sql.LastError() or "unknown SQLite error"
        if log then
            log:Error(self.label .. " SQLite error: " .. err)
            log:Error("query: " .. query)
        end
        p:reject(err)
        return
    end

    if sql.LastError() and sql.LastError() ~= "" and sql.LastError() ~= lastErrBefore then
        // sometimes sql.Query returns a value
    end

    local insertId
    local raw = sql.QueryValue("SELECT last_insert_rowid()")
    if raw then insertId = tonumber(raw) end

    p:resolve({
        rows         = normalizeRows(rows),
        insertId     = insertId,
        affectedRows = nil,
    })
end

function CONN:_runMySQL(query, p)
    if not self.connected then
        self.queue[#self.queue + 1] = { query = query, promise = p }
        return
    end

    local q = self.handle:query(query)

    q.onSuccess = function(qObj, data)
        p:resolve({
            rows         = normalizeRows(data),
            insertId     = qObj:lastInsert(),
            affectedRows = qObj:affectedRows(),
        })
    end

    q.onError = function(_, err)
        if log then
            log:Error(self.label .. " MySQL error: " .. tostring(err))
            log:Error("query: " .. query)
        end
        p:reject(err)
    end

    q:start()
end

function CONN:_flushQueue()
    local pending = self.queue
    self.queue = {}
    for _, entry in ipairs(pending) do
        self:_runMySQL(entry.query, entry.promise)
    end
end

function CONN:Execute(query, params)
    if type(query) ~= "string" then
        local p = Elib.Deferred.new()
        p:reject("Elib.Database: query must be a string")
        return p
    end

    local bound = self:Bind(query, params)

    if self.debug and log then
        log:Debug("[" .. self.label .. "] " .. bound)
    end

    local p = Elib.Deferred.new()

    if self:IsSQLite() then
        self:_runSQLite(bound, p)
    else
        self:_runMySQL(bound, p)
    end

    return p
end

function CONN:Query(query, params)
    return self:Execute(query, params):next(function(res) return res.rows end)
end

function CONN:QueryRow(query, params)
    return self:Query(query, params):next(function(rows) return rows[1] end)
end

function CONN:QueryValue(query, params)
    return self:QueryRow(query, params):next(function(row)
        if not row then return nil end
        for _, v in pairs(row) do return v end
        return nil
    end)
end