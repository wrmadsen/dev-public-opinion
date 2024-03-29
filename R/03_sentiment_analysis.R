#' Remove patterns from tweets
#' @param tweet column with tweet text
#' @return tweet without certain patterns
remove_patterns_in_tweet <- function(tweet){

  # Special characters
  single_characters <- paste("@", "#", "\\.", "\\,", ":", ";",
                             "\\/", "\\(", "\\)",
                             "[^\x01-\x7F]", # remove all non-ASCII, emojis
                             '"', "\\!", "\\?", "-", "・", sep = "|")

  # http, URLs
  urls <- paste("http.*", "https.*", sep = "|")

  # Remove patterns
  ## First need to remove URLs, then other patterns
  gsub(urls, "", tweet) %>%
    gsub(single_characters, "", .)

}

#' Create and clean tweets tokens
#' @param tweets_sf
#' @return Tokens of tweets for sentiment analysis
create_tweets_tokens <- function(tweets_sub){

  # Clean from patterns and turn to lower-case
  tweets_dt <- tweets_sub %>%
    mutate(document = paste0("text", row_number())) %>%
    as.data.table()

  # Create corpus
  tweets_corpus <- corpus(tweets_dt$tweet, docvars = tweets_dt)

  # Tokenise tweets
  # Remove various characters
  tweets_tokens <- quanteda::tokens(tweets_corpus,
                                    remove_punct = TRUE,
                                    remove_symbols = TRUE,
                                    remove_numbers = TRUE,
                                    remove_url = TRUE)

  # Stem
  tweets_tokens_stemmed <- tokens_wordstem(tweets_tokens)

  # Lower case
  tweets_tokens_lower <- tokens_tolower(tweets_tokens_stemmed)

  # To dfm before converting to data.frame
  # Remove stopwords
  tweets_dfm <- dfm(tweets_tokens_lower, remove = stopwords())

  tweets_tokens_dt <- tidytext::tidy(tweets_dfm) %>%
    rename(token = term,
           token_count = count) %>%
    as.data.table()

  # Join docvars back by document number
  tokens_master <- merge(tweets_dt, tweets_tokens_dt,
                         all.x = TRUE, by = "document") %>%
    tibble()

  Sys.sleep(1)

  # Return
  tokens_master

}

#' Join lexicon to tokens
#' @param tokens_master
#' @param afinn_stem
#' @return Tweet tokens with sentiment values
#' @details best join may be by stemmed words
add_sentiment_to_tokens <- function(tokens_master, afinn_stem){

  # Join sentiment dictionary to tokens
  senti_tokens <- merge(tokens_master %>% as.data.table(),
                        afinn_stem %>% rename(token = stem) %>% as.data.table(),
                        all.x = TRUE,
                        by = "token") %>%
    tibble()

  # Return
  senti_tokens

}

#' Calculate sentiment per tweet
#' @param senti_tweets
calculate_sentiment_per_tweet <- function(senti_tokens){

  # Use data.table for speed
  # Find sentiment per tweet
  senti_tokens_dt <- as.data.table(senti_tokens)

  senti_tokens_dt[, by = list(id, conversation_id, username, date,
                              replies_count, retweets_count, likes_count,
                              x, y, leader, leader_country),
                  .(afinn_mean = mean(afinn_value, na.rm = TRUE))]

}

#' Calculate sentiment per day
#' @param senti_tweets
calculate_sentiment_per_day <- function(senti_tweet){

  # Use data.table for speed
  # Find mean sentiment per day
  senti_tweet_dt <- as.data.table(senti_tweet)

  senti_tweet_dt[, by = list(date, has_point,
                             country, region_1, region_2, leader, leader_country),
                 .(afinn_mean = mean(afinn_mean, na.rm = TRUE),
                   n_replies_mean = mean(replies_count, na.rm = TRUE),
                   n_retweets_mean = mean(retweets_count, na.rm = TRUE),
                   n_likes_mean = mean(likes_count, na.rm = TRUE),
                   n_tweets = .N)] %>%
    tibble()

}

# Linear interpolation of sentiment per day
interpolate_missing_days <- function(senti_day){

  senti_day %>%
    group_by(senti_day, gadm_region) %>%
    complete(year = 2006:2021) %>% # Twitter founded in 2006
    arrange(country, gadm_region, year) %>%
    # linear interpolation for missing years
    # extrapolate with rule = 2: the value at the closest data extreme is used
    mutate(across(c(eye, popshare, cellphone, phone), ~zoo::na.approx(., na.rm = FALSE, rule = 2))) %>%
    ungroup()

}

#' Create region-adjusted sentiment per day
#' @param senti_day
create_region_adjusted_sentiment <- function(senti_day){

  # Average sentiment per region
  mean_senti_per_region <- senti_day %>%
    filter(!is.na(region_1)) %>%
    group_by(leader, leader_country, country, region_1, region_2) %>%
    summarise(afinn_mean_region = mean(afinn_mean, na.rm = TRUE),
              n_tweets_region = sum(n_tweets)
    ) %>%
    ungroup()

  # Daily average across regions and non-points
  mean_senti_per_day <- senti_day %>%
    group_by(date, leader, leader_country) %>%
    summarise(afinn_mean_daily = mean(afinn_mean, na.rm = TRUE),
              n_retweets_mean = mean(n_retweets_mean, na.rm = TRUE),
              n_likes_mean = mean(n_likes_mean, na.rm = TRUE),
              n_tweets_daily = sum(n_tweets)
    ) %>%
    ungroup()

  # Add daily mean to each region
  senti_day_region_adj <- left_join(mean_senti_per_region, mean_senti_per_day,
                                    by = c("leader", "leader_country"))

  senti_day_region_adj

}



