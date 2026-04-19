// Made by Eve Haddox & imLiaMxo

Elib.Database            = Elib.Database or {}
Elib.Database.Registered = Elib.Database.Registered or {}

if util.IsBinaryModuleInstalled("mysqloo") then
    pcall(require, "mysqloo")
end

local DATABASE = {}
DATABASE.__index = DATABASE

local dbLog = Elib.NewLogger("Elib.Database")
Elib.Database.Logger = dbLog

local MYSQLOO_AVAILABLE = mysqloo ~= nil
if MYSQLOO_AVAILABLE then
    --dbLog:Success("MySQLoo detected - MySQL mode is available.")
else
    dbLog:Info("MySQLoo not found - only SQLite will be available.")
end

/////////////////////////
// Instance Creation
/////////////////////////
function Elib.NewDatabase(addonName)
    local db = setmetatable({}, DATABASE)

    db.addonName       = addonName or "Unknown"
    db.useMySQL        = false
    db.connected       = false
    db.mysqlConnection = nil
    db.queryQueue      = {}
    db.processing      = false
    db.debug           = false

    table.insert(Elib.Database.Registered, db)

    dbLog:Info("Initialised database for: " .. db.addonName)
    return db
end

/////////////////////////
// Configuration
/////////////////////////
function DATABASE:UseMySQL(enabled)
    if enabled and not MYSQLOO_AVAILABLE then
        dbLog:Error("Cannot enable MySQL for " .. self.addonName .. " - MySQLoo is not installed.")
        return false
    end

    self.useMySQL = enabled == true

    if self.useMySQL then
        dbLog:Info(self.addonName .. " switched to MySQL mode.")
    else
        dbLog:Info(self.addonName .. " switched to SQLite mode.")
    end

    return true
end

function DATABASE:SetDebug(enabled)
    self.debug = enabled == true
end

function DATABASE:IsConnected()
    return self.connected
end

/////////////////////////
// Connection
/////////////////////////
function DATABASE:Connect(host, username, password, database, port)
    if not self.useMySQL then
        self.connected = true
        dbLog:Success(self.addonName .. " is using SQLite (no connection required).")
        return true
    end

    if not MYSQLOO_AVAILABLE then
        dbLog:Error("Cannot connect - MySQLoo is not installed.")
        return false
    end

    port = port or 3306

    self.mysqlConnection = mysqloo.connect(host, username, password, database, port)

    self.mysqlConnection.onConnected = function()
        self.connected = true
        dbLog:Success(self.addonName .. " connected to MySQL (" .. host .. ":" .. port .. ").")
        self:ProcessQueue()
    end

    self.mysqlConnection.onConnectionFailed = function(_, err)
        self.connected = false
        dbLog:Error(self.addonName .. " MySQL connection failed: " .. tostring(err))
    end

    self.mysqlConnection:connect()
    return true
end

function DATABASE:Disconnect()
    if self.useMySQL and self.mysqlConnection then
        self.mysqlConnection:disconnect()
        self.connected = false
        dbLog:Info(self.addonName .. " disconnected from MySQL.")
    end
end

/////////////////////////
// Escaping & Formatting
/////////////////////////
function DATABASE:Escape(str)
    if str == nil then return "" end

    if self.useMySQL and self.mysqlConnection then
        return self.mysqlConnection:escape(tostring(str))
    end

    return sql.SQLStr(tostring(str), true)
end

local function toLiteral(db, value)
    local t = type(value)

    if t == "string" then
        return "'" .. db:Escape(value) .. "'"
    elseif t == "number" then
        return tostring(value)
    elseif t == "boolean" then
        return value and "1" or "0"
    elseif value == nil then
        return "NULL"
    end

    return "'" .. db:Escape(tostring(value)) .. "'"
end

function DATABASE:Format(query, ...)
    local args    = { ... }
    local escaped = {}

    for i, arg in ipairs(args) do
        if type(arg) == "string" then
            escaped[i] = self:Escape(arg)
        elseif type(arg) == "number" then
            escaped[i] = tostring(arg)
        elseif type(arg) == "boolean" then
            escaped[i] = arg and "1" or "0"
        elseif arg == nil then
            escaped[i] = "NULL"
        else
            escaped[i] = self:Escape(tostring(arg))
        end
    end

    return string.format(query, unpack(escaped))
end

/////////////////////////
// Query Execution
/////////////////////////
function DATABASE:Query(query, callback, errorCallback)
    if self.debug then
        dbLog:Debug("[" .. self.addonName .. "] " .. query)
    end

    if self.useMySQL then
        return self:QueryMySQL(query, callback, errorCallback)
    end

    return self:QuerySQLite(query, callback, errorCallback)
end

function DATABASE:QuerySQLite(query, callback, errorCallback)
    local result = sql.Query(query)

    if result == false then
        local err = sql.LastError()
        dbLog:Error("[" .. self.addonName .. "] SQLite error: " .. err)
        dbLog:Error("Query was: " .. query)

        if errorCallback then errorCallback(err) end
        return false, err
    end

    if callback then callback(result or {}) end
    return true, result
end

function DATABASE:QueryMySQL(query, callback, errorCallback)
    if not self.connected then
        table.insert(self.queryQueue, {
            query         = query,
            callback      = callback,
            errorCallback = errorCallback,
        })
        return
    end

    local q = self.mysqlConnection:query(query)

    q.onSuccess = function(_, data)
        if callback then callback(data or {}) end
    end

    q.onError = function(_, err)
        dbLog:Error("[" .. self.addonName .. "] MySQL error: " .. err)
        dbLog:Error("Query was: " .. query)
        if errorCallback then errorCallback(err) end
    end

    q:start()
    return q
