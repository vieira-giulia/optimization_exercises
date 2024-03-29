# My interpretation for the implementation in 
# "A matheuristic approach for the b-coloring problem using integer programming 
# and a multi-start multi-greedy randomized metaheuristic"
# https://arxiv.org/pdf/2102.09696.pdf

using DelimitedFiles
using JuMP
using HiGHS

function get_neighbors(E, v)
    neighbors = Int[]
    for (u, w) in E
        if u == v
            push!(neighbors, w)
        elseif w == v
            push!(neighbors, u)
        end
    end
    return neighbors
end

function get_not_neighbors(N, E, v)
    neighbors = get_neighbors(E, v) 
    all_vertices = Set(1:N)
    not_neighbors = setdiff(all_vertices, union(neighbors, Set([v])))
    return not_neighbors
end

function get_not_neighbors_after_edges(N, E, u)
    neighbors_u = get_neighbors(E, u)  # Get the set of neighbors of vertex u
    all_vertices = Set(1:N)  # Set of all vertices in the graph
    not_neighbors_u = setdiff(all_vertices, union(neighbors_u, Set([u])))  # Vertices not adjacent to u
    for (v, w) in E
        if w in not_neighbors_u && v in neighbors_u
            delete!(not_neighbors_u, w)  # Remove w from not_neighbors_u if there exists an edge vw where v is a neighbor of u
        end
    end
    return not_neighbors_u
end

function get_not_E(N, E)
    all_edges = Set([(i, j) for i in 1:N for j in 1:N if i != j])
    edges_set = Set(E)
    not_in_E = filter(e -> !(e in edges_set), all_edges)
    return collect(not_in_E)
end

function b_chromatic_number(N, E)
    # Create optimization model
    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    #set_silent(model)

    # Binary decision variables indicating whether a vertex u represents the color of vertex v
    @variable(model, 0 <= x[1:N, 1:N], Bin)

    # Binary variable: whether color was used
    @variable(model, y[1:N], Bin)

    # Constraint: each vertex is assigned to exactly one color
    for i in 1:N
        @constraint(model, sum(x[i, j] for j in 1:N) == 1)
    end
    
    # Constraint: proper coloring
    # adjacent vertices cannot have the same color
    for (v1, v2) in E
        for k in 1:N
            @constraint(model, x[v1, k] + x[v2, k] <= 1)
        end
    end

    # Constraint: a vertex can only give colors if it's representative
    # for every v1, v2 is a vertice in the non_neighbors of u that are not indirectly 
    # connected to u via any edge in the graph
    for v1 in 1:N
        for v2 in get_not_neighbors_after_edges(N, E, v1)
            @constraint(model, x[v1, v2] <= x[v2, v2]) 
        end
    end
    
    # Constraint: b_coloring
    # if both u and v are b_vertices, then there must be a neighbor of v 
    # that represents u
    for (v1, v2) in get_not_E(N, E)
        for v3 in intersect(get_neighbors(E, v1), get_not_neighbors(N, E, v2))
            @constraint(model, sum(x[v2, v3]) >= x[v2, v2] + x[v1, v1] - 1)
        end
    end
    
    # Constraint: link y[j] to x[i, j] to represent if bin j is used
    for j in 1:N
       @constraint(model, sum(x[i, j] for i in 1:N) <= N * y[j])   
    end

    # Objective: maximize the total number of colors used
    # maximizes the number of representative vertices
    #@objective(model, Max, sum(y[i] for i in 1:N))
    @objective(model, Max, sum(x[v, v] for v in 1:N))

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
    
    solution = b_chromatic_number(N, E)
    
    println("TP1 2016006492: $solution")

end