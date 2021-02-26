###### Get Tweets with Python's twint

###### Set up
# python version
use_python("/usr/local/bin/python3", required = TRUE)

# Source get_tweets Python function
source_python("src/py/get_tweets.py", convert = FALSE)

# Test
#get_tweets("Buhari", "en", "", 100000, "2019-01-01", "2019-03-01", "data/tweets/buhari.json")

###### Get tweets without point data
names_scrape %>%
  filter(country == "Nigeria" & date > as.Date("2019-01-10") & date < as.Date("2019-03-01")) %>%
  mutate(file_path = paste0("data/tweets/without/", country, "/", name, "_", paste(date), ".json"), # name of file to be saved
         date = paste0(date, " 00:00:00"),
         date_end = paste0(date_end, " 23:59:59")
  ) %>%
  mutate(tweets = pmap(list(name, date, date_end, file_path),
                       ~get_tweets(..1,
                                   "en",
                                   "", # no geocode
                                   10, # limit
                                   ..2,
                                   ..3,
                                   ..4
                       )
  )
  )

###### Get tweets with point data
scraper_help %>%
  filter(country == "Nigeria" & date > as.Date("2019-01-10") & date < as.Date("2019-03-01")) %>%
  transmute(name,
            geocode,
            file_path = paste0("data/tweets/with/", country, "/", name, "_", location, "_", paste(date), ".json"),
            date = paste0(date, " 00:00:00"),
            date_end = paste0(date_end, " 23:59:59")
  ) %>%
  mutate(tweets = pmap(list(name, geocode, date, date_end, file_path),
                       ~get_tweets(..1,
                                   "en",
                                   ..2,
                                   10,
                                   ..3,
                                   ..4,
                                   ..5
                       )
  )
  )