end

function DATABASE:ProcessQueue()
    if self.processing or not self.connected then return end
    if #self.queryQueue == 0 then return end

    self.processing = true

    local queue     = self.queryQueue
    self.queryQueue = {}

    for _, data in ipairs(queue) do
        self:QueryMySQL(data.query, data.callback, data.errorCallback)
    end

    self.processing = false
end

/////////////////////////
// Prepared Statements (MySQL only)
/////////////////////////
function DATABASE:Prepare(query)
    if not self.useMySQL then
        dbLog:Error("[" .. self.addonName .. "] Prepared statements require MySQL.")
        return nil
    end

    if not self.connected or not self.mysqlConnection then
        dbLog:Error("[" .. self.addonName .. "] Cannot prepare statement - not connected.")
        return nil
    end

    return self.mysqlConnection:prepare(query)
end

/////////////////////////
// Transactions
/////////////////////////
function DATABASE:BeginTransaction(callback, errorCallback)
    self:Query(self.useMySQL and "START TRANSACTION" or "BEGIN TRANSACTION", callback, errorCallback)
end

function DATABASE:Commit(callback, errorCallback)
    self:Query("COMMIT", callback, errorCallback)
end

function DATABASE:Rollback(callback, errorCallback)
    self:Query("ROLLBACK", callback, errorCallback)
end

function DATABASE:Transaction(queries, callback, errorCallback)
    self:BeginTransaction(function()
        local completed = 0
        local failed    = false

        local function checkComplete()
            completed = completed + 1
            if failed then return end

            if completed >= #queries then
                self:Commit(function()
                    if callback then callback() end
                end, errorCallback)
            end
        end

        local function onError(err)
            if failed then return end
            failed = true
            self:Rollback(function()
                if errorCallback then errorCallback(err) end
            end)
        end

        for _, query in ipairs(queries) do
            self:Query(query, checkComplete, onError)
        end
    end, errorCallback)
end

/////////////////////////
// Helpers - Schema
/////////////////////////
function DATABASE:TableExists(tableName, callback)
    local query

    if self.useMySQL then
        query = string.format("SHOW TABLES LIKE '%s'", self:Escape(tableName))
    else
        query = string.format(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='%s'",
            self:Escape(tableName)
        )
    end

    self:Query(query, function(data)
        if callback then callback(data and #data > 0) end
    end)
end

function DATABASE:CreateTable(tableName, columns, callback, errorCallback)
    local columnDefs  = {}
    local constraints = {}

    for name, def in pairs(columns) do
        if name == "PRIMARY" or name == "UNIQUE" or name == "INDEX" then
            constraints[#constraints + 1] = name .. " " .. def
        else
            columnDefs[#columnDefs + 1] = name .. " " .. def
        end
    end

    for _, c in ipairs(constraints) do
        columnDefs[#columnDefs + 1] = c
    end

    local query = string.format(
        "CREATE TABLE IF NOT EXISTS %s (%s)",
        tableName,
        table.concat(columnDefs, ", ")
    )

    self:Query(query, callback, errorCallback)
end

function DATABASE:DropTable(tableName, callback, errorCallback)
    self:Query(string.format("DROP TABLE IF EXISTS %s", tableName), callback, errorCallback)
end

/////////////////////////
// Helpers
/////////////////////////
function DATABASE:Insert(tableName, data, callback, errorCallback)
    local columns = {}
    local values  = {}

    for col, val in pairs(data) do
        columns[#columns + 1] = col
        values[#values + 1]   = toLiteral(self, val)
    end

    local query = string.format(
        "INSERT INTO %s (%s) VALUES (%s)",
        tableName,
        table.concat(columns, ", "),
        table.concat(values, ", ")
    )

    self:Query(query, callback, errorCallback)
end

function DATABASE:Update(tableName, data, where, callback, errorCallback)
    local sets = {}

    for col, val in pairs(data) do
        sets[#sets + 1] = col .. " = " .. toLiteral(self, val)
    end

    local query = string.format(
        "UPDATE %s SET %s WHERE %s",
        tableName,
        table.concat(sets, ", "),
        where
    )

    self:Query(query, callback, errorCallback)
end

function DATABASE:Delete(tableName, where, callback, errorCallback)
    self:Query(string.format("DELETE FROM %s WHERE %s", tableName, where), callback, errorCallback)
end

function DATABASE:Select(tableName, columns, where, callback, errorCallback)
    local columnStr = type(columns) == "table" and table.concat(columns, ", ") or (columns or "*")
    local whereStr  = where and (" WHERE " .. where) or ""

    self:Query(
        string.format("SELECT %s FROM %s%s", columnStr, tableName, whereStr),
        callback,
        errorCallback
    )
end

function DATABASE:Count(tableName, where, callback, errorCallback)
    local whereStr = where and (" WHERE " .. where) or ""

    self:Query(
        string.format("SELECT COUNT(*) as count FROM %s%s", tableName, whereStr),
        function(data)
            if callback and data and data[1] then
                callback(tonumber(data[1].count) or 0)
            end
        end,
        errorCallback
    )
end

/////////////////////////
// Global Cleanup
/////////////////////////
hook.Add("ShutDown", "Elib.Database.Cleanup", function()
    for _, db in ipairs(Elib.Database.Registered) do
        db:Disconnect()
    end
end)
