library(shiny)
library(data.table)
library(DT)
library(JBrowseR)
library(shinythemes)
library(XML)
library(plyr)
library(dplyr)

library(RSQLite)
library(shinyWidgets)

#read config file
source("config.R")

#file check to avoid recreating the db at every start up
if (file.exists("database.csv") == F) {
  source("data_wrangling_scripts/create_full_text_search_database.R")
}

#read csv to data table
database <- fread("database.csv")
colnames(database)[1] <- "No."
setindex(database, Names, ID)


#check if config.R contains localhost, create local server to serve genome data if true
if (run_from_server == F) {
  try(data_server <- serve_data("genome_data/"))
}

options(DT.options = list(pageLength = 5))

#############
##shiny app##
#############
ui <- fluidPage(theme = shinytheme("flatly"),
                navbarPage("Abies Alba Genome Browser",
                           tabPanel(
                             "Welcome",
                             h2("Welcome to the Abies Alba Genome Browser"),
                             fluidRow(
                               column(7,
                                      includeMarkdown("welcome.Rmd")),
                             column(5,
                               img(src = "360px-Abies_alba1.jpg", width = "50%")
                             )
                           )),
                           tabPanel("full-text search",
                                    searchInput(
                                      inputId = "search",
                                      label = "Enter search query",
                                      value = "",
                                      placeholder = "e.g. fatty acid",
                                      btnSearch = icon("search"),
                                      btnReset = icon("remove", verify_fa = FALSE),
                                      width = "450px"
                                    ),
                                    DTOutput("table"),
                                    JBrowseROutput("browserOutput_ft_search")
                           ), 

                  tabPanel("BLAST-search",
                    tagList(
                  tags$head(
                    tags$link(rel="stylesheet", type="text/css",href="style.css"),
                    tags$script(type="text/javascript", src = "busy.js")
                  )
                ),
                
                #This block gives us all the inputs:
                mainPanel(
                  headerPanel('Shiny Blast!'),
                  textAreaInput('query', 'Input sequence:', value = "", placeholder = "", width="100%", height = "200px"),
                  selectInput("eval", "e-value:", choices=c(1,0.001,1e-4,1e-5,1e-10), width="100px"),
                  actionButton("blast", "BLAST!"), 
                  width = 12
                ),
                
                #this snippet generates a progress indicator for long BLASTs
                div(class = "busy",  
                    p("Calculation in progress.."), 
                    img(src="https://i.stack.imgur.com/8puiO.gif", height = 100, width = 100,align = "center")
                ),
                
                #Basic results output
                mainPanel(
                  h4("Results"),
                  DT::dataTableOutput("blastResults"),
                  p("Alignment:", tableOutput("clicked") ),
                  verbatimTextOutput("alignment"),
                  JBrowseROutput("browserOutput_BLAST_search"), 
                  width = 12
                ))
                ))

