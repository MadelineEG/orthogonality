#!/bin/bash
#SBATCH --job-name=fetch_genomes      # Name of the job
#SBATCH --output=genomes_%j.out       # Standard output log (%j = job ID)
#SBATCH --error=genomes_%j.err        # Standard error log
#SBATCH --nodes=1                     # Request 1 node
#SBATCH --ntasks=1                    # Request 1 task (single process)
#SBATCH --cpus-per-task=1             # 1 CPU is plenty for downloading/unzipping
#SBATCH --mem=4G                      # 4GB memory is more than enough
#SBATCH --time=02:00:00               # 2 hours max (should take minutes depending on list size)

REFS_DIR=./references/genomes
GFFS_DIR=./references/gffs
tail -n +2 references/genomes.tsv | while IFS=$'\t' read -r genome accession; do

datasets download genome accession $accession --include genome,gff --filename ${genome}.zip
unzip -p "${genome}.zip" "ncbi_dataset/data/*/*.fna" > $REFS_DIR/"${genome}.fna"
unzip -p "${genome}.zip" "ncbi_dataset/data/*/*.gff" > $GFFS_DIR/"${genome}.gff"
rm "${genome}.zip"

done
