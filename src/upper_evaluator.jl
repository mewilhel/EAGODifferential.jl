"""
$(TYPEDEF)

$(TYPEDFIELDS)
"""
mutable struct ODEUpperEvaluator{F,G,T,V,I,np} <: MOI.AbstractNLPEvaluator
    nx::Int
    nt::Int
    ng::Int
    last_p::Vector{V}
    x::V
    t::Vector{V}
    xgrad
    xdual::Array{Dual{T,V,np},2}
    pdual::Vector{Dual{T,V,np}}
    fdual::Dual{T,V,np}
    gdual::Dual{T,V,np}
    _p_seed::Partials{np,V}
    _p_inds::UnitRange{Int}
    _param_inds::Vector{ParameterValue}
    integrator
    jacobian_sparsity
    has_nlobj::Bool
    disable_1storder::Bool
    disable_2ndorder::Bool
    objective_callback::F
    constraint_callback::G
end
function ODEUpperEvaluator(np)
    d = new()
    d.disable_1storder = false
    d.disable_2ndorder = true
end

"""
$(TYPEDSIGNATURES)

"""
function eval_integral(d::ODEUpperEvaluator, p)
    if p !== d.last_p
        DiffEqRelax.set(d.integrator, d._param_inds, p)
        DiffEqRelax.integrate!(d.integrator)
        DiffEqRelax.getall!(d.x, d.integrator, DiffEqRelax.Value())
        d.last_p[:] = p
        d.duals_built = false
    end
    return
end

"""
$(TYPEDSIGNATURES)

"""
function build_dual_numbers!(d::ODEUpperEvaluator)
    if !d.duals_built
        getall!(d.xgrad, d.integrator, DiffEqRelax.Gradient{NOMINAL}())
        for i in 1:d.nx
            for j in 1:d.nx
                d.xdual[i,j,:] = Dual{T,V,np}.(x, Partials{np,v}(d.xgrad[i,j,:]))
            end
        end
        d.pdual[:] = Dual{T,v,np}.(p, d._p_seed)
        d.duals_built = true
    end
    return
end

"""
$(TYPEDSIGNATURES)

"""
function MOI.eval_objective(d::ODEUpperEvaluator, p)
    val = 0.0
    if d.has_nlobj
        eval_integral!(d, p)
        val = d.objective_callback(d.x, p, d.t)
    end
    return val
end

"""
$(TYPEDSIGNATURES)

"""
function MOI.eval_objective_gradient(d::ODEUpperEvaluator, df, p)
    if d.has_nlobj
        eval_integral!(d, p)
        build_dual_numbers!(d)
        d.fdual = d.objective_callback(d.xdual, d.pdual, d.t)
        setindex!(df. d.fdual.partials.values, d._p_inds)
    end
    return
end

"""
$(TYPEDSIGNATURES)

"""
function MOI.eval_constraint(d::ODEUpperEvaluator, g, p)
    if d.ng > 0
        if p !== last_p
            eval_integral(d,p)
            d.constraint_callback(g, d.x, p, d.t)
        end
    end
    return
end

"""
$(TYPEDSIGNATURES)

"""
function MOI.jacobian_structure(d::ODEUpperEvaluator)
    if length(d.jacobian_sparsity) > 0
        return d.jacobian_sparsity
    else
        d.jacobian_sparsity = Tuple{Int64,Int64}[(row, idx) for row in 1:d.ng for idx in 1:d.np]
        return d.jacobian_sparsity
    end
end

"""
$(TYPEDSIGNATURES)

"""
function MOI.hessian_lagrangian_structure(d::ODEUpperEvaluator)
    error("Hessian computations not currently supported by ODEUpperEvaluator.")
end

"""
$(TYPEDSIGNATURES)

"""
function _hessian_lagrangian_structure(d::ODEUpperEvaluator)
    error("Hessian lagrangian structure not supported by ODEUpperEvaluator.")
end

"""
$(TYPEDSIGNATURES)

"""
function MOI.eval_constraint_jacobian(d::ODEUpperEvaluator, J, p)
    if !d.disable_1storder
        fill!(J, 0.0)
        if d.ng > 0
            eval_integral!(d, p)
            build_dual_numbers!(d)
            d.constraint_callback(d.gdual, d.xdual, d.pdual, d.t)
            for i in 1:d.ng
                J[i,:] = d.gdual[i].cv_grad[:]
            end
        end
    end
    return
end

"""
$(TYPEDSIGNATURES)

"""
function MOI.features_available(d::ODEUpperEvaluator)
    features = Symbol[]
    if !d.disable_1storder
        push!(features,:Grad)
        push!(features,:Jac)
    end
    if !d.disable_2ndorder
        push!(features,:Hess)
        push!(features,:HessVec)
    end
    return features
end

"""
$(TYPEDSIGNATURES)

"""
MOI.objective_expr(d::ODEUpperEvaluator) = error("ODEUpperEvaluator doesn't provide expression graphs of constraint functions.")

"""
$(TYPEDSIGNATURES)

"""
MOI.constraint_expr(d::ODEUpperEvaluator) = error("ODEUpperEvaluator doesn't provide expression graphs of constraint functions.")

"""
$(TYPEDSIGNATURES)

"""
function MOI.initialize(d::ODEUpperEvaluator, requested_features::Vector{Symbol}) end
