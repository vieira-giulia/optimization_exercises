using DelimitedFiles
using JuMP
using HiGHS

function max_subgraph(n, edges)
    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    set_silent(model)

    # Binary decision variables indicating whether each vertex is included
    @variable(model, x[1:n], Bin)

    # Constraint: include both vertices of an edge if the edge is included
    # 1 + 1 - 1 = 1 > 0
    # 1 + 0 - 1 = 0 = 0
    # 0 + 1 - 1 = 0 = 0
    # 0 + 0 - 1 = -1 < 0
    for (v1, v2, _) in edges
        @constraint(model, x[v1] + x[v2] - 1 >= 0)
    end

    # Objective: maximize the sum of weights of included edges
    # include only if both are there, which means x[edge[1]] + x[edge[2]] - 1 > 0 to multiply
    @objective(model, Max, sum(edge[3] * (x[edge[1]] + x[edge[2]] - 1) for edge in edges))


    # Solve the optimization problem
    optimize!(model)

    # Solution
    solution = objective_value(model)
    
    # Certificate
    certificate = findall(v -> value(x[v]) > 0, 1:n)

    return solution, certificate
end



# Check args
if length(ARGS) != 1
    println("Por favor, forneça o caminho do arquivo como único argumento.")

else
    path = ARGS[1]

    # Read file
    # Read the first line to get number of vertices N
    first_line = readline(path)
    N = parse(Int, split(first_line)[2]) 

    E = []
    # Read the rest of the file line by line
    for (i, line) in enumerate(eachline(path))
        if i == 1
            continue  # Skip the first line
        end

        parts = split(line)
        _, v1, v2, w = parts[1], parse(Int, parts[2]), parse(Int, parts[3]), parse(Float64, parts[4])
        push!(E, (v1, v2, w))
    end

    # Call function
    solution, certificate = max_subgraph(N, E)

    # Print result
    println("TP2 2016006492: $solution")
    writedlm(stdout, certificate)
end