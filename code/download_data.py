# download_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Oct 31, 2020
#
# Download NBA data using NBA API https://github.com/swar/nba_api

# Modules
# reticulate::repl_python() # Run Python in Console, type "exit" to exit session
# Alternatively, run interactively in Terminal window (type "python")
import nba_api

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
from nba_api.stats.library.parameters import Season
from nba_api.stats.library.parameters import SeasonAll
from nba_api.stats.library.parameters import SeasonType

# Regular season game IDs
game_ids_regular = []
for season in season_range:
  for team_id in nba_team_ids:
    print(team_id)
    gamefinder = leaguegamefinder.LeagueGameFinder(team_id_nullable = team_id,
    season_nullable = season,
    season_type_nullable = SeasonType.regular)
    
    games_dict = gamefinder.get_normalized_dict()
    games = games_dict["LeagueGameFinderResults"]
    game_ids = [game["GAME_ID"] for game in games]
    game_ids_regular.extend(game_ids)
  
    # Find most recent year in data
    if len(games) > 0:
      game_year = int(games[0]["GAME_DATE"][0:4])
      if game_year > last_year_scraped:
        last_year_scraped = game_year

print(len(game_ids_regular))
game_ids_regular = list(set(game_ids_regular))
print(len(game_ids_regular))

# Save last year that had a game ID scraped
with open("./data/last_year_scraped.txt", "w") as file:
  file.write(str(last_year_scraped))

# Playoffs game IDs
game_ids_playoffs = []
for season in season_range:
  for team_id in nba_team_ids:
    gamefinder = leaguegamefinder.LeagueGameFinder(team_id_nullable = team_id,
    season_nullable = season,
    season_type_nullable = "Playoffs")
    
    games_dict = gamefinder.get_normalized_dict()
    games = games_dict["LeagueGameFinderResults"]
    game_ids = [game["GAME_ID"] for game in games]
    game_ids_playoffs.extend(game_ids)

print(len(game_ids_playoffs))
game_ids_playoffs = list(set(game_ids_playoffs))
print(len(game_ids_playoffs))

# Return nested list of regular season game IDs and playoff game IDs
game_ids_all = [game_ids_regular, game_ids_playoffs]
return game_ids_all


# Get play by play for every game, team, season
# Play by play data

def get_play_by_play(game_id):
  from nba_api.stats.endpoints import playbyplay
  print(game_id)
  df = playbyplay.PlayByPlay(game_id).get_data_frames()[0]
  
  df.head() # just looking at the head of the data