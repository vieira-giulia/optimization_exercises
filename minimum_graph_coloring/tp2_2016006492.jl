using DelimitedFiles
using JuMP
using HiGHS

function minimum_coloring(N, E)
    # Create optimization model
    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    set_silent(model)

    # Binary decision variables indicating whether each vertex is colored with each color
    @variable(model, 0 <= x[1:N, 1:N] <= 1, Bin)

    # Binary variable: represent if color was used
    @variable(model, y[1:N], Bin)

    # Constraint: each vertex is assigned to exactly one color
    for i in 1:N
        @constraint(model, sum(x[i, j] for j in 1:N) == 1)
    end

    # Constraint: adjacent vertices cannot have the same color
    for (v1, v2) in E
        for k in 1:N
            @constraint(model, x[v1, k] + x[v2, k] <= 1)
        end
    end

    # Constraint: link y[j] to x[i, j] to represent if color j is used
    for j in 1:N
        @constraint(model, sum(x[i, j] for i in 1:N) <= N * y[j])
    end

    # Objective: maximize the total number of colors used
    @objective(model, Min, sum(y[j] for j in 1:N))

    # Solve the optimization problem
    optimize!(model)

     # Extract the solution
     solution = objective_value(model)

    # Collect certificate
    colors = Vector{Vector{Int}}(undef, N)
    for i in 1:N
        color = argmax(value.(x[i, :]))
        if isempty(colors[color])
            colors[color] = [i]
        else
            push!(colors[color], i)
        end
    end

     return solution, colors
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

    solution, certificate = minimum_coloring(N, E)

    println("TP1 2016006492: $solution")

end