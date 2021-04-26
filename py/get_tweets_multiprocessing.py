import pandas as pd
import twint
import time
from multiprocessing.dummy import Pool as ThreadPool

# Load data
get_data = pd.read_csv("py/get_data.csv")

# Set up twint function
def get_tweets(search, since, until, row_no):

    c = twint.Config()
    c.Search = search
    c.Lang = "en"
    c.Limit = 5000
    #c.Geo = geo
    c.Since = since
    c.Until = until
    #c.User_full = True
    c.Output = "data-raw/tweets/tweets_without.json"
    c.Store_json = True
    c.Hide_output = True

    twint.run.Search(c)

    print("row " + row_no)

    time.sleep(2)

start = time.perf_counter()

# Convert dataframe to tuples
records = get_data.to_records(index=False)
tuples = list(records)

# Get tweets in parallel
pool = ThreadPool(10)
pool.starmap(get_tweets, tuples)
pool.close()
pool.join()

finish = time.perf_counter()

print(f'Finished in {round(finish-start, 2)} second(s)')
