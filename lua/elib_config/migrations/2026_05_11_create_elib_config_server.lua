// Made by Eve Haddox & imLiaMxo
//
// Initial schema for Elib.Config's server-side persistence.
//
// Stores one row per (addon, category, id) tuple with the raw value and its
// original Lua type so cl/sv_saving.lua can round-trip strings, numbers,
// booleans, tables and colors.
//
// On servers that previously ran the legacy Elib config code this migration is
// effectively a no-op: the table is created with CREATE TABLE IF NOT EXISTS so
// existing rows are preserved. The migration is still recorded in
// `elib_migrations` so it won't try to run again.

return function(schema)
    return schema:Create("elib_config_server", function(t)
        // PK columns get a length so the schema works under MySQL too (TEXT
        // columns can't be part of a PRIMARY KEY there without an index length).
        // SQLite ignores VARCHAR lengths so behaviour stays the same.
        t:String("addon", 64)
        t:String("category", 64)
        t:String("id", 128)

        // value is the serialised form; can be JSON, a number-as-string, etc.
        t:Text("value")
        t:String("vtype", 32)

        t:PrimaryKey({ "addon", "category", "id" })
    end)
end