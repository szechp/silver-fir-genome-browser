# silver-fir-genome-browser
a searchable genome browser for the European silver fir (Abies alba)
![image](https://user-images.githubusercontent.com/45265588/135330076-306706c9-0959-45d2-9215-8734324ba4ac.png)

## Introduction
### Genome data information
in my case a silver fir reference genome was used, it is available for download [here](https://treegenesdb.org/FTP/Genomes/Abal/v1.1/)
```
########
QUAST Results
########

All statistics are based on contigs of size >= 500 bp, unless otherwise noted (e.g., "# contigs (>= 0 bp)" and "Total length (>= 0 bp)" include all contigs).

Assembly                    Abal.1_1   
# contigs (>= 0 bp)         37192295   
# contigs (>= 1000 bp)      1276678    
# contigs (>= 5000 bp)      529013     
# contigs (>= 10000 bp)     343016     
# contigs (>= 25000 bp)     145508     
# contigs (>= 50000 bp)     46234      
Total length (>= 0 bp)      18167382048
Total length (>= 1000 bp)   13017811908
Total length (>= 5000 bp)   11361640463
Total length (>= 10000 bp)  10034318481
Total length (>= 25000 bp)  6872368770 
Total length (>= 50000 bp)  3406852776 
# contigs                   1887964    
Largest contig              297427     
Total length                13450974050
GC (%)                      38.76      
N50                         25814      
N75                         9780       
L50                         139726     
L75                         348468     
# N's per 100 kbp           1703.76    

########
BUSCO Results
########

# BUSCO version is: 4.0.2 
# The lineage dataset is: embryophyta_odb10 (Creation date: 2019-11-20, number of species: 50, number of BUSCOs: 1614)
# Summarized benchmarking in BUSCO notation for file Abal.1_1.fa
# BUSCO was run in mode: genome

	***** Results: *****

	C:28.3%[S:25.0%,D:3.3%],F:18.9%,M:52.8%,n:1614	   
	457	Complete BUSCOs (C)			   
	403	Complete and single-copy BUSCOs (S)	   
	54	Complete and duplicated BUSCOs (D)	   
	305	Fragmented BUSCOs (F)			   
	852	Missing BUSCOs (M)			   
	1614	Total BUSCO groups searched		   
```
## Requirenments
* Linux
* R 4.1.1+ (lower probably works too, but I developed on that version)
* RStudio

## Dependencies
### R libraries
* data.table
* dbplyr
* dplyr
* DT
* JBrowseR
* plyr
* shiny
* shinythemes
* stringr
* tibble
* tidyr
* XML

### Command-line tools
* [genometools](http://genometools.org/)
* [samtools](https://www.htslib.org/)
* [tabix](https://www.htslib.org/)
* [gffread](https://github.com/gpertea/gffread) optional, for fixing bad gff-files
* [faSplit](http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/faSplit)
* [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)
## Tools and data preparation workflow
**You need to prepare the files using the guides below and add them to config.R**

### Preparing the genome fasta
using faSplit start with extracting each single fasta from the genome
```
faSplit byname <your_file.fa> /path/to/file
```
create a index file for each single fasta
```
for FILE in *; do samtools faidx $FILE; done
```
(this takes a long time, took me two days)

### preparing the annotation file

#### fix the gff file if needed
```
gffread -O <in.gff> -o <out.gff>

```
#### prepare gff file for JBrowse
```
gt gff3 -sortlines -tidy -retainids <in_fixed.gff> > <out.sorted.gff>
bgzip <out.sorted.gff>
tabix <out.sorted.gff.gz>
```

### making a blast database from a fasta file
```
makeblastdb -in <your_file.fa> -out <my_blast_db> -parse_seqids -dbtype nucl
```
(it's also required to provide the path to the BLAST executable in R.config)
