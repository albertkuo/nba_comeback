# main.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 1, 2020
#
# Main script for analysis


# Packages
library(reticulate)
library(here)
source_python(here("./code/download_data.py")) # Call Python script to use NBA API

# Download data
## Get game IDs
game_ids = get_game_ids() # function in download_data.py
game_ids_regular = game_ids[[1]]
game_ids_playoffs = game_ids[[2]]
game_ids_all = c(game_ids_regular, game_ids_playoffs)

## Get game IDs previously scraped already
if(file.exists(here("./data/game_ids.txt"))){
  game_ids_previous = readLines(here("./data/game_ids.txt"))
} else {
  game_ids_previous = c()
}

## Only scrape new game IDs
game_ids_regular = setdiff(game_ids_regular, game_ids_previous)
game_ids_playoffs = setdiff(game_ids_playoffs, game_ids_previous)
message("Scraping ", length(game_ids_regular), " regular season games and ",
        length(game_ids_playoffs), " playoff games")

## Get play by play for every game ID
game_id = "0041000206" # Note game_id = "1421200014" is empty
empty_games = 0
games_regular = vector(mode = "list", length = length(game_ids_regular))
for(i in seq_along(game_ids_regular[1:100])){
  if(i %% 10 == 0){
    message("Scraped ", i, " out of ", length(game_ids_regular), " games...")
  }

  game_id = game_ids_regular[[i]]
  games_regular[[i]] = get_play_by_play(game_id)

  # Count number of games that were not found
  if(is.null(games_regular[[i]]))
    empty_games = empty_games + 1
}

message("Failed to scrape ", empty_games, " out of ", length(game_ids_regular), " regular season games")




# Save game IDs that have been scraped
game_ids_scraped = c(game_ids_previous, game_ids_regular, game_ids_playoffs)
write(game_ids_scraped, here("./data/game_ids.txt"))

