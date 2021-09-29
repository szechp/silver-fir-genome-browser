library(shiny)
library(data.table)
library(DT)
library(JBrowseR)
library(shinythemes)

#set working directory to script destination
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

#file check to avoid recreating the db at every start up
if (file.exists("database.csv") == F) {
  source("data_wrangling_scripts/create_full_text_search_database.R")
}

#read config file
source("config.R")

#read csv to data table
database <- fread("database.csv")
colnames(database)[1] <- "No."
setindex(database, Names, ID)


#check if config.R contains localhost, create local server to serve genome data if true
if (grepl("http://127.0.0.1:5000*", splitted_fastas_url) == T &
    grepl("http://127.0.0.1:5000*", annotation_file_url) == T) {
  data_server <- serve_data("genome_data/")
}

options(DT.options = list(pageLength = 5))

#############
##shiny app##
#############
ui <- fluidPage(theme = shinytheme("flatly"),
                navbarPage("Abies Alba Genome Browser",
                  tabPanel("full-text search",
                    DT::dataTableOutput("DT_annotations"),
                    verbatimTextOutput("select_entry"),
                    JBrowseROutput("browserOutput")
                  ),
                  tabPanel("BLAST-search")
                ))

server <- function(input, output, session) {
  output$DT_annotations <-
    DT::renderDataTable(database, selection = "single", rownames = F)
  
  output$select_entry = renderPrint(location())

  url <- reactive(paste0(splitted_fastas_url, database[input$DT_annotations_rows_selected,2], ".fa")
  )
  
  location <- reactive(paste0(database[input$DT_annotations_rows_selected,2],":", database[input$DT_annotations_rows_selected,4], "..", database[input$DT_annotations_rows_selected,5]))
  
  output$browserOutput <- renderJBrowseR({JBrowseR("View",
                                                  assembly = assembly(url()),
                                                  tracks = tracks(track_feature(annotation_file_url,
                                                                                assembly(url()))),
                                                  location = location(), #placeholder
                                                  defaultSession = default_session(assembly(url()),
                                                                                    c(track_feature(annotation_file_url,
                                                                                                    assembly(url()))))
    )
  })
}

shinyApp(ui, server)
