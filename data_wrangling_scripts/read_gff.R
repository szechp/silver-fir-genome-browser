library(dbplyr)
library(tidyr)
library(tibble)

#read annotation file and store in DF
read.delim("genome_data/Abal.1_1.fixed_v2.gff",
           header = F,
           comment.char = "#") %>% dplyr::select(V1, V3, V4, V5, V9) %>%
  
  # get separate columns for ID and Parents, general clean up and renaming of columns
  separate(V9, into = c("V9_1", "V9_2"), sep = ";") %>%
  add_column(ID = NA) %>% add_column(Parent = NA) %>%
  dplyr::mutate(ID = dplyr::case_when(grepl("ID=", V9_1) ~ substring(V9_1, first = 4),
                                      grepl("ID=", V9_2) ~ substring(V9_2, first =4))) %>%
  dplyr::mutate(Parent = dplyr::case_when(grepl("Parent=", V9_1) ~ substring(V9_1, first = 8),
                                      grepl("Parent=", V9_2) ~ substring(V9_2, first =8))) %>%
  dplyr::select(V1, V3, V4, V5, ID, Parent) %>%
  dplyr::rename(c(contig = V1, type = V3, start = V4, end = V5)) -> annotations


#read protein definition file and store in DF
read.delim("genome_data/Abal.1_1.protein_definition.txt",sep = "\t", na.strings = "---NA---", col.names = c("ID", "Rest"), header = F) %>% 
  #seperate into IDs , entry names and full Names
  separate(Rest, into = c("entry names", "full names"), sep = " ", extr = "merge", fill = "right") -> protein_def  
