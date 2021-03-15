###### Get Tweets with Python's twint

# Set up ------
# python version
use_python("/usr/local/bin/python3", required = TRUE)

# Source get_tweets Python function
source_python("src/py/get_tweets.py", convert = FALSE)

# Check data
head(scrape_data)

# Function
get_tweets()

# Get tweets without point data -------
scrape_data %>%
  mutate(file_path = paste0("data/tweets/without/", name, "_", paste(date), ".json"), # name of file to be saved
         date = paste0(date, " 00:00:00"),
         date_end = paste0(date_end, " 23:59:59")
  ) %>%
  mutate(tweets = pmap(list(name, date, date_end, file_path),
                       ~get_tweets(..1,
                                   "en",
                                   "", # no geocode
                                   1000, # limit
                                   ..2,
                                   ..3,
                                   ..4
                       )
  )
  )

# Get tweets with point data ------
scrape_data %>%
  #filter(date %in% seq(as.Date("2019-01-01"), as.Date("2019-02-01"), by = "day")) %>%
  mutate(file_path = paste0("data/tweets/with/", name, "_", paste(date), ".json"), # name of file to be saved
         date = paste0(date, " 00:00:00"),
         date_end = paste0(date_end, " 23:59:59")
  ) %>%
  mutate(tweets = pmap(list(name, geocode, date, date_end, file_path),
                       ~get_tweets(..1,
                                   "en",
                                   ..2, # geocode
                                   10000, # limit
                                   ..3,
                                   ..4,
                                   ..5
                       )
  )
  )
