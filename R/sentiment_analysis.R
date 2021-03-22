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
#' @param tweets_formatted
#' @return Tokens of tweets for sentiment analysis
create_tweet_tokens <- function(tweets_formatted){

  # Clean from patterns and turn to lower-case
  tweets_clean <- tweets_formatted %>%
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
  tweets_tokens <- tweets_clean %>%
    unnest_tokens(word, tweet) %>%
    mutate(stem = SnowballC::wordStem(word),
           stop_word = if_else(word %in% stop_words$word | word %in% stop_words$stem,
                               TRUE, FALSE)
    )

  tweets_tokens

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
create_mean_sentiment_per_tweet <- function(senti_tweets){

  senti_tweets %>%
    group_by(id, username, date, week = floor_date(date, "week"), country, region_1, leader) %>%
    summarise(afinn_mean = mean(afinn_value, na.rm = TRUE)) %>%
    ungroup() %>%
    filter(!is.na(afinn_mean)) # drop lexicon NAs

}


#' Calculate binary for-against based cut off of mean sentiment
#' @param senti_cut_offs
#' @param n_roll window of rolling average
#' @return pro shares at different cut offs
find_pro_share <- function(senti_cut_offs, n_roll = 5){

  senti_cut_offs %>%
    mutate(stance = if_else(afinn_mean > cut_off, "pro", "con")) %>%
    group_by(country, leader, week = floor_date(date, "week"), cut_off, stance) %>%
    summarise(n = n()) %>%
    pivot_wider(names_from = stance, values_from = n) %>%
    group_by(country, leader, cut_off) %>%
    arrange(week) %>%
    mutate(across(c(pro, con), ~if_else(is.na(.), as.integer(0), .)),
           total = pro + con,
           pro_share = pro/total*100,
           pro_share_roll = RcppRoll::roll_mean(pro_share, n_roll, fill = NA)
           ) %>%
    ungroup()

}





