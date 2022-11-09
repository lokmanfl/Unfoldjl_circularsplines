## Effects
# Effects are super useful to understand the actual modelfits. If you are an EEG-Researcher, you can think of effects as the "modelled ERPs", and the coefficients as the "difference-waves".
# In some way, we are fitting a model with coefficients and then try to get back the "original" ERPs - of course typically with some effect adjusted, overlap removed or similar - else why bother ;)

# Define some packages

using Unfold
using DataFrames
using Random
using CSV
using UnfoldMakie

# # Setup things
# Let's load some data and fit a model of a 2-level categorical and a continuous predictor with interaction.
include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities.jl") ) # to load data

data, evts = loadtestdata("test_case_3a")

basisfunction = firbasis(τ = (-0.5, 1.5), sfreq = 20, name = "basisA")

evts.conditionA= ["off","on"][(evts.conditionA .+1)] # convert evts into categorical
f = @formula 0 ~ 1+conditionA*continuousA # 1

m = fit(UnfoldModel, Dict(Any=>(f,basisfunction)), evts, data,eventcolumn="type")

# Plot the results
plot_erp(coeftable(m))

# As expected, we get four lines - the interaction is flat, the slope of the continuous is around 4, the categorical effect is at 3 and the intercept at 0 (everything is dummy coded by default)
# ### Effects
# A convenience function is [effects](@ref). It allows to specify effects on specific levels, while setting non-specified ones to a typical value (usually the mean)

eff = effects(Dict(:conditionA => ["off","on"]),m)
plot_erp(eff;setMappingValues=(:color=>:conditionA,))

# We can also generate continuous predictions
eff = effects(Dict(:continuousA => -0.5:0.05:1),m)
plot_erp(eff;setMappingValues=(:color=>:continuousA,),setExtraValues=(categoricalColor=false,categoricalGroup=false))

# or split it up by condition
eff = effects(Dict(:conditionA=>["off","on"],:continuousA => -1:.5:1),m)
plot_erp(eff;setMappingValues=(:color=>:conditionA,:col=>:continuousA=>nonnumeric))

# ## What is typical anyway?
# The user can specify the typical function applied to the covariates/factors that are marginalized over. This offers even greater flexibility.
# Note that this is rarely necessary, in most applications the mean will be assumed.
eff_max = effects(Dict(:conditionA=>["off","on"]),m;typical=maximum) # typical continuous value fixed to 1
eff_max.typical .= :maximum
eff = effects(Dict(:conditionA=>["off","on"]),m)
eff.typical .= :mean # mean is the default

plot_erp(vcat(eff,eff_max);color=:conditionA,col=:typical)
