// Made by Eve Haddox & imLiaMxo

Elib.Database = Elib.Database or {}

local META_TABLE = "elib_migrations"

/////////////////////////
// Meta table bootstrap
/////////////////////////
local function ensureMetaTable(db)
    return db.Schema:Has(META_TABLE):next(function(exists)
        if exists then return true end

        return db.Schema:Create(META_TABLE, function(t)
            t:String("addon", 64)
            t:String("name", 255)
            t:Integer("applied_at"):Default(0)
            t:PrimaryKey({ "addon", "name" })
        end)
    end)
end

/////////////////////////
// Helpers
/////////////////////////
local function listMigrationFiles(path)
    local files = file.Find(path .. "/*.lua", "LUA")
    if not files then return {} end
    table.sort(files)
    return files
end

local function runMigrationFile(db, path, fileName)
    local fullPath = path .. "/" .. fileName

    local ok, definition = pcall(include, fullPath)
    if not ok then
        return Elib.Deferred.new():reject("error loading migration " .. fileName .. ": " .. tostring(definition))
    end

    local upFn
    if type(definition) == "function" then
        upFn = definition
    elseif type(definition) == "table" then
        upFn = definition.up
    end

    if type(upFn) ~= "function" then
        return Elib.Deferred.new():reject("migration " .. fileName .. " did not return a function or {up = ...} table")
    end

    local result = upFn(db.Schema, db)

    local readyPromise
    if type(result) == "table" and type(result.next) == "function" then
        readyPromise = result
    else
        readyPromise = Elib.Deferred.new()
        readyPromise:resolve(true)
    end

    return readyPromise:next(function()
        return db:Table(META_TABLE):Insert({
            addon      = db.addonName,
            name       = fileName,
            applied_at = os.time(),
        }):Run()
    end)
end

/////////////////////////
// Public entry
/////////////////////////
function Elib.Database.RunMigrations(db, path)
    local log = Elib.Database.Logger

    return ensureMetaTable(db):next(function()
        local files = listMigrationFiles(path)
        if #files == 0 then
            if log then log:Debug(db.addonName .. " no migration files in " .. path) end
            return {}
        end

        return db:Table(META_TABLE)
            :Select("name")
            :Where("addon", "=", db.addonName)
            :Get()
            :next(function(rows)
                local applied = {}
                for _, r in ipairs(rows) do applied[r.name] = true end

                // Run pending migrations
                local newlyApplied = {}

                local function step(i)
                    if i > #files then return newlyApplied end
                    local f = files[i]
                    if applied[f] then return step(i + 1) end

                    if log then log:Info(db.addonName .. " applying migration: " .. f) end

                    return runMigrationFile(db, path, f):next(function()
                        if log then log:Success(db.addonName .. " applied: " .. f) end
                        newlyApplied[#newlyApplied + 1] = f
                        return step(i + 1)
                    end, function(err)
                        if log then log:Error(db.addonName .. " migration failed at " .. f .. ": " .. tostring(err)) end
                        // reject wit error.
                        return Elib.Deferred.new():reject(err)
                    end)
                end

                return step(1)
            end)
    end)
end

function Elib.Database.MarkMigrationApplied(db, namesOrName)
    local names = type(namesOrName) == "table" and namesOrName or { namesOrName }

    return ensureMetaTable(db):next(function()
        local rows = {}
        for _, n in ipairs(names) do
            rows[#rows + 1] = { addon = db.addonName, name = n, applied_at = os.time() }
        end
        if #rows == 0 then return true end

        return db:Table(META_TABLE):Upsert(rows, { "addon", "name" }):Run()
    end)
end