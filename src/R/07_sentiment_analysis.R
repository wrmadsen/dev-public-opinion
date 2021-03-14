# Sentiment analysis

# Clean tweets ----
# Print raw corpus columns
names(tweets)

# Subset
tweets_corpus <- tweets %>%
  mutate(leader = gsub("data.+/|_.+", "", tweets_raw$filename)) %>%
  select(id, username, tweet, leader)

# Head of corpus
head(tweets_corpus)

# Convert to tidytext format
tweets_tidy <- tweets_corpus %>%
  unnest_tokens(word, tweet)


