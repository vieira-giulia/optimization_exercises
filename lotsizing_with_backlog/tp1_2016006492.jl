using JuMP
using HiGHS

function min_cost(T, production_costs, demands, storage_costs, penalties)
    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    set_silent(model)
    
    # Variables
    @variable(model, 0 <= x[1:T])  # Production of product p at each time t
    @variable(model, 0 <= y[1:T])  # Early production: product holding
    @variable(model, 0 <= z[1:T])  # Late production: backloging
    
    sum_x, sum_d = 0, 0
    for t in 1:T
       sum_x += x[t]
        sum_d += demands[t]
        #@constraint(model, x[t] == demands[t])
        if t > 1
            @constraint(model, y[t-1] + x[t] - z[t-1] == demands[t] + y[t] - z[t])
        end
    end

    # Constraint: total production needs to meet demand
    #for t in 1:T
    #    @constraint(model, x[t] <= sum(demands[j] for j in t:T))
    #end
    @constraint(model, sum_x == sum_d)

    @objective(model, Min, sum(
        production_costs[i] * x[i] + storage_costs[i] * y[i] + penalties[i] * z[i]
        for i in 1:T))

    # Solve the problem
    optimize!(model)

    # Print values of x
    #println("Values of x:")
    #for i in 1:T
    #    println("x[$i] = ", value(x[i]))
    #end

    # Print sum of values of x
    #x_sum = sum(value(x[i]) for i in 1:T)
    #println("Sum of values of x: ", x_sum)

    println(sum(values(demands)))

    # Solition
    solution = objective_value(model)

    return solution

end

# Check args
if length(ARGS) != 1
    println("Por favor, forneça o caminho do arquivo como único argumento.")
else
    path = ARGS[1]
    # Read file

    C = Dict{Int, Float64}()
    D = Dict{Int, Float64}()
    S = Dict{Int, Float64}()
    P = Dict{Int, Float64}()

   # Read the first line to get the number of time periods (T)
   first_line = readline(path)
   T = parse(Int, split(first_line)[2])

   
   # Read the rest of the file line by line
   for (i, line) in enumerate(eachline(path))
        if i == 1
            continue  # Skip the first line
        end

        parts = split(line)
        activity, t, value = parts[1], parse(Int, parts[2]), parse(Float64, parts[3])

        # Store the parsed values in the appropriate dictionary
        if activity == "c"
            C[t] = value
        elseif activity == "d"
            D[t] = value
        elseif activity == "s"
            S[t] = value
        elseif activity == "p"
            P[t] = value
        end
    end

    # TrDnsform dictionaries into vectors
    C_vector = [C[t] for t in 1:T]
    D_vector = [D[t] for t in 1:T]
    S_vector = [S[t] for t in 1:T]
    P_vector = [P[t] for t in 1:T]

    # Call function
    solution = min_cost(T, C, D, S, P)
    
    # Print result
    println("TP1 2016006492: $solution")
end