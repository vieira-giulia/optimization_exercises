using DelimitedFiles
using JuMP
using HiGHS

using JuMP
using HiGHS

function a_coloring(N, E)
    # Create optimization model
    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    set_silent(model)

    # Binary decision variables indicating whether a vertex has a color
    @variable(model, x[1:N, 1:N], Bin)

    # Variable representing color pairs: if color i is near color j 
    @variable(model, y[1:N, 1:N], Int)

    # Binary variable: represent if color was used
    @variable(model, z[1:N], Bin)

    # Constraint: each vertex is assigned exactly one color
    for i in 1:N
        @constraint(model, sum(x[i, j] for j in 1:N) == 1)
    end

    # Constraint: adjacent vertices cannot have the same color
    for (v1, v2) in E
        for k in 1:N
            @constraint(model, x[v1, k] + x[v2, k] <= 1)
        end
    end

    # Constraint: A-coloring property
    for (v1, v2) in E
        # Increment the corresponding positions in the color pair matrix
        for i in 1:N
            for j in 1:N
                if i != j
                    @constraint(model, y[i, j] + y[j, i] >= x[v1, i] + x[v2, j])
                end
            end
        end
    end

    # Constraint: Mark a color as used whenever a vertex is assigned that color
    for i in 1:N
        @constraint(model, sum(x[i, j] for j in 1:N) <= N * z[i])
    end

    # Objective: maximize the total number of colors used
    @objective(model, Max, sum(z[i] for i in 1:N))

    # Solve the optimization problem
    optimize!(model)

    # Solution
    solution = objective_value(model)

    return solution
end

# Check args
if length(ARGS) != 1
    println("Please provide the file path as the only argument.")
else
    path = ARGS[1]
    data = readdlm(path)

    N = Int(data[1, 2])
    #E = [(Int(row[2]), Int(row[3])) for row in eachrow(data[2:end])]
    E = [(Int(data[i, 2]), Int(data[i, 3])) for i in 2:size(data, 1)]
    
    solution = a_coloring(N, E)
    
    println("TP1 2016006492: $solution")

end