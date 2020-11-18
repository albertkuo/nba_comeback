# model_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 17, 2020
#
# Model-based probabilities

# Find number of points left for each row in play-by-play dataframe
n_points_left = function(df){
  # Remove beginning/end of quarter rows
  df = df %>%
    mutate(left_score_diff = left_score - lag(left_score),
           right_score_diff = right_score - lag(right_score)) %>%
    filter(!(left_score_diff == 0 & right_score_diff == 0))%>%
    select(-left_score_diff, -right_score_diff)

  # Find number of points left to play
  df = df %>%
    mutate(n_points_left = (last(left_score) - left_score) +
             (last(right_score) - right_score)) %>%
    select(period, minute, n_points_left)

  # Create quarter column from period, merging overtime into the 4th quarter
  df = df %>%
    mutate(quarter = case_when(period == 1 ~ "1",
                               period == 2 ~ "2",
                               period == 3 ~ "3",
                               period == 4 ~ "4",
                               period >= 4 ~ "4")) %>%
    mutate(quarter = factor(quarter, levels = c("1", "2", "3", "4")))

  return(df)
}

# tic("Find n points left for playoffs") # 20 sec
# games_playoffs_npoints = lapply(games_playoffs, n_points_left)
# toc()
#
# games_playoffs_npoints = bind_rows(games_playoffs_npoints) %>%
#   mutate(time_left = (4-as.numeric(quarter))*12 + minute) %>%
#   group_by(time_left) %>%
#   summarize(n_points_left = mean(n_points_left))
# saveRDS(games_playoffs_npoints, here("./data/games_playoffs_npoints.rds"))
games_playoffs_npoints = readRDS(here("./data/games_playoffs_npoints.rds"))

# Find probability of winning given the time left (x) and score margin (diff)
model_prob = function(x, diff){
  score_margin = abs(diff)
  n = games_playoffs_npoints %>%  # number of scoring plays left
    filter(time_left == x) %>%
    pull(n_points_left) %>%
    floor()

  p = 0.5 # probability scoring on each play of losing team

  # X ~ Binom(n, p) # the number of points losing team will score in remaining time
  # Y ~ Binom(n, 1 - p) # the number of points winning team will score in remaining time
  p_win = 0 # Probability of winning the game
  if(n >= score_margin/2){
    # Probability of winning in regulation
    p_win = p_win + (1 - pbinom(floor((n + score_margin)/2), n, p))

    # Probability of winning in overtime
    if((n + score_margin) %% 2 == 0){
      p_tie = dbinom((n + score_margin)/2, n, p)
    } else {
      p_tie = 0
    }
    p_win_overtime = p_tie*0.5 # In the event of a tie at regulation, assume teams are equally matched, so conditional probability of winning in overtime is 0.5

    p_win = p_win + p_win_overtime
  } else {
    p_win = 0
  }
  return(p_win)
}

