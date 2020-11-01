# main.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Oct 30, 2020
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
        length(game_ids_playoffs), " playoff games.")

## Get play by play for every game ID
get_play_by_play(game_id)


# Save game IDs that have been scraped
game_ids_scraped = c(game_ids_previous, game_ids_regular, game_ids_playoffs)
write(game_ids_scraped, here("./data/game_ids.txt"))

