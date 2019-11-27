using JuMP

model = Model(with_optimizer(EAGODifferential.Optimizer));

@variable(model, t in [0, 2])

pL = [10.0; 10.0; 0.001]; pU = [1200.0; 1200.0; 40.0]
@variable(model, p[i=1:np] in Interval.(pL[i], pU[i]))
@variable(model, x[i=1:nx])

@constraint(model, cODEs, [x,p,t] in ParametricODEs(g, x0, xL, xU))

tdisc =
@objective(model, Min, Supported(f,x,p,t,tdisc))

#=
@constraint(model, cDAEs, [x,y,p,t] in ParametricDAEs(g, h, x0, xL, xU,
                                                            y0, yL, yU))
@objective(model, Min, Integral(f,x,p,t))
=#
#ParametricDAEs
