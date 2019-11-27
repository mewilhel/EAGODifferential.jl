"""
$(TYPDEF)
"""
struct ScalarParametricODE <: MOI.AbstractScalarSet
end

"""
$(TYPDEF)
"""
struct VectorParametricODE <: MOI.AbstractVectorSet
    dimension::Int
end
