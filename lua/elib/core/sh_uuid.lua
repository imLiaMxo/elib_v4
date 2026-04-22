// Made by Eve Haddox & imLiaMxo
 
Elib.UUID = Elib.UUID or {}
Elib.UUID.Used = Elib.UUID.Used or {}
 
/////////////////////////
// Internal Helpers
/////////////////////////
local function randomHex(len)
    local out = {}
    for i = 1, len do
        out[i] = string.format("%x", math.random(0, 15))
    end
    return table.concat(out)
end
 
local function randomHexByte()
    return string.format("%02x", math.random(0, 255))
end
 
-- Returns a RFC 4122 v4 UUID string: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx thanks stackoverflow: https://stackoverflow.com/a/2117523
local function buildUUID()
    local p1 = randomHex(8)
    local p2 = randomHex(4)
    local p3 = "4" .. randomHex(3) -- version 4
    local p4 = string.format("%x", math.random(8, 11)) .. randomHex(3) -- variant 10xx
    local p5 = randomHex(12)
 
    return p1 .. "-" .. p2 .. "-" .. p3 .. "-" .. p4 .. "-" .. p5 -- example output: "f47ac10b-58cc-4372-a567-0e02b2c3d479"
end
 
/////////////////////////
// UUID API
/////////////////////////.
function Elib.UUID.Generate(markUsed)
    if markUsed == nil then markUsed = true end

    local uuid
    local attempts = 0

    repeat
        uuid = buildUUID()
        attempts = attempts + 1

        if attempts > 1000 then
            Elib.Logger:Error("[UUID] Failed to generate a unique UUID after 1000 attempts.")
            return nil
        end
    until not Elib.UUID.Used[uuid]
    
    if markUsed then
        Elib.UUID.Used[uuid] = true
    end
 
    return uuid
end

function Elib.UUID.Mark(uuid)
    if not Elib.UUID.IsValid(uuid) then
        Elib.Logger:Warn("[UUID] Attempted to mark an invalid UUID: " .. tostring(uuid))
        return false
    end
 
    Elib.UUID.Used[uuid] = true
    return true
end

function Elib.UUID.Unmark(uuid)
    if not Elib.UUID.IsValid(uuid) then
        Elib.Logger:Warn("[UUID] Attempted to unmark an invalid UUID: " .. tostring(uuid))
        return false
    end
 
    Elib.UUID.Used[uuid] = nil
    return true
end
 
function Elib.UUID.IsUsed(uuid)
    return Elib.UUID.Used[uuid] == true
end

function Elib.UUID.IsValid(uuid)
    if type(uuid) ~= "string" then return false end
    return uuid:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

function Elib.UUID.Count()
    local n = 0
    for _ in pairs(Elib.UUID.Used) do n = n + 1 end
    return n
end

function Elib.UUID.Reset()
    Elib.UUID.Used = {}
    Elib.Logger:Warn("[UUID] UUID store has been reset. All previously used UUIDs have been cleared.")
end