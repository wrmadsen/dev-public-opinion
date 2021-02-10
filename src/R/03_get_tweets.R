###### Get tweets

###### Get Tweets with Python's Twint

###### Set up
# python version
use_python("/usr/local/bin/python3", required = TRUE)

# Source get_tweets Python function
source_python("src/py/get_tweets.py", convert = FALSE)

###### Get tweets and save as JSONs
# Testing
# get_tweets("Mnangagwa", "en", "-17.81666667,31.033333,20km",  5, "2020-01-01", "2020-01-05",
#            "data/test.json"
#            #"77.73.241.154", as.integer(8080), "http"
#            )

# Map across help data
get_help %>%
  filter(country == "Zimbabwe") %>%
  filter(date > as.Date("2020-01-01")) %>%
  #filter(date < as.Date("2020-01-10")) %>%
  mutate(csv_date = format(date, "%Y_%m_%d"),
         date = paste(date),
         date_plus_one = paste(date_plus_one),
  ) %>%
  mutate(tweets = pmap(list(leader, geocode, date, date_plus_one, country),
                       ~get_tweets(..1,
                                   "en",
                                   ..2,
                                   20,
                                   ..3,
                                   ..4,
                                   paste0("data/tweets/", ..1, "_", ..5, "_", ..3, ".json")
                                   # ..6,
                                   # ..7,
                                   # ..8
                       )
  )
  )