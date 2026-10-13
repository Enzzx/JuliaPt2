# =============================================================================
# PARTE 2 - Funções de alta ordem (higher-order functions)
# =============================================================================
# Execute com:  julia exemplos/parte2.jl
# =============================================================================

secao(t) = println("\n", "-"^70, "\n", t, "\n", "-"^70)

xs = collect(1:10)
println("xs = ", xs)

# -----------------------------------------------------------------------------
secao("2.1 - map")
# -----------------------------------------------------------------------------
println("map(x -> x^2, xs)        = ", map(x -> x^2, xs))
println("map(+, xs, 10:10:100)    = ", map(+, xs, 10:10:100))   # dois iteráveis
println("map(sqrt, [1, 4, 9, 16]) = ", map(sqrt, [1, 4, 9, 16]))

# -----------------------------------------------------------------------------
secao("2.2 - filter")
# -----------------------------------------------------------------------------
println("filter(iseven, xs)          = ", filter(iseven, xs))
println("filter(x -> x % 3 == 0, xs) = ", filter(x -> x % 3 == 0, xs))
println("filter(>(5), xs)            = ", filter(>(5), xs))   # aplicação parcial

# -----------------------------------------------------------------------------
secao("2.3 - reduce / fold")
# -----------------------------------------------------------------------------
println("reduce(+, xs)              = ", reduce(+, xs))
println("reduce(*, 1:5)             = ", reduce(*, 1:5))
println("reduce(+, xs; init = 100)  = ", reduce(+, xs; init = 100))
println("foldl(-, 1:4)              = ", foldl(-, 1:4), "   ((1-2)-3)-4")
println("foldr(-, 1:4)              = ", foldr(-, 1:4), "   1-(2-(3-4))")
println("mapreduce(x -> x^2, +, xs) = ", mapreduce(x -> x^2, +, xs))
println("sum(x -> x^2, xs)          = ", sum(x -> x^2, xs), "   (açúcar p/ mapreduce)")

# -----------------------------------------------------------------------------
secao("2.4 - Outras HOFs da biblioteca padrão")
# -----------------------------------------------------------------------------
print("foreach(x -> print(x, \" \"), 1:5) = "); foreach(x -> print(x, " "), 1:5); println()
println("count(iseven, xs)          = ", count(iseven, xs))
println("any(x -> x > 8, xs)        = ", any(x -> x > 8, xs))
println("all(x -> x > 0, xs)        = ", all(x -> x > 0, xs))
println("sort(by = x -> -x)         = ", sort(xs; by = x -> -x))
println("sqrt.(1:5)  (broadcast)    = ", sqrt.(1:5))

# -----------------------------------------------------------------------------
secao("2.5 - Criando nossa própria função de alta ordem")
# -----------------------------------------------------------------------------

function aplicar_em_todos(f, colecao)
    map(f, colecao)
end
println("aplicar_em_todos(sqrt, [1,4,9]) = ", aplicar_em_todos(sqrt, [1, 4, 9]))

# HOF que orquestra várias outras HOFs (filter -> map -> reduce).
# Note o uso de Base.Fix2/Fix1 para "fixar" um argumento de filter/map/reduce.
function processar(f, p, g, colecao)
    colecao |>
        Base.Fix1(filter, p) |>      # filter(p, ·)
        Base.Fix1(map, f) |>         # map(f, ·)
        Base.Fix1(reduce, g)         # reduce(g, ·)
end
println("soma dos quadrados dos pares de 1:10 = ",
        processar(x -> x^2, iseven, +, collect(1:10)))

# -----------------------------------------------------------------------------
secao("2.6 - Polimorfismo por multiple dispatch: mesmo nome, tipos diferentes")
# -----------------------------------------------------------------------------

agregar(f, xs::AbstractVector) = reduce(f, xs)
agregar(f, xs::AbstractDict)   = reduce(f, values(xs))
agregar(f, xs::AbstractString) = reduce(f, collect(xs))
agregar(f, xs::Tuple)          = reduce(f, xs)

println("agregar(*, [1, 2, 3, 4])                     = ", agregar(*, [1, 2, 3, 4]))
println("agregar(+, Dict(a => 1, b => 2))             = ", agregar(+, Dict("a" => 1, "b" => 2)))
println("agregar((a,b) -> string(a,b), \"abc\")         = ", agregar((a, b) -> string(a, b), "abc"))
println("agregar(max, (3, 9, 4))                      = ", agregar(max, (3, 9, 4)))

# O compilador escolhe o método pelo TIPO do argumento em tempo de chamada:
for x in ([1, 2, 3], Dict("x" => 5), "abc", (1, 2))
    ok = hasmethod(agregar, Tuple{typeof(iseven), typeof(x)})
    println("  existe método p/ ", rpad(string(typeof(x)), 28), " -> ", ok)
end

# -----------------------------------------------------------------------------
secao("2.7 - Polimorfismo paramétrico (where)")
# -----------------------------------------------------------------------------

function resumo(xs::AbstractVector{T}) where {T <: Number}
    s = reduce(+, xs)
    return (tipo = T, tamanho = length(xs), soma = s, media = s / length(xs))
end

println("Int      : ", resumo([1, 2, 3, 4]))
println("Float64  : ", resumo([1.5, 2.5]))
println("Rational : ", resumo([1//2, 1//3]))

# -----------------------------------------------------------------------------
secao("2.8 - HOF aceitando até functors (objetos chamáveis)")
# -----------------------------------------------------------------------------

struct Dobrar end
(d::Dobrar)(x) = 2x

println("aplicar_em_todos(Dobrar(), [1, 2, 3]) = ", aplicar_em_todos(Dobrar(), [1, 2, 3]))

# -----------------------------------------------------------------------------
secao("2.9 - Pipeline final: filter + map + reduce com |>, ∘ e aplicação parcial")
# -----------------------------------------------------------------------------

resultado = 1:20 |>
            (Base.Fix1(filter, iseven)) |>     # mantém os pares
            (Base.Fix1(map, x -> x^2)) |>      # eleva ao quadrado
            (Base.Fix1(reduce, +))             # soma tudo
println("soma dos quadrados dos pares de 1:20 = ", resultado)
