# =============================================================================
# PARTE 1 - Como funções são tratadas na linguagem Julia?
# =============================================================================
# Execute com:  julia exemplos/parte1.jl
# =============================================================================

using InteractiveUtils: subtypes

secao(t) = println("\n", "-"^70, "\n", t, "\n", "-"^70)

# -----------------------------------------------------------------------------
secao("1.1 - Função é um tipo? Sim: toda função é um valor do tipo Function")
# -----------------------------------------------------------------------------

f_anon = x -> x^2
g_anon = x -> x^3

println("sqrt         isa Function : ", sqrt isa Function)
println("(x -> x^2)   isa Function : ", f_anon isa Function)
println("typeof(sqrt)              : ", typeof(sqrt))
println("typeof(+)                 : ", typeof(+))
println("typeof(f_anon)            : ", typeof(f_anon))
println("Function é tipo abstrato? : ", isabstracttype(Function))
println("supertype(typeof(sqrt))   : ", supertype(typeof(sqrt)))

# Cada lambda cria um TIPO PRÓPRIO (tipo singleton): são valores distintos.
println("typeof(f_anon) === typeof(g_anon)? : ", typeof(f_anon) === typeof(g_anon))

# `Function` é um tipo abstrato: qualquer função é um subtipo dele.
println("typeof(sqrt) <: Function     : ", typeof(sqrt) <: Function)

# E por ser um tipo, podemos ANOTAR variáveis/campos com `::Function`
minha::Function = x -> 2x
println("(minha::Function)(21)        : ", minha(21))

# -----------------------------------------------------------------------------
secao("1.2 - Funções são valores: passam-se por parâmetro, retornam-se, guardam-se")
# -----------------------------------------------------------------------------

# (a) recebendo uma função como parâmetro
aplicar(f, x) = f(x)
println("aplicar(sqrt, 16)              = ", aplicar(sqrt, 16))
println("aplicar(x -> x + 1, 41)        = ", aplicar(x -> x + 1, 41))

# (b) restringindo o parâmetro ao tipo abstrato Function
executar(f::Function, x) = f(x)
println("executar(abs, -7)              = ", executar(abs, -7))

# (c) funções guardadas em uma coleção
ops = [sqrt, abs, x -> x + 1]
println("map(o -> o(9), ops)            = ", map(o -> o(9), ops))

# (d) retornando uma função (closure: captura `n` do escopo léxico)
function potenciador(n)
    x -> x^n
end
quadrado = potenciador(2)
cubo     = potenciador(3)
println("potenciador(2)(5)              = ", quadrado(5))
println("potenciador(3)(3)              = ", cubo(3))

# (e) recebendo E devolvendo funções no mesmo HOF
compor(f, g) = x -> f(g(x))
somar1_e_dobrar = compor(x -> x + 1, x -> 2x)
println("compor(x->x+1, x->2x)(10)      = ", somar1_e_dobrar(10))

# -----------------------------------------------------------------------------
secao("1.3 - Sintaxes: forma curta, longa, varargs, defaults e keyword args")
# -----------------------------------------------------------------------------

dobro(x) = 2x                                  # forma curta
function soma(a, b)                            # forma longa
    a + b
end

potencia(base, expoente = 2) = base^expoente    # valor padrão
media(xs...) = sum(xs) / length(xs)             # varargs

function saudacao(nome; saudacao = "Olá", pontuacao = "!")   # keyword args
    "$saudacao, $nome$pontuacao"
end

println("dobro(10)                          = ", dobro(10))
println("soma(2, 3)                         = ", soma(2, 3))
println("potencia(3)  (default 2)           = ", potencia(3))
println("potencia(3, 4)                     = ", potencia(3, 4))
println("media(1, 2, 3, 4)                  = ", media(1, 2, 3, 4))
println("saudacao(\"Julia\")                  = ", saudacao("Julia"))
println("saudacao(\"Julia\"; pontuacao = \"?\") = ", saudacao("Julia"; pontuacao = "?"))

# -----------------------------------------------------------------------------
secao("1.4 - Uma função pode ter VÁRIOS métodos (multiple dispatch)")
# -----------------------------------------------------------------------------

struct Triangulo
    base::Float64
    altura::Float64
end

area(r::Real)          = π * r^2            # círculo
area(l::Real, w::Real) = l * w              # retângulo
area(t::Triangulo)     = t.base * t.altura / 2

println("area(1.0)             (círculo)   = ", area(1.0))
println("area(3.0, 4.0)        (retângulo) = ", area(3.0, 4.0))
println("area(Triangulo(3, 4)) (triângulo) = ", area(Triangulo(3.0, 4.0)))
println("area é uma função genérica com ", length(methods(area)), " métodos.")

# -----------------------------------------------------------------------------
secao("1.5 - Funções como objeto: struct \"chamável\" (functor)")
# -----------------------------------------------------------------------------

struct Polinomio
    coefs::Vector{Float64}      # do menor para o maior grau
end

# Define COMO chamar uma instância: p(x)
function (p::Polinomio)(x)
    sum(c * x^(i - 1) for (i, c) in enumerate(p.coefs))
end

p = Polinomio([1.0, 2.0, 3.0])          # 1 + 2x + 3x²
println("p(2.0)  (1 + 2x + 3x²)        = ", p(2.0))
println("p isa Function?               = ", p isa Function, "  (mas é chamável!)")

# -----------------------------------------------------------------------------
secao("1.6 - O bloco `do`: açúcar sintático para passar uma função anônima")
# -----------------------------------------------------------------------------

resultado = map([1, 2, 3]) do x
    x^2
end
println("map([1,2,3]) do x; x^2 end    = ", resultado)
# equivale a: map(x -> x^2, [1, 2, 3])

# `do` é muito usado para callbacks (abrir/ler arquivos, locks, timers...):
with_lock(f) = (println("[lock adquirido]"); r = f(); println("[lock liberado]"); r)
with_lock() do
    println("... seção crítica ...")
end
