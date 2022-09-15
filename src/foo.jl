# [src/foo.jl]

using StaticArrays

"""
    foo(x, y)

Creates a 2-element static array from the scalars `x` and `y`.
"""
function foo(x::Number, y::Number)
    StaticArrays.SA[x, y]
end