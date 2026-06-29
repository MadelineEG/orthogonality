#!/bin/bash
#SBATCH --job-name=deseq_guo
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --output=deseq_log.txt
#SBATCH --mail-type=FAIL,BEGIN,END
#SBATCH --mail-user=mweibnergebhar@wm.edu

Rscript ./scripts/06_get_de-genes.R
