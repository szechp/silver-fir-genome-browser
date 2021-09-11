library(shiny)
library(DT)

##get neccesary data

source("data_wrangling_scripts/read_gff.R")



ui <- basicPage(
  h2("datatable"),
  DT::dataTableOutput("DT_annotations"))

server <- function(input, output, session) {
  output$DT_annotations <-
    DT::renderDataTable(DT::datatable(annotations, options = list(pageLength = 10)))
  
}

shinyApp(ui, server)