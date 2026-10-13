# =============================================================================
# Executa as 4 partes de uma vez, cada uma em um módulo isolado
# (para evitar colisão de nomes entre os exemplos).
#
#   julia exemplos/tudo.jl
# =============================================================================

const DIR = @__DIR__

module Parte1
include(joinpath(@__DIR__, "parte1.jl"))
end

module Parte2
include(joinpath(@__DIR__, "parte2.jl"))
end

module Parte3
include(joinpath(@__DIR__, "parte3.jl"))
end

module Parte4
include(joinpath(@__DIR__, "parte4.jl"))
end

println("\n\n>>> Todas as 4 partes foram executadas com sucesso.")
