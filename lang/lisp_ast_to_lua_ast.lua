local ASTConverter = {}

local ast_converter_by_kind = {}
local special_expressions = {}

local function wrap_statement_in_called_lambda(convert_statement_function)
    return function (lisp_ast, lua_ast_builder)
        print("Trace: wrap in lambda")
        lua_ast_builder:fscope_begin()
        local params = lua_ast_builder:func_parameters_decl({}, false)
        local body = {convert_statement_function(lisp_ast, lua_ast_builder)}
        lua_ast_builder:fscope_end()
        local wrapping_lambda = lua_ast_builder:expr_function(params, body, {varargs = false, firstline = lisp_ast.line, lastline = lisp_ast.line})
        return lua_ast_builder:expr_function_call(wrapping_lambda, {}, lisp_ast.line)
    end
end

local function convert_body(stmts, stmts_start, lua_ast_builder, body)
    print("Trace: convert body")
    local prev_used_as_expression = used_as_expression
    used_as_expression = false
    for i=stmts_start, #stmts-1 do
        body[#body+1] = convert_expression(stmts[i], lua_ast_builder, false)
    end
    used_as_expression = prev_used_as_expression
    body[#body+1] = convert_expression(stmts[#stmts], lua_ast_builder, used_as_expression)
end

local function convert_block(lisp_ast, lua_ast_builder)
    print("Trace: convert block")
    lua_ast_builder:fscope_begin()
    local body = {}
    convert_body(lisp_ast.elements, 2, lua_ast_builder, body)
    lua_ast_builder:fscope_end()
    local firstLine = 999999999999999
    local lastLine = 0
    for i, stmt in ipairs(body) do
        if stmt.line and stmt.line < firstLine then
            firstLine = stmt.line
        end
        if stmt.line and stmt.line > lastLine then
            lastLine = stmt.line
        end
    end
    return lua_ast_builder:do_stmt(body, firstLine, lastLine)
end

local function convert_goto(lisp_ast, lua_ast_builder)
    print("Trace: convert goto")
    assert(#lisp_ast.elements == 2)
    assert(lisp_ast.elements[2].kind == "identifier")
    return lua_ast_builder:goto_stmt(lisp_ast.elements[2].value, lisp_ast.line)
end

-- TODO: handle label at return position (how? maybe insert empty return?)
local function convert_label(lisp_ast, lua_ast_builder)
    print("Trace: convert label")
    assert(#lisp_ast.elements == 2)
    assert(lisp_ast.elements[2].kind == "identifier")
    return lua_ast_builder:label_stmt(lisp_ast.elements[2].value, lisp_ast.line)
end

local function convert_cond(lisp_ast, lua_ast_builder)
    print("Trace: convert cond")
    local tests = {}
    local branches = {}
    for i = 2, #lisp_ast.elements-1, 2 do
        tests[#tests+1] = convert_expression(lisp_ast.elements[i], lua_ast_builder, false)
        branches[#branches+1] = {convert_expression(lisp_ast.elements[i+1], lua_ast_builder, used_as_expression)}
        branches[#branches].firstline = lisp_ast.elements[i+1].line
        branches[#branches].lastline = lisp_ast.elements[i+1].line -- FIXME
    end
    return lua_ast_builder:if_stmt(tests, branches, nil, lisp_ast.line)
end

local function convert_statement(converter)
    return function(lisp_ast, lua_ast_builder)
        if used_as_expression then
            return wrap_statement_in_called_lambda(converter)(lisp_ast, lua_ast_builder)
        else
            return converter(lisp_ast, lua_ast_builder)
        end
    end
end

local function convert_parameters(lisp_ast, lua_ast_builder)
    assert(lisp_ast.kind == "list")
    print("Trace: convert parameters")
    local varargs = false
    local params = {}
    for i=1,#lisp_ast.elements do
        assert(lisp_ast.elements[i].kind == "identifier")
        if lisp_ast.elements[i].value == ":rest" then
            print("Trace: varargs param")
            varargs = true
            assert(i+1 == #lisp_ast.elements)
            assert(lisp_ast.elements[#lisp_ast.elements].kind == "identifier")
            break
        else
            print("Trace: param")
            params[#params+1] = lisp_ast.elements[i].value
        end
    end
    if varargs then
        return lua_ast_builder:func_parameters_decl(params, varargs), varargs, lisp_ast.elements[#lisp_ast.elements]
    else
        return lua_ast_builder:func_parameters_decl(params, varargs), varargs
    end
end

local function convert_lambda(lisp_ast, lua_ast_builder)
    print("Trace: convert lambda")
    local proto = {varargs = false, firstline = lisp_ast.line}
    lua_ast_builder:fscope_begin()
    local params, varargs, varargs_variable = convert_parameters(lisp_ast.elements[2], lua_ast_builder)
    local body = {}
    if varargs then
        proto.varargs = varargs
        print(varargs_variable.value)
        body[1] = lua_ast_builder:local_decl(
            {varargs_variable.value},
            {lua_ast_builder:expr_table({{lua_ast_builder:expr_vararg()}})},
            lisp_ast.line)
    end
    local prev_used_as_expression = used_as_expression
    used_as_expression = true
    convert_body(lisp_ast.elements, 3, lua_ast_builder, body)
    used_as_expression = prev_used_as_expression
    if #lisp_ast.elements > 2 then
        proto.lastline = lisp_ast.elements[#lisp_ast.elements].line
    else
        proto.lastline = proto.firstline
    end
    lua_ast_builder:fscope_end()
    return lua_ast_builder:expr_function(params, body, proto)
end

-- TODO: Handle (local var (lambda ...)), rn it does not support recursion
local function convert_local(lisp_ast, lua_ast_builder)
    print("Trace: convert local")
    assert(used_as_expression == false, "local not yet handled in return position")
    assert(#lisp_ast.elements == 2 or #lisp_ast.elements == 3)
    assert(lisp_ast.elements[2].kind == "identifier")
    --if #lisp_ast.elements == 3 and lisp_ast.elements[3].kind == "list" and #lisp_ast.elements[3].elements > 0 and
        --lisp_ast.elements[3].elements[1].kind == "identifier" and lisp_ast.elements[3].elements[1].value == "lambda" then
        --print("convert local function")
        --local lambda_ast = lisp_ast.elements[3]
        --local proto = {varargs = false, firstline = lambda_ast.line}
        --lua_ast_builder:fscope_begin()
        --local params, varargs, varargs_variable = convert_parameters(lambda_ast.elements[2], lua_ast_builder)
        --local body = {}
        --if varargs then
            --proto.varargs = varargs
            --body[1] = lua_ast_builder:assignment_expr(
                --{lua_ast_builder:identifier(varargs_variable.value)},
                --{lua_ast_builder:expr_table({{lua_ast_builder:expr_vararg()}})},
                --lambda_ast.line)
        --end
        --local prev_used_as_expression = used_as_expression
        --used_as_expression = true
        --convert_body(lisp_ast.elements, 3, lua_ast_builder, body)
        --used_as_expression = prev_used_as_expression
        --if #lambda_ast.elements > 2 then
            --proto.lastline = lambda_ast.elements[#lambda_ast.elements].line
        --else
            --proto.lastline = proto.firstline
        --end
        --lua_ast_builder:fscope_end()
        --return lua_ast_builder:local_function_decl(lisp_ast.elements[2].value,
                                                   --params, body, proto)
    --else
        print("convert local variable")
        local variable = lisp_ast.elements[2].value
        local expression_list = {}
        if #lisp_ast.elements == 3 then
            used_as_expression = true
            expression_list = {convert_expression(lisp_ast.elements[3], lua_ast_builder, false)}
            used_as_expression = false
        end
        return lua_ast_builder:local_decl({variable}, expression_list, lisp_ast.line)
    --end
end


local function convert_args(lisp_ast, lua_ast_builder)
    assert(lisp_ast.kind == "list")
    print("Trace: convert args")
    local args = {}
    for i = 2, #lisp_ast.elements do
        args[i-1] = convert_expression(lisp_ast.elements[i], lua_ast_builder, false)
    end
    return args
end

local function convert_call(lisp_ast, lua_ast_builder)
    assert(lisp_ast.kind == "list")
    print("Trace: convert call")
    local callee = convert_expression(lisp_ast.elements[1], lua_ast_builder, false)
    local prev_used_as_expression = used_as_expression
    used_as_expression = true
    local args = convert_args(lisp_ast, lua_ast_builder)
    used_as_expression = prev_used_as_expression
    return lua_ast_builder:expr_function_call(callee, args, lisp_ast.line)
end

local function convert_call_or_special_expression(lisp_ast, lua_ast_builder)
    assert(lisp_ast.kind == "list")
    print("Trace: convert call/special")
    if lisp_ast.elements[1].kind == "identifier" and
        special_expressions[lisp_ast.elements[1].value] then
        return special_expressions[lisp_ast.elements[1].value](lisp_ast, lua_ast_builder)
    else
        return convert_call(lisp_ast, lua_ast_builder)
    end
end

local function convert_literal(lisp_ast, lua_ast_builder)
    print("Trace: convert literal")
    return lua_ast_builder:literal(lisp_ast.value)
end

local function convert_identifier(lisp_ast, lua_ast_builder)
    assert(lisp_ast.kind == "identifier")
    print("Trace: convert identifier")
    return lua_ast_builder:identifier(lisp_ast.value);
end

local function convert_symbol(lisp_ast, lua_ast_builder)
    assert(lisp_ast.kind == "symbol")
    print("Trace: convert symbol")
    return lua_ast_builder:expr_function_call(lua_ast_builder:identifier("*lua-make-symbol*"),
                                              {lua_ast_builder:literal(lisp_ast.value)},
                                              lisp_ast.line)
end

local function convert_set(lisp_ast, lua_ast_builder)
    assert(used_as_expression == false, "set not yet handled in return position")
    assert(#lisp_ast.elements == 3)
    assert(lisp_ast.elements[2].kind == "identifier")
    used_as_expression = true
    local ret = lua_ast_builder:assignment_expr({lua_ast_builder:identifier(lisp_ast.elements[2].value)},
        {convert_expression(lisp_ast.elements[3], lua_ast_builder, false)},
        lisp_ast.line)
    used_as_expression = false
    return ret
end

special_expressions["lambda"] = convert_lambda
special_expressions["cond"] = convert_statement(convert_cond)
special_expressions["local"] = convert_local
special_expressions["block"] = convert_statement(convert_block)
special_expressions["goto"] = convert_goto
special_expressions["label"] = convert_label
special_expressions["set"] = convert_set

ast_converter_by_kind["list"] = convert_call_or_special_expression
ast_converter_by_kind["number"] = convert_literal
ast_converter_by_kind["identifier"] = convert_identifier
ast_converter_by_kind["string"] = convert_literal
ast_converter_by_kind["symbol"] = convert_symbol

function convert_expression(lisp_ast, lua_ast_builder, should_return)
    print("Trace: convert expression")
    local expr = ast_converter_by_kind[lisp_ast.kind](lisp_ast, lua_ast_builder)
    if should_return then
        return lua_ast_builder:return_stmt({expr}, lisp_ast.line)
    else
        return expr
    end
end

local function convert(lisp_ast, lua_ast_builder, should_return)
    local prev_used_as_expression = used_as_expression
    used_as_expression = should_return
    print("Trace: convert")
    lua_ast_builder:fscope_begin()
    local expression = convert_expression(lisp_ast, lua_ast_builder, should_return)
    local chunk = lua_ast_builder:chunk({expression}, "some_chunk_name", lisp_ast.line, lisp_ast.line)
    lua_ast_builder:fscope_end()
    used_as_expression = prev_used_as_expression
    return chunk
end

return convert