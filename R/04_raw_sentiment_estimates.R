# Raw sentiment estimates

#' Create object with different cut-offs
#' @param senti_tweet
#' @return senti_cut_offs
#' @details data.table does not seem required to cut down on time
create_cut_offs <- function(senti_tweet){

  # # Create vector of different cut offs
  # (cut_off_seq <- seq(-2, 2, length.out = 9) %>% round(., 2))
  #
  # # Add row number to group by
  # senti_tweet_w_row_no <- senti_tweet %>%
  #   mutate(row_number = row_number())
  #
  # # Add cut off to each tweet
  # purrr::map_dfr(seq_len(9), function(x) senti_tweet_w_row_no) %>%
  #   group_by(row_number) %>%
  #   mutate(cut_off = seq(-2, 2, length.out = 9)) %>%
  #   ungroup() %>%
  #   # For each tweet, determine whether it's pro or con based on different cut offs
  #   mutate(stance = if_else(afinn_mean > cut_off, "pro", "con"))


  # Add row number to group by
  senti_tweet_w_row_no <- senti_tweet_w_region[, row_number := .I]

  # Bind 9 times
  senti_tweet_w_row_no <- rbindlist(replicate(n = 9, expr = senti_tweet_w_row_no, simplify = FALSE))

  # Create cut offs by grouping by row number
  senti_tweet_w_row_no[, cut_off := seq(-2, 2, length.out = 9), by = row_number]

  # For each tweet, determine whether it's pro or con based on different cut offs
  senti_tweet_w_row_no[, stance := if_else(afinn_mean > cut_off, "pro", "con")]


}

#' Calculate baseline number of pros and cons per day
#' @param senti_cut_offs
#' @param n_roll window of rolling average
#' @return raw estimates at different cut offs
calculate_baseline_n_per_day <- function(senti_cut_offs){

  # Calculate raw number of pros and cons per day, by cut off
  senti_cut_offs_dt <- as.data.table(senti_cut_offs)

  senti_cut_offs_dt[, by = list(country, region_1, region_2,
                                leader, leader_country,
                                date, #week = floor_date(date, "week"),
                                cut_off, stance),
                    .(n = .N)]

}

#' Calculate baseline estimate
calculate_baseline_estimate_per_day <- function(baseline_n_day, n_roll = 7){

  # Calculate raw estimat per day along with rolling average
  baseline_n_day %>%
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

#' MAE by cut offs and country
#' @param raw_day_targets_covars
mae_by_cut_offs <- function(baseline_day_targets_covars, type = "election", days_diff_less = 1000){

  # Calculate mean, sd and summary of difference between raw estimates and cut-off
  # For period col
  baseline_mae <- baseline_day_targets_covars %>%
    mutate(pro_share_diff = abs(pro_share - votes_share),
           pro_share_roll_diff = abs(pro_share_roll - votes_share)
           )

  # Summarise by country, election, and cut offs
  baseline_mae %>%
    # choose polls or election
    filter(type == "election") %>%
    # choose which window of days to election to analyse summary for
    filter(days_diff_abs < days_diff_less) %>%
    group_by(country, date_target, cut_off) %>%
    summarise(mean = mean(pro_share_diff, na.rm = TRUE),
              min = min(pro_share_diff, na.rm = TRUE),
              max = max(pro_share_diff, na.rm = TRUE),
              sd = sd(pro_share_diff, na.rm = TRUE),
              total_tweets = sum(total)
    ) %>%
    ungroup()

}


