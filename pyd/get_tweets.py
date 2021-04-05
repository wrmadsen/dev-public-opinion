# Get tweets
import twint
import time
import pandas as pd

# Read in candidates
pd.read_csv("data/get_data.csv")

# Wd
wd = "/Users/williamrohdemadsen/Dropbox/UCL/Year 3/Term 2/POLS0014 Diss/dev-public-opinion/py"

# Create Twint function to get tweets
# proxy, port, proxy_type
def get_tweets(search, geo, limit, since, until, path):

    # Twint arguments
    c = twint.Config()
    c.Search = search
    c.Lang = "en"
    c.Geo = geo
    c.Limit = limit
    c.Since = since
    c.Until = until
    #c.User_full = True
    c.Output = path
    c.Store_json = True
    #c.Hide_output = True

    # Run twint
    twint.run.Search(c)

    # Sleep
    #time.sleep(0.1)
    
    # Print
    #print(path)


get_tweets("Buhari", "9.083333333,7.533333,20km",  100, "2020-12-01", "2020-12-05", wd)
