local profile = require('profile')
local lex_setup = require('lang.lexer')
local reader = require('lang.reader')
local function usage()
  io.stderr:write[[
LuaJIT Language Toolkit usage: luajit [options]... [script [args]...].

Available options are:
  -b ...    Save or list bytecode.
  -c ...    Generate Lua code and run.
            If followed by the "v" option the generated Lua code
            will be printed.
]]
  os.exit(1)
end

local function check(success, result)
    if not success then
        io.stderr:write(result .. "\n")
        os.exit(1)
    else
        return result
    end
end

local filename

local args = {...}
local opt = {}
local k = 1
while args[k] do
    local a = args[k]
    if string.sub(args[k], 1, 1) == "-" then
        if string.sub(a, 2, 2) == "b" then
            local j = 1
            if #a > 2 then
                args[j] = "-" .. string.sub(a, 3)
                j = j + 1
            else
                table.remove(args, j)
            end
            require("lang.bcsave").start(unpack(args))
            os.exit(0)
        elseif string.sub(a, 2, 2) == "c" then
            opt.code = true
            local copt = string.sub(a, 3, 3)
            if copt == "v" then
                opt.debug = true
            elseif copt ~= "" then
                print("Invalid Lua code option: ", copt)
                usage()
            end
        elseif string.sub(a, 2, 2) == "v" then
            opt.debug = true
        else
            print("Invalid option: ", args[k])
            usage()
        end
    else
        filename = args[k]
    end
    k = k + 1
end

if not filename then usage() end

function dump(o)
    if type(o) == 'table' and getmetatable(o) ~= symbol_metatable and getmetatable(o) ~= conscell_metatable then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    elseif type(o) == 'string' then
        return '"' .. o .. '"'
    else
        return tostring(o)
    end
end
ogprint = print

profile.start()
require("lang.prelude")
profile.stop()
local compile = require("lang.compile")

-- Compute the bytecode string for the given filename.

local ls = lex_setup(reader.file(filename), filename)
while ls.token ~= "TK_eof" do
    print = function (...) end
    profile.start()
    local luacode = compile.compile(ls, filename, opt)
    profile.stop()
    local fn = assert(loadstring(luacode))
    ogprint(dump(fn()))
    print = ogprint
    ls:next()
end
print(profile.report(10))