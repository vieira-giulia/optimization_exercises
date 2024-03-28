import sys
from scipy.optimize import linprog

def read_input(filename):
    with open(filename, 'r') as file:
        # Read the first line
        n, m = map(int, file.readline().split())
        
        # Read the second line
        c = list(map(int, file.readline().split()))
        
        # Read the remaining lines for A and b
        A = []
        b = []
        for _ in range(n):
            row = list(map(int, file.readline().split()))
            A.append(row[:-1])  # Exclude last element (bi) from the row
            b.append(row[-1])   # Add the element (bi) to the b vector
        
    return n, m, c, A, b

if __name__ == "__main__":
    # Check if a filename is provided as a command-line argument
    if len(sys.argv) != 2:
        sys.exit(1)

    # Get the filename from the command line
    filename = sys.argv[1]

     # Read inputs
    n, m, c, A, b = read_input(filename)

    # Solve the linear programming problem using HiGHS solver
    result = linprog(c, A_ub=A, b_ub=b, method='highs')

    # Print results
    if result.success:
        print("otima\n",-result.fun,"\n",result.x)
    else:
        if result.status == 2:
            print("inviavel\n", result)
        elif result.status == 3:
            print("ilimitada\n", result)

