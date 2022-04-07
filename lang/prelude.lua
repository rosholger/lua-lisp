require('lang.env')
original_print = print
print = function(...) end
local lex_setup = require('lang.lexer')
local reader = require('lang.reader')
local compile = require("lang.compile")
local function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)") or "."
end

local function check(success, result)
    if not success then
        io.stderr:write("failed to execute prelude\n")
        io.stderr:write(result .. "\n")
        os.exit(1)
    else
        return result
    end
end

local prelude_filename = script_path() .. "/prelude.lsp"

local ls = lex_setup(reader.file(prelude_filename), prelude_filename)
while ls.token ~= "TK_eof" do
    local luacode = compile.compile(ls, filename, opt)
    local fn = assert(loadstring(luacode))
    fn()
    ls:next()
end
print = original_print