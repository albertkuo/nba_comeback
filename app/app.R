# app.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 18, 2020
#
# Shiny app for displaying plots

library(shiny)
library(shinyWidgets)
library(plotly)
library(here)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("NBA Comeback"),

    fluidRow(
        column(4, offset = 2, align = "left",
        radioGroupButtons(
            inputId = "season_type",
            label = "",
            choices = c("All", "Regular", "Playoffs"),
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
        column(8, offset = 2,
               plotlyOutput("distPlot", height = 800)
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    # Read in ggplots
    plot_ls = list()
    empirical_file_ls = list.files(here("./app/plots"), pattern = "empirical*", full.names = T)
    plot_ls[["Data Only"]] = lapply(empirical_file_ls, readRDS)
    names(plot_ls[["Data Only"]]) = c("All", "Playoffs", "Regular")

    smoothed_file_ls = list.files(here("./app/plots"), pattern = "smoothed*", full.names = T)
    plot_ls[["Smoothed Trends"]] = lapply(smoothed_file_ls, readRDS)
    names(plot_ls[["Smoothed Trends"]]) = c("All", "Playoffs", "Regular")

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
