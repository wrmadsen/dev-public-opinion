import pandas as pd
import twint
import time
import concurrent.futures

# Load data
get_data = pd.read_csv("py/get_data.csv")

# Set up twint function
def get_tweets(search, since, until):

    c = twint.Config()
    c.Search = search
    c.Lang = "en"
    #c.Geo = geo
    c.Since = since
    c.Until = until
    #c.User_full = True
    c.Output = "data-raw/tweets/tweets_without.json"
    c.Store_json = True
    c.Hide_output = True

    twint.run.Search(c)

start = time.perf_counter()

# Convert dataframe to
records = get_data.to_records(index=False)
tuples = list(records)

# Helper
def helper(numbers):
    get_tweets(numbers[0], numbers[1], numbers[2])

# Get tweets in parallel
#with concurrent.futures.ThreadPoolExecutor() as executor:
#    for _ in executor.map(helper, tuples):
#        pass

# 285.34 secs
with concurrent.futures.ThreadPoolExecutor() as executor:
    executor.map(get_tweets, *zip(*tuples))

finish = time.perf_counter()

print(f'Finished in {round(finish-start, 2)} second(s)')
