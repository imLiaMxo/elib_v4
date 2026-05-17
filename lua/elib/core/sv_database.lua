// Made by Eve Haddox & imLiaMxo

Elib.Database            = Elib.Database or {}
Elib.Database.Registered = Elib.Database.Registered or {}

local dbLog = Elib.NewLogger("Elib.Database")
Elib.Database.Logger = dbLog

if mysqloo or (util.IsBinaryModuleInstalled and util.IsBinaryModuleInstalled("mysqloo")) then
    if not mysqloo then pcall(require, "mysqloo") end
end

-- load the related files not in the autoloader for load order reasons
include("elib/core/database/sv_connection.lua")
include("elib/core/database/sv_schema.lua")
include("elib/core/database/sv_query.lua")
include("elib/core/database/sv_migration.lua")
include("elib/core/database/sv_model.lua")

/////////////////////////
// DATABASE class
/////////////////////////
local DATABASE = {}
DATABASE.__index = DATABASE

local function newDatabase(addonName)
    local db = setmetatable({}, DATABASE)

    db.addonName = addonName or "Unknown"
    db.connection = nil
    db.Schema = nil
    db._models = {}
    db._pendingMigrations = {}

    table.insert(Elib.Database.Registered, db)

    dbLog:Info("Initialised database for: " .. db.addonName)
    return db
end

Elib.NewDatabase = newDatabase
Elib.Database.New = newDatabase

/////////////////////////
// Configuration
/////////////////////////
function DATABASE:Configure(config)
    config = config or {}
    config.label = self.addonName

    self.connection = Elib.Database.NewConnection(config)
    self.Schema = Elib.Database.NewSchema(self.connection)
    return self
end

function DATABASE:IsConnected()
    return self.connection and self.connection:IsConnected() or false
end

function DATABASE:UseMySQL(enabledOrConfig)
    if type(enabledOrConfig) == "table" then
        enabledOrConfig.driver = "mysql"
        return self:Configure(enabledOrConfig)
    end

    if enabledOrConfig and not Elib.Database.MySQLAvailable then
        dbLog:Error(self.addonName .. ": cannot enable MySQL - mysqloo not installed")
        return false
    end

    self._legacyUseMySQL = enabledOrConfig == true
    return true
end

function DATABASE:SetDebug(enabled)
    if self.connection then self.connection:SetDebug(enabled) end
end

/////////////////////////
// Connection
/////////////////////////
// Returns a Promise that resolves with the database when ready.
function DATABASE:Connect(host, username, password, database, port)
    if type(host) == "string" then
        return self:Configure({
            driver   = self._legacyUseMySQL and "mysql" or "mysql",
            host     = host,
            username = username,
            password = password,
            database = database,
            port     = port,
        }):Connect()
    end

    if not self.connection then
        self:Configure({ driver = "sqlite" })
    end

    return self.connection:Connect():next(function()
        if #self._pendingMigrations == 0 then return self end

        local pending = self._pendingMigrations
        self._pendingMigrations = {}

        local function runOne(i)
            if i > #pending then return self end
            return Elib.Database.RunMigrations(self, pending[i]):next(function() return runOne(i + 1) end)
        end
        return runOne(1)
    end)
end

function DATABASE:Disconnect()
    if self.connection then
        self.connection:Disconnect()
        dbLog:Info(self.addonName .. " disconnected")
    end
end

/////////////////////////
// Raw query passthrough
/////////////////////////
function DATABASE:Query(query, params)
    if not self.connection then self:Configure({ driver = "sqlite" }) end
    return self.connection:Query(query, params)
end

function DATABASE:Execute(query, params)
    if not self.connection then self:Configure({ driver = "sqlite" }) end
    return self.connection:Execute(query, params)
end

function DATABASE:QueryRow(query, params)
    if not self.connection then self:Configure({ driver = "sqlite" }) end
    return self.connection:QueryRow(query, params)
end

function DATABASE:QueryValue(query, params)
    if not self.connection then self:Configure({ driver = "sqlite" }) end
    return self.connection:QueryValue(query, params)
end

function DATABASE:Escape(value)
    if not self.connection then self:Configure({ driver = "sqlite" }) end
    return self.connection:Escape(value)
end

/////////////////////////
// Query builder entry point
/////////////////////////
function DATABASE:Table(name)
    if not self.connection then self:Configure({ driver = "sqlite" }) end
    return Elib.Database.NewQuery(self.connection, name)
end

DATABASE.From = DATABASE.Table

/////////////////////////
// Schema convenience
/////////////////////////
function DATABASE:CreateTable(name, definerOrColumns, callback, errorCallback)
    if not self.Schema then self:Configure({ driver = "sqlite" }) end

    if type(definerOrColumns) == "function" then
        return self.Schema:Create(name, definerOrColumns)
    end

    return self:CreateTableLegacy(name, definerOrColumns, callback, errorCallback)
end

function DATABASE:DropTable(name)
    if not self.Schema then self:Configure({ driver = "sqlite" }) end
    return self.Schema:Drop(name)
end

function DATABASE:HasTable(name)
    if not self.Schema then self:Configure({ driver = "sqlite" }) end
    return self.Schema:Has(name)
end

/////////////////////////
// Migrations
/////////////////////////
function DATABASE:LoadMigrations(path)
    if not self:IsConnected() then
        table.insert(self._pendingMigrations, path)
        local p = Elib.Deferred.new()
        p:resolve({})
        return p
    end

    return Elib.Database.RunMigrations(self, path)
end

function DATABASE:MarkMigrationApplied(name)
    return Elib.Database.MarkMigrationApplied(self, name)
end

/////////////////////////
// Models
/////////////////////////
function DATABASE:DefineModel(name, config)
    local model = Elib.Database.NewModel(self, name, config)
    self._models[name] = model
    return model
