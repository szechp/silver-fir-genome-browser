library(shiny)
library(data.table)
library(DT)
library(JBrowseR)

#set working directory to script destination
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

#file check to avoid recreating the db at every start up
if (file.exists("database.csv") == F) {
  source("data_wrangling_scripts/read_gff.R")
}

#read csv to data table
database <- fread("database.csv")
colnames(database)[1] <- "No."
setindex(database, Names, ID)

#create local server to serve genome data
data_server <- serve_data("genome_data/")

options(DT.options = list(pageLength = 5))

#############
##shiny app##
#############
ui <- fluidPage(titlePanel("Tabsets"),
                mainPanel(tabsetPanel(
                  type = "tabs",
                  tabPanel(
                    "full-text search",
                    DT::dataTableOutput("DT_annotations"),
                    verbatimTextOutput("select_entry"),
                    JBrowseROutput("browserOutput")
                  ),
                  tabPanel("BLAST-search")
                )))

server <- function(input, output, session) {
  output$DT_annotations <-
    DT::renderDataTable(database, selection = "single", rownames = F)
  
  output$select_entry = renderPrint(location())

  url <- reactive(paste0("http://127.0.0.1:5000/splitfasta/splitted/", database[input$DT_annotations_rows_selected,2], ".fa")
  )
  
  location <- reactive(paste0(database[input$DT_annotations_rows_selected,2],":", database[input$DT_annotations_rows_selected,4], "..", database[input$DT_annotations_rows_selected,5]))
  
  output$browserOutput <- renderJBrowseR({JBrowseR("View",
                                                  assembly = assembly(url()),
                                                  tracks = tracks(track_feature("http://127.0.0.1:5000/Abal.1_1.gff.fixed.sorted_v2.gff.gz",
                                                                                assembly(url()))),
                                                  location = location(), #placeholder
                                                  defaultSession = default_session(assembly(url()),
                                                                                    c(track_feature("http://127.0.0.1:5000/Abal.1_1.gff.fixed.sorted_v2.gff.gz",
                                                                                                    assembly(url()))))
    )
  })
}

shinyApp(ui, server)
