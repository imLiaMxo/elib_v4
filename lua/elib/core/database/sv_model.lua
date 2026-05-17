// Made by Eve Haddox & imLiaMxo

Elib.Database = Elib.Database or {}

/////////////////////////
// Cast helpers
/////////////////////////
local function castFromDB(value, castType)
    if value == nil then return nil end

    if castType == "json" then
        if type(value) ~= "string" then return value end
        local ok, decoded = pcall(util.JSONToTable, value)
        if ok then return decoded end
        return nil

    elseif castType == "boolean" then
        if type(value) == "boolean" then return value end
        // SQLite returns "1"/"0" as strings.
        return tostring(value) == "1" or value == true

    elseif castType == "number" then
        return tonumber(value)

    elseif castType == "string" then
        return tostring(value)
    end

    return value
end

local function castToDB(value, castType)
    if value == nil then return nil end

    if castType == "json" then
        if type(value) == "string" then return value end
        return util.TableToJSON(value or {})

    elseif castType == "boolean" then
        return value and 1 or 0
    end

    return value
end

local function applyCasts(row, casts, direction)
    if not casts or not row then return row end

    local cast = direction == "from" and castFromDB or castToDB

    for col, ctype in pairs(casts) do
        if row[col] ~= nil then
            row[col] = cast(row[col], ctype)
        end
    end

    return row
end

/////////////////////////
// Instance metatable
/////////////////////////
local function buildInstanceMeta(model)
    local meta = {}
    meta.__index = meta

    function meta:Save()
        local pk    = model._primaryKey
        local table_ = model._table
        local db    = model._db

        local payload = {}
        if model._fillable then
            for _, col in ipairs(model._fillable) do
                if self[col] ~= nil then payload[col] = self[col] end
            end
        else
            for k, v in pairs(self) do
                if type(v) ~= "function" and k ~= pk then
                    payload[k] = v
                end
            end
        end

        if self[pk] ~= nil then payload[pk] = self[pk] end

        if model._timestamps then
            local now = os.time()
            payload.updated_at = now
            if self[pk] == nil then
                payload.created_at = now
            end
        end

        applyCasts(payload, model._casts, "to")

        if self[pk] == nil then
            // INSERT
            return db:Table(table_):Insert(payload):Run():next(function(insertId)
                if insertId and insertId ~= true then
                    self[pk] = insertId
                end
                if model._timestamps then
                    self.created_at = payload.created_at
                    self.updated_at = payload.updated_at
                end
                return self
            end)
        else
            // UPDATE
            local writeData = {}
            for k, v in pairs(payload) do
                if k ~= pk then writeData[k] = v end
            end
            return db:Table(table_)
                :Where(pk, "=", self[pk])
                :Update(writeData)
                :Run()
                :next(function() return self end)
        end
    end

    function meta:Delete()
        local pk = model._primaryKey
        if self[pk] == nil then
            local p = Elib.Deferred.new()
            p:reject("cannot delete unsaved instance")
            return p
        end
        return model._db:Table(model._table):Where(pk, "=", self[pk]):Delete():Run()
    end

    function meta:Refresh()
        local pk = model._primaryKey
        if self[pk] == nil then
            local p = Elib.Deferred.new()
            p:reject("cannot refresh unsaved instance")
            return p
        end
        return model:Find(self[pk]):next(function(fresh)
            if not fresh then return self end
            for k, v in pairs(fresh) do
                if type(v) ~= "function" then self[k] = v end
            end
            return self
        end)
    end

    function meta:ToTable()
        local out = {}
        for k, v in pairs(self) do
            if type(v) ~= "function" then out[k] = v end
        end
        return out
    end

    return meta
end

local function hydrateRow(model, row)
    if not row then return nil end
    applyCasts(row, model._casts, "from")
    return setmetatable(row, model._instanceMeta)
end

local function hydrateRows(model, rows)
    if not rows then return {} end
    for i, r in ipairs(rows) do rows[i] = hydrateRow(model, r) end
    return rows
end

/////////////////////////
// Model class
/////////////////////////
local MODEL = {}
MODEL.__index = MODEL

function Elib.Database.NewModel(db, name, config)
    if not config or not config.table then
        error("Elib.Database.NewModel: config.table is required")
    end

    local model = setmetatable({
        _db         = db,
        _name       = name,
        _table      = config.table,
        _primaryKey = config.primaryKey or "id",
        _fillable   = config.fillable,
        _casts      = config.casts,
        _timestamps = config.timestamps == true,
    }, MODEL)

    model._instanceMeta = buildInstanceMeta(model)
    return model
end

function MODEL:New(attrs)
    local row = {}
    if type(attrs) == "table" then
        for k, v in pairs(attrs) do row[k] = v end
    end
    return setmetatable(row, self._instanceMeta)
end

function MODEL:Create(attrs)
    local instance = self:New(attrs)
    return instance:Save()
end

function MODEL:Find(id)
    return self._db:Table(self._table)
        :Where(self._primaryKey, "=", id)
        :First()
        :next(function(row) return hydrateRow(self, row) end)
end

function MODEL:FindOrFail(id)
    return self:Find(id):next(function(instance)
        if not instance then
            return Elib.Deferred.new():reject(self._name .. " #" .. tostring(id) .. " not found")
        end
        return instance
    end)
end

function MODEL:Query()
    local q = self._db:Table(self._table)

    local model = self
    local origGet = q.Get
    function q:Get()
        return origGet(self):next(function(rows) return hydrateRows(model, rows) end)
    end

    local origFirst = q.First
    function q:First()
        return origFirst(self):next(function(row) return hydrateRow(model, row) end)
    end

    q.All = q.Get

    return q
end

function MODEL:Where(col, op, val) return self:Query():Where(col, op, val) end
function MODEL:All()               return self:Query():Get() end
function MODEL:Count()             return self._db:Table(self._table):Count() end

function MODEL:Destroy(idOrIds)
    local ids = type(idOrIds) == "table" and idOrIds or { idOrIds }
    if #ids == 0 then
        local p = Elib.Deferred.new()
        p:resolve(0)
        return p
    end
    return self._db:Table(self._table):WhereIn(self._primaryKey, ids):Delete():Run()
end