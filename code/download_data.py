# download_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 1, 2020
#
# Download NBA data using NBA API https://github.com/swar/nba_api
# https://github.com/swar/nba_api/blob/master/docs/examples/PlayByPlay.ipynb
# Need to fix read timeout issue: https://github.com/swar/nba_api/blob/master/docs/nba_api/stats/examples.md

# Modules
# reticulate::repl_python() # Run Python in Console, type "exit" or "quit" to exit session
# Alternatively, run interactively in Terminal window (type "python")
import nba_api
import time

# Get Game IDs from current season + all seasons not fully scraped
def get_game_ids():
  # Get NBA team IDs
  from nba_api.stats.static import teams
  nba_teams = teams.get_teams()
  nba_team_ids = [team["id"] for team in nba_teams]
  
  # Get season names since 2000/last season not scraped
  from datetime import datetime
  from pathlib import Path
  year_min = 2000
  last_year_scraped = 2020
  current_year = datetime.today().year
  
  if Path("./data/last_year_scraped.txt").is_file(): 
    file = open('./data/last_year_scraped.txt', 'r', encoding='utf-8')
    last_year_scraped = file.readlines()
    print(last_year_scraped)
    year_min = int(last_year_scraped[0]) - 1 
  
  year_range = range(year_min, current_year)
  season_range = [str(year) + "-" +str(year+1)[2:4] for year in year_range]
  
  # Get game IDs
  from nba_api.stats.endpoints import leaguegamefinder
  from nba_api.stats.library.parameters import SeasonType
  
  # Regular season game IDs
  game_ids_regular = []
  for season in season_range:
    print(season)
    gamefinder = leaguegamefinder.LeagueGameFinder(season_nullable = season,
    season_type_nullable = SeasonType.regular, timeout = 10) 
    time.sleep(0.5) # Slow down request frequency
    
    games_dict = gamefinder.get_normalized_dict()
    games = games_dict["LeagueGameFinderResults"]
    game_ids = [game["GAME_ID"] for game in games if game["TEAM_ID"] in nba_team_ids] # Filter to nba teams only
    game_ids_regular.extend(game_ids)
  
    # Find most recent year in data
    if len(games) > 0:
      game_year = int(games[0]["GAME_DATE"][0:4])
      if game_year > last_year_scraped:
        last_year_scraped = game_year
  
  # Take unique game IDs
  game_ids_regular = list(set(game_ids_regular))
  
  # Save last year that had a game ID scraped
  # with open("./data/last_year_scraped.txt", "w") as file:
  #   file.write(str(last_year_scraped))

  # Playoffs game IDs
  game_ids_playoffs = []
  for season in season_range:
    gamefinder = leaguegamefinder.LeagueGameFinder(season_nullable = season,
    season_type_nullable = "Playoffs", timeout = 10)
    time.sleep(0.5) # Slow down request frequency
    
    games_dict = gamefinder.get_normalized_dict()
    games = games_dict["LeagueGameFinderResults"]
    game_ids = [game["GAME_ID"] for game in games if game["TEAM_ID"] in nba_team_ids] # Filter to nba teams only
    game_ids_playoffs.extend(game_ids)
    
  game_ids_playoffs = list(set(game_ids_playoffs))
  
  # Return nested list of regular season game IDs and playoff game IDs
  game_ids_all = [game_ids_regular, game_ids_playoffs]
  return game_ids_all

# Get play by play for every game, team, season
# Play by play data
from nba_api.stats.endpoints import playbyplay
def get_play_by_play(game_id):
  # game_id = "0041000206" # example game ID
  df = playbyplay.PlayByPlay(game_id).get_data_frames()[0]
  time.sleep(0.5)
  
  if(df.empty): return None
  
  # Select rows with scores
  df = df.loc[df["SCORE"].notnull()]
  
  # Clean up columns
  df[["minute", "second"]] = df["PCTIMESTRING"].str.split(":", expand = True).astype(int)
  df[["left_score", "right_score"]] = df["SCORE"].str.split(" - ", expand = True).astype(int)
  df.rename(columns = {"PERIOD":"period"}, inplace = True)
  df = df.loc[:, ["period", "minute", "second", "left_score", "right_score"]]
    
  # Return data frame of time left and scores
  return df
