# clean_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 4, 2020
#
# Clean NBA play-by-play data for analysis
library(dplyr)

clean_data = function(df){
  # Remove rows where diff = 0 or
  # no change in score from previous row (transition between quarters)
  df = df %>%
    mutate(diff = left_score - right_score) %>%
    filter(diff != 0) %>%
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

  # Summarize time at minute level (negative time means overtime)
  df = df %>%
    mutate(time_left = ifelse(period <= 4,
                              12*(4 - period) + minute + ceiling(second/60),
                              -(5*(period - 5) + (5 - minute) - ceiling(second/60))))

  # Select columns
  df = df %>%
    select(time_left, diff, win)

  return(df)
}