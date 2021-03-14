###### Load tweets

# Load all Tweets ------
# Circa size of Tweets
file.size("data/tweets/without/")/1000 # mb

# Function to read in and add file name as column
read_tweets_back <- function(json){
  
  df <- stream_in(file(json)) %>%
    as_tibble() %>%
    mutate(place = paste0(place))
  
  df$filename <- json
  
  df
  
}

# Map across function load all Tweets
tweets_raw <- list.files("data/tweets", full.names = TRUE, recursive = TRUE) %>%
  map_df(~read_tweets_back(.))
