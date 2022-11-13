import os
path = "tests/"

for file in os.listdir(path):
    with open(f"results/c/{file}", "r") as result:
        c_result = result.read()
    with open(f"results/asm/{file}", "r") as result:
        asm_result = result.read()
    with open(f"results/optimized/{file}", "r") as result:
        optimized_result = result.read()
    
    if (c_result != asm_result or c_result != optimized_result \
        or asm_result != optimized_result):
        print(f"{file} is failed!")
    else:
        print(f"{file} OK")