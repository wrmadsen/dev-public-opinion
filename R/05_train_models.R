# Train models

#' Join targets vector to sentiment estimates
#' @param raw_pro_shares
#' @param targets_master
join_targets <- function(df, targets_master){

  # Join election results to pro shares
  df %>%
    mutate(region_1 = if_else(is.na(region_1), "National", region_1),
           region_2 = if_else(is.na(region_2), region_1, region_2),
           country = if_else(is.na(country), leader_country, country)
           ) %>%
    left_join(.,
              targets_master,
              by = c("leader" = "name", "leader_country" = "country", "region_1", "region_2"))

}


#' For each tweet, select the nearest target (poll or election) in time
#' One election per tweet
select_nearest_target <- function(senti_targets_all){

  # Select nearest election or poll for each sentiment day
  senti_targets <- senti_targets_all %>%
    # diff between tweet and election date in days
    mutate(days_diff = (date - date_target) %>% as.integer,
           days_diff_abs = abs(days_diff)
    ) %>%
    # choose target for each estimate closest in time
    group_by(target_id) %>%
    slice_min(days_diff_abs, n = 1) %>%
    ungroup() %>%
    arrange(leader, country, region_1, date)

  # Return
  senti_targets

}

#' Add GDL covariates
add_gdl_covariates <- function(senti_targets, gdl_interpo){

  left_join(senti_targets, gdl_interpo,
            by = c("year", "country", "region_1" = "gadm_region"))

}

#' Summarise cut-off validation statistics
#' @param validate_elex_raw
#' @return summary statistics by cut-off values to evaluate their differences and merits
summarise_cut_off_validation <- function(df){

  # Calculate mean, sd and summary of difference between raw estimates and cut-off
  # For period col
  df %>%
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
