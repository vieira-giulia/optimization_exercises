using DelimitedFiles
using JuMP
using HiGHS
import MathOptInterface

function max_independent_set(N, E)
    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    set_silent(model)

    # Binary variable for each vertex
    @variable(model, x[1:N], binary=true)

    # Constraint: No adjacent vertices should be selected
    for edge in eachrow(E)
        @constraint(model, x[edge[1]] + x[edge[2]] <= 1)
    end

    # Objective: Maximize the sum of selected vertices
    @objective(model, Max, sum(x))

    # Solve
    optimize!(model)

    # Solution
    solution = objective_value(model)

    return solution
end

# Check args
if length(ARGS) != 1
    println("Por favor, forneça o caminho do arquivo como único argumento.")

else
    path = ARGS[1]
    data = readdlm(path)

    N = Int(data[1, 2]) 
    E = data[2:end, 2:3]

    solution = max_independent_set(N, E)

    println("TP1 2016006492 = $solution")

end