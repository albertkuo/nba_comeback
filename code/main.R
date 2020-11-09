# main.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 8, 2020
#
# Main script for analysis


# Packages
library(reticulate)
library(here)
library(tictoc)

# Download data
source_python(here("./code/download_data.py")) # Call Python script to use NBA API

## Get game IDs
game_ids = get_game_ids() # function in download_data.py
game_ids_regular = game_ids[[1]]
game_ids_playoffs = game_ids[[2]]
game_ids_all = c(game_ids_regular, game_ids_playoffs)

## Get game IDs previously downloaded already
if(file.exists(here("./data/game_ids.txt"))){
  game_ids_previous = readLines(here("./data/game_ids.txt"))
} else {
  game_ids_previous = c()
}

## Only download new game IDs
game_ids_regular = setdiff(game_ids_regular, game_ids_previous)
game_ids_playoffs = setdiff(game_ids_playoffs, game_ids_previous)
message("Downloading ", length(game_ids_regular), " regular season games and ",
        length(game_ids_playoffs), " playoff games")

## Get play by play for every regular season game
game_id = "0041000206" # Note game_id = "1421200014" is empty
empty_games = 0
games_regular = vector(mode = "list", length = length(game_ids_regular))
tic("Download regular season games")
for(i in seq_along(game_ids_regular)){
  if(i %% 100 == 0){
    message("Downloaded ", i, " out of ", length(game_ids_regular), " games...")
  }

  game_id = game_ids_regular[[i]]
  games_regular[[i]] = tryCatch({get_play_by_play(game_id)}, error = function(e) return(NULL))

  # Count number of games that were not found
  if(is.null(games_regular[[i]]))
    empty_games = empty_games + 1
}
toc()
message("Failed to download ", empty_games, " out of ", length(game_ids_regular), " regular season games")
if(file.exists(here("./data/games_regular.rds"))){
  games_regular_previous = readRDS(here("./data/games_regular.rds"))
  games_regular = bind_rows(games_regular_previous, games_regular)
  saveRDS(games_regular, here("./data/games_regular.rds"))
} else {
  saveRDS(games_regular, here("./data/games_regular.rds"))
}

## Get play by play for every playoffs game
empty_games = 0
games_playoffs = vector(mode = "list", length = length(game_ids_playoffs))
tic("Download playoff games")
for(i in seq_along(game_ids_playoffs)){
  if(i %% 100 == 0){
    message("Downloaded ", i, " out of ", length(game_ids_playoffs), " games...")
  }

  game_id = game_ids_playoffs[[i]]
  games_playoffs[[i]] = tryCatch({get_play_by_play(game_id)}, error = function(e) return(NULL))

  # Count number of games that were not found
  if(is.null(games_playoffs[[i]]))
    empty_games = empty_games + 1
}
toc()
message("Failed to download ", empty_games, " out of ", length(game_ids_playoffs), " playoff games")
if(file.exists(here("./data/games_playoffs.rds"))){
  games_regular_previous = readRDS(here("./data/games_playoffs.rds"))
  games_regular = bind_rows(games_regular_previous, games_regular)
  saveRDS(games_regular, here("./data/games_playoffs.rds"))
} else {
  saveRDS(games_regular, here("./data/games_playoffs.rds"))
}

## Save game IDs that have been downloaded (or attempted to download)
game_ids_scraped = c(game_ids_previous, game_ids_regular, game_ids_playoffs)
write(game_ids_scraped, here("./data/game_ids.txt"))

## Save game IDs that failed to download
if(file.exists(here("./data/game_ids_failed.txt"))){
  game_ids_failed = readLines(here("./data/game_ids_failed.txt"))
  game_ids_failed = c(game_ids_failed,
                      game_ids_regular[which(sapply(games_regular, function(x) is.null(x)))],
                      game_ids_playoffs[which(sapply(games_playoffs, function(x) is.null(x)))])
  write(game_ids_failed, here("./data/game_ids_failed.txt"))
} else {
  game_ids_failed = c(game_ids_regular[which(sapply(games_regular, function(x) is.null(x)))],
                      game_ids_playoffs[which(sapply(games_playoffs, function(x) is.null(x)))])
  write(game_ids_failed, here("./data/game_ids_failed.txt"))
}

# Clean data
source(here("./code/clean_data.R"))

## Read in games
games_playoffs = readRDS(here("./data/games_playoffs.rds"))
games_regular = readRDS(here("./data/games_regular.rds"))

## Clean up columns
tic("Clean playoff games") # 20 sec
games_playoffs_clean = lapply(games_playoffs, clean_data)
toc()
saveRDS(games_playoffs_clean, here("./data/games_playoffs_clean.rds"))

tic("Clean regular season games") # 3 min
games_regular_clean = lapply(games_regular, clean_data)
toc()
saveRDS(games_regular_clean, here("./data/games_regular_clean.rds"))

## Summarize data
games_playoffs_clean = readRDS(here("./data/games_playoffs_clean.rds"))
games_regular_clean = readRDS(here("./data/games_regular_clean.rds"))

games_playoffs_summ = summarize_data(games_playoffs_clean)
games_regular_summ = summarize_data(games_regular_clean)

## Plot data
source(here("./code/plot_data.R"))
p = plot_data(games_playoffs_summ)
ggplotly(p, tooltip = "text")

p = plot_data(games_regular_summ)
ggplotly(p, tooltip = "text")


## Monotone smoother
# https://www.rdocumentation.org/packages/fda/versions/5.1.5.1/topics/smooth.monotone
library(fda)
score_margin = 5
tmp = games_playoffs_summ %>% filter(diff == -score_margin) %>%
  mutate(time_left = (4-as.numeric(quarter))*12 + minute)

tmp = tmp %>% arrange(time_left)
x = tmp$time_left
y = tmp$prob_win
rng = c(0, 47) # range of x

# b-spline basis
norder = 6
n = length(x)
nbasis = n + norder - 2
wbasis = create.bspline.basis(rng, nbasis, norder, x)

# starting values for coefficient
cvec0 = matrix(0, nbasis, 1)
Wfd0 = fd(cvec0, wbasis)

# set up functional parameter object
Lfdobj = 3          #  penalize curvature of acceleration
lambda = 10^(-0.5)  #  smoothing parameter
growfdPar = fdPar(Wfd0, Lfdobj, lambda)
wgt = tmp$n         # weight vector = sample size

# smoothed result
result = smooth.monotone(x, y, growfdPar, wgt,
                          conv=0.1)
# coefficients
Wfd = result$Wfdobj
beta = result$beta
y_smooth = beta[1] + beta[2]*eval.monfd(x, Wfd)

# plot the data and the curve
plot(x, y, type="p")
lines(x, y_smooth)
y_smooth = sapply(y_smooth, function(y) min(0.5, y))
lines(x, y_smooth)


## Model-based probabilities
# tic("Find n points left for playoffs") # 20 sec
# games_playoffs_npoints = lapply(games_playoffs, n_points_left)
# toc()
#
# games_playoffs_npoints = bind_rows(games_playoffs_npoints) %>%
#   mutate(time_left = (4-as.numeric(quarter))*12 + minute) %>%
#   group_by(time_left) %>%
#   summarize(n_points_left = mean(n_points_left))
# saveRDS(games_playoffs_npoints, here("./data/games_playoffs_npoints.rds"))


y_model = sapply(x, function(x) model_prob(x, score_margin))
lines(x, y_model, col = "red")
