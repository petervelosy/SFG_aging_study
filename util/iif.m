% Ternary operator for a one-line conditional assignment: a = iif(c > 7, 2, 3);
function result = iif(condition, a, b)
    if condition
        result = a;
    else
        result = b;
    end
end