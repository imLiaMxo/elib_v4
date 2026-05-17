// Made by Eve Haddox & imLiaMxo

Elib.Database = Elib.Database or {}

/////////////////////////
// Column class
/////////////////////////
local COLUMN = {}
COLUMN.__index = COLUMN

local function newColumn(name, ctype, isMySQL)
    return setmetatable({
        _name      = name,
        _type      = ctype,
        _isMySQL   = isMySQL,
        _length    = nil,
        _decimals  = nil,
        _primary   = false,
        _unique    = false,
        _nullable  = false,
        _unsigned  = false,
        _increments = false,
        _default   = nil,
        _hasDefault = false,
        _foreign   = nil,
        _onUpdate  = nil,
    }, COLUMN)
end

function COLUMN:Length(n)     self._length = n; return self end
function COLUMN:Decimals(n)   self._decimals = n; return self end
function COLUMN:Primary()     self._primary = true; return self end
function COLUMN:Unique()      self._unique = true; return self end
function COLUMN:Nullable()    self._nullable = true; return self end
function COLUMN:NotNull()     self._nullable = false; return self end
function COLUMN:Unsigned()    self._unsigned = true; return self end
function COLUMN:Increments()  self._increments = true; return self end

function COLUMN:Default(value)
    self._hasDefault = true
    self._default = value
    return self
end

function COLUMN:References(table, column)
    self._foreign = { table = table, column = column or "id" }
    return self
end

function COLUMN:OnDelete(action)
    self._foreign = self._foreign or {}
    self._foreign.onDelete = action
    return self
end

function COLUMN:OnUpdate(action)
    if self._foreign then
        self._foreign.onUpdate = action
    else
        self._onUpdate = action
    end
    return self
end

/////////////////////////
// Column SQL emission
/////////////////////////
local function escapeDefault(val, isMySQL)
    if val == nil then return "NULL" end

    if type(val) == "table" and val.__raw then
        return tostring(val.__raw)
    end

    local t = type(val)
    if t == "boolean" then return val and "1" or "0" end
    if t == "number" then return tostring(val) end
    // string
    return "'" .. tostring(val):gsub("'", "''") .. "'"
end

