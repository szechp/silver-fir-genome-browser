library(dbplyr)
library(tidyr)
library(tibble)
library(stringr)

#read annotation file and store in DF
read.delim("genome_data/Abal.1_1.fixed_v2.gff",
           header = F,
           comment.char = "#") %>% dplyr::select(V1, V3, V4, V5, V9) %>%
  
  # get separate columns for ID and Parents, general clean up and renaming of columns
  separate(V9, into = c("V9_1", "V9_2"), sep = ";") %>%
  add_column(ID = NA) %>% add_column(Parent = NA) %>%
  
  dplyr::mutate(ID = dplyr::case_when(
    grepl("ID=", V9_1) ~ substring(V9_1, first = 4),
    grepl("ID=", V9_2) ~ substring(V9_2, first = 4))) %>%
  
  dplyr::mutate(Parent = dplyr::case_when(
    grepl("Parent=", V9_1) ~ substring(V9_1, first = 8),
    grepl("Parent=", V9_2) ~ substring(V9_2, first = 8))) %>%
  
  dplyr::select(V1, V3, V4, V5, ID, Parent) %>%
  
  dplyr::rename(c(
    contig = V1,
    type = V3,
    start = V4,
    end = V5)) -> annotations


#read protein definition file and store in DF
read.delim(
  "genome_data/Abal.1_1.protein_definition.txt",
  sep = "\t",
  na.strings = "---NA---",
  col.names = c("ID", "Rest"),
  header = F) %>%
  
  #seperate into IDs , entry names and full Names
  separate(
    Rest,
    into = c("Entry names", "Names"),
    sep = " ",
    extr = "merge",
    fill = "right") %>%
  
  #mutate Names column to (somewhat) tidy the messy names
  dplyr::mutate(`Entry names` = str_replace_all(`Entry names`, "RecName:", "")) %>%
  dplyr::mutate(Names = str_replace_all(Names, "ame: ", "")) %>%
  dplyr::mutate(Names = str_replace_all(Names, "Full=", ", ")) %>%
  dplyr::mutate(Names = str_replace_all(Names, "Short=", ", ")) %>%
  dplyr::mutate(Names = str_replace(Names, ", ", "")) %>%
  dplyr::filter(grepl("P1$", ID)) %>%
  dplyr::mutate(ID = dplyr::case_when(grepl("P1$", ID) ~ str_sub(ID, 1, nchar(ID) -2))) -> protein_def

#join the two data frames and save to file
merge(x = annotations,
      y = protein_def,
      by =  "ID",
      all.x = T) %>% dplyr::relocate(ID, .after = end) %>% dplyr::arrange(contig) -> merged

#write to csv
write.csv(merged, "database.csv", row.names = T)
