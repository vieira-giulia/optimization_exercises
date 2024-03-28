using DelimitedFiles
using JuMP
using HiGHS


function bin_packing(n_bins, w_obj)
    bin_capacity = 20
    n_obj = length(w_obj)

    model = Model(optimizer_with_attributes(HiGHS.Optimizer))
    set_silent(model)

    # Binary variable: represents if object in bin
    @variable(model, 0 <= x[1:n_obj, 1:n_bins] <= 1, Bin)

    # Binary variable: represent if bin was used
    @variable(model, y[1:n_bins], Bin)

    # Constraint: each object is assigned to exactly one bin
    for i in 1:n_obj
        @constraint(model, sum(x[i, j] for j in 1:n_bins) == 1)
    end

    # Constraint: bins have max capacity
    for j in 1:n_bins
        @constraint(model, sum(w_obj[i] * x[i, j] for i in 1:n_obj) <= bin_capacity)
    end

    # Constraint: link y[j] to x[i, j] to represent if bin j is used
    for j in 1:n_bins
        @constraint(model, sum(x[i, j] for i in 1:n_obj) <= n_obj * y[j])
    end

    # Objective: minimize the number of used bins
    @objective(model, Min, sum(y[j] for j in 1:n_bins))

    # Solve the problem
    optimize!(model)

    # Extract the solution
    solution = objective_value(model)

    # Certificate
    certificate = []
    for j in 1:n_bins
        if sum(value(x[i, j]) for i in 1:n_obj) > 0.0
            push!(certificate, [i-1 for i in 1:n_obj if value(x[i, j]) > 0.0])
        end
    end

    return solution, certificate
end


# Check args
if length(ARGS) != 1
    println("Por favor, forneça o caminho do arquivo como único argumento.")
else
    path = ARGS[1]

    # Read files
    data = readdlm(path)
    n = Int(data[1, 2])  # n: total number of boxes
    w = data[2:n+1, 3]  # w: list of object weights
    
    # Call function
    solution, certificate = bin_packing(n, w)

    # Print result
    
    println("TP2 2016006492 = $solution")
    writedlm(stdout, certificate)
end
