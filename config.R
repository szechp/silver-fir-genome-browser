#set working directory
setwd(dirname(rstudioapi::getSourceEditorContext()$path))#only works in RStudio, has to be set manually when running from server

#run locally?
run_from_server = FALSE

#for db creation (Note: File locations have to be specified as Os file paths, not URLs)
#specify the location of the splitted fasta files
annotation_file <- "genome_data/Abal.1_1.fixed_v2.gff"
protein_definitions <- "genome_data/Abal.1_1.protein_definition.txt"

#URLs
#specify the location of the splitted fasta files
splitted_fastas_url <- "http://127.0.0.1:5000/splitfasta/splitted/"
#specify the location of the annotation file (a sorted bigzipped gff file is needed)
annotation_file_url <- "http://127.0.0.1:5000/Abal.1_1.gff.fixed.sorted_v2.gff.gz"

#path to the blast executables (bin folder)
blast_path <- "~/ncbi-blast-2.12.0+/bin/"

#specify the location of the local BLAST Database
BLAST_db_path <- c("/media/sf_Masterarbeit/silver-fir-genome-browser/genome_data/splitfasta/Abal.1_1_filtered.1000.blast_db")
