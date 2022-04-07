function fib(a)
    if a == 1 then return 1
    elseif a == 2 then return 1
    else return fib(a-1) + fib(a-2)
    end
end
print(fib(30))