end

function DATABASE:GetModel(name)
    return self._models[name]
end

/////////////////////////
// Transactions
/////////////////////////
function DATABASE:Transaction(body)
    local conn = self.connection
    if not conn then
        local p = Elib.Deferred.new()
        p:reject("not configured")
        return p
    end

    local beginSQL  = conn:IsMySQL() and "START TRANSACTION" or "BEGIN TRANSACTION"
    local commitSQL = "COMMIT"
    local rollSQL   = "ROLLBACK"

    return conn:Execute(beginSQL):next(function()
        local ok, result = pcall(body, self)
        if not ok then
            return conn:Execute(rollSQL):next(function()
                return Elib.Deferred.new():reject(result)
            end)
        end

        // body returned a promise chain on it.
        if type(result) == "table" and type(result.next) == "function" then
            return result:next(function(value)
                return conn:Execute(commitSQL):next(function() return value end)
            end, function(err)
                return conn:Execute(rollSQL):next(function()
                    return Elib.Deferred.new():reject(err)
                end)
            end)
        end

        // body returned a synchronous value just commit.
        return conn:Execute(commitSQL):next(function() return result end)
    end)
end

function DATABASE:BeginTransaction(callback, errorCallback)
    if not self.connection then self:Configure({ driver = "sqlite" }) end
    self.connection:Execute(self.connection:IsMySQL() and "START TRANSACTION" or "BEGIN TRANSACTION")
        :next(function() if callback then callback() end end,
              function(err) if errorCallback then errorCallback(err) end end)
end

function DATABASE:Commit(callback, errorCallback)
    if not self.connection then return end
    self.connection:Execute("COMMIT")
        :next(function() if callback then callback() end end,
              function(err) if errorCallback then errorCallback(err) end end)
end

function DATABASE:Rollback(callback, errorCallback)
    if not self.connection then return end
    self.connection:Execute("ROLLBACK")
        :next(function() if callback then callback() end end,
              function(err) if errorCallback then errorCallback(err) end end)
end

/////////////////////////
// Legacy CRUD shorthands (preserved from v3)
/////////////////////////
function DATABASE:Insert(tableName, data, callback, errorCallback)
    self:Table(tableName):Insert(data):Run()
        :next(function(insertId)
            if callback then callback(insertId) end
        end,
        function(err)
            if errorCallback then errorCallback(err) end
        end)
end

function DATABASE:Update(tableName, data, where, callback, errorCallback)
    if not self.connection then self:Configure({ driver = "sqlite" }) end
    local q = self:Table(tableName):Update(data)
    if where and where ~= "" then q:WhereRaw(where) end
    q:Run():next(
        function(n) if callback then callback(n) end end,
        function(err) if errorCallback then errorCallback(err) end end
    )
end

function DATABASE:Delete(tableName, where, callback, errorCallback)
    local q = self:Table(tableName):Delete()
    if where and where ~= "" then q:WhereRaw(where) end
    q:Run():next(
        function(n) if callback then callback(n) end end,
        function(err) if errorCallback then errorCallback(err) end end
    )
end

function DATABASE:Select(tableName, columns, where, callback, errorCallback)
    local q = self:Table(tableName)
    if columns and columns ~= "*" then
        if type(columns) == "table" then q:Select(unpack(columns)) else q:Select(columns) end
    end
    if where and where ~= "" then q:WhereRaw(where) end
    q:Get():next(
        function(rows) if callback then callback(rows) end end,
        function(err) if errorCallback then errorCallback(err) end end
    )
end

function DATABASE:Count(tableName, where, callback, errorCallback)
    local q = self:Table(tableName)
    if where and where ~= "" then q:WhereRaw(where) end
    q:Count():next(
        function(n) if callback then callback(n) end end,
        function(err) if errorCallback then errorCallback(err) end end
    )
end

function DATABASE:TableExists(tableName, callback)
    self:HasTable(tableName):next(function(exists)
        if callback then callback(exists) end
    end)
end

function DATABASE:CreateTableLegacy(tableName, columns, callback, errorCallback)
    local conn = self.connection
    local columnDefs, constraints = {}, {}

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

    self:Execute(query):next(
        function() if callback then callback() end end,
        function(err) if errorCallback then errorCallback(err) end end
    )
end

function DATABASE:Prepare(query)
    if not self.connection or not self.connection:IsMySQL() then
        dbLog:Error(self.addonName .. ": prepared statements require MySQL")
        return nil
    end
    if not self.connection.handle then
        dbLog:Error(self.addonName .. ": cannot prepare - not connected")
        return nil
    end
    return self.connection.handle:prepare(query)
end

/////////////////////////
// Format helper (legacy)
/////////////////////////
function DATABASE:Format(query, ...)
    if not self.connection then self:Configure({ driver = "sqlite" }) end
    local args = { ... }
    local out = {}
    for i, arg in ipairs(args) do
        if type(arg) == "string" then
            local esc = self.connection:Escape(arg)
            if esc:sub(1, 1) == "'" and esc:sub(-1) == "'" then
                esc = esc:sub(2, -2)
            end
            out[i] = esc
        elseif type(arg) == "number" then
            out[i] = tostring(arg)
        elseif type(arg) == "boolean" then
            out[i] = arg and "1" or "0"
        elseif arg == nil then
            out[i] = "NULL"
        else
            out[i] = self.connection:Escape(tostring(arg))
        end
    end
    return string.format(query, unpack(out))
end

/////////////////////////
// Global cleanup
/////////////////////////
hook.Add("ShutDown", "Elib.Database.Cleanup", function()
    for _, db in ipairs(Elib.Database.Registered) do
        db:Disconnect()
    end
end)