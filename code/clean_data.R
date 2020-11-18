# clean_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 8, 2020
#
# Clean NBA play-by-play data for analysis
library(dplyr)

# Clean up play-by-play dataframe
clean_data = function(df){
  if(is.null(df)) return(NULL)

  # Remove rows where diff = 0
  df = df %>%
    mutate(diff = left_score - right_score) %>%
    filter(diff != 0)

  # Remove beginning/end of quarter rows
  df = df %>%
    mutate(left_score_diff = left_score - lag(left_score),
           right_score_diff = right_score - lag(right_score)) %>%
    filter(!(left_score_diff == 0 & right_score_diff == 0)) %>%
    select(-left_score_diff, -right_score_diff)

  # Find out who won (left or right)
  final_diff = df$diff[nrow(df)]
  if(final_diff > 0){
    winner = "left"
  } else if(final_diff < 0 ){
    winner = "right"
  }

  # Create win column (if the team that was behind won)
  df = df %>%
    mutate(win = (diff < 0 & winner == "left") |
             (diff > 0 & winner == "right"),
           diff = -abs(diff))

  # Create quarter column from period, merging overtime into the 4th quarter
  df = df %>%
    mutate(quarter = case_when(period == 1 ~ "1",
                               period == 2 ~ "2",
                               period == 3 ~ "3",
                               period == 4 ~ "4",
                               period >= 4 ~ "4")) %>%
    mutate(quarter = factor(quarter, levels = c("1", "2", "3", "4")))

  # Select columns
  df = df %>%
    select(quarter, minute, second, diff, win)

  return(df)
}

# Summarize list of play-by-play dataframes at a minute level/diff level
summarize_data = function(df_ls){
  # Summarize columns at minute/score diff level
  df_summ = bind_rows(df_ls) %>%
    group_by(quarter, minute, diff) %>%
    summarize(prob_win = sum(win)/n(),
              n = n()) %>%
    ungroup()

  # Add symmetric rows
  df_summ = bind_rows(df_summ,
                      df_summ %>%
                        mutate(diff = -diff,
                               prob_win = 1 - prob_win))

  # Add tie games
  df_summ = bind_rows(df_summ,
                      df_summ %>%
                        select(quarter, minute) %>%
                        distinct() %>%
                        add_row(quarter = as.factor(1), minute = 12) %>% # Add beginning of game
                        mutate(diff = 0,
                               prob_win = 0.5,
                               n = max(df_summ$n)))

  # Remove 12 minute points (beginning of quarters)
  df_summ = df_summ %>%
    filter(minute != 12)

  # Add quarter and text
  df_summ = df_summ %>%
    mutate(text = paste0(minute, " minutes left in quarter ", quarter,
                         "\n", "Score margin = ", ifelse(diff > 0, paste0("+", diff), diff),
                         "\n", "Probability of win = ", round(prob_win, 2),
                         "\n", "Sample size = ", n))

  return(df_summ)
}

# Create symmetric probabilities after smoothing
symmetrize_data = function(df){
  # Add symmetric rows
  df = bind_rows(df,
                 df %>%
                   mutate(diff = -diff) %>%
                   mutate_at(vars(starts_with("prob")), list(~.*-1 + 1)))

  # Add tie games
  df = bind_rows(df,
                 df %>%
                   select(quarter, minute) %>%
                   distinct() %>%
                   mutate(diff = 0,
                          prob_win = 0.5,
                          prob_win_smooth = 0.5,
                          prob_win_smooth_time = 0.5,
                          prob_win_smooth_margin = 0.5,
                          n = max(df$n)))

  # Add quarter and text
  df = df %>%
    mutate(text = paste0(minute, " minutes left in quarter ", quarter,
                         "\n", "Score margin = ", ifelse(diff > 0, paste0("+", diff), diff),
                         "\n", "Probability of win = ", round(prob_win_smooth, 2)))

  return(df)
}
