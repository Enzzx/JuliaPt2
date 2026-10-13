# =============================================================================
# PARTE 3 - Funções parciais e Currying
# =============================================================================
# Execute com:  julia exemplos/parte3.jl
# =============================================================================

secao(t) = println("\n", "-"^70, "\n", t, "\n", "-"^70)

# -----------------------------------------------------------------------------
secao("3.1 - Encadeamento de funções com o operador pipe |>")
# -----------------------------------------------------------------------------

f(x) = x + 1
g(x) = 2x

println("16 |> sqrt |> f |> g   = ", 16 |> sqrt |> f |> g)
println("g(f(sqrt(16)))         = ", g(f(sqrt(16))), "   (idêntico, sem aninhamento)")

# -----------------------------------------------------------------------------
secao("3.2 - Composição de funções com ∘ (ComposedFunction)")
# -----------------------------------------------------------------------------

h = g ∘ f ∘ sqrt          # (g ∘ f ∘ sqrt)(x) == g(f(sqrt(x)))
println("(g ∘ f ∘ sqrt)(16)     = ", h(16))
println("h isa Function         = ", h isa Function)
println("typeof(h)              = ", typeof(h))
println("invertendo a ordem: (sqrt ∘ f ∘ g)(16) = ", (sqrt ∘ f ∘ g)(16))

# Funções anônimas também compõem:
dobra = 2 .* (1:5) .+ 1
println("((x -> x + 1) ∘ (x -> 2x))(10) = ", ((x -> x + 1) ∘ (x -> 2x))(10))

# -----------------------------------------------------------------------------
secao("3.3 - Julia NÃO faz currying automático (diferente de Haskell)")
# -----------------------------------------------------------------------------

soma3(a, b, c) = a + b + c

erro = try
    soma3(1)                      # parcial "ao estilo Haskell"
    "funcionou"
catch e
    string(typeof(e))
end
println("soma3(1) -> ", erro, "   (não existe currying implícito)")
println("Em Haskell, soma3 1 2 3 == ((soma3 1) 2) 3; em Julia é preciso pedir.\n")

# -----------------------------------------------------------------------------
secao("3.4 - Aplicação parcial nativa: Base.Fix1 e Base.Fix2")
# -----------------------------------------------------------------------------

# Fix1 fixa o PRIMEIRO argumento; Fix2 fixa o SEGUNDO.
dobrar_todos = Base.Fix1(map, x -> 2x)
println("dobrar_todos([1, 2, 3])      = ", dobrar_todos([1, 2, 3]))

maior_que_5  = Base.Fix2(>, 5)
println("filter(maior_que_5, 1:10)    = ", filter(maior_que_5, 1:10))

soma10 = Base.Fix1(+, 10)
println("soma10(5)                    = ", soma10(5))
println("soma10 isa Function          = ", soma10 isa Function)
println("typeof(soma10)               = ", typeof(soma10))

# Da mesma forma, `Base.Fix2(iseven, ...)`? Não: queremos `filter(iseven, ·)`,
# então Fix1. E os operadores de comparação já vêm "pré-aplicados" na Base:
println("filter(>(5), 1:10)          = ", filter(>(5), 1:10))
println("typeof(>(5))                 = ", typeof(>(5)))

# -----------------------------------------------------------------------------
secao("3.5 - Aplicação parcial via closures")
# -----------------------------------------------------------------------------

adicionar(a) = b -> a + b
soma5 = adicionar(5)
println("adicionar(5)(10)             = ", soma5(10))

# Uma função auxiliar genérica de aplicação parcial
partial(f, args...) = (rest...) -> f(args..., rest...)

multiplica(a, b, c) = a * b * c
mult_por_6 = partial(multiplica, 2, 3)   # fixa 2 e 3
println("partial(multiplica, 2, 3)(4) = ", mult_por_6(4))

# -----------------------------------------------------------------------------
secao("3.6 - Currying manual")
# -----------------------------------------------------------------------------

curry_(f)    = a -> b -> f(a, b)
curry_(f, a) = b -> f(a, b)

soma = curry_(+)
somador3 = soma(3)                       # aplicação parcial do curried
println("curry_(+)(3)(4)              = ", somador3(4))
println("curry_(+, 3)(4)              = ", curry_(+, 3)(4))

# curry genérico para N argumentos, via recursão
function curry(f, aridade::Int)
    passo(args) = length(args) == aridade ? f(args...) : (x) -> passo((args..., x))
    return passo(())
end

soma4 = curry((a, b, c, d) -> a + b + c + d, 4)
println("curry((a,b,c,d)->a+b+c+d, 4)(1)(2)(3)(4) = ", soma4(1)(2)(3)(4))
println("curry(+, 2)(3)(4)                        = ", curry(+, 2)(3)(4))

# uncurry: o caminho de volta (desfaz o currying, virando f(a, b))
uncurry2(fc) = (a, b) -> fc(a)(b)
println("uncurry2(curry_(+))(3, 4)               = ", uncurry2(curry_(+))(3, 4))

# -----------------------------------------------------------------------------
secao("3.7 - Encadeando tudo: pipeline com aplicação parcial")
# -----------------------------------------------------------------------------

resultado = 1:20 |>
            Base.Fix1(filter, iseven) |>       # mantém pares
            Base.Fix1(map, x -> x^2) |>        # eleva ao quadrado
            Base.Fix1(reduce, +)               # soma
println("soma dos quadrados dos pares de 1:20 = ", resultado)

# Composição reutilizável de funções parciais:
somar_todos  = Base.Fix1(reduce, +)
quadrados    = Base.Fix1(map, x -> x^2)
apenas_pares = Base.Fix1(filter, iseven)

processar = somar_todos ∘ quadrados ∘ apenas_pares
println("(somar ∘ quadratico ∘ pares)(1:20) = ", processar(1:20))
