#!/bin/bash
#SBATCH --job-name=sra_download       # Name of the job
#SBATCH --output=sra_%j.out           # Standard output log (%j = job ID)
#SBATCH --error=sra_%j.err            # Standard error log
#SBATCH --nodes=1                     # Request 1 node
#SBATCH --ntasks=1                    # Request 1 task
#SBATCH --cpus-per-task=4             # Request 4 cores (matches fasterq-dump -e 4)
#SBATCH --mem=16G                     # Request 16GB of memory (adjust if needed)
#SBATCH --time=24:00:00               # Max runtime in HH:MM:SS (set to 24 hrs to be safe)

cd ./data/raw
for study in ../accessions/*.txt; do

# est study prefix to label fastqs by study
prefix=$(basename "$study" .txt)

# download files for all accessions in study list
while read accession; do
	# download sra
	prefetch $accession

	# get fastq from sra
	# --split-files: separate out fwd and rev if applicable
	# -e 4: ensure enough threads for reasonable speed 
	fasterq-dump "${accession}/${accession}.sra" --split-files -e 4	

	# add study prefix to fastq
	for fastq in "${accession}"*.fastq; do
            mv "$fastq" "${prefix}_${fastq}";
        done
	
	# get rid of outer sra directories
	rm -rf $accession
done < $study

done

