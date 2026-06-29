#!/bin/bash
#SBATCH --job-name=htseq_count
#SBATCH --output=./output/counts/htseq_%j.out
#SBATCH --error=./output/counts/htseq_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --mail-type=FAIL,BEGIN,END
#SBATCH --mail-user=mweibnergebhar@wm.edu

set -ueo pipefail

GFF_DIR="./references/gffs"
BAM_DIR="./output/alignments"
COUNTS_OUT="./output/counts"

mkdir -p "$COUNTS_OUT"

# iterate through metadata tsv
tail -n +2 ./data/metadata.tsv | while IFS=$'\t' read -r study acc desc strain plasmid layout strandedness rest; do

    BASE_NAME="${study}_${acc}"
    BAM_FILE="${BAM_DIR}/${BASE_NAME}_aligned.bam"

    # determine gff based on strain and plasmid
    if [ "$plasmid" == "NA" ]; then
        GFF_FILE="${GFF_DIR}/${strain}.gff"
    else
        GFF_FILE="${GFF_DIR}/${strain}_${plasmid}.gff"
    fi

    # determine htseq strandedness param based on metadata
    HTSEQ_STRAND="no" # unstranded, change below if otherwise

    if [[ "$strandedness" == "RF" || "$strandedness" == "R" ]]; then
        HTSEQ_STRAND="reverse"
    elif [[ "$strandedness" == "FR" || "$strandedness" == "F" ]]; then
        HTSEQ_STRAND="yes"
    fi

    # establish output file
    OUTPUT_COUNTS="${COUNTS_OUT}/${BASE_NAME}_counts.txt"

    # run HTSeq-Count
    htseq-count -f bam \
                -r name \
                -s "$HTSEQ_STRAND" \
                -t gene \
                -i Name \
                --nonunique fraction \
                "$BAM_FILE" \
                "$GFF_FILE" > "$OUTPUT_COUNTS"

done

