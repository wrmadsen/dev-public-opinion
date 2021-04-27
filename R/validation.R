# Validation

#' Join election results to raw sentiment estimates
#' @param raw_pro_shares
#' @param elex_master
join_election_to_tweets <- function(senti_per_tweet, elex_master){

  # Join election results to pro shares
  senti_per_tweet %>%
    mutate(region_1 = if_else(is.na(region_1), "National", region_1),
           region_2 = if_else(is.na(region_2), "National", region_2),
           country = if_else(is.na(country), leader_country, country),
           id = row_number()
           ) %>%
    left_join(.,
              elex_master,
              by = c("leader" = "name", "leader_country" = "country", "region_1", "region_2"))

}


#' For each tweet, select the nearest election in time
#' One election per tweet
select_nearest_election <- function(validate_elex_raw){

  validate_elex_raw %>%
    group_by(id) %>%
    # diff between tweet and election date in days
    mutate(days_diff = (date - elex_date) %>% as.integer,
           days_diff_abs = abs(days_diff)
    ) %>%
    slice_min(days_diff_abs, n = 1) %>%
    ungroup() %>%
    arrange(leader, country, region_1, date)

}

#' Summarise cut-off validation statistics
#' @param validate_elex_raw
#' @return summary statistics by cut-off values to evaluate their differences and merits
summarise_cut_off_validation <- function(validate_elex_raw){

  # Calculate mean, sd and summary of difference between raw estimates and cut-off
  # For period col
  validate_elex_raw %>%
    mutate(pro_share_diff = pro_share - votes_share,
           pro_share_roll_diff = pro_share_roll - votes_share) %>%
    # choose which window of days to election to analyse summary for
    #filter(days_diff_abs < 100) %>%
    group_by(elex_date, days_diff, cut_off) %>%
    summarise(mean = mean(pro_share_diff, na.rm = TRUE),
              min = min(pro_share_diff, na.rm = TRUE),
              max = max(pro_share_diff, na.rm = TRUE),
              sd = sd(pro_share_diff, na.rm = TRUE),
              total_tweets = sum(total)
    ) %>%
    ungroup() %>%
    arrange(days_diff)

}
