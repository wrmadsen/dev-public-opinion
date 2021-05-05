# Raw sentiment manipulations

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



