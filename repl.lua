local lex_setup = require('lang.lexer')
local reader = require('lang.reader')
require('lang.env')
local compile = require("lang.compile")

function dump(o)
    if type(o) == 'table' and getmetatable(o) ~= symbol_metatable and getmetatable(o) ~= conscell_metatable then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function check(success, result)
    if not success then
        io.stderr:write(result .. "\n")
    else
        return result
    end
end



io.write(">  ")
local ls = lex_setup(function () return io.read() .. '\n' end, "stdin")
while true do
    local luacode = check(compile.compile(ls, filename, opt))
    local fn = assert(loadstring(luacode))
    print(dump(check(pcall(fn))))
    io.write(">  ")
    ls:next()
end