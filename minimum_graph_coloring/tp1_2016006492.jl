using DelimitedFiles

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

using JuMP
using HiGHS

function minimum_colors(N, E)
    # Create optimization model
    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    set_silent(model)
   
    @variable(model, x[1:N, 1:N], Bin)  # Binary variable representing color of each vertex
    
    # Add constraint: each vertex must have exactly one color
    for i in 1:N
        @constraint(model, sum(x[i, j] for j in 1:N) == 1)
    end

    # Add constraint: adjacent vertices cannot have the same color
    for (u, v) in E
        @constraint(model, x[u, v] + x[v, u] <= 1)
    end

    # Minimize the number of colors used
    @objective(model, Min, sum(x))

    # Solve the optimization problem
    optimize!(model)

    # Extract the solution
    num_colors = objective_value(model)
    
    for row in eachrow(value.(x))
        println(join(row, "\t"))
    end

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
    
    solution = minimum_colors(N, E)
    
    println()
    println("TP1 2016006492: $solution")

end