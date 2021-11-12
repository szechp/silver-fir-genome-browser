#set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path)) #set working directory to script destination, this only works when running in RStudio

#URLs
#specify the location of the splitted fasta files
splitted_fastas_url <- "http://127.0.0.1:5000/splitfasta/splitted/"
#specify the location of the annotation file (a sorted bigzipped gff file is needed)
annotation_file_url <- "http://127.0.0.1:5000/Abal.1_1.gff.fixed.sorted_v2.gff.gz"

#path to the blast executables (bin folder)
blast_path <- "~/ncbi-blast-2.12.0+/bin/"

#specify the location of the local BLAST Database
BLAST_db_path <- c("/media/sf_Masterarbeit/silver-fir-genome-browser/genome_data/splitfasta/Abal.1_1_filtered.1000.blast_db")
