// Made by Eve Haddox & imLiaMxo

Elib.Database = Elib.Database or {}

local OP_SELECT, OP_INSERT, OP_UPDATE, OP_DELETE = 1, 2, 3, 4

/////////////////////////
// QueryBuilder class
/////////////////////////
local QB = {}
QB.__index = QB

function Elib.Database.NewQuery(connection, tableName)
    return setmetatable({
        _conn       = connection,
        _table      = tableName,
        _op         = OP_SELECT,
        _columns    = nil,
        _wheres     = {},
        _joins      = {},
        _orders     = {},
        _groups     = nil,
        _havings    = {},
        _limit      = nil,
        _offset     = nil,
        _insertRows = nil,
        _updateData = nil,
        _upsertConflict = nil,
    }, QB)
end

/////////////////////////
// SELECT
/////////////////////////
function QB:Select(...)
    local args = { ... }
    if #args == 0 then
        self._columns = nil
    else
        if #args == 1 and type(args[1]) == "table" and not args[1].__raw then
            self._columns = args[1]
        else
            self._columns = args
        end
    end
    self._op = OP_SELECT
    return self
end

function QB:Distinct()
    self._distinct = true
    return self
end

/////////////////////////
// WHERE
/////////////////////////
local function pushWhere(self, boolean, col, op, val)
    if val == nil then
        val = op
        op = "="
    end

    self._wheres[#self._wheres + 1] = {
        type    = "basic",
        column  = col,
        op      = op,
        value   = val,
        boolean = boolean,
    }
    return self
end

function QB:Where(col, op, val)   return pushWhere(self, "AND", col, op, val) end
function QB:OrWhere(col, op, val) return pushWhere(self, "OR",  col, op, val) end

function QB:WhereIn(col, values, boolean)
    self._wheres[#self._wheres + 1] = {
        type = "in", column = col, values = values, boolean = boolean or "AND",
    }
    return self
end

function QB:OrWhereIn(col, values) return self:WhereIn(col, values, "OR") end

function QB:WhereNull(col, boolean)
    self._wheres[#self._wheres + 1] = {
        type = "null", column = col, boolean = boolean or "AND",
    }
    return self
end

function QB:WhereNotNull(col, boolean)
    self._wheres[#self._wheres + 1] = {
        type = "notnull", column = col, boolean = boolean or "AND",
    }
    return self
end

function QB:WhereRaw(expression, params, boolean)
    self._wheres[#self._wheres + 1] = {
        type = "raw", expression = expression, params = params or {}, boolean = boolean or "AND",
    }
    return self
end

/////////////////////////
// JOINs
/////////////////////////
local function pushJoin(self, kind, tbl, leftCol, op, rightCol)
    if rightCol == nil then
        rightCol = op
        op = "="
    end
    self._joins[#self._joins + 1] = {
        kind = kind, table = tbl, left = leftCol, op = op, right = rightCol,
    }
    return self
end

function QB:Join(tbl, leftCol, op, rightCol)      return pushJoin(self, "INNER JOIN", tbl, leftCol, op, rightCol) end
function QB:LeftJoin(tbl, leftCol, op, rightCol)  return pushJoin(self, "LEFT JOIN",  tbl, leftCol, op, rightCol) end
function QB:RightJoin(tbl, leftCol, op, rightCol) return pushJoin(self, "RIGHT JOIN", tbl, leftCol, op, rightCol) end

