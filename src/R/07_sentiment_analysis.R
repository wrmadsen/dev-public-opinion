# Sentiment analysis

# Clean tweets ----
# Print raw corpus columns
names(tweets)

# Subset
tweets_corpus <- tweets %>%
  select(id, username, date, leader, country, tweet)

# Head of corpus
head(tweets_corpus)

# Tidytext format ------
# Convert to tidytext format
tweets_tidy <- tweets_corpus %>%
  unnest_tokens(word, tweet)

# Run sentiment analysis ----
afinn <- get_sentiments("afinn")

tweets_senti <- tweets_tidy %>%
  left_join(afinn)

# Binary classification -------
tweets_binary <- tweets_senti %>%
  group_by(id, username, leader, country, date) %>%
  summarise(mean = mean(value, na.rm = TRUE)) %>%
  mutate(binary = if_else(mean > 0, 1, 0))

# Plot -----
tweets_binary %>%
  group_by(date, leader, country, binary) %>%
  summarise(count = n())
  ggplot(.,
       aes(x = date,
           y = ))
