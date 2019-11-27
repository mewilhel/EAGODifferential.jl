module EAGODifferential


    using EAGO, MathOptInterface, LinearAlgebra

    const MOI = MathOptInterface

    import EAGO: build_evaluator!, set_current_node!, set_last_node!,
                 num_state_variables, num_decision_variables,
                 eval_constraint_cc, eval_constraint_cc_grad

    include("src/calc_ode.jl")

    export ImplicitODELowerEvaluator, ImplicitODEUpperEvaluator,
           build_evaluator!, set_current_node!, set_last_node!,
           num_state_variables, num_decision_variables, solve_ode,
           export_path, eval_constraint_cc, eval_constraint_cc_grad

    include("src/lower_evaluator/lower_evaluator.jl")
    include("src/upper_evaluator/upper_evaluator.jl")
    include("src/solve_ode.jl")
    include("src/data_handling.jl")

end # module
