library(shiny)
library(DT)

##get neccesary data

source("data_wrangling_scripts/read_gff.R")



ui <- fluidPage(titlePanel("Tabsets"),
                mainPanel(tabsetPanel(
                  type = "tabs",
                  tabPanel("full-text search", DT::dataTableOutput("DT_annotations")),
                  tabPanel("BLAST-search")
                ),))

server <- function(input, output, session) {
  output$DT_annotations <-
    DT::renderDataTable(DT::datatable(annotations, options = list(pageLength = 10)))
  
}

shinyApp(ui, server)