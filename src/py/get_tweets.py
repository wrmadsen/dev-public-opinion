# Get tweets
import twint
import os

# Wd
wd = "/Users/williamrohdemadsen/Dropbox/UCL/Year 3/Term 2/POLS0014 Diss/dev-public-opinion"

# Configure
c = twint.Config()
c.Search = "buhari"
c.Lang = "en"
c.Geo = "6.45506,3.39418,5km" # lagos
c.Limit = 300
c.Output = wd + "/data/tweets/buhari.csv"
c.Store_json = True

# Run
twint.run.Search(c)