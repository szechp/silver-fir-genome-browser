library(shiny)
library(DT)
library(JBrowseR)

#set working directory to script destination
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

##get necessary data

source("data_wrangling_scripts/read_gff.R")

data_server <-
  serve_data("genome_data/")

options(DT.options = list(pageLength = 10))

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
                ), ))

server <- function(input, output, session) {
  output$DT_annotations <-
    DT::renderDataTable(annotations, selection = "single")
  
  output$select_entry = renderPrint(location())

  url <- reactive(paste0("http://127.0.0.1:5000/splitfasta/splitted/", annotations[input$DT_annotations_rows_selected,1], ".fa")
  )
  
  location <- reactive(paste0(annotations[input$DT_annotations_rows_selected,1],":", annotations[input$DT_annotations_rows_selected,3], "..", annotations[input$DT_annotations_rows_selected,4]))
  
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










