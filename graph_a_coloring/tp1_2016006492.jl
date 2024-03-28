using DelimitedFiles
using JuMP
using HiGHS

function a_coloring(N, E)
    # Create optimization model
    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    set_silent(model)

    # Binary decision variables indicating whether each vertex is colored with each color
    @variable(model, x[1:N, 1:N], Bin)

    for i in 1:N
        # Constraint: each vertex is assigned exactly one color
        @constraint(model, sum(x[i, j] for j in 1:N) == 1)
    end

    # Constraint: adjacent vertices cannot have the same color
    for (v1, v2) in E
        for k in 1:N
            @constraint(model, x[v1, k] + x[v2, k] <= 1)
        end
    end

    # Objective: minimize the total number of colors used
    @objective(model, Min, sum(x))

    # Solve the optimization problem
    optimize!(model)

    # Extract the colors used for each vertex
    colors_used = []
    for i in 1:N
        color = findfirst(value.(x[i, :]) .> 0)
        push!(colors_used, color)
    end

    # Determine the number of distinct colors used
    solution = length(unique(colors_used))-1

    # Extract the number of colors used
    #solution = objective_value(model)

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