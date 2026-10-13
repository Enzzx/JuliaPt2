# =============================================================================
# PARTE 4 - Tipos algébricos e Mônadas
# =============================================================================
# Execute com:  julia exemplos/parte4.jl
# =============================================================================

using InteractiveUtils: subtypes

secao(t) = println("\n", "-"^70, "\n", t, "\n", "-"^70)

# -----------------------------------------------------------------------------
secao("4.1 - Tipo PRODUTO: um struct agrupa vários campos (produto cartesiano)")
# -----------------------------------------------------------------------------

struct Ponto
    x::Float64
    y::Float64
end

Ponto() = Ponto(0.0, 0.0)          # construtor extra

mover(p::Ponto, dx, dy) = Ponto(p.x + dx, p.y + dy)
norma(p::Ponto) = sqrt(p.x^2 + p.y^2)

p = Ponto(3.0, 4.0)
println("p                     = ", p)
println("norma(p)              = ", norma(p))
println("mover(p, 1, 1)        = ", mover(p, 1.0, 1.0))

# -----------------------------------------------------------------------------
secao("4.2 - Tipo SOMA: tipo abstrato + subtipos (tagged union)")
# -----------------------------------------------------------------------------
# Julia não tem `data` (Haskell) nem `enum` (Rust), mas o idioma
# "tipo abstrato + structs concretos" modela uma união disjunta:
#   Forma = Circulo | Retangulo | Triangulo
# A "tag" é o próprio tipo concreto, e o "pattern matching" é o dispatch.

abstract type Forma end

struct Circulo   <: Forma; raio::Float64;                 end
struct Retangulo <: Forma; largura::Float64; altura::Float64; end
struct Triangulo <: Forma; base::Float64;    altura::Float64; end

area(f::Circulo)   = π * f.raio^2
area(f::Retangulo) = f.largura * f.altura
area(f::Triangulo) = f.base * f.altura / 2

descricao(f::Circulo)   = "círculo de raio $(f.raio)"
descricao(f::Retangulo) = "retângulo $(f.largura) x $(f.altura)"
descricao(f::Triangulo) = "triângulo com base $(f.base)"

formas = Forma[Circulo(1.0), Retangulo(2.0, 3.0), Triangulo(3.0, 4.0)]

println("subtipos de Forma  = ", subtypes(Forma))
for f in formas
    println("  ", rpad(descricao(f), 34), " -> área = ", round(area(f); digits = 4))
end
println("área total          = ", round(sum(area, formas); digits = 4))

# "Pattern matching" imperativo com isa (quando necessário):
function classificar(f::Forma)
    f isa Circulo && return "redondo"
    f isa Retangulo && return "retangular"
    return "outro"
end
println("classificar(Circulo(1.0)) = ", classificar(Circulo(1.0)))

# A stdlib também oferece `@match` via pacote Match.jl, mas o idioma
# nativo de "casar" tipos é o multiple dispatch acima.

# -----------------------------------------------------------------------------
secao("4.3 - Tipo soma com Union (união de tipos existentes)")
# -----------------------------------------------------------------------------

const NumeroOuTexto = Union{Int, Float64, String}

descrever(x::Int)     = "inteiro: $x"
descrever(x::Float64) = "real: $x"
descrever(x::String)  = "texto: $x"

println("NumeroOuTexto = ", NumeroOuTexto)
println("descrever(10)      = ", descrever(10))
println("descrever(1.5)     = ", descrever(1.5))
println("descrever(\"oi\")    = ", descrever("oi"))
println("10 isa NumeroOuTexto       = ", 10 isa NumeroOuTexto)
println("true isa NumeroOuTexto     = ", true isa NumeroOuTexto)

# -----------------------------------------------------------------------------
secao("4.4 - Mônada MAYBE (Option): Some(x) | nothing")
# -----------------------------------------------------------------------------
# Em Julia, `Some` e `nothing` já existem na Base. Definimos as operações
# `return`/`pure` e `>>=`/`bind` (aqui: `mreturn` e `mbind`).

mreturn(x) = Some(x)                       # return / pure
mbind(f, ::Nothing) = nothing              # >>= sobre "falha"
mbind(f, m::Some)   = f(m.value)           # >>= sobre "sucesso"
mmap(f, m) = mbind(x -> Some(f(x)), m)     # fmap (= map da Functor)

# Uma função "segura" que pode falhar: inverso de x (falha se x == 0)
inv_seguro(x) = x == 0 ? nothing : Some(1 / x)

