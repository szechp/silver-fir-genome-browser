library(shiny)
library(DT)
library(JBrowseR)

#set working directory to script destination
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

##get neccesary data

source("data_wrangling_scripts/read_gff.R")

options(DT.options = list(pageLength = 10))

ui <- fluidPage(titlePanel("Tabsets"),
                mainPanel(tabsetPanel(
                  type = "tabs",
                  tabPanel("full-text search", DT::dataTableOutput("DT_annotations"), verbatimTextOutput('y11')),
                  tabPanel("BLAST-search")
                ),))

server <- function(input, output, session) {
  output$DT_annotations <-
    DT::renderDataTable(annotations, selection = "single")
  
  output$y11 = renderPrint(input$DT_annotations_rows_selected)

}

shinyApp(ui, server)