# Validation

#' Find actual vote shares in test data
find_actual_vote_shares_national <- function(prediction_master){

  prediction_master %>%
    filter(region_2 == "National") %>%
    distinct(country, leader, votes_share) %>%
    arrange(country)

}
