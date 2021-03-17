using CSV
using DelimitedFiles

function loadtestdata(testCase::String; dataPath::String=(@__DIR__)*"/data_new_testcases")
    #println(pwd()) # to debug github action
    data = readdlm(joinpath(dataPath, "$(testCase)_data.csv"), ',', Float64, '\n')
    data = dropdims(data,dims=1) # convert to vector
    evts = CSV.read(joinpath(dataPath, "$(testCase)_events.csv"), DataFrame)
    return data, evts
end


function gridexpand(conditionA  = [0,1.],continuousA = [-1.,0,1.])

tmp = reshape([ [x,y]  for x=conditionA, y=continuousA ],length(conditionA)*length(continuousA))
evts_grid = DataFrame(hcat(tmp...)')
rename!(evts_grid,["conditionA","continuousA"])
return evts_grid
end


function simulate_lmm(τ = 1.5,fs = 12)

    subj_btwn = item_btwn = both_win = nothing
#subj_btwn = Dict("age" => ["O", "Y"])

# there are no between-item factors in this design so you can omit it or set it to nothing
item_btwn = Dict("stimType" => ["I","II"])

# put within-subject/item factors in a Dict
#both_win = Dict("condition" => ["A", "B"])

# simulate data
evt = DataFrame(simdat_crossed(20, 30,
                    subj_btwn = subj_btwn, 
                    item_btwn = item_btwn, 
                    both_win = both_win))

#    f1 = @formula dv ~ 1 + age * condition  + (1+condition|item) + (1+condition|subj);
f1 = @formula dv ~ 1 + stimType  + (1|item) + (1+stimType|subj);
m = MixedModels.fit(MixedModel, f1, evt)

# set the random effects


# XXX Todo: set sigma somehow



function gen_han(τ,fs,peak)
    hanLen = Int(τ*fs/3)
    han = hanning(hanLen,zerophase=false)
    sig = zeros(Int(τ*fs))
    sig[1+hanLen*(peak-1):hanLen*peak] .= han
    return sig
end


#gen_han(τ,fs,1)
basis = gen_han(τ,fs,2)

epoch_dat = zeros(Int(τ*fs),size(evt,1))
for t = 1:size(epoch_dat,1)
    b = basis[t]
    MixedModelsSim.update!(m,create_re(b .* 0.,b .*0),create_re( b.* 1.))
    simulate!(MersenneTwister(t),m,β = [b .* 0.,b .* -1.], σ = 1.)
    epoch_dat[t,:] = m.y
end

epoch_dat = reshape(epoch_dat,(1,size(epoch_dat)...))

return evt,epoch_dat
end