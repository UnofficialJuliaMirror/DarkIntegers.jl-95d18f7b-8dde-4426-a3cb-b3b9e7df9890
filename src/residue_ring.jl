abstract type AbstractRRElem <: Unsigned end


struct _NoConversion
end

const _no_conversion = _NoConversion()


"""
Residue ring element, an unsigned integer with all operations performed modulo `M`.

Supports `+`, `-`, `*`, `divrem`, `div`, `rem`, `^`, `<`, `<=`, `>`, `>=`,
`zero`, `one` and `isodd`.
Note that the division is a regular division, not multiplication by the inverse
(which is not guaranteed to exist for any `M`).

    RRElem{T, M}(x::Integer) where {T <: Unsigned, M}

Creates an `RRElem` object. `M` must have the type `T`.
"""
struct RRElem{T, M} <: AbstractRRElem
    value :: T

    # This is the only method using `new` to ensure `M` has the type `T`
    # (since we cannot enforce it with Julia syntax)
    @inline function RRElem(x::T, m::T, ::_NoConversion) where T <: Unsigned
        new{T, m}(x)
    end

    @inline function RRElem{T, M}(x::T, ::_NoConversion) where {T <: Unsigned, M}
        RRElem(x, M, _no_conversion)
    end

    @inline function RRElem{T, M}(x::Integer) where {T <: Unsigned, M}
        # No need to take the modulus first, conversion will take care of it.
        RRElem{T, M}(convert(T, mod(x, M)), _no_conversion)
    end
end


@inline Base.convert(::Type{RRElem{T, M}}, x::RRElem{T, M}) where {T, M} = x
@inline Base.convert(::Type{V}, x::RRElem{T, M}) where {V <: Integer, T, M} = convert(V, x.value)


@inline Base.promote_type(::Type{RRElem{T, M}}, ::Type{<:Integer}) where {T, M} = RRElem{T, M}
@inline Base.promote_type(::Type{<:Integer}, ::Type{RRElem{T, M}}) where {T, M} = RRElem{T, M}


# We need this to correctly process arithmetic operations on RRElem and Int
# (which is signed and the default in Julia for number literals)
# without defining specific methods for each operator.
@inline Base.signed(x::RRElem{T, M}) where {T, M} = x
@inline Base.unsigned(x::RRElem{T, M}) where {T, M} = x


# Unlike `one(x)`, `zero(x)` does not have a fallback `= zero(typeof(x))` in the standard library
# and uses conversion instead. So we are defining our own.
@inline Base.zero(::Type{RRElem{T, M}}) where {T, M} = RRElem(zero(T), M, _no_conversion)
@inline Base.zero(::RRElem{T, M}) where {T, M} = zero(RRElem{T, M})


@inline Base.one(::Type{RRElem{T, M}}) where {T, M} = RRElem(one(T), M, _no_conversion)


@inline function Base.:+(x::RRElem{T, M}, y::RRElem{T, M}) where {T, M}
    RRElem(addmod(x.value, y.value, M), M, _no_conversion)
end


@inline function Base.:-(x::RRElem{T, M}, y::RRElem{T, M}) where {T, M}
    RRElem(submod(x.value, y.value, M), M, _no_conversion)
end


@inline function Base.:-(x::RRElem{T, M}) where {T, M}
    # TODO: can be optimized
    zero(RRElem{T, M}) - x
end


@inline function Base.:*(x::RRElem{T, M}, y::RRElem{T, M}) where {T, M}
    xt = x.value
    yt = y.value
    res = mulmod_widemul(xt, yt, M)
    RRElem(res, M, _no_conversion)
end


@inline function Base.isodd(x::RRElem{T, M}) where {T, M}
    isodd(x.value)
end


@inline function Base.div(x::RRElem{T, M}, y::RRElem{T, M}) where {T, M}
    RRElem(div(x.value, y.value), M, _no_conversion)
end


@inline function Base.div(x::RRElem{T, M}, y::Unsigned) where {T, M}
    # TODO: assumes that `y` fits into RRElem
    div(x, RRElem{T, M}(y))
end


# Apparently we cannot just define a method for `y::Integer`, since there is a
# `div(Unsigned, Union{...})` in Base, resulting in ambiguity.
@inline function Base.div(x::RRElem{T, M}, y::Union{Int128, Int16, Int32, Int64, Int8}) where {T, M}
    y < 0 ? div(-x, unsigned(-y)) : div(x, unsigned(y))
end


@inline function Base.divrem(x::RRElem{T, M}, y::RRElem{T, M}) where {T, M}
    d, r = divrem(x.value, y.value)
    RRElem(d, M, _no_conversion), RRElem(r, M, _no_conversion)
end


@inline Base.:<(x::RRElem{T, M}, y::RRElem{T, M}) where {T, M} = x.value < y.value


@inline Base.:>(x::RRElem{T, M}, y::RRElem{T, M}) where {T, M} = x.value > y.value


@inline Base.:<=(x::RRElem{T, M}, y::RRElem{T, M}) where {T, M} = x.value <= y.value


@inline Base.:>=(x::RRElem{T, M}, y::RRElem{T, M}) where {T, M} = x.value >= y.value


Base.string(x::RRElem{T, M}) where {T, M} = string(x.value) * "RR"


Base.show(io::IO, x::RRElem{T, M}) where {T, M} = print(io, string(x))


# Required for broadcasting


Base.length(x::RRElem{T, M}) where {T, M} = 1


Base.iterate(x::RRElem{T, M}) where {T, M} = (x, nothing)
Base.iterate(x::RRElem{T, M}, state) where {T, M} = nothing
