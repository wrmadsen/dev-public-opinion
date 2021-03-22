# Validation

#' Join election results to raw sentiment estimates
#' @param senti_pro_shares
#' @param elex_master

# Need to add join by area as well, or option to do so
join_election_to_raw_senti <- function(senti_pro_shares, elex_master){

  # Join election results to pro shares
  validate_raw <- senti_pro_shares %>%
    mutate(id = row_number()) %>%
    left_join(., elex_master,
              by = c("country", "leader" = "name", "region_1" = "area"))

  # For each tweet, select the nearest election in time
  validate_raw <- validate_raw %>%
    group_by(country, leader, cut_off, pro_share, id) %>%
    # diff between tweet and election date in days
    mutate(date_diff = (elex_date - week),
           date_diff = as.integer(date_diff) %>% abs) %>%
    slice_min(diff, n = 1) %>%
    ungroup()


  validate_raw



}
