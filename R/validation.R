# Validation

#' Join election results to raw sentiment estimates
#' @param raw_pro_shares
#' @param elex_master
join_election_to_raw_senti <- function(raw_pro_shares, elex_master){

  # Join election results to pro shares
  validate_elex_raw <- raw_pro_shares %>%
    mutate(region_1 = if_else(is.na(region_1), "National", region_1),
           id = row_number()) %>%
    left_join(., elex_master,
              by = c("country", "leader" = "name", "region_1"))

  # For each tweet, select the nearest election in time
  # One tweet, one election
  validate_elex_raw %>%
    group_by(country, leader, cut_off, pro_share, id) %>%
    # diff between tweet and election date in days
    mutate(days_diff = (elex_date - date) %>% as.integer,
           days_diff_abs = abs(days_diff)
           ) %>%
    slice_min(days_diff_abs, n = 1) %>%
    ungroup() %>%
    arrange(country, leader, region_1, date)

}
