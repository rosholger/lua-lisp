
local AST = { }

function AST.number(value, line)
    return { kind = "number", value = value, line = line }
end

function AST.symbol(value, line)
    return { kind = "symbol", value = value, line = line }
end

function AST.identifier(value, line)
    return { kind = "identifier", value = value, line = line }
end

function AST.string(value, line)
    return { kind = "string", value = value, line = line }
end

function AST.list(elements, line)
    return { kind = "list", elements = elements, line = line }
end

function AST.expression(elements, line)
    return { kind = "expression", elements = elements, line = line }
end

function AST.consListToList(consList)
    local elements = {}
    local firstLine = 9999999
    while consList do
        if consList.car == nil then
            if consList.line then
                elements[#elements+1] = AST.list({}, consList.line)
            else
                elements[#elements+1] = AST.list({}, -1)
            end
        elseif _G["list?"](consList.car) then
            elements[#elements+1] = AST.consListToList(consList.car)
        else
            local line = -1
            if type(consList.car) == "table" and consList.car.line then
                line = consList.car.line
            elseif consList.line then
                line = consList.line
            end
            if _G["symbol?"](consList.car) then
                elements[#elements+1] = AST.identifier(consList.car.value, line)
            elseif type(consList.car) == "string" then
                elements[#elements+1] = AST.string(consList.car, line)
            elseif type(consList.car) == "number" then
                elements[#elements+1] = AST.number(consList.car, line)
            elseif type(consList.car) == "boolean" then
                elements[#elements+1] = AST.identifier(tostring(consList.car), line)
            end
        end
        if consList.line and firstLine > consList.line then
            firstLine = consList.line
        end
        consList = consList.cdr
    end
    return AST.list(elements, firstLine)
end

function AST.astToSexp(sexp)
    if sexp.kind == "identifier" then
        local ret = _G["*lua-make-symbol*"](sexp.value)
        rawset(ret, "line", sexp.line)
        return ret
    elseif sexp.kind == "list" then
        return AST.listToConsList(sexp.elements)
    else
        return sexp.value
    end
end

function AST.listToConsList(lst)
    local function handleNilQuotes(consList)
        if _G["list?"](consList) then
            local thisCar = handleNilQuotes(car(consList))
            local thisCdr = cdr(consList)
            if thisCar == symbol("quote") and thisCdr == nil then
                return cons(thisCar, cons(nil, nil))
            elseif thisCar ~= car(consList) then
                return cons(thisCar, thisCdr)
            end
       end
        return consList
    end
    local conv_lst = nil
    local tail = nil
    for i, elem in ipairs(lst) do
        if tail == nil then
            conv_lst = cons(AST.astToSexp(elem), nil)
            tail = conv_lst
        else
            tail.cdr = cons(AST.astToSexp(elem), nil)
            tail = tail.cdr
        end
    end
    return handleNilQuotes(conv_lst)
end

function AST.listToExpression(list)
    return AST.expression(list.elements, list.firstLine, list.lastLine)
end

return AST

--[[
    list = parseList(lexer)
    head = expression.elements[1] --[[
    while macros[head] do
        consList = macros[head](AST.listToConsList(l)
        head = expression.elements[1] --[[
    end
]]