println("mreturn(4)                    = ", mreturn(4))
println("inv_seguro(4)                 = ", inv_seguro(4))
println("inv_seguro(0)                 = ", inv_seguro(0))
println("mbind(inv_seguro, Some(4))    = ", mbind(inv_seguro, Some(4)))
println("mbind(inv_seguro, Some(0))    = ", mbind(inv_seguro, Some(0)))
println("mmap(x -> x^2, Some(5))       = ", mmap(x -> x^2, Some(5)))
println("mmap(x -> x^2, nothing)       = ", mmap(x -> x^2, nothing))

# Encadeamento monádico: (inv 4) * 2, e cada passo pode falhar
cadeia = mbind(x -> Some(2x), mbind(inv_seguro, Some(4)))
println("mbind(2x, mbind(inv, Some(4)))  = ", cadeia)

# Comparação: o mesmo raciocínio SEM a mônada (código "piramidal")
function sem_monada(x)
    a = inv_seguro(x)
    a === nothing && return nothing
    b = inv_seguro(a.value)
    b === nothing && return nothing
    return Some(2 * b.value)
end
println("versão verbosa p/ x = 4       = ", sem_monada(4))
println("versão monádica p/ x = 4      = ",
        mbind(y -> Some(2y), mbind(inv_seguro, inv_seguro(4))))

# `something` extrai o valor com um default -- o "unwrap_or" de Julia:
println("something(Some(7), 0)         = ", something(Some(7), 0))
println("something(nothing, 0)         = ", something(nothing, 0))

# -----------------------------------------------------------------------------
secao("4.5 - Leis das mônadas (verificação empírica)")
# -----------------------------------------------------------------------------

f(x) = Some(x + 1)
g_(x) = Some(2x)
a = 3
m = Some(10)

esq = mbind(f, mreturn(a)) == f(a)                         # identidade à esquerda
dir = mbind(mreturn, m) == m                               # identidade à direita
assoc = mbind(g_, mbind(f, m)) == mbind(x -> mbind(g_, f(x)), m)  # associatividade

println("identidade à esquerda: mbind(f, mreturn(a)) == f(a)        -> ", esq)
println("identidade à direita : mbind(mreturn, m)    == m           -> ", dir)
println("associatividade      : mbind(g, mbind(f,m)) == mbind(..)   -> ", assoc)

# -----------------------------------------------------------------------------
secao("4.6 - Mônada RESULT / EITHER: Ok(valor) | Erro(motivo)")
# -----------------------------------------------------------------------------

struct Ok{T}
    valor::T
end
struct Erro{E}
    motivo::E
end

rreturn(x) = Ok(x)
rbind(f, e::Erro) = e            # curto-circuito no primeiro erro
rbind(f, o::Ok)   = f(o.valor)

parse_seguro(s) = try
    Ok(parse(Int, s))
catch
    Erro("não é inteiro: \"$s\"")
end

metade(x) = iseven(x) ? Ok(x ÷ 2) : Erro("número ímpar: $x")

println("rbind(metade, parse_seguro(\"10\"))   = ", rbind(metade, parse_seguro("10")))
println("rbind(metade, parse_seguro(\"7\"))    = ", rbind(metade, parse_seguro("7")))
println("rbind(metade, parse_seguro(\"abc\"))  = ", rbind(metade, parse_seguro("abc")))

# encadeando várias operações que podem falhar
programa(s) = rbind(metade, rbind(metade, parse_seguro(s)))
println("programa(\"40\")  = ", programa("40"))
println("programa(\"10\")  = ", programa("10"))
println("programa(\"abc\") = ", programa("abc"))

# -----------------------------------------------------------------------------
secao("4.7 - Outros \"efeitos\" que Julia modela com tipos")
# -----------------------------------------------------------------------------

# ausência de valor: `missing` (tipo Missing) + propagação automática
println("1 + missing            = ", 1 + missing)
println("ismissing(1 + missing) = ", ismissing(1 + missing))

# erros: try/catch é o tratamento imperativo; Union{} é o tipo "bottom"
println("Union{} (Bottom)       = ", Union{})
println("Union{Int,String}      = ", Union{Int, String})

# -----------------------------------------------------------------------------
secao("4.8 - Observação sobre `do`-notation")
# -----------------------------------------------------------------------------
# Julia tem blocos `do`, mas eles NÃO são do-notation monádica:
# `f(x) do y ... end` é apenas `f(y -> ..., x)`.
# Não existe açúcar `>>=`/`do` ligado a uma mônada como em Haskell.
