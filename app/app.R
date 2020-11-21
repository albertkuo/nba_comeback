# app.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 20, 2020
#
# Shiny app for displaying plots

library(shiny)
library(shinyWidgets)
library(shinythemes)
library(plotly)

# Define UI for application that draws a histogram
ui <- fluidPage(theme = shinytheme("paper"),

    # Application title
    column(8, offset = 2, align = "center",
    titlePanel("The NBA Comeback"),
    h3("Minute-by-minute probabilities of winning an NBA game")
    ),

    fluidRow(
        column(4, offset = 2, align = "left",
        radioGroupButtons(
            inputId = "season_type",
            label = "",
            choices = c("All Games", "Regular Season", "Playoffs"),
            status = "primary"
        )
        ),
        column(4, align = "right",
               radioGroupButtons(
                   inputId = "model",
                   label = "",
                   choices = c("Data Only", "Model-based"),
                   status = "primary"
               )
        )
    ),

    fluidRow(
        column(8, offset = 2, align = "left",
               plotlyOutput("distPlot", height = 600),
               p("Probabilities are calculated as the proportion of times a team has won
               given a score margin (y-axis) at x minutes into the game (x-axis) using historical
               data from all NBA games in seasons 2000-2020. Model-based, smoothed probabilities
               are estimated using a nonparametric model. For more details,
                 click", a("here.",
                 href="https://blog.albertkuo.me"))
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    # Read in ggplots
    plot_ls = list()
    empirical_file_ls = list.files("./plots", pattern = "empirical*", full.names = T)
    plot_ls[["Data Only"]] = lapply(empirical_file_ls, readRDS)
    names(plot_ls[["Data Only"]]) = c("All Games", "Playoffs", "Regular Season")

    smoothed_file_ls = list.files("./plots", pattern = "smoothed*", full.names = T)
    plot_ls[["Model-based"]] = lapply(smoothed_file_ls, readRDS)
    names(plot_ls[["Model-based"]]) = c("All Games", "Playoffs", "Regular Season")

    # Reactive values
    season_type = reactive(input$season_type)
    model = reactive(input$model)

    output$distPlot <- renderPlotly({
        plot = plot_ls[[model()]][[season_type()]]
        print(ggplotly(plot, tooltip = 'text') %>% config(displayModeBar = F))
    })
}

# Run the application
shinyApp(ui = ui, server = server)
