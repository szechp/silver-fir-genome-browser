# silver-fir-genome-browser
a searchable genome browser for the European silver fir (Abies alba)
![image](https://user-images.githubusercontent.com/45265588/133756336-deefc6a4-520e-46d4-8f3f-3a046a3f2f0e.png)
## Introduction
### Genome data information
## Dependencies
### R libraries
* shiny
* DT
* JBrowseR
* dbplyr
* tidyr
* stringr
### Command-line tools
* [genometools](http://genometools.org/)
* [samtools](https://www.htslib.org/)
* [tabix](https://www.htslib.org/)
* [gffread](https://github.com/gpertea/gffread) optional, for fixing bad gff-files
* [faSplit](http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/faSplit)
## Tools and data preparation workflow
### Preparing the genome fasta
using faSplit start with extracting each single fasta from the genome
```
faSplit byname your_file.fa /genome_data/splitted
```
create a index file for each single fasta
```
for FILE in *; do samtools faidx $FILE; done
```
(this takes a long time, took me two days)

### preparing the annotation file
