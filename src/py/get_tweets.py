# Get tweets
import twint
#import os

# Wd
wd = "/Users/williamrohdemadsen/Dropbox/UCL/Year 3/Term 2/POLS0014 Diss/dev-public-opinion"

# Create function to get tweets
# proxy, port, type
def get_tweets(search, lang, geo, limit, since, until, path, proxy, port, proxy_type):

    # Arguments
    c = twint.Config()
    c.Search = search
    c.Lang = lang
    c.Geo = geo # lagos 6.45506,3.39418,5km
    c.Limit = limit
    c.Since = since
    c.Until = until
    c.Output = path
    c.Store_json = True
    c.Proxy_host = proxy
    c.Proxy_port = port
    c.Proxy_type = proxy_type

    # Run
    twint.run.Search(c)


#get_tweets("Buhari", "en", "9.083333333,7.533333,20km",  20, "2020-12-01", "2020-12-05", wd, "193.56.255.180", 3128, "http")