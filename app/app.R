# app.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 18, 2020
#
# Shiny app for displaying plots

library(shiny)
library(shinyWidgets)
library(shinythemes)
library(plotly)
library(here)

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
            choices = c("All", "Regular Season", "Playoffs"),
            status = "primary"
        )
        ),
        column(4, align = "right",
               radioGroupButtons(
                   inputId = "model",
                   label = "",
                   choices = c("Data Only", "Smoothed Trends"),
                   status = "primary"
               )
        )
    ),

    fluidRow(
        column(8, offset = 2, align = "right",
               plotlyOutput("distPlot", height = 800),
               p("Probabilities are based on NBA games from 2000-2020. For more details,
                 click", a("here.",
                 href="https://blog.albertkuo.me"), "This app was built by", a("Albert Kuo.",
                                                                                 href="https://albertkuo.me"))
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    # Read in ggplots
    plot_ls = list()
    empirical_file_ls = list.files(here("./app/plots"), pattern = "empirical*", full.names = T)
    plot_ls[["Data Only"]] = lapply(empirical_file_ls, readRDS)
    names(plot_ls[["Data Only"]]) = c("All", "Playoffs", "Regular Season")

    smoothed_file_ls = list.files(here("./app/plots"), pattern = "smoothed*", full.names = T)
    plot_ls[["Smoothed Trends"]] = lapply(smoothed_file_ls, readRDS)
    names(plot_ls[["Smoothed Trends"]]) = c("All", "Playoffs", "Regular Season")

    # Reactive values
    season_type = reactive(input$season_type)
    model = reactive(input$model)

    output$distPlot <- renderPlotly({
        plot = plot_ls[[model()]][[season_type()]]
        print(ggplotly(plot, tooltip = 'text'))
    })
}

# Run the application
shinyApp(ui = ui, server = server)
