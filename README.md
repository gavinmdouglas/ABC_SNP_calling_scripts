# ABC SNP calling pipeline
  
This repository contains the scripts used to help automate the ABC SNP calling and analysis pipeline.
  
This README contains a brief description of each script included (note that the majority of these scripts are simple wrappers). 
  
The [wiki pages](https://github.com/gavinmdouglas/ABC_SNP_calling_scripts/wiki) of this repository contain the commands used for a few different pipelines:  
  
* Deconvolution of raw FASTQs and quality filtering and read mapping
* SNP calling with GATK and samtools
* The full GBS pipeline with Tassel alone (raw fastq to SNPs)
* Looking at the concordance in SNP calls between these different SNP callers
* Using fastphase and selscan to calculate genome-wide xpehh (I ran this on the CET, but the same commands will work)
* Quickly calculating the closest inter-SNP distance for all SNPs
* Alternative scripts that could be used to filter VCFs based on highest depth and missingness quantiles (note: I didn't use these since LinkImputeR recalls all SNPs anyway)
