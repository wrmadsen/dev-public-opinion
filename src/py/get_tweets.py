# Get tweets
import twint
import time

# Wd
wd = "/Users/williamrohdemadsen/Dropbox/UCL/Year 3/Term 2/POLS0014 Diss/dev-public-opinion"

# Create Twint function to get tweets
# proxy, port, proxy_type
def get_tweets(search, lang, geo, limit, since, until, path):

    # Twint arguments
    c = twint.Config()
    c.Search = search
    c.Lang = lang
    c.Geo = geo
    c.Limit = limit
    c.Since = since
    c.Until = until
    c.Output = path
    c.Store_json = True
    #c.Proxy_host = proxy
    #c.Proxy_port = port
    #c.Proxy_type = proxy_type

    # Run twint
    twint.run.Search(c)

    # Sleep
    time.sleep(1)


get_tweets("Buhari", "en", "9.083333333,7.533333,20km",  19, "2020-12-01", "2020-12-05", wd)