function COLUMN:_buildString()
    local isMySQL = self._isMySQL
    local typeName = self._type:upper()

    if not isMySQL then
        if typeName == "INT"        then typeName = "INTEGER" end
        if typeName == "JSON"       then typeName = "TEXT"    end
        if typeName == "BOOLEAN"    then typeName = "INTEGER" end
        if typeName == "DATETIME"   then typeName = "TEXT"    end
        if typeName == "TIMESTAMP"  then typeName = "INTEGER" end
        if typeName == "LONGTEXT"   then typeName = "TEXT"    end
        if typeName == "TINYINT"    then typeName = "INTEGER" end
        if typeName == "SMALLINT"   then typeName = "INTEGER" end
        if typeName == "DOUBLE"     then typeName = "REAL"    end
        if typeName == "FLOAT"      then typeName = "REAL"    end
        if typeName == "DECIMAL"    then typeName = "NUMERIC" end
    end

    local parts = { "`" .. self._name .. "`" }

    local typeStr = typeName
    if self._length and (typeName == "VARCHAR" or typeName == "CHAR" or typeName == "DECIMAL" or typeName == "NUMERIC") then
        if self._decimals then
            typeStr = typeStr .. "(" .. self._length .. "," .. self._decimals .. ")"
        else
            typeStr = typeStr .. "(" .. self._length .. ")"
        end
    end
    parts[#parts + 1] = typeStr

    if self._unsigned and isMySQL then
        parts[#parts + 1] = "UNSIGNED"
    end

    if self._increments then
        if isMySQL then
            parts[#parts + 1] = "AUTO_INCREMENT"
        else
            parts[#parts + 1] = "PRIMARY KEY AUTOINCREMENT"
            self._primary = false
        end
    end

    if self._primary and not self._increments then
        parts[#parts + 1] = "PRIMARY KEY"
    end

    if self._unique then
        parts[#parts + 1] = "UNIQUE"
    end

    if self._nullable then
        parts[#parts + 1] = "NULL"
    elseif not self._increments then
        parts[#parts + 1] = "NOT NULL"
    end

    if self._hasDefault then
        parts[#parts + 1] = "DEFAULT " .. escapeDefault(self._default, isMySQL)
    end

    if self._onUpdate then
        if isMySQL then
            parts[#parts + 1] = "ON UPDATE " .. tostring(self._onUpdate)
        end
    end

    return table.concat(parts, " ")
end

/////////////////////////
// Table builder
/////////////////////////
local TABLE = {}
TABLE.__index = TABLE

local function newTable(connection, name)
    return setmetatable({
        _conn    = connection,
        _name    = name,
        _columns = {},
        _indexes = {},
        _foreigns = {},
    }, TABLE)
end

function TABLE:_addColumn(name, ctype)
    local col = newColumn(name, ctype, self._conn:IsMySQL())
    self._columns[#self._columns + 1] = col
    return col
end

// Type shortcuts
function TABLE:Integer(name)      return self:_addColumn(name, "INT") end
function TABLE:BigInteger(name)   return self:_addColumn(name, "BIGINT") end
function TABLE:SmallInteger(name) return self:_addColumn(name, "SMALLINT") end
function TABLE:TinyInteger(name)  return self:_addColumn(name, "TINYINT") end
function TABLE:String(name, len)  return self:_addColumn(name, "VARCHAR"):Length(len or 255) end
function TABLE:Char(name, len)    return self:_addColumn(name, "CHAR"):Length(len or 255) end
function TABLE:Text(name)         return self:_addColumn(name, "TEXT") end
function TABLE:LongText(name)     return self:_addColumn(name, "LONGTEXT") end
function TABLE:Boolean(name)      return self:_addColumn(name, "BOOLEAN") end
function TABLE:Float(name)        return self:_addColumn(name, "FLOAT") end
function TABLE:Double(name)       return self:_addColumn(name, "DOUBLE") end
function TABLE:Decimal(name, len, dec)
    local col = self:_addColumn(name, "DECIMAL")
    if len then col:Length(len) end
    if dec then col:Decimals(dec) end
    return col
end
function TABLE:Json(name)         return self:_addColumn(name, "JSON") end
function TABLE:Date(name)         return self:_addColumn(name, "DATE") end
function TABLE:DateTime(name)     return self:_addColumn(name, "DATETIME") end
function TABLE:Time(name)         return self:_addColumn(name, "TIME") end
function TABLE:Timestamp(name)    return self:_addColumn(name, "TIMESTAMP") end

// Useful things to have as standard
function TABLE:SteamID(name)      return self:String(name, 24) end
function TABLE:SteamID64(name)    return self:Char(name, 21) end

function TABLE:Increments(name)
    name = name or "id"
    local col = self:Integer(name):Increments():Primary()
    if self._conn:IsMySQL() then col:Unsigned() end
    return col
end

function TABLE:Timestamps()
    self:Integer("created_at"):Nullable()
    self:Integer("updated_at"):Nullable()
end

function TABLE:Index(columns, unique)
    if type(columns) == "string" then columns = { columns } end
    self._indexes[#self._indexes + 1] = { columns = columns, unique = unique == true }
    return self
end

function TABLE:Unique(columns)
    return self:Index(columns, true)
end

function TABLE:PrimaryKey(columns)
    if type(columns) == "string" then columns = { columns } end
    self._primaryKey = columns
    return self
end

/////////////////////////
// SQL generation
/////////////////////////
function TABLE:_buildCreateSQL()
    local conn = self._conn
    local lines = {}

    for _, col in ipairs(self._columns) do
        lines[#lines + 1] = col:_buildString()
    end

    if self._primaryKey then
        local quoted = {}
        for _, c in ipairs(self._primaryKey) do
            quoted[#quoted + 1] = "`" .. c .. "`"
        end
        lines[#lines + 1] = "PRIMARY KEY (" .. table.concat(quoted, ", ") .. ")"
    end

    return string.format(
        "CREATE TABLE IF NOT EXISTS %s (\n  %s\n)",
        conn:Quote(self._name),
        table.concat(lines, ",\n  ")
    )
end

function TABLE:_buildIndexSQLs()
    local conn = self._conn
    local out = {}
    for i, idx in ipairs(self._indexes) do
        local quoted = {}
        for _, c in ipairs(idx.columns) do
            quoted[#quoted + 1] = "`" .. c .. "`"
        end
        local indexName = self._name .. "_" .. table.concat(idx.columns, "_") .. "_idx"
        out[#out + 1] = string.format(
            "CREATE %sINDEX IF NOT EXISTS %s ON %s (%s)",
            idx.unique and "UNIQUE " or "",
            conn:Quote(indexName),
            conn:Quote(self._name),
            table.concat(quoted, ", ")
        )
    end
    return out
end

/////////////////////////
// Schema-level operations
/////////////////////////
local Schema = {}
Schema.__index = Schema

function Elib.Database.NewSchema(connection)
    return setmetatable({ _conn = connection }, Schema)
end

function Schema:Create(name, definer)
    local builder = newTable(self._conn, name)
    if definer then
        local ok, err = pcall(definer, builder)
        if not ok then
            local p = Elib.Deferred.new()
            p:reject("schema definer error: " .. tostring(err))
            return p
        end
    end

    local createSQL = builder:_buildCreateSQL()
    local indexSQLs = builder:_buildIndexSQLs()

    return self._conn:Execute(createSQL):next(function()
        if #indexSQLs == 0 then return true end

        local function runOne(i)
            if i > #indexSQLs then return true end
            return self._conn:Execute(indexSQLs[i]):next(function() return runOne(i + 1) end)
        end
        return runOne(1)
    end)
end

function Schema:Drop(name)
    return self._conn:Execute(string.format("DROP TABLE IF EXISTS %s", self._conn:Quote(name)))
end

function Schema:Rename(from, to)
    return self._conn:Execute(string.format(
        "ALTER TABLE %s RENAME TO %s",
        self._conn:Quote(from),
        self._conn:Quote(to)
    ))
end

function Schema:Has(name)
    if self._conn:IsMySQL() then
        return self._conn:QueryValue(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?",
            { name }
        ):next(function(count) return tonumber(count or 0) > 0 end)
    else
        return self._conn:QueryValue(
            "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
            { name }
        ):next(function(result) return result ~= nil end)
    end
end