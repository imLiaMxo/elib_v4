// Promise / deferred library.
// Adapted from https://github.com/zserge/lua-promises (MIT licence).
//
// This is a pretty standard A+ Promise implementation. Exposed as Elib.Deferred:
//
//   local p = Elib.Deferred.new()
//   someAsyncThing(function(result, err)
//       if err then p:reject(err) else p:resolve(result) end
//   end)
//   return p
//
// Callers consume it with :next(onResolve, onReject), which itself returns a
// new promise so you can chain. Returning a promise from inside a :next handler
// waits for that promise before continuing the chain.
//
//   load("a.txt"):next(function(contents)
//       print(contents)
//       return load("b.txt")
//   end):next(function(contents)
//       print(contents)
//   end, function(err) print("error:", err) end)

local M = {}

local deferred = {}
deferred.__index = deferred

local PENDING   = 0
local RESOLVING = 1
local REJECTING = 2
local RESOLVED  = 3
local REJECTED  = 4

local function finish(d, state)
    state = state or REJECTED
    for _, f in ipairs(d.queue) do
        if state == RESOLVED then
            f:resolve(d.value)
        else
            f:reject(d.value)
        end
    end
    d.state = state
end

local function isfunction(f)
    if type(f) == "table" then
        local mt = getmetatable(f)
        return mt ~= nil and type(mt.__call) == "function"
    end
    return type(f) == "function"
end

local function promise(d, nextFn, success, failure, nonpromisecb)
    if type(d) == "table" and type(d.value) == "table" and isfunction(nextFn) then
        local called = false

        local ok, err = pcall(nextFn, d.value,
            function(v)
                if called then return end
                called = true
                d.value = v
                success()
            end,
            function(v)
                if called then return end
                called = true
                d.value = v
                failure()
            end
        )

        if not ok and not called then
            d.value = err
            failure()
        end
    else
        nonpromisecb()
    end
end

local function fire(d)
    local nextFn
    if type(d.value) == "table" then
        nextFn = d.value.next
    end

    promise(d, nextFn,
        function()
            d.state = RESOLVING
            fire(d)
        end,
        function()
            d.state = REJECTING
            fire(d)
        end,
        function()
            local ok, v
            if d.state == RESOLVING and isfunction(d.success) then
                ok, v = pcall(d.success, d.value)
            elseif d.state == REJECTING and isfunction(d.failure) then
                ok, v = pcall(d.failure, d.value)
                if ok then d.state = RESOLVING end
            end

            if ok ~= nil then
                if ok then
                    d.value = v
                else
                    d.value = v
                    return finish(d)
                end
            end

            if d.value == d then
                d.value = pcall(error, "resolving promise with itself")
                return finish(d)
            else
                promise(d, nextFn,
                    function() finish(d, RESOLVED) end,
                    function(state) finish(d, state) end,
                    function() finish(d, d.state == RESOLVING and RESOLVED) end
                )
            end
        end
    )
end

local function resolve(d, state, value)
    if d.state == PENDING then
        d.value = value
        d.state = state
        fire(d)
    end
    return d
end

/////////////////////////
// Public API
/////////////////////////
function deferred:resolve(value) return resolve(self, RESOLVING, value) end
function deferred:reject(value)  return resolve(self, REJECTING, value) end

function M.new(options)
    if isfunction(options) then
        local d = M.new()
        local ok, err = pcall(options, d)
        if not ok then d:reject(err) end
        return d
    end

    options = options or {}

    local d
    d = {
        next = function(_, success, failure)
            local n = M.new({
                success = success,
                failure = failure,
                extend  = options.extend,
            })

            if d.state == RESOLVED then
                n:resolve(d.value)
            elseif d.state == REJECTED then
                n:reject(d.value)
            else
                table.insert(d.queue, n)
            end

            return n
        end,

        state   = PENDING,
        queue   = {},
        success = options.success,
        failure = options.failure,
    }

    d = setmetatable(d, deferred)
    if isfunction(options.extend) then options.extend(d) end
    return d
end

function M.all(args)
    local d = M.new()
    if #args == 0 then return d:resolve({}) end

    local method  = "resolve"
    local pending = #args
    local results = {}

    local function sync(i, resolved)
        return function(value)
            results[i] = value
            if not resolved then method = "reject" end
            pending = pending - 1
            if pending == 0 then d[method](d, results) end
            return value
        end
    end

    for i = 1, pending do
        args[i]:next(sync(i, true), sync(i, false))
    end
    return d
end

function M.map(args, fn)
    local d = M.new()
    local results = {}

    local function donext(i)
        if i > #args then
            d:resolve(results)
        else
            fn(args[i]):next(
                function(res)
                    table.insert(results, res)
                    donext(i + 1)
                end,
                function(err) d:reject(err) end
            )
        end
    end

    donext(1)
    return d
end

function M.first(args)
    local d = M.new()
    for _, v in ipairs(args) do
        v:next(
            function(res) d:resolve(res) end,
            function(err) d:reject(err) end
        )
    end
    return d
end

Elib.Deferred = M
