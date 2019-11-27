struct DiffEqExt <: EAGO.ExtensionType end

mutable struct DiffOptimizer{I<:AbstractODERelaxIntegator, S<:MOI.AbstractOptimizer, T<:MOI.AbstractOptimizer} <: MOI.AbstractOptimizer
    inner_optimizer::EAGO.Optimizer{S,T}
    integrator::I
    function DiffOptimizer{I,S,T}(; options) where {I <: AbstractODERelaxIntegrator,
                                                    S <: MOI.AbstractOptimizer,
                                                    T <: MOI.AbstractOptimizer}

        m = new()

        default_opt_dict = Dict{Symbol,Any}()

        default_opt_dict[:integrator] = Wilhelm2019{MC,ImpEuler,ImpEuler}()

        m.inner_optimizer = EAGO.Optimizer(; eago_options)

        return m
    end
end

function MOI.add_constraint(m::DiffOptimizer, v::VectorOfInfinite, pODEs::ParametricODEs{T}) where T
end

function MOI.add_constraint(m::DiffOptimizer, v::VectorOfInfinite, pODEs::ParametricDAEs{T}) where T
end

function EAGO.relax_objective!(t::DiffEqExt, x::EAGO.Optimizer, x0::Vector{Float64})
end

function EAGO.relax_problem!(t::DiffEqExt, x::EAGO.Optimizer, v::Vector{Float64}, q::Int64)
end

function EAGO.preprocess!(t::DiffEqExt, x::EAGO.Optimizer)
end

function EAGO.lower_problem!(t::DiffEqExt, x::EAGO.Optimizer)
end

function initialize_evaluators!(m::EAGO.Optimizer, flag::Bool)
    upper_evaluator = ODEUpperEvaluator{T,V,I,np}()
end

function optimize!(m::DiffOptimizer)
    m.inner_optimizer._start_time = time()

    setrounding(Interval, m.inner_optimizer.rounding_mode)
    _variable_len = length(m.inner_optimizer._variable_info)
    m.inner_optimizer._continuous_variable_number = _variable_len
    m.inner_optimizer._variable_number = _variable_len
    m.inner_optimizer._current_xref = fill(0.0, _variable_len)
    m.inner_optimizer._cut_solution = fill(0.0, _variable_len)
    m.inner_optimizer._lower_solution = fill(0.0, _variable_len)
    m.inner_optimizer._upper_solution = fill(0.0, _variable_len)
    m.inner_optimizer._lower_lvd = fill(0.0, _variable_len)
    m.inner_optimizer._lower_uvd = fill(0.0, _variable_len)
    m.inner_optimizer._continuous_solution = zeros(Float64, _variable_len)

    initialize_evaluators!(m, false)
    presolve_problem!(m.inner_optimizer)

    # Runs the branch and bound routine
    if ~m.inner_optimizer.enable_optimize_hook
        if m.inner_optimizer.local_solve_only
            local_solve!(m.inner_optimizer)
        else
            global_solve!(m.inner_optimizer)
        end
    end

    new_time = time() - m._start_time
    m._parse_time = new_time
    m._run_time = new_time
    return
end

MOI.empty!(m::DiffOptimizer)
MOI.is_empty(m::DiffOptimizer)

MOI.get(m::DiffOptimizer, x::AbstractOptimizerAttribute) = MOI.get(m.inner_optimizer,x)
MOI.add_variable(m::DiffOptimizer) = MOI.add_variable(m.inner_optimizer)
