# Sistemas de Funções na Linguagem Julia

**Trabalho — Parte 2: como funciona o sistema de funções na linguagem Julia**

## Integrantes
- Enzo Sliva Bellotti
- Clóvis de Almeida Pelosini

> Todo o código deste trabalho foi **executado** com **Julia 1.11.5**.
> Os arquivos estão em `exemplos/parte1.jl`, `exemplos/parte2.jl`,
> `exemplos/parte3.jl` e `exemplos/parte4.jl`.
>
> Para reproduzir:
>
> ```bash
> julia exemplos/parte1.jl
> julia exemplos/parte2.jl
> julia exemplos/parte3.jl
> julia exemplos/parte4.jl
> ```

---

## Sumário

1. [Parte 1 — Como funções são tratadas em Julia](#parte-1--como-funções-são-tratadas-em-julia)
2. [Parte 2 — Funções de alta ordem](#parte-2--funções-de-alta-ordem)
3. [Parte 3 — Funções parciais e Currying](#parte-3--funções-parciais-e-currying)
4. [Parte 4 — Tipos algébricos e Mônadas](#parte-4--tipos-algébricos-e-mônadas)
5. [Conclusão](#conclusão)

---

# Parte 1 — Como funções são tratadas em Julia?

## 1.1 Função é um tipo?

**Sim.** Em Julia, funções são **cidadãs de primeira classe** (*first-class
citizens*): são valores, têm tipo, podem ser guardadas em variáveis, colocadas
em coleções, passadas por parâmetro e devolvidas como resultado.

Toda função é um subtipo do tipo **abstrato** `Function`. O tipo concreto de uma
função nomeada (`sqrt`) é um *tipo singleton* — isto é, existe **um único
valor** daquele tipo, a própria função.

```julia
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
```

**Saída:**

```text
----------------------------------------------------------------------
1.1 - Função é um tipo? Sim: toda função é um valor do tipo Function
----------------------------------------------------------------------
sqrt         isa Function : true
(x -> x^2)   isa Function : true
typeof(sqrt)              : typeof(sqrt)
typeof(+)                 : typeof(+)
typeof(f_anon)            : var"#1#2"
Function é tipo abstrato? : true
supertype(typeof(sqrt))   : Function
typeof(f_anon) === typeof(g_anon)? : false
typeof(sqrt) <: Function     : true
(minha::Function)(21)        : 42
```

**Observações importantes:**

- `typeof(sqrt)` imprime `typeof(sqrt)`: este é o *nome* do tipo singleton da
  função `sqrt`. Já uma lambda anônima recebe um nome gerado pelo compilador
  (`var"#1#2"`), e **cada lambda tem um tipo diferente** (por isso
  `typeof(f_anon) === typeof(g_anon)` é `false`).
- Isso é possível porque o tipo de uma função é um **tipo singleton**: há um só
  valor habitando aquele tipo. O compilador usa isso para *devirtualizar*
  chamadas e gerar código tão rápido quanto chamadas diretas.

## 1.2 Dá para passar uma função por parâmetro?

**Sim**, e também devolvê-la e guardá-la.

```julia
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
```

**Saída:**

```text
----------------------------------------------------------------------
1.2 - Funções são valores: passam-se por parâmetro, retornam-se, guardam-se
----------------------------------------------------------------------
aplicar(sqrt, 16)              = 4.0
aplicar(x -> x + 1, 41)        = 42
executar(abs, -7)              = 7
map(o -> o(9), ops)            = Real[3.0, 9, 10]
potenciador(2)(5)              = 25
potenciador(3)(3)              = 27
compor(x->x+1, x->2x)(10)      = 21
```

Uma **closure** (`potenciador`) é uma função que "captura" variáveis do escopo
onde foi criada. Aqui `quadrado` e `cubo` são funções distintas que lembram,
respectivamente, `n = 2` e `n = 3`.

## 1.3 As várias sintaxes de definição

```julia
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
```

**Saída:**

```text
----------------------------------------------------------------------
1.3 - Sintaxes: forma curta, longa, varargs, defaults e keyword args
----------------------------------------------------------------------
dobro(10)                          = 20
soma(2, 3)                         = 5
potencia(3)  (default 2)           = 9
potencia(3, 4)                     = 81
media(1, 2, 3, 4)                  = 2.5
saudacao("Julia")                  = Olá, Julia!
saudacao("Julia"; pontuacao = "?") = Olá, Julia?
```

Recursos da assinatura de funções em Julia:

| Recurso | Exemplo |
|---|---|
| Forma curta | `dobro(x) = 2x` |
| Forma longa | `function f(x) ... end` |
| Valor padrão | `potencia(base, expoente = 2)` |
| Varargs | `media(xs...)` |
| Argumentos nomeados (*keyword*) | `saudacao(nome; saudacao = "Olá")` |
| Anotação de tipo | `area(r::Real)` |
| Tipos paramétricos | `resumo(xs::AbstractVector{T}) where {T}` |
| Métodos múltiplos | vários `area(...)` |
| Docstring | `"""..."""` acima da função |
| Retorno implícito | a última expressão é o retorno |

## 1.4 Vários métodos: *Multiple Dispatch*

Este é o recurso mais característico de Julia. Um nome de função é uma
**função genérica**: um conjunto de *métodos*. O método executado é escolhido
pelos **tipos** de todos os argumentos, em tempo de chamada.

```julia
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
```

**Saída:**

```text
----------------------------------------------------------------------
1.4 - Uma função pode ter VÁRIOS métodos (multiple dispatch)
----------------------------------------------------------------------
area(1.0)             (círculo)   = 3.141592653589793
area(3.0, 4.0)        (retângulo) = 12.0
area(Triangulo(3, 4)) (triângulo) = 6.0
area é uma função genérica com 3 métodos.
```

Isso é decisivo para a Parte 2: como o *dispatch* é feito pelos tipos (e não por
um objeto receptor, como em OO clássico), o **polimorfismo em Julia é o
*multiple dispatch***.

## 1.5 Funções como objetos: `struct` callable (*functor*)

Qualquer objeto pode se comportar como função: basta definir um método para o
próprio tipo usando a sintaxe `(p::Tipo)(args...)`. O objeto **não** herda de
`Function`, mas é chamável.

```julia
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
```

**Saída:**

```text
----------------------------------------------------------------------
1.5 - Funções como objeto: struct "chamável" (functor)
----------------------------------------------------------------------
p(2.0)  (1 + 2x + 3x²)        = 17.0
p isa Function?               = false  (mas é chamável!)
```

## 1.6 O bloco `do`

O `do` é açúcar sintático: `f(args...) do x ... end` significa
`f(x -> ..., args...)`, isto é, a função anônima vira o **primeiro** argumento.

```julia
resultado = map([1, 2, 3]) do x
    x^2
end
println("map([1,2,3]) do x; x^2 end    = ", resultado)

with_lock(f) = (println("[lock adquirido]"); r = f(); println("[lock liberado]"); r)
with_lock() do
    println("... seção crítica ...")
end
```

**Saída:**

```text
----------------------------------------------------------------------
1.6 - O bloco `do`: açúcar sintático para passar uma função anônima
----------------------------------------------------------------------
map([1,2,3]) do x; x^2 end    = [1, 4, 9]
[lock adquirido]
... seção crítica ...
[lock liberado]
```

---

# Parte 2 — Funções de alta ordem

Uma **função de alta ordem (HOF)** é uma função que recebe funções como
argumento e/ou devolve funções. Como Julia tem funções como valores
(Parte 1), HOFs são o estilo natural da linguagem.

## 2.1 `map`

Aplica uma função a cada elemento, devolvendo uma **nova** coleção.

```julia
xs = collect(1:10)

println("map(x -> x^2, xs)        = ", map(x -> x^2, xs))
println("map(+, xs, 10:10:100)    = ", map(+, xs, 10:10:100))   # dois iteráveis
println("map(sqrt, [1, 4, 9, 16]) = ", map(sqrt, [1, 4, 9, 16]))
```

**Saída:**

```text
map(x -> x^2, xs)        = [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
map(+, xs, 10:10:100)    = [11, 22, 33, 44, 55, 66, 77, 88, 99, 110]
map(sqrt, [1, 4, 9, 16]) = [1.0, 2.0, 3.0, 4.0]
```

## 2.2 `filter`

Mantém apenas os elementos que satisfazem o predicado.

```julia
println("filter(iseven, xs)          = ", filter(iseven, xs))
println("filter(x -> x % 3 == 0, xs) = ", filter(x -> x % 3 == 0, xs))
println("filter(>(5), xs)            = ", filter(>(5), xs))   # aplicação parcial
```

**Saída:**

```text
filter(iseven, xs)          = [2, 4, 6, 8, 10]
filter(x -> x % 3 == 0, xs) = [3, 6, 9]
filter(>(5), xs)            = [6, 7, 8, 9, 10]
```

> Repare em `filter(>(5), xs)`: `>(5)` já é uma função pronta
> (`Base.Fix2(>, 5)`), ou seja, o próprio `Base` fornece formas parcialmente
> aplicadas dos operadores de comparação. Esse tema volta na Parte 3.

## 2.3 `reduce` e *folds*

`reduce` "dobra" a coleção usando uma função binária.

```julia
println("reduce(+, xs)              = ", reduce(+, xs))
println("reduce(*, 1:5)             = ", reduce(*, 1:5))
println("reduce(+, xs; init = 100)  = ", reduce(+, xs; init = 100))
println("foldl(-, 1:4)              = ", foldl(-, 1:4), "   ((1-2)-3)-4")
println("foldr(-, 1:4)              = ", foldr(-, 1:4), "   1-(2-(3-4))")
println("mapreduce(x -> x^2, +, xs) = ", mapreduce(x -> x^2, +, xs))
println("sum(x -> x^2, xs)          = ", sum(x -> x^2, xs), "   (açúcar p/ mapreduce)")
```

**Saída:**

```text
reduce(+, xs)              = 55
reduce(*, 1:5)             = 120
reduce(+, xs; init = 100)  = 155
foldl(-, 1:4)              = -8   ((1-2)-3)-4
foldr(-, 1:4)              = -2   1-(2-(3-4))
mapreduce(x -> x^2, +, xs) = 385
sum(x -> x^2, xs)          = 385   (açúcar p/ mapreduce)
```

`foldl` associa à esquerda e `foldr` à direita — por isso `-` dá resultados
diferentes. `mapreduce` combina `map` + `reduce` em uma única passagem, sem
criar a coleção intermediária (eficiência).

## 2.4 Outras HOFs prontas na `Base`

```julia
print("foreach(x -> print(x, \" \"), 1:5) = "); foreach(x -> print(x, " "), 1:5); println()
println("count(iseven, xs)          = ", count(iseven, xs))
println("any(x -> x > 8, xs)        = ", any(x -> x > 8, xs))
println("all(x -> x > 0, xs)        = ", all(x -> x > 0, xs))
println("sort(by = x -> -x)         = ", sort(xs; by = x -> -x))
println("sqrt.(1:5)  (broadcast)    = ", sqrt.(1:5))
```

**Saída:**

```text
foreach(x -> print(x, " "), 1:5) = 1 2 3 4 5 
count(iseven, xs)          = 5
any(x -> x > 8, xs)        = true
all(x -> x > 0, xs)        = true
sort(by = x -> -x)         = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
sqrt.(1:5)  (broadcast)    = [1.0, 1.4142135623730951, 1.7320508075688772, 2.0, 2.23606797749979]
```

## 2.5 Criando nossa própria HOF

```julia
function aplicar_em_todos(f, colecao)
    map(f, colecao)
end
println("aplicar_em_todos(sqrt, [1,4,9]) = ", aplicar_em_todos(sqrt, [1, 4, 9]))

# HOF que orquestra várias outras HOFs (filter -> map -> reduce).
# Note o uso de Base.Fix1 para "fixar" o primeiro argumento de filter/map/reduce.
function processar(f, p, g, colecao)
    colecao |>
        Base.Fix1(filter, p) |>      # filter(p, ·)
        Base.Fix1(map, f) |>         # map(f, ·)
        Base.Fix1(reduce, g)         # reduce(g, ·)
end
println("soma dos quadrados dos pares de 1:10 = ",
        processar(x -> x^2, iseven, +, collect(1:10)))
```

**Saída:**

```text
aplicar_em_todos(sqrt, [1,4,9]) = [1.0, 2.0, 3.0]
soma dos quadrados dos pares de 1:10 = 220
```

## 2.6 HOF + polimorfismo: *multiple dispatch*

A mesma HOF pode ter comportamentos diferentes para tipos diferentes de
coleção, **sem `if`/`switch` e sem classes/fábricas**.

```julia
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
```

**Saída:**

```text
agregar(*, [1, 2, 3, 4])                     = 24
agregar(+, Dict(a => 1, b => 2))             = 3
agregar((a,b) -> string(a,b), "abc")         = abc
agregar(max, (3, 9, 4))                      = 9
  existe método p/ Vector{Int64}                -> true
  existe método p/ Dict{String, Int64}          -> true
  existe método p/ String                       -> true
  existe método p/ Tuple{Int64, Int64}          -> true
```

## 2.7 Polimorfismo paramétrico (`where`)

Além de despachar por tipo, é possível **parametrizar** pela *estrutura* do
tipo, mantendo a mesma implementação para qualquer `T` que seja `Number`.

```julia
function resumo(xs::AbstractVector{T}) where {T <: Number}
    s = reduce(+, xs)
    return (tipo = T, tamanho = length(xs), soma = s, media = s / length(xs))
end

println("Int      : ", resumo([1, 2, 3, 4]))
println("Float64  : ", resumo([1.5, 2.5]))
println("Rational : ", resumo([1//2, 1//3]))
```

**Saída:**

```text
Int      : (tipo = Int64, tamanho = 4, soma = 10, media = 2.5)
Float64  : (tipo = Float64, tamanho = 2, soma = 4.0, media = 2.0)
Rational : (tipo = Rational{Int64}, tamanho = 2, soma = 5//6, media = 5//12)
```

## 2.8 HOF aceitando *functors* (objetos chamáveis, da Parte 1.5)

```julia
struct Dobrar end
(d::Dobrar)(x) = 2x

println("aplicar_em_todos(Dobrar(), [1, 2, 3]) = ", aplicar_em_todos(Dobrar(), [1, 2, 3]))
```

**Saída:**

```text
aplicar_em_todos(Dobrar(), [1, 2, 3]) = [2, 4, 6]
```

## 2.9 Pipeline final: `filter` → `map` → `reduce`

```julia
resultado = 1:20 |>
            (Base.Fix1(filter, iseven)) |>     # mantém os pares
            (Base.Fix1(map, x -> x^2)) |>      # eleva ao quadrado
            (Base.Fix1(reduce, +))             # soma tudo
println("soma dos quadrados dos pares de 1:20 = ", resultado)
```

**Saída:**

```text
soma dos quadrados dos pares de 1:20 = 1540
```

---

# Parte 3 — Funções parciais e Currying

## 3.1 Como a linguagem lida com o encadeamento de funções?

Julia oferece três mecanismos principais:

**(a) O operador *pipe* `|>`** — passa o valor da esquerda como primeiro
argumento da função da direita: `x |> f` é `f(x)`.

```julia
f(x) = x + 1
g(x) = 2x

println("16 |> sqrt |> f |> g   = ", 16 |> sqrt |> f |> g)
println("g(f(sqrt(16)))         = ", g(f(sqrt(16))), "   (idêntico, sem aninhamento)")
```

**(b) O operador de composição `∘`** — `(f ∘ g)(x) == f(g(x))` (aplica da
direita para a esquerda, como em matemática). O resultado é uma
`ComposedFunction`, que é uma função como qualquer outra.

```julia
h = g ∘ f ∘ sqrt
println("(g ∘ f ∘ sqrt)(16)     = ", h(16))
println("h isa Function         = ", h isa Function)
println("typeof(h)              = ", typeof(h))
println("invertendo a ordem: (sqrt ∘ f ∘ g)(16) = ", (sqrt ∘ f ∘ g)(16))
println("((x -> x + 1) ∘ (x -> 2x))(10) = ", ((x -> x + 1) ∘ (x -> 2x))(10))
```

**Saída:**

```text
----------------------------------------------------------------------
3.1 - Encadeamento de funções com o operador pipe |>
----------------------------------------------------------------------
16 |> sqrt |> f |> g   = 10.0
g(f(sqrt(16)))         = 10.0   (idêntico, sem aninhamento)

----------------------------------------------------------------------
3.2 - Composição de funções com ∘ (ComposedFunction)
----------------------------------------------------------------------
(g ∘ f ∘ sqrt)(16)     = 10.0
h isa Function         = true
typeof(h)              = ComposedFunction{ComposedFunction{typeof(g), typeof(f)}, typeof(sqrt)}
invertendo a ordem: (sqrt ∘ f ∘ g)(16) = 5.744562646538029
((x -> x + 1) ∘ (x -> 2x))(10) = 21
```

## 3.2 Currying automático **não** existe em Julia

Julia **não** faz *currying* implícito nem aplicação parcial automática como
Haskell. Se você chamar uma função com menos argumentos do que ela exige, você
recebe um `MethodError`:

```julia
soma3(a, b, c) = a + b + c

erro = try
    soma3(1)                      # parcial "ao estilo Haskell"
    "funcionou"
catch e
    string(typeof(e))
end
println("soma3(1) -> ", erro, "   (não existe currying implícito)")
```

**Saída:**

```text
soma3(1) -> MethodError   (não existe currying implícito)
```

Em Haskell, `soma3 1 2 3 == ((soma3 1) 2) 3` — toda função é unária e já
curried. Em Julia é preciso **pedir** a aplicação parcial.

## 3.3 Aplicação parcial nativa: `Base.Fix1` e `Base.Fix2`

Desde a versão 1.7, a `Base` oferece dois tipos para isso:

- `Base.Fix1(f, a)` → cria `x -> f(a, x)` (fixa o **1º** argumento);
- `Base.Fix2(f, b)` → cria `x -> f(x, b)` (fixa o **2º** argumento).

```julia
dobrar_todos = Base.Fix1(map, x -> 2x)
println("dobrar_todos([1, 2, 3])      = ", dobrar_todos([1, 2, 3]))   # map(f, ·)

maior_que_5  = Base.Fix2(>, 5)
println("filter(maior_que_5, 1:10)    = ", filter(maior_que_5, 1:10))  # · > 5

soma10 = Base.Fix1(+, 10)
println("soma10(5)                    = ", soma10(5))
println("soma10 isa Function          = ", soma10 isa Function)
println("typeof(soma10)               = ", typeof(soma10))

# Os operadores de comparação já vêm "pré-aplicados" na Base:
println("filter(>(5), 1:10)          = ", filter(>(5), 1:10))
println("typeof(>(5))                 = ", typeof(>(5)))
```

**Saída:**

```text
dobrar_todos([1, 2, 3])      = [2, 4, 6]
filter(maior_que_5, 1:10)    = [6, 7, 8, 9, 10]
soma10(5)                    = 15
soma10 isa Function          = true
typeof(soma10)               = Base.Fix1{typeof(+), Int64}
filter(>(5), 1:10)          = [6, 7, 8, 9, 10]
typeof(>(5))                 = Base.Fix2{typeof(>), Int64}
```

> Note que `Base.Fix1`/`Fix2` são, eles próprios, *callables* (functors!) e
> portanto `isa Function` — o que confirma a Parte 1.

## 3.4 Funções parciais com *closures*

A forma mais comum (e mais legível) de criar uma função parcial é simplesmente
devolver uma lambda que captura os argumentos já aplicados.

```julia
adicionar(a) = b -> a + b
soma5 = adicionar(5)
println("adicionar(5)(10)             = ", soma5(10))

# Uma função auxiliar genérica de aplicação parcial
partial(f, args...) = (rest...) -> f(args..., rest...)

multiplica(a, b, c) = a * b * c
mult_por_6 = partial(multiplica, 2, 3)   # fixa 2 e 3
println("partial(multiplica, 2, 3)(4) = ", mult_por_6(4))
```

**Saída:**

```text
adicionar(5)(10)             = 15
partial(multiplica, 2, 3)(4) = 24
```

## 3.5 Currying manual

Se você quiser o estilo de Haskell, é preciso implementar o *currying*
(transformar `f(a, b)` em `f(a)(b)`) explicitamente.

```julia
curry_(f)    = a -> b -> f(a, b)
curry_(f, a) = b -> f(a, b)

soma = curry_(+)
println("curry_(+)(3)(4)              = ", soma(3)(4))
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
```

**Saída:**

```text
curry_(+)(3)(4)              = 7
curry_(+, 3)(4)              = 7
curry((a,b,c,d)->a+b+c+d, 4)(1)(2)(3)(4) = 10
curry(+, 2)(3)(4)                        = 7
uncurry2(curry_(+))(3, 4)               = 7
```

## 3.6 Encadeando funções parciais

A combinação de **aplicação parcial + composição** produz *pipelines* muito
declarativos:

```julia
somar_todos  = Base.Fix1(reduce, +)
quadrados    = Base.Fix1(map, x -> x^2)
apenas_pares = Base.Fix1(filter, iseven)

processar = somar_todos ∘ quadrados ∘ apenas_pares
println("(somar ∘ quadratico ∘ pares)(1:20) = ", processar(1:20))
```

**Saída:**

```text
soma dos quadrados dos pares de 1:20 = 1540
(somar ∘ quadratico ∘ pares)(1:20) = 1540
```

---

# Parte 4 — Tipos algébricos e Mônadas

## 4.1 Tipos algébricos: **produtos**

Julia **não** tem `data` (Haskell) nem `enum` (Rust), mas os *tipos algébricos*
podem ser modelados com os recursos da própria linguagem.

O **tipo produto** (um valor com vários campos) é simplesmente um `struct`:

```julia
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
```

**Saída:**

```text
p                     = Ponto(3.0, 4.0)
norma(p)              = 5.0
mover(p, 1, 1)        = Ponto(4.0, 5.0)
```

## 4.2 Tipos algébricos: **somas** (*tagged unions*)

Um **tipo soma** (um valor que é *uma entre* várias alternativas) se modela com
**tipo abstrato + subtipos concretos**. A "etiqueta" (*tag*) é o próprio tipo
concreto e o "*pattern matching*" é feito por *multiple dispatch*.

```julia
abstract type Forma end

struct Circulo   <: Forma; raio::Float64;                     end
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
```

**Saída:**

```text
subtipos de Forma  = Any[Circulo, Retangulo, Triangulo]
  círculo de raio 1.0                -> área = 3.1416
  retângulo 2.0 x 3.0                -> área = 6.0
  triângulo com base 3.0             -> área = 6.0
área total          = 15.1416
```

> Quando o "*matching*" não é sobre tipos, pode-se usar `isa`:
>
> ```julia
> function classificar(f::Forma)
>     f isa Circulo && return "redondo"
>     f isa Retangulo && return "retangular"
>     return "outro"
> end
> # classificar(Circulo(1.0)) = redondo
> ```
>
> Para *pattern matching* mais completo existe o pacote `Match.jl`
> (`@match`), que não faz parte da `Base`.

## 4.3 Union types como tipos soma

Para uniões de tipos **já existentes**, Julia tem o `Union`:

```julia
const NumeroOuTexto = Union{Int, Float64, String}

descrever(x::Int)     = "inteiro: $x"
descrever(x::Float64) = "real: $x"
descrever(x::String)  = "texto: $x"

println("descrever(10)      = ", descrever(10))
println("descrever(1.5)     = ", descrever(1.5))
println("descrever(\"oi\")    = ", descrever("oi"))
println("10 isa NumeroOuTexto       = ", 10 isa NumeroOuTexto)
println("true isa NumeroOuTexto     = ", true isa NumeroOuTexto)
```

**Saída:**

```text
NumeroOuTexto = Union{Float64, Int64, String}
descrever(10)      = inteiro: 10
descrever(1.5)     = real: 1.5
descrever("oi")    = texto: oi
10 isa NumeroOuTexto       = true
true isa NumeroOuTexto     = false
```

## 4.4 Mônada `Maybe` (*Option*)

Uma **mônada** é um tipo que encapsula um "efeito" e fornece duas operações:
o *return*/*pure* (colocar um valor "no contexto") e o *bind* (`>>=`, encadear
computações que produzem o mesmo contexto).

Julia já traz, na `Base`, os tipos `Some{T}` e `Nothing`, ideais para modelar
`Maybe`:

```julia
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
```

**Saída:**

```text
mreturn(4)                    = Some(4)
inv_seguro(4)                 = Some(0.25)
inv_seguro(0)                 = nothing
mbind(inv_seguro, Some(4))    = Some(0.25)
mbind(inv_seguro, Some(0))    = nothing
mmap(x -> x^2, Some(5))       = Some(25)
mmap(x -> x^2, nothing)       = nothing
```

O ganho da mônada: **encadear** passos que podem falhar **sem** `if`s aninhados.

```julia
# versão "verbosa", com verificação manual:
function sem_monada(x)
    a = inv_seguro(x)
    a === nothing && return nothing
    b = inv_seguro(a.value)
    b === nothing && return nothing
    return Some(2 * b.value)
end

# versão monádica, com bind:
println("versão verbosa p/ x = 4       = ", sem_monada(4))
println("versão monádica p/ x = 4      = ",
        mbind(y -> Some(2y), mbind(inv_seguro, inv_seguro(4))))
```

**Saída:**

```text
versão verbosa p/ x = 4       = Some(8.0)
versão monádica p/ x = 4      = Some(8.0)
```

### As três leis das mônadas

Verificamos as leis com o `Maybe`:

```julia
f(x) = Some(x + 1)
g_(x) = Some(2x)
a = 3
m = Some(10)

println("identidade à esquerda: mbind(f, mreturn(a)) == f(a)        -> ",
        mbind(f, mreturn(a)) == f(a))
println("identidade à direita : mbind(mreturn, m)    == m           -> ",
        mbind(mreturn, m) == m)
println("associatividade      : mbind(g, mbind(f,m)) == mbind(..)   -> ",
        mbind(g_, mbind(f, m)) == mbind(x -> mbind(g_, f(x)), m))
```

**Saída:**

```text
identidade à esquerda: mbind(f, mreturn(a)) == f(a)        -> true
identidade à direita : mbind(mreturn, m)    == m           -> true
associatividade      : mbind(g, mbind(f,m)) == mbind(..)   -> true
```

## 4.5 Mônada `Result` (*Either*)

Para distinguir "sucesso" de "erro com motivo", usamos dois tipos como um
tipo soma: `Ok{T} | Erro{E}`.

```julia
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

programa(s) = rbind(metade, rbind(metade, parse_seguro(s)))
println("programa(\"40\")  = ", programa("40"))
println("programa(\"10\")  = ", programa("10"))
println("programa(\"abc\") = ", programa("abc"))
```

**Saída:**

```text
rbind(metade, parse_seguro("10"))   = Ok{Int64}(5)
rbind(metade, parse_seguro("7"))    = Erro{String}("número ímpar: 7")
rbind(metade, parse_seguro("abc"))  = Erro{String}("não é inteiro: \"abc\"")
programa("40")  = Ok{Int64}(10)
programa("10")  = Erro{String}("número ímpar: 5")
programa("abc") = Erro{String}("não é inteiro: \"abc\"")
```

Observe que, uma vez que o erro aparece, todos os passos seguintes são
**ignorados** (`rbind(f, e::Erro) = e`) — exatamente o curto-circuito típico
da mônada `Either`.

## 4.6 Outros "efeitos" modelados por tipos na linguagem

```julia
println("1 + missing            = ", 1 + missing)
println("ismissing(1 + missing) = ", ismissing(1 + missing))
println("Union{} (Bottom)       = ", Union{})
println("Union{Int,String}      = ", Union{Int, String})
```

**Saída:**

```text
1 + missing            = missing
ismissing(1 + missing) = true
Union{} (Bottom)       = Union{}
Union{Int,String}      = Union{Int64, String}
```

- `missing` (tipo `Missing`) é o "valor ausente" oficial da linguagem e se
  **propaga automaticamente** por qualquer operação (`1 + missing == missing`).
- `Union{}` é o tipo **Bottom**, sem habitantes — útil em teoria de tipos.

## 4.7 Observação sobre `do`-notation

Julia possui blocos `do`, mas eles **não** são *do-notation monádica*:

```julia
f(x) do y
    ...
end
# é exatamente:  f(y -> ..., x)
```

Não há açúcar sintático ligado a `>>=`/`bind` de uma mônada como em Haskell.
As mônadas em Julia existem, mas são **implementadas à mão** (como fizemos
acima) com HOFs e *multiple dispatch*.

---

# Conclusão

| Tópico | Como Julia resolve |
|---|---|
| **Função é um tipo?** | Sim. `Function` é um tipo abstrato; cada função tem um tipo (singleton) próprio. |
| **Passar função por parâmetro?** | Sim — funções são valores de primeira classe; podem ser argumentos, retornos, campos e elementos de coleções. |
| **Polimorfismo** | *Multiple dispatch*: o método é escolhido pelos tipos de **todos** os argumentos; mais tipos paramétricos (`where`). |
| **Funções de alta ordem** | `map`, `filter`, `reduce`, `foldl`/`foldr`, `mapreduce`, `foreach`, `count`, `any`, `all`, `sort(by=)`, `broadcast` (`f.(x)`), além de HOFs definidas pelo usuário. |
| **Encadeamento** | Operador *pipe* `|>`, composição `∘` (`ComposedFunction`) e chamadas aninhadas. |
| **Currying** | **Não** é automático (ao contrário de Haskell). Implementa-se manualmente com closures ou com uma função `curry` genérica. |
| **Funções parciais** | `Base.Fix1`/`Base.Fix2`, closures, e `partial(f, args...)`. |
| **Tipos algébricos** | Produto = `struct`; Soma = `abstract type` + subtipos (ou `Union`) com *dispatch*/*pattern matching* via métodos. |
| **Mônadas** | Sem suporte nativo; implementadas à mão. `Maybe`/`Option` via `Some`/`nothing`; `Result`/`Either` via `Ok`/`Erro`, com `return` e `bind` definidos pelo usuário. |

**Ideia central:** Julia é uma linguagem **funcional com tipos**, onde o
mecanismo unificador do *sistema de funções* é o **multiple dispatch** — ele
substitui, ao mesmo tempo, a sobrecarga de métodos, o polimorfismo orientado a
objetos e o *pattern matching* de tipos algébricos, tudo com desempenho de
código compilado.

---

## Como executar

```bash
# 1) Com o Julia instalado no PATH:
julia exemplos/parte1.jl
julia exemplos/parte2.jl
julia exemplos/parte3.jl
julia exemplos/parte4.jl

# ou, de uma vez só:
julia exemplos/tudo.jl
```

Versão usada: **Julia 1.11.5** (Linux x86-64).
