function param_values(f::AbstractParameterizedFunction)
  [getfield(f,s) for s in f.params]
end

num_params(f::AbstractParameterizedFunction) = length(f.params)

# Fallbacks

param_values(f) = nothing
num_params(f) = 0

function problem_new_parameters(prob::ODEProblem,p)
  f = (t,u,du) -> prob.f(t,u,p,du)
  uEltype = eltype(p)
  u0 = [uEltype(prob.u0[i]) for i in 1:length(prob.u0)]
  tspan = (uEltype(prob.tspan[1]),uEltype(prob.tspan[2]))
  ODEProblem(f,u0,tspan)
end
param_values(prob::ODEProblem) = param_values(prob.f)
num_params(prob::ODEProblem) = num_params(prob.f)

function problem_new_parameters(prob::DAEProblem,p)
  f = (t,u,du,resid) -> prob.f(t,u,p,du,resid)
  uEltype = eltype(p)
  u0 = [uEltype(prob.u0[i]) for i in 1:length(prob.u0)]
  tspan = (uEltype(prob.tspan[1]),uEltype(prob.tspan[2]))
  DAEProblem(f,u0,tspan)
end
param_values(prob::DAEProblem) = param_values(prob.f)
num_params(prob::DAEProblem) = num_params(prob.f)

function problem_new_parameters(prob::ConstantLagDDEProblem,p)
  f = (t,u,h,du) -> prob.f(t,u,h,p,du)
  uEltype = eltype(p)
  u0 = [uEltype(prob.u0[i]) for i in 1:length(prob.u0)]
  tspan = (uEltype(prob.tspan[1]),uEltype(prob.tspan[2]))
  DAEProblem(f,prob.h,u0,prob.lags,tspan)
end
param_values(prob::ConstantLagDDEProblem) = param_values(prob.f)
num_params(prob::ConstantLagDDEProblem) = num_params(prob.f)

function problem_new_parameters(prob::SDEProblem,p)
  fpars = num_params(prob.f)
  if fpars > 0
    f = (t,u,du) -> prob.f(t,u,@view(p[1:fpars]),du)
    if num_params(prob.g) > 0
      g = (t,u,du) -> prob.g(t,u,@view(p[(fpars+1):end]),du)
    else
      g = prob.g
    end
  else
    f = prob.f
    g = (t,u,du) -> prob.g(t,u,p,du)
  end
  uEltype = eltype(p)
  u0 = [uEltype(prob.u0[i]) for i in 1:length(prob.u0)]
  tspan = (uEltype(prob.tspan[1]),uEltype(prob.tspan[2]))
  SDEProblem(f,g,u0,tspan)
end
param_values(prob::SDEProblem) = (A = [param_values(prob.f) ; param_values(prob.g)]; [A.!=nothing])
num_params(prob::SDEProblem) = num_params(prob.f) + num_params(prob.g)

function problem_new_parameters(prob::MonteCarloProblem,p)
  probpars = num_params(prob.prob)
  pfpars = num_params(prob.prob_func)
  opars = num_params(prob.output_func)
  if probpars > 0
    tmp_prob = problem_new_parameters(prob.prob,@view(p[1:probpars]))
    if pfpars > 0
      prob_func = (prob,i) -> prob.prob_func(prob,i,@view(p[(probpars+1):(probpars+pfpars)]))
      opars>0 ? output_func = prob.output_func(sol,@view(p[(probpars+pfpars+1):end])) : output_func = prob.output_func
    else
      prob_func = prob.prob_func
      opars>0 ? output_func = prob.output_func(sol,@view(p[(probpars+pfpars+1):end])) : output_func = prob.output_func
    end
  else
    tmp_prob = prob.prob
    if pfpars > 0
      prob_func = (prob,i) -> prob.prob_func(prob,i,@view(p[1:pfpars]))
      opars>0 ? output_func = prob.output_func(sol,@view(p[(pfpars+1):end])) : output_func = prob.output_func
    else
      prob_func = prob.prob_func
      output_func = prob.output_func(sol,p)
    end
  end
  MonteCarloProblem(tmp_prob,prob_func,output_func)
end

param_values(prob::MonteCarloProblem) = (A = [param_values(prob.prob) ; param_values(prob.prob_func) ; param_values(prob.output_func)]; [A.!=nothing])
num_params(prob::MonteCarloProblem) = num_params(prob.prob) + num_params(prob.prob_func) + num_params(prob.output_func)