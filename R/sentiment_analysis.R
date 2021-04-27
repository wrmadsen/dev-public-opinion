#' Remove patterns from tweets
#' @param tweet column with tweet text
#' @return tweet without certain patterns
remove_patterns_in_tweet <- function(tweet){

  # Single characters
  single_characters <- paste("@", "#", "\\.", "\\,", ":", ";", '"', "\\!", "\\?", "-", "・", sep = "|")

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
create_tweet_tokens <- function(tweets_sf){

  # Clean from patterns and turn to lower-case
  tweets_clean <- tweets_sf %>%
    as.data.frame() %>%
    select(-c(geometry)) %>%
    tibble() %>%
    mutate(tweet = tolower(tweet),
           tweet = remove_patterns_in_tweet(tweet),
           tweet = str_squish(tweet) # removes repeated white space
    )

  # Save stopwords
  stop_words <- get_stopwords(language = "en", source = "snowball") %>%
    tibble() %>%
    transmute(word, stem = SnowballC::wordStem(word))

  # Convert to tokens and stem
  tweets_clean %>%
    unnest_tokens(word, tweet) %>%
    mutate(stem = SnowballC::wordStem(word),
           stop_word = if_else(word %in% stop_words$word | word %in% stop_words$stem,
                               TRUE, FALSE)
    )

}

#' Join lexicon to tokens
#' @param tweet_tokens
#' @param afinn_stem
#' @return Tweet tokens with sentiment values
#' @details best join may be by stemmed words
join_sentiment_by_stem <- function(tweet_tokens, afinn_stem){

  # Unique words to join as factors for speed
  stem_lvls <- unique(c(tweets_tokens$stem, afinn_stem$stem))

  # Join lexicon
  senti_tweets <- tweets_tokens %>%
    mutate(stem = factor(stem, stem_lvls)) %>%
    left_join(.,
              afinn_stem,
              by = "stem") %>%
    arrange(country, region_1, leader, date)

  senti_tweets

}

#' Mean sentiment per tweet
#' @param senti_tweets
create_mean_sentiment_per_tweet <- function(senti_per_token){

  senti_per_token %>%
    group_by(id, conversation_id, username, date, has_point,
             replies_count, retweets_count, likes_count,
             country, region_1, region_2, leader, leader_country) %>%
    summarise(afinn_mean = mean(afinn_value, na.rm = TRUE)) %>%
    ungroup()

}

#' Create object with different cut-offs
#' @param senti_mean
#' @return senti_cut_offs
create_cut_offs <- function(senti_per_tweet){

  (cut_off_seq <- seq(-2, 2, length.out = 9) %>% round(., 2))

  senti_per_tweet_w_row_no <- senti_per_tweet %>%
    mutate(row_number = row_number())

  purrr::map_dfr(seq_len(9), function(x) senti_per_tweet_w_row_no) %>%
    group_by(row_number) %>%
    mutate(cut_off = seq(-2, 2, length.out = 9))

}

#' Find pro share
#' @param senti_cut_offs
#' @param n_roll window of rolling average
#' @return pro shares at different cut offs
find_pro_share <- function(senti_cut_offs, n_roll = 5){

  # Create binary stance against cut-off
  senti_cut_offs %>%
    mutate(stance = if_else(afinn_mean > cut_off, "pro", "con")) %>%
    group_by(country, region_1, region_2,
             leader, leader_country,
             date, #week = floor_date(date, "week"),
             cut_off, stance) %>%
    # number of pros and cons per day
    summarise(n = n()) %>%
    pivot_wider(names_from = stance, values_from = n) %>%
    group_by(country, leader, cut_off) %>%
    arrange(date) %>%
    # find pro share and rolling mean
    mutate(across(c(pro, con), ~if_else(is.na(.), as.integer(0), .)),
           total = pro + con,
           pro_share = pro/total,
           pro_share_roll = RcppRoll::roll_mean(pro_share, n_roll, fill = NA)
    ) %>%
    ungroup()

}



