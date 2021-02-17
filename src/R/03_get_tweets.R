###### Get Tweets with Python's twint

###### Set up
# python version
use_python("/usr/local/bin/python3", required = TRUE)

# Source get_tweets Python function
source_python("src/py/get_tweets.py", convert = FALSE)

###### Get tweets and save as a json file per day per location, 
# Map across help data
scraper_help %>%
  filter(country == "Nigeria") %>%
  filter(date > as.Date("2020-01-01")) %>%
  filter(date < as.Date("2020-01-05")) %>%
  mutate(file_name = paste0(leader, "_", country, "_", gpw_smallest, "_", paste(date)), # name of file to be saved
         date = paste(date),
         date_plus_one = paste(date_plus_one),
  ) %>%
  mutate(tweets = pmap(list(leader, geocode, date, date_plus_one, file_name),
                       ~get_tweets(..1,
                                   "en",
                                   ..2,
                                   20,
                                   ..3,
                                   ..4,
                                   paste0("data/tweets/", ..5, ".json")
                       )
  )
  )