server <- function(input, output, session) {


  #####################################
  ###servercode for full text search###
  #####################################
  con <- dbConnect(RSQLite::SQLite(), "database.db")
  
  sqlInput <- reactive({
    paste0("SELECT * 
            FROM genome_data
          WHERE contig LIKE '%",input$search,"%'
           OR Names LIKE '%",input$search,"%'
           OR ID LIKE '%",input$search,"%'
           OR Parent LIKE '%",input$search,"%'
           OR type LIKE '%",input$search,"%'")
  })
  
  
  sqlOutput <- reactive({
    dbGetQuery(con, sqlInput())
  })
  
  #dbDisconnect(db)
  output$table <- DT::renderDT(sqlOutput(), server=TRUE, options=list(pageLength = 10, dom = 't'), selection = list(mode = "single", selected = c(1)), rownames = F)

  
  output$DT_annotations <-
    DT::renderDataTable(database, selection = list(mode = "single", selected = c(341)), rownames = F)
  
  output$select_entry = renderPrint(location())

  #get location and filename from selected entry and display it in JBrowse
  
  url <- reactive(paste0(splitted_fastas_url, database[input$table_rows_selected,2], ".fa")
  )
  
  location_ft_search <- reactive(paste0(database[input$table_rows_selected,2],":", database[input$table_rows_selected,4], "..", database[input$table_rows_selected,5]))
  
  output$browserOutput_ft_search <- renderJBrowseR({JBrowseR("View",
                                                  assembly = assembly(url()),
                                                  tracks = tracks(track_feature(annotation_file_url,
                                                                                assembly(url()))),
                                                  location = location_ft_search(),
                                                  defaultSession = default_session(assembly(url()),
                                                                                    c(track_feature(annotation_file_url,
                                                                                                    assembly(url()))))
    )
  })


  ##################################
  ###server code for BLAST search###
  ##################################
 
  blastresults <- eventReactive(input$blast, {
    
    #gather input and set up temp file
    query <- input$query
    tmp <- tempfile(fileext = ".fa")
    
    #this makes sure the fasta is formatted properly
    if (startsWith(query, ">")){
      writeLines(query, tmp)
    } else {
      writeLines(paste0(">Query\n",query), tmp)
    }
    
    #calls the blast
    data <- system(paste0(blast_path, "blastn", " -query ",tmp," -db ",BLAST_db_path," -evalue ",input$eval," -outfmt 5 -max_hsps 1 -max_target_seqs 10 "), intern = T)
    #write.table(data, file = "debug2.txt")
    xmlParse(data)
  }, ignoreNULL= T)
  
  #Parse the results...
  parsedresults <- reactive({
    if (is.null(blastresults())){}
    else {
      xmltop = xmlRoot(blastresults())
      
      #the first chunk is for multi-fastas
      results <- xpathApply(blastresults(), '//Iteration',function(row){
        query_ID <- getNodeSet(row, 'Iteration_query-def') %>% sapply(., xmlValue)
        hit_IDs <- getNodeSet(row, 'Iteration_hits//Hit//Hit_id') %>% sapply(., xmlValue)
        hit_to <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_hit-from') %>% sapply(., xmlValue)
        hit_from <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_hit-to') %>% sapply(., xmlValue)
        hit_length <- getNodeSet(row, 'Iteration_hits//Hit//Hit_len') %>% sapply(., xmlValue)
        bitscore <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_bit-score') %>% sapply(., xmlValue)
        eval <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_evalue') %>% sapply(., xmlValue)
        cbind(query_ID,hit_IDs,hit_from,hit_to,hit_length,bitscore,eval)
      })
      #this ensures that NAs get added for no hits
      results <-  rbind.fill(lapply(results,function(y){as.data.frame((y),stringsAsFactors=FALSE)}))
    }
  })
  
  #makes the datatable
  output$blastResults <- renderDataTable({
    if (is.null(blastresults())){
    } else {
      parsedresults()
    }
  }, selection="single")
  
  #get the alignemnt information from a clicked row
  output$clicked <- renderTable({
    if(is.null(input$blastResults_rows_selected)){}
    else{
      xmltop = xmlRoot(blastresults())
      clicked = input$blastResults_rows_selected
      tableout<- data.frame(parsedresults()[clicked,])
      
      tableout <- t(tableout)
      names(tableout) <- c("")
      rownames(tableout) <- c("Query ID","Hit ID" , "Hit from", "to", "Length", "Bit Score", "e-value")
      colnames(tableout) <- NULL
      data.frame(tableout)
    }
  },rownames =T,colnames =F)
  
  #make alignments for clicked rows
  output$alignment <- renderText({
    if(is.null(input$blastResults_rows_selected)){}
    else{
      xmltop = xmlRoot(blastresults())
      
      clicked = input$blastResults_rows_selected
      
      #loop over the xml to get the alignments
      align <- xpathApply(blastresults(), '//Iteration',function(row){
        top <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_qseq') %>% sapply(., xmlValue)
        mid <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_midline') %>% sapply(., xmlValue)
        bottom <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_hseq') %>% sapply(., xmlValue)
        rbind(top,mid,bottom)
      })
      
      #split the alignments every 40 carachters to get a "wrapped look"
      alignx <- do.call("cbind", align)
      splits <- strsplit(gsub("(.{40})", "\\1,", alignx[1:3,clicked]),",")
      
      #paste them together with returns '\n' on the breaks
      split_out <- lapply(1:length(splits[[1]]),function(i){
        rbind(paste0("Q-",splits[[1]][i],"\n"),paste0("M-",splits[[2]][i],"\n"),paste0("H-",splits[[3]][i],"\n"))
      })
      unlist(split_out)
    }
  })
  
  #displays the selected row in JBrowser
  url_BLAST_search <- reactive(paste0(splitted_fastas_url, parsedresults()[input$blastResults_rows_selected,2], ".fa")
  )
  
  location_BLAST_search <- reactive(paste0(parsedresults()[input$blastResults_rows_selected,2],":", parsedresults()[input$blastResults_rows_selected,3], "..", parsedresults()[input$blastResults_rows_selected,4]))
  
  output$browserOutput_BLAST_search <- renderJBrowseR({JBrowseR("View",
                                                   assembly = assembly(url_BLAST_search()),
                                                   tracks = tracks(track_feature(annotation_file_url,
                                                                                  assembly(url_BLAST_search()))),
                                                    location = location_BLAST_search(), #placeholder
                                                    defaultSession = default_session(assembly(url_BLAST_search()),
                                                                                     c(track_feature(annotation_file_url,
                                                                                                     assembly(url_BLAST_search()))))
   )
  })
  
  cancel.onSessionEnded <- session$onSessionEnded(function() {
    dbDisconnect(con)
  })
  
}

shinyApp(ui, server)
