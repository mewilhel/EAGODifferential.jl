"""
$(TYPDEF)
"""
abstract type AbstractParametricFunction <: MOI.AbstractVectorFunction end

"""
$(TYPDEF)
"""
abstract type AbstractParametricVectorSet <: MOI.AbstractSet end

"""
$(TYPDEF)
"""
struct pODEs{T} <: AbstractParametricVectorSet
    f::T
    x0::T
    xL::T
    xU::T
end

function _check_bounds

struct JuMPParametricODEs <: JuMP.AbstractConstraint

function JuMP.build_constraint(_error::Function,
                               expr::ParametricVectorSet,
                               set::ParametricODEs;
                               parameter_bounds::ParameterBounds = ParameterBounds())
    # make the constraint
    offset = JuMP.constant(expr)
    JuMP.add_to_expression!(expr, -offset)
    if length(parameter_bounds) != 0
        InfiniteOpt._check_bounds(parameter_bounds)
    end
    return BoundedScalarConstraint(expr, MOIU.shift_constant(set, -offset),
                                   parameter_bounds, copy(parameter_bounds))
end

"""
$(TYPDEF)
"""
struct pDAEs{T} <: AbstractParametricVectorSet
    f::T
    x0::T
    xL::T
    xU::T
    y0::T
    yL::T
    yU::T
end

"""
$(TYPDEF)
"""
struct EndpointCost{T} <: MOI.AbstractScalarFunction
    continuous_integral::Integral{T}
end

"""
$(TYPDEF)
"""
struct IntegralCost{T} <: MOI.AbstractScalarFunction
    f::T
    x::Vector{MOI.SingleVariable}
    p::Vector{MOI.SingleVariable}
    t::MOI.SingleVariable
end

"""
$(TYPDEF)
"""
struct ContinuousCost{T} <: MOI.AbstractScalarFunction
    endpoint::EndpointCost{T}
    continuous_integral::IntegralCost{T}
end

function JuMP.set_objective(model::JuMP.Model, sense::MOI.OptimizationSense,
                            func::Integral)
end

#=
set_objective_sense(model, sense)
set_objective_function(model, func)
=#
