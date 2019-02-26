using EAGO_Differential, EAGO, DataFrames

# soft build, then evaluate
lower_eval = ImplicitODELowerEvaluator{1}()

f(x,p,t) = x[1]
function h(H,x,p,t)
    H[1] = p[1]*x[1]*(1-x[1])
end
function hj(J,x,p,t)
    J[1,1] = p[1]*(1.0-2.0*x[1])
end
x0(p) = [0.1]

np = 1
nx = 1
nt = 10
s = 2

t_start = 0.0
t_end = 1.0
method = :BDF

pL = [1.49]; pU = [1.59]
xL = [0.1]; xU = [1.0]

# build the basic evaluator (w/o inequality constraints)
EAGO_Differential.build_evaluator!(lower_eval, f, h, np, nx, nt, s, t_start, t_end, method, pL, pU, xL, xU, x0; hj = hj)

lower_vars = fill(xL[1], (nt-1,))
upper_vars = fill(xU[1], (nt-1,))
append!(lower_vars, pL)
append!(upper_vars, pU)
n = NodeBB(lower_vars, upper_vars, -Inf, Inf, 0, -1, false)

println("EVALUATE POINT 1")
y = [1.5]
EAGO.set_current_node!(lower_eval, n)
EAGO_Differential.relax_ode_implicit!(lower_eval, y)

println("EVALUATE POINT 2")
y1 = [1.5]
EAGO_Differential.relax_ode_implicit!(lower_eval, y1)



upper_eval = ImplicitODEUpperEvaluator()
EAGO_Differential.build_evaluator!(upper_eval, f, h, np, nx, nt, s, t_start, t_end, method, pL, pU, xL, xU, x0; hj = hj)
EAGO.set_current_node!(upper_eval, n)
EAGO_Differential.relax_ode_implicit!(upper_eval, y)

x = EAGO.Optimizer()
EAGO_Differential.interval_preprocess_ode(x, y)

#=
opt = EAGO.Optimizer()

EAGO_Differential.interval_preprocess_ode!(opt, y)
postpre = deepcopy(y)

nmid = create_mid_node(y, nx, np, nt)

EAGO_Differential.midpoint_upper_bnd_ode!(opt, y)
postubd = deepcopy(y)

EAGO_Differential.solve_ode(f, h, hj, g, x0, xL, xU, pL, pU, t_start, t_end, nt, s, method, opt)
=#
