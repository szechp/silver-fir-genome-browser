library(dbplyr)

#read file and store in DF
read.delim("genome_data/Abal.1_1.gff",
           header = F,
           comment.char = "#") %>% select(V1, V3, V4, V5, V9) -> annotations

#change column names
colnames(annotations) <- c("contig", "type", "start", "end", "description")