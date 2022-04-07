
_G["*macros-table*"] = {}

local macros_table_metatable = {}
setmetatable(_G["*macros-table*"], macros_table_metatable)

_G["*lua-addition*"] = function (a, b) return a + b end
_G["*lua-subtraction*"] = function (a, b) return a - b end
_G["*lua-multiplication*"] = function (a, b) return a * b end
_G["*lua-division*"] = function (a, b) return a / b end
_G["*lua-create-table*"] = function () return {} end
_G[":"] = function (tbl, key) return tbl[key] end
_G[":!"] = function (tbl, key, val) tbl[key] = val end

symbol_metatable = {}


symbol_metatable.__eq = function(a, b)
    if getmetatable(b) == symbol_metatable then
        return a.value == b.value
    else
        return false
    end
end

symbol_metatable.__tostring = function(a)
    return "'" .. a.value
end

symbol_metatable.__newindex = function(key, value)
    assert(false)
end

symbol_metatable.__hash = function(a)
    return a.value
end

macros_table_metatable.__index = function(tbl, key)
    if type(key) == "table" and getmetatable(key).__hash then
        return rawget(tbl, getmetatable(key).__hash(key))
    else
        return rawget(tbl, key)
    end
end

macros_table_metatable.__newindex = function(tbl, key, value)
    if type(key) == "table" and getmetatable(key).__hash then
        return rawset(tbl, getmetatable(key).__hash(key), value)
    else
        return rawset(tbl, key, value)
    end
end

_G["*lua-make-symbol*"] = function (value)
    local symbol = {value = value, kind = "symbol"}
    setmetatable(symbol, symbol_metatable)
    return symbol
end

conscell_metatable = {}

conscell_metatable.__tostring = function(a)
    local override_tostring = nil
    local function inner_tostring(b)
        if b.cdr then
            if _G["list?"](b.cdr) then
                return override_tostring(b.car) .. " " .. inner_tostring(b.cdr)
            else
                return override_tostring(b.car) .. " . " .. override_tostring(b.cdr)
            end
        else
            return override_tostring(b.car)
        end
    end
    override_tostring = function(b)
        if type(b) == "table" then
            if getmetatable(b) == conscell_metatable then
                return "(" .. inner_tostring(b) .. ")"
            elseif getmetatable(b) == symbol_metatable then
                return b.value
            else
                return tostring(b)
            end
        elseif type(b) == "string" then
            return '"' .. tostring(b) .. '"'
        else
            return tostring(b)
        end
    end
    return "'" .. override_tostring(a)
end

function cons(car, cdr)
    local conscell = {car = car, cdr = cdr, kind = "conscell"}
    if type(car) == "table" then
        conscell.line = car.line
    end
    setmetatable(conscell, conscell_metatable)
    return conscell
end

function car(consCell)
    if consCell.kind ~= "conscell" then
        assert(consCell.kind == "conscell", tostring(consCell) .. " is not a cons cell")
    end
    return consCell.car
end

function cdr(consCell)
    if consCell.kind ~= "conscell" then
        assert(consCell.kind == "conscell", tostring(consCell) .. " is not a cons cell")
    end
    return consCell.cdr
end

function list(...)
    local args = {...}
    local numArgs = select("#", ...)
    if numArgs < 1 then
        return nil
    end
    local tail = cons(args[1], nil)
    local current = tail
    for i = 2, numArgs do
        current.cdr = cons(args[i], nil)
        current = cdr(current)
    end
    return tail
end

_G["array-to-list"] = function(array)
    return list(unpack(array))
end

local gensym_counter = 0

function internal_gensym(name)
    gensym_counter = gensym_counter + 1
    return "*gensym_prefix*_" .. name .. tostring(gensym_counter)
end

_G["*symbol-table*"] = {}
function symbol(name)
    if _G["*symbol-table*"][name] == nil then
        _G["*symbol-table*"][name] = _G["*lua-make-symbol*"](name)
    end
    return _G["*symbol-table*"][name]
end

function gensym(name)
    return symbol(internal_gensym(name or ""))
end

_G["true"] = true
_G["false"] = false
_G["not"] = function (a)
    return not a
end
_G["="] = function (a, b)
    return a == b
end
_G[">"] = function (a, b)
    return a > b
end
_G["<"] = function (a, b)
    return a < b
end
_G[">="] = function (a, b)
    return a >= b
end
_G["<="] = function (a, b)
    return a <= b
end
_G["list?"] = function (a)
    return type(a) == "table" and getmetatable(a) == conscell_metatable
end
_G["nil?"] = function (a)
    return nil == a
end
_G["symbol?"] = function (a)
    return type(a) == "table" and getmetatable(a) == symbol_metatable
end
function length (a)
    if _G["list?"](a) then
        return length(cdr(a)) + 1
    end
    if _G["nil?"](a) then
        return 0
    end
    if type(a) == "table" then
        return select("#", unpack(a))
    end
end

--TODO: error handling
_G["list-to-array"] = function (a)
    local ret = {}
    while a do
        ret[#ret+1] = a.car
        a = a.cdr
    end
    return ret
end

function apply(func, args)
    if _G["list?"](args) then
        return func(unpack(_G["list-to-array"](args)))
    else
        return func(unpack(args))
    end
end

_G["concat-strings"] = function(...)
    local args = {...}
    local ret = ""
    for i,s in ipairs(args) do
        ret = ret .. s
    end
    return ret
end
