local lisp_ast_builder = require('lang.lisp_ast')

local function is_quoted(lisp_ast)
    return lisp_ast.kind == "list" and #lisp_ast.elements > 0 and lisp_ast.elements[1].kind == "identifier" and lisp_ast.elements[1].value == "quote"
end

local function should_expand(lisp_ast)
    return lisp_ast.kind == "list" and #lisp_ast.elements > 0 and lisp_ast.elements[1].kind == "identifier" and _G["*macros-table*"][_G["*lua-make-symbol*"](lisp_ast.elements[1].value)]
end

local function expand_quote(lisp_ast)
    assert(#lisp_ast.elements == 2)
    if lisp_ast.elements[2].kind == "list" then
        lisp_ast.elements[1].value = "list"
        local quoted_list = lisp_ast.elements[2]
        if #quoted_list.elements == 0 then
            lisp_ast.elements[2] = nil
        end
        for i = 1, #quoted_list.elements do
            lisp_ast.elements[i+1] = lisp_ast_builder.list({lisp_ast_builder.identifier("quote", quoted_list.elements[i].line), quoted_list.elements[i]}, quoted_list.elements[i].line)
        end
    elseif lisp_ast.elements[2].kind == "identifier" then
        lisp_ast = lisp_ast.elements[2]
        lisp_ast.kind = "symbol"
    else
        lisp_ast = lisp_ast.elements[2]
    end
    return lisp_ast
end

local function expand_macro(lisp_ast)
    local args = {}
    for i = 2,#lisp_ast.elements do
        args[#args+1] = lisp_ast_builder.astToSexp(lisp_ast.elements[i])
    end
    local conslist = _G["*macros-table*"][lisp_ast.elements[1].value](unpack(args))
    if _G["list?"](conslist) then
        return lisp_ast_builder.consListToList(conslist)
    elseif _G["symbol?"](conslist) then
        if conslist.line then
            return lisp_ast_builder.identifier(conslist.value, conslist.line)
        else
            return lisp_ast_builder.identifier(conslist.value, lisp_ast.line)
        end
    else return conslist
    end
end

local function macro_expand(lisp_ast)
    if lisp_ast.kind == "list" then
        while is_quoted(lisp_ast) or should_expand(lisp_ast) do
            if is_quoted(lisp_ast) then
                lisp_ast = expand_quote(lisp_ast)
            end
            if should_expand(lisp_ast) then
                lisp_ast = expand_macro(lisp_ast)
            end
        end
    end
    if lisp_ast.kind == "list" then
        for i=1, #lisp_ast.elements do
            lisp_ast.elements[i] = macro_expand(lisp_ast.elements[i])
        end
    end
    return lisp_ast
end

return macro_expand