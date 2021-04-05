import pandas as pd
import numpy as np
from multiprocessing import cpu_count, Pool

cores = cpu_count() #Number of CPU cores on your system
partitions = cores #Define as many partitions as you want

data = pd.DataFrame(np.array([["Larry", 3, "Germany"], ["Jerry", 5, "Sweden"], ["George", 12, "UK"]]),
                    columns=['leader', 'years', 'score'])

def parallelize(data, func):
    data_split = np.array_split(data, partitions)
    pool = Pool(cores)
    data = pd.concat(pool.map(func, data_split))
    pool.close()
    pool.join()
    return data

def work(cols):
    col1, col2 = cols[0], cols[1]
    # ... your tasks
    print(col1 + col2)

data = parallelize(data,work)

data = data.apply(work)