/////////////////////////
// ORDER / GROUP / LIMIT / OFFSET
/////////////////////////
function QB:OrderBy(col, dir)
    dir = string.upper(dir or "ASC")
    if dir ~= "ASC" and dir ~= "DESC" then dir = "ASC" end
    self._orders[#self._orders + 1] = { column = col, direction = dir }
    return self
end

function QB:GroupBy(...)
    local args = { ... }
    if #args == 1 and type(args[1]) == "table" then
        self._groups = args[1]
    else
        self._groups = args
    end
    return self
end

function QB:Having(col, op, val)
    if val == nil then val = op; op = "=" end
    self._havings[#self._havings + 1] = { column = col, op = op, value = val }
    return self
end

function QB:Limit(n)  self._limit = n;  return self end
function QB:Offset(n) self._offset = n; return self end

/////////////////////////
// Mutations
/////////////////////////
function QB:Insert(rowOrRows)
    self._op = OP_INSERT
    if type(rowOrRows) ~= "table" then
        error("Elib.Database: Insert() expects a table")
    end

    local isList = false
    if rowOrRows[1] and type(rowOrRows[1]) == "table" then
        isList = true
    end

    self._insertRows = isList and rowOrRows or { rowOrRows }
    return self
end

function QB:Upsert(rowOrRows, conflictColumns)
    self:Insert(rowOrRows)
    self._upsertConflict = conflictColumns or {}
    return self
end

function QB:Update(data)
    self._op = OP_UPDATE
    if type(data) ~= "table" then
        error("Elib.Database: Update() expects a table")
    end
    self._updateData = data
    return self
end

function QB:Delete()
    self._op = OP_DELETE
    return self
end

/////////////////////////
// SQL generation
/////////////////////////
local function quoteCol(conn, col)
    if type(col) == "table" and col.__raw then return tostring(col.__raw) end
    if type(col) ~= "string" then return tostring(col) end
    if col == "*" then return "*" end
    if col:find("%(") then return col end

    local body, alias = col:match("^(.-)%s+[Aa][Ss]%s+(.+)$")
    if body and alias then
        return conn:Quote(body) .. " AS " .. conn:Quote(alias)
    end

    return conn:Quote(col)
end

function QB:_buildSelect()
    local conn = self._conn
    local parts = { "SELECT" }

    if self._distinct then parts[#parts + 1] = "DISTINCT" end

    if self._columns then
        local cols = {}
        for _, c in ipairs(self._columns) do
            cols[#cols + 1] = quoteCol(conn, c)
        end
        parts[#parts + 1] = table.concat(cols, ", ")
    else
        parts[#parts + 1] = "*"
    end

    parts[#parts + 1] = "FROM " .. conn:Quote(self._table)

    for _, j in ipairs(self._joins) do
        parts[#parts + 1] = string.format(
            "%s %s ON %s %s %s",
            j.kind,
            conn:Quote(j.table),
            quoteCol(conn, j.left),
            j.op,
            quoteCol(conn, j.right)
        )
    end

    local whereSQL = self:_buildWheres()
    if whereSQL ~= "" then parts[#parts + 1] = whereSQL end

    if self._groups then
        local gs = {}
        for _, g in ipairs(self._groups) do gs[#gs + 1] = quoteCol(conn, g) end
        parts[#parts + 1] = "GROUP BY " .. table.concat(gs, ", ")
    end

    if #self._havings > 0 then
        local hs = {}
        for _, h in ipairs(self._havings) do
            hs[#hs + 1] = quoteCol(conn, h.column) .. " " .. h.op .. " " .. conn:Escape(h.value)
        end
        parts[#parts + 1] = "HAVING " .. table.concat(hs, " AND ")
    end

    if #self._orders > 0 then
        local os = {}
        for _, o in ipairs(self._orders) do
            os[#os + 1] = quoteCol(conn, o.column) .. " " .. o.direction
        end
        parts[#parts + 1] = "ORDER BY " .. table.concat(os, ", ")
    end

    if self._limit  then parts[#parts + 1] = "LIMIT "  .. tonumber(self._limit)  end
    if self._offset then parts[#parts + 1] = "OFFSET " .. tonumber(self._offset) end

    return table.concat(parts, " ")
end

function QB:_buildWheres()
    if #self._wheres == 0 then return "" end

    local conn = self._conn
    local out = { "WHERE" }

    for i, w in ipairs(self._wheres) do
        if i > 1 then out[#out + 1] = w.boolean end

        if w.type == "basic" then
            out[#out + 1] = quoteCol(conn, w.column) .. " " .. w.op .. " " .. conn:Escape(w.value)

        elseif w.type == "in" then
            local vals = {}
            for _, v in ipairs(w.values) do vals[#vals + 1] = conn:Escape(v) end
            if #vals == 0 then
                out[#out + 1] = "0 = 1" -- empty IN clause never matches
            else
                out[#out + 1] = quoteCol(conn, w.column) .. " IN (" .. table.concat(vals, ", ") .. ")"
            end

        elseif w.type == "null" then
            out[#out + 1] = quoteCol(conn, w.column) .. " IS NULL"

        elseif w.type == "notnull" then
            out[#out + 1] = quoteCol(conn, w.column) .. " IS NOT NULL"

        elseif w.type == "raw" then
            out[#out + 1] = conn:Bind(w.expression, w.params)
        end
    end

    return table.concat(out, " ")
end

function QB:_buildInsert()
    local conn = self._conn
    if not self._insertRows or #self._insertRows == 0 then
        error("Elib.Database: nothing to insert")
    end

    local cols = {}
    for k in pairs(self._insertRows[1]) do cols[#cols + 1] = k end
    table.sort(cols)

    local rowStrs = {}
    for _, row in ipairs(self._insertRows) do
        local vals = {}
        for _, c in ipairs(cols) do
            vals[#vals + 1] = conn:Escape(row[c])
        end
        rowStrs[#rowStrs + 1] = "(" .. table.concat(vals, ", ") .. ")"
    end

    local quotedCols = {}
    for _, c in ipairs(cols) do quotedCols[#quotedCols + 1] = conn:Quote(c) end

    local sql = string.format(
        "INSERT INTO %s (%s) VALUES %s",
        conn:Quote(self._table),
        table.concat(quotedCols, ", "),
        table.concat(rowStrs, ", ")
    )

    if self._upsertConflict then
        if conn:IsMySQL() then
            local sets = {}
            for _, c in ipairs(cols) do
                local q = conn:Quote(c)
                sets[#sets + 1] = q .. " = VALUES(" .. q .. ")"
            end
            sql = sql .. " ON DUPLICATE KEY UPDATE " .. table.concat(sets, ", ")
        else
            if #self._upsertConflict > 0 then
                local conflictCols = {}
                for _, c in ipairs(self._upsertConflict) do
                    conflictCols[#conflictCols + 1] = conn:Quote(c)
                end
                local sets = {}
                for _, c in ipairs(cols) do
                    local skip = false
                    for _, cc in ipairs(self._upsertConflict) do
                        if cc == c then skip = true break end
                    end
                    if not skip then
                        local q = conn:Quote(c)
                        sets[#sets + 1] = q .. " = excluded." .. q
                    end
                end
                if #sets > 0 then
                    sql = sql .. string.format(
                        " ON CONFLICT (%s) DO UPDATE SET %s",
                        table.concat(conflictCols, ", "),
                        table.concat(sets, ", ")
                    )
                else
                    sql = sql .. string.format(
                        " ON CONFLICT (%s) DO NOTHING",
                        table.concat(conflictCols, ", ")
                    )
                end
            end
        end
    end

    return sql
end

function QB:_buildUpdate()
    local conn = self._conn
    if not self._updateData then
        error("Elib.Database: nothing to update")
    end

    local sets = {}
    for col, val in pairs(self._updateData) do
        sets[#sets + 1] = conn:Quote(col) .. " = " .. conn:Escape(val)
    end

    if #sets == 0 then
        error("Elib.Database: Update() called with empty data")
    end

    local sql = string.format(
        "UPDATE %s SET %s",
        conn:Quote(self._table),
        table.concat(sets, ", ")
    )

    local whereSQL = self:_buildWheres()
    if whereSQL ~= "" then sql = sql .. " " .. whereSQL end

    if self._limit then sql = sql .. " LIMIT " .. tonumber(self._limit) end

    return sql
end

function QB:_buildDelete()
    local conn = self._conn
    local sql = "DELETE FROM " .. conn:Quote(self._table)

    local whereSQL = self:_buildWheres()
    if whereSQL ~= "" then sql = sql .. " " .. whereSQL end

    if self._limit then sql = sql .. " LIMIT " .. tonumber(self._limit) end

    return sql
end

function QB:ToSQL()
    if self._op == OP_SELECT then return self:_buildSelect() end
    if self._op == OP_INSERT then return self:_buildInsert() end
    if self._op == OP_UPDATE then return self:_buildUpdate() end
    if self._op == OP_DELETE then return self:_buildDelete() end
    error("Elib.Database: invalid operation")
end

/////////////////////////
// Execution
/////////////////////////
function QB:Run()
    local sqlText = self:ToSQL()

    return self._conn:Execute(sqlText):next(function(res)
        if self._op == OP_SELECT then return res.rows end
        if self._op == OP_INSERT then return res.insertId or true end
        return res.affectedRows or true
    end)
end

function QB:Get()
    self._op = OP_SELECT
    return self:Run()
end

function QB:First()
    self._op = OP_SELECT
    self._limit = 1
    return self:Run():next(function(rows) return rows[1] end)
end

function QB:Count(column)
    column = column or "*"
    local saved = self._columns
    self._columns = { Elib.Database.Raw("COUNT(" .. (column == "*" and "*" or self._conn:Quote(column)) .. ") AS aggregate") }
    self._op = OP_SELECT
    return self:Run():next(function(rows)
        self._columns = saved
        if rows and rows[1] then return tonumber(rows[1].aggregate) or 0 end
        return 0
    end)
end

function QB:Exists()
    return self:Count():next(function(n) return n > 0 end)
end