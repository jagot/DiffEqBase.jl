using DiffEqBase
using Base.Test

mutable struct TestDiffEqOperator{T} <: AbstractDiffEqLinearOperator{T}
    m::Int
    n::Int
end

TestDiffEqOperator{T}(A::AbstractMatrix{T}) =
    TestDiffEqOperator{T}(size(A)...)

Base.size(A::TestDiffEqOperator) = (A.m, A.n)


A = TestDiffEqOperator([0 0; 0 1])
B = TestDiffEqOperator([0 0 0; 0 1 0; 0 0 2])

@test_throws ErrorException AffineDiffEqOperator{Int64}((A,B),())
