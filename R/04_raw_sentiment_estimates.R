# Raw sentiment estimates

#' Create object with different cut-offs
#' @param senti_tweet
#' @return senti_cut_offs
#' @details data.table does not seem required to cut down on time
create_cut_offs <- function(senti_tweet){

  # Create vector of different cut offs
  (cut_off_seq <- seq(-2, 2, length.out = 9) %>% round(., 2))

  # Add row number to group by
  senti_tweet_w_row_no <- senti_tweet %>%
    mutate(row_number = row_number())

  # Add cut off to each tweet
  purrr::map_dfr(seq_len(9), function(x) senti_tweet_w_row_no) %>%
    group_by(row_number) %>%
    mutate(cut_off = seq(-2, 2, length.out = 9)) %>%
    ungroup() %>%
    # For each tweet, determine whether it's pro or con based on different cut offs
    mutate(stance = if_else(afinn_mean > cut_off, "pro", "con"))


}

#' Calculate raw estimates
#' @param senti_cut_offs
#' @param n_roll window of rolling average
#' @return raw estimates at different cut offs
calculate_raw_estimates <- function(senti_cut_offs, n_roll = 5){

  # Calculate raw number of pros and cons per day, by cut off
  senti_cut_offs_dt <- as.data.table(senti_cut_offs)

  raw_n_per_day <- senti_cut_offs_dt[, by = list(country, region_1, region_2,
                                                 leader, leader_country,
                                                 date, #week = floor_date(date, "week"),
                                                 cut_off, stance),
                                     .(n = .N)]



  # number of pros and cons per day
  raw_n_per_day %>%
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



