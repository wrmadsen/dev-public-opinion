# # Sentiment analysis
#
#
# # Run sentiment analysis ----
# ## Add lexicons
# tweets_senti <- tweets_tidy
#
# unique(tweets_senti$bing_sentiment)
# unique(tweets_senti$nrc_sentiment)
#
# head(tweets_senti)
#
#
# # Binary classification -------
# tweets_binary <- tweets_senti %>%
#   group_by(id, username, leader, country, date) %>%
#   summarise(mean = mean(value, na.rm = TRUE)) %>%
#   mutate(binary = case_when(mean > 0 ~ 1,
#                             mean < 0 ~ 0,
#                             bing_sentiment == "positive" ~ 1,
#                             bing_sentiment == "negative" ~ 0,
#                             #nrc_sentiment %in% c("positive", "joy", "trust") ~ 1.
#                             #nrc_sentiment %in% c("fear", "negative", "disgust", "sadness") ~ 0,
#                             TRUE ~ as.double(NA)
#                             )
#          )
#
# # Plot -----
# tweets_binary %>%
#   filter
#   group_by(date, leader, country, binary) %>%
#   summarise(count = n()) %>%
#   group_by()
#   ggplot(.,
#        aes(x = date,
#            y = ))
