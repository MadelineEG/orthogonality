# orthogonality
Pipeline to meta-analyze *E. coli* gene expression data--spanning various studies, bacterial strains, and laboratory environments--to identify genes associated with the bacterial response to different engineering conditions. 

## Dependencies

### Software Tools
All relevant software tools and their dependencies are included in the Conda environments **ortho-env** and **htseq-env**. Below are the key tools and version numbers:
* sra-tools: 3.4.1
* ncbi-datasets-cli: 18.31.0
* trim-galore: 2.2.0
* multiqc: 1.35
* hisat2: 2.2.2
* samtools: 1.23.1
* htseq: 2.1.2
* python: 3.11.15
* r-base: 4.6.1
* bioconductor-deseq2: 1.50.2

### Raw Data, References, and Databases
* **Data:** NCBI accessions are listed in ./data/metadata.tsv and can be downloaded via ./scripts/00_download_raw_data.sh
* **References:** NCBI accessions are listed in ./references/genomes.tsv and can be downloaded via ./scripts/00_download_refs.sh
* **SortMeRNA DB:** ./references/databases/smr_v4.3_default_db, downloadble via ./scripts/00_download_rrna-db.sh

## Directory Structure
.
├── data
│   ├── accessions
│   ├── clean
│   ├── comparisons.tsv
│   ├── filtered
│   ├── logs
│   │   ├── multiqc_data
│   │   └── multiqc_report.html
│   ├── metadata.tsv
│   ├── qc_summary.tsv
│   └── raw
├── output
│   ├── alignments
│   ├── counts
│   ├── counts-processed
│   └── de-genes
├── pipeline.slurm
├── README.md
├── references
│   ├── databases
│   ├── genomes
│   ├── genomes.tsv
│   ├── gffs
│   ├── hisat2_indexes
│   └── plasmids
└── scripts
    ├── 00_download_raw_data.sh
    ├── 00_download_refs.sh
    ├── 00_download_rrna-db.sh
    ├── 01_clean_raw_data.sh
    ├── 02_remove_rrna.sh
    ├── 03_align_reads.sh
    ├── 04_quantify_counts.sh
    ├── 05_process_counts.R
    ├── 06_get_de-genes.R
    └── 07_remove_plasmid-genes.R

## Metadata and DE Comparisons
Ensure you have populated **./data/metadata.tsv** with accession numbers for raw data, corresponding bacterial strain and plasmid (if applicable), data layout (paired vs. unpaired) and strandedness parameters, and a condition name to group together biological replicates

Also populate **./data/comparisons.tsv** with information on the conditions to be compared. (Note that condition names should match those in metadata.tsv.)

## Setup
Before running the pipeline, clone this repository and run the below setup steps in order from the project directory:
1. Ensure basic directory structure
```bash
# add script once written
```
2. Create conda environments using the provided .yml files
```bash
# add script once make .ymls and script to set up envs with them
```
3. Download raw data from SRA
```bash
sbatch ./scripts/00_download_raw_data.slurm
```
4. Download reference genomes from SRA
```bash
sbatch ./scripts/00_download_refs.slurm
```
5. Download SortMeRNA database
```bash
sbatch ./scripts/download_rrna-db.slurm
```

## Usage
After populating metadata.tsv and comparisons.tsv and completing the setup steps above, run the below command from the project directory:
```bash
sbatch pipeline.slurm
```

## Overview
[List of scripts and their functions]

## Outputs
**DE gene lists** containing lists of significantly DE genes (padj<0.05) in .csv format can be found in ./output/de-genes

## References
