###### Load tweets

# Function to read in and add file name as column
read_tweets_back <- function(json){
  
  df <- stream_in(file(json)) %>%
    as_tibble()
  
  df$filename <- json
  
  df
  
}
