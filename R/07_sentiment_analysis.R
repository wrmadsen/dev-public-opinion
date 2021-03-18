#' Function to remove patterns from tweets
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
