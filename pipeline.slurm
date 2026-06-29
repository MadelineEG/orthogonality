#!/bin/bash
#SBATCH --job-name=ortho_pipeline
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=logs/pipeline_%j.out
#SBATCH --error=logs/pipeline_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=mweibnergebhar@wm.edu

set -ueo pipefail

########## SET UP ENVIRONMENT ##########

module load miniforge3
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate ortho-env

########## PROCESS DATA AND REMOVE RRNA ##########

# step 1: clean raw data and generate quality reports with trim galore and fastqc
./01_clean_raw_data.sh

# step 2: remove rrna from clean data with sortmerna 
./02_remove_rrna.sh

########## ALIGN READS AND QUANTIFY GENE COUNTS ##########

# step 3: align reads vs ref sequence with hisat2 and samtools 
./03_align_reads.sh

### SWITCH TO HTSEQ-ENV TO HANDLE HTSEQ DEPENDENCIES ###

conda deactivate
conda activate htseq-env

# step 4: quantify gene counts with htseq-count
./04_quantify_counts.sh

### SWITCH BACK TO MAIN ORTHO-ENV ###
conda deactivate
conda activate ortho-env

# step 5: prep counts data for deseq
./05_process_counts.R

########## PERFORM DIFFERENTIAL EXPRESSION ANALYSIS ##########

# step 6: generate DE gene lists for comparisons of interest
./06_get_de-genes.R 

# exit env
conda deactivate
