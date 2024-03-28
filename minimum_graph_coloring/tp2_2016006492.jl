using DelimitedFiles
using JuMP
using HiGHS

function min_color(N, E)
    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    set_silent(model)
    
    # c[i] = color for vertice i
    @variable(model, 1 <= c[1:N] <= N, Int)

    # same_color[i, j] means i and j have the same color
    @variable(model, same_color[1:N, 1:N], Bin)
   
    for edge in eachrow(E)
        # Constraint: adjacent vertices cannot have the same color
        @constraint(model, c[edge[1]] + c[edge[2]] <= N + 1)
         # Constrant: same color for connected vertices
        @constraint(model, same_color[edge[1], edge[2]] + same_color[edge[2], edge[1]] == 1)
        @constraint(model, c[edge[1]] - c[edge[2]] + N * same_color[edge[1], edge[2]] >= 1)
        @constraint(model, c[edge[2]] - c[edge[1]] + N * same_color[edge[2], edge[1]] >= 1)
    end

    # Min number of colors
    @objective(model, Min, sum(c))

    # Solve
    optimize!(model)

   # Extract the solution
    # Create a matrix where each row represents vertices with the same color
    colors = []
    for i in 1:N
        color = Int(value(c[i]))
        if length(colors) <= color
            push!(colors, [i])
        else
            push!(colors[color], i)
        end
    end

    # Solution
    solution = length(colors)

    return solution, colors
end


# Check args
if length(ARGS) != 1
    println("Por favor, forneça o caminho do arquivo como único argumento.")

else
    path = ARGS[1]

    # Read file
    data = readdlm(path)
    N = Int(data[1, 2])  # N = number of vertices
    E = data[2:end, 2:3]

    # Call function
    solution, certificate = min_color(N, E)
    
    # Print result
    println("TP2 2016006492: $solution")
    writedlm(stdout, certificate)
end