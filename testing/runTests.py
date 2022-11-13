import os
path = "tests/"

for file in os.listdir(path):
    os.system(f'../code {path+file} results/c/{file}')
    os.system(f'../code {path+file} results/asm/{file}')
    os.system(f'../code {path+file} results/optimized/{file}')
