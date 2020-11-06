# clean_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 4, 2020
#
# Clean NBA play-by-play data for analysis
library(dplyr)

clean_data = function(df){
  # Remove rows where diff = 0
  df = df %>%
    mutate(diff = left_score - right_score) %>%
    filter(diff != 0)

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
    mutate(quarter = factor(quarter, levels = c("1", "2", "3", "4", "Overtime")))

  # Select columns
  df = df %>%
    select(quarter, minute, second, diff, win)

  return(df)
}


summarize_data = function(df_ls){
  # Summarize columns at minute/score diff level
  df_summ = bind_rows(df_ls) %>%
    group_by(quarter, minute, diff) %>%
    summarize(prob_win = sum(win)/n())

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
                        mutate(diff = 0,
                               prob_win = 0.5))

  # Add quarter and text
  df_summ = df_summ %>%
    mutate(text = paste0(minute, " minutes left in quarter ", quarter,
                         "\n", "Score margin = ", ifelse(diff > 0, paste0("+", diff), diff),
                         "\n", "Probability of win = ", round(prob_win, 2)))

  return(df_summ)
}