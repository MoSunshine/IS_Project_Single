using JuMP, Plots, CPLEX, DataFrames, XLSX, CSV, IterTools, LinearAlgebra, Statistics, Distributions, PGFPlotsX
##constants
T = 7 ##Time periods
J_value = 4 ##drop-off destinations
I_value = 4 ##pick-up-locations
Ω_numb = 3 #number of  possible scenarios
Ω = Ω_numb^(T-1) #number of scenarios


##Function to generate all possible scenario combinations.
##@return scenarios_full - list of all possible scenario combinations.
##@return possibility - list of all possibilites of all scenario combinations.
function generate_scenario()
    ##possible scenarios##
    high_demand = [40 35 38 29;
    36 35 39 42;
    37 39 26 46;
    29 40 48 30]
    medium_demand = [26 21 24 13;
    20 19 27 21;
    14 22 19 21;
    17 26 27 20]
    low_demand = [17 12 15 12;
    9 13 10 10;
    6 15 17 11;
    10 17 21 15] 
    demand = [low_demand,medium_demand,high_demand]
    p_full = [0.4,0.2,0.4]
    scenarios_full = []
    possibility = []
    ##build all possible scenarios
    for a in 1:Ω_numb
        for b in 1:Ω_numb
            for c in 1:Ω_numb
                for d in 1:Ω_numb
                    for e in 1:Ω_numb
                        for f in 1:Ω_numb
                            push!(scenarios_full,([],demand[a],demand[b],demand[c],demand[d],demand[e],demand[f]))
                            push!(possibility,(1*p_full[a]*p_full[b]*p_full[c]*p_full[d]*p_full[e]*p_full[f]))
                        end
                    end
                end
            end
        end
    end
    ##return values
    possibility = Float64.(possibility)
    return scenarios_full,possibility
end


###function to calculate the optimal allocation and revenue.
###@param penalty - penalty cost
###@param scenarios_full - list of all possible scenario combinations
###@param possibility - list of all possibilites of all scenario combinations
###@return revenue - Revenue of the optimazation
###@return x - Matrix with number of cars used after first period by custemors
###@return y - Matrix with number of cars that are moved empthy after first period
function calc_opt_model_matrix(scenarios_full,possibility)
    ##constants for model
    net_revenue = [10 11 9 14;12 15 10 9;12 6 7 9;14 12 10 8]
    transfer_costs = [0 6 6 5;6 0 4 7;6 4 0 5;5 7 5 0]
    L = [25 20 23 16;18 23 22 21;17 25 19 26;19 25 27 16]
    S_1 = [90;100;90;90]
    penalty = [15 9 8 7;11 14 12 13;11 12 9 13;17 18 12 15]
    ##build model
    opt = with_optimizer(CPLEX.Optimizer)
    cars = Model(opt)
    set_silent(cars)
    #add variables
    @variable(cars, x[1:T,1:Ω,1:I_value,1:J_value]>=0,integer=true)
    @variable(cars, y[1:T,1:Ω,1:I_value,1:J_value]>=0,integer=true)
    @variable(cars, S[1:T,1:Ω,1:I_value]>=0,integer=true)
    @variable(cars, z[1:T,1:Ω,1:I_value,1:J_value]>=0,integer=true)
    ##add expressions
    @expression(cars, R[ω in 1:Ω],    
    sum(sum(sum(
                ((net_revenue[i,j]*x[t,ω,i,j]) - (transfer_costs[i,j]*y[t,ω,i,j]))
                for j in 1:J_value)
                for i in 1:I_value) for t in 1:T)
    )
    @expression(cars, Penalty_Costs[ω in 1:Ω],    
        sum(sum(sum(
                    z[t,ω,i,j]*penalty[i,j]
                    for j in 1:J_value)
                    for i in 1:I_value) 
                    for t in 1:T)
    )
    ##add constrains
    #1.a
    @constraint(cars,cap_start[ω in 1:Ω,i in 1:I_value,j in 1:J_value],x[1,ω,i,j]<=L[i,j])
    #1.b
    @constraint(cars,max_demand[t in 2:T,ω in 1:Ω,i in 1:I_value,j in 1:J_value],x[t,ω,i,j]<=scenarios_full[ω][t][i,j])
    #1.c
    @constraint(cars,floting[t in 2:T,ω in 1:Ω,i in 1:I_value],sum(x[t,ω,i,j]+ y[t,ω,i,j] for j in 1:J_value)==S[t,ω,i])
    #1.d
    @constraint(cars,floting_2[t in 1:T,ω in 1:Ω,i in 1:I_value],sum( x[1,ω,i,j]+ y[1,ω,i,j] for j in 1:J_value)==S_1[i])
    #1.e
    @constraint(cars,flow_c_p[t in 1:(T-1),ω in 1:Ω,j in 1:J_value],sum(x[t,ω,i,j]+ y[t,ω,i,j] for i in 1:I_value)==S[t+1,ω,j])
    #1.f
    @constraint(cars,pen_1[t in 2:T,ω in 1:Ω,i in 1:I_value,j in 1:J_value],z[t,ω,i,j]+x[t,ω,i,j]==scenarios_full[ω][t][i,j])
    #1.g
    @constraint(cars,pen_2[ω in 1:Ω,i in 1:I_value,j in 1:J_value],z[1,ω,i,j]+x[1,ω,i,j]==L[i,j])
    ##add objective function and optimize
    @objective(cars, Max,sum((R[ω]-Penalty_Costs[ω])*possibility[ω] for ω in 1:Ω))
    optimize!(cars)
    termination_status(cars)
    println("DONE")
    return objective_value(cars), value.(x[1,1,:,:]), value.(y[1,1,:,:]),value.(z[1,1,:,:])
end
###main###
###Generate Scenarios###
scenarios, possibility = generate_scenario()
###Calculate optimizations
revenue,x_1,y_1,z_1 = calc_opt_model_matrix(scenarios,possibility)
println(x_1)
println(y_1)
println(z_1)
println(revenue)

