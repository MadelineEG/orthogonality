#!/bin/bash
#SBATCH --job-name=hisat2_align
#SBATCH --output=hisat2_%j.out
#SBATCH --error=hisat2_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8             # HISAT2 scales beautifully up to 8 threads
#SBATCH --mem=16G                     # 16GB is plenty of RAM for bacterial genomes + plasmids
#SBATCH --time=04:00:00               # Bacterial alignment is fast; 4 hours is plenty for 9 samples
#SBATCH --mail-type=FAIL,BEGIN,END
#SBATCH --mail-user=mweibnergebhar@wm.edu

set -ueo pipefail

GENOME_DIR="./references/genomes"
PLASMID_DIR="./references/plasmids"
INDEX_DIR="./references/hisat2_indexes"
ALIGN_OUT="./output/alignments"

mkdir -p $INDEX_DIR
mkdir -p $ALIGN_OUT

# Read metadata line by line
tail -n +2 ./data/metadata.tsv | while IFS=$'\t' read -r study acc desc strain plasmid layout strandedness rest; do

    BASE_NAME="${study}_${acc}"    
    STRAIN_FASTA="${GENOME_DIR}/${strain}.fna"
    RAW_PLASMID_FILE="${PLASMID_DIR}/${plasmid}.fasta"
    
    # addressing NA plasmids and lack of combined strain here
    if [ "$plasmid" == "NA" ]; then
	COMBINED_NAME="${strain}"
        COMBINED_FASTA="${STRAIN_FASTA}"
	INDEX_BASE="${INDEX_DIR}/${COMBINED_NAME}"

    # combination names/files if plasmid exists
    else
        COMBINED_NAME="${strain}_plus_${plasmid}"
        COMBINED_FASTA="${INDEX_DIR}/${COMBINED_NAME}.fasta"
        INDEX_BASE="${INDEX_DIR}/${COMBINED_NAME}"

    	# build combined reference if it doesn't exist
        if [ ! -f "$COMBINED_FASTA" ]; then
        	cp "$STRAIN_FASTA" "$COMBINED_FASTA"
        	echo ">${plasmid}" >> "$COMBINED_FASTA"
        	cat "$RAW_PLASMID_FILE" >> "$COMBINED_FASTA"
        	echo "" >> "$COMBINED_FASTA"
    	fi
    fi

    # build HISAT2 index if it doesn't exist
    if [ ! -f "${INDEX_BASE}.1.ht2" ]; then
        hisat2-build -p $SLURM_CPUS_PER_TASK "$COMBINED_FASTA" "$INDEX_BASE"
    fi

    # run HISAT2 for paired or single end
    STRAND_FLAG=""    

    if [ "$layout" == "PE" ]; then
        # determine correct strandedness param
	if [ "$strandedness" == "RF" ]; then
            STRAND_FLAG="--rna-strandness RF"
        elif [ "$strandedness" == "FR" ]; then
            STRAND_FLAG="--rna-strandness FR"
        else
            STRAND_FLAG="" # Unstranded paired-end leaves parameter empty
        fi

	R1="./data/filtered/${BASE_NAME}_filtered_fwd.fq"
        R2="./data/filtered/${BASE_NAME}_filtered_rev.fq"
        
        hisat2 $STRAND_FLAG \
	       -p $SLURM_CPUS_PER_TASK \
               -x "$INDEX_BASE" \
               -1 "$R1" -2 "$R2" \
               --summary-file "${ALIGN_OUT}/${BASE_NAME}_summary.txt" \
	| samtools sort -n \
               -@ $SLURM_CPUS_PER_TASK \
               -o "${ALIGN_OUT}/${BASE_NAME}_aligned.bam"
    else
 	# determine correct strandedness param - single-stranded reqs dif fmt
	if [ "$strandedness" == "RF" ]; then
            STRAND_FLAG="--rna-strandness R"
        elif [ "$strandedness" == "FR" ]; then
            STRAND_FLAG="--rna-strandness F"
        else
            STRAND_FLAG="" # Unstranded single-end leaves parameter empty
        fi       

	R1="./data/filtered/${BASE_NAME}_filtered.fq"
        
        hisat2 $STRAND_FLAG \
	       -p $SLURM_CPUS_PER_TASK \
               -x "$INDEX_BASE" \
               -U "$R1" \
               --summary-file "${ALIGN_OUT}/${BASE_NAME}_summary.txt" \
	| samtools sort -n \
               -@ $SLURM_CPUS_PER_TASK \
               -o "${ALIGN_OUT}/${BASE_NAME}_aligned.bam"    
    fi

done
