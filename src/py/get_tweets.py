# Get tweets
import twint
#import os

# Wd
wd = "/Users/williamrohdemadsen/Dropbox/UCL/Year 3/Term 2/POLS0014 Diss/dev-public-opinion"

# Create function to get tweets
def get_tweets(search, lang, geo, limit, since, until, path):

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

    # Run
    twint.run.Search(c)

#get_tweets("buhari", "en", "6.45506,3.39418,5km", 300)

#get_tweets("frederiksen", "en", "55.66666667,12.583333,5km",  10, "2020-04-05",  "2020-04-06", wd)