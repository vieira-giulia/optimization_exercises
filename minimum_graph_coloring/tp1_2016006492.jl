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

     return solution
end


function dsatur(N, E)
    degrees = zeros(Int, N)  # Array to store the degree of each vertex
    colors = zeros(Int, N)   # Array to store the color of each vertex
    saturation = zeros(Int, N)  # Array to store the saturation degree of each vertex
    adj_list = [[] for _ in 1:N]  # Adjacency list representation of the graph

    # Build adjacency list
    for edge in eachrow(E)
        i, j = edge
        push!(adj_list[i], j)
        push!(adj_list[j], i)
        degrees[i] += 1
        degrees[j] += 1
    end

    # Initialize DSatur algorithm
    uncolored_vertices = collect(1:N)  # Vertices that are yet to be colored
    max_saturation = -1  # Maximum saturation degree
    vertex_to_color = 0  # Vertex to be colored

    while !isempty(uncolored_vertices)
        # Compute saturation degree for each vertex
        for v in uncolored_vertices
            s = 0
            for neighbor in adj_list[v]
                s += (colors[neighbor] != 0)
            end
            saturation[v] = s
        end

        # Find vertex with maximum saturation degree
        for v in uncolored_vertices
            if saturation[v] > max_saturation
                max_saturation = saturation[v]
                vertex_to_color = v
            end
        end

        # Choose the minimum available color for the vertex
        available_colors = Set(1:maximum(colors) + 1)
        for neighbor in adj_list[vertex_to_color]
            delete!(available_colors, colors[neighbor])
        end
        colors[vertex_to_color] = minimum(collect(available_colors))

        # Remove the colored vertex from the uncolored list
        deleteat!(uncolored_vertices, findfirst(x -> x == vertex_to_color, uncolored_vertices))

        # Reset variables for the next iteration
        max_saturation = -1
        vertex_to_color = 0
    end

    num_colors = maximum(colors)
    return num_colors
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
    
    solution = minimum_coloring(N, E)
    
    println()
    println("TP1 2016006492: $solution")

end