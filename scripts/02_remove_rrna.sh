#!/bin/bash
#SBATCH --job-name=sortmerna
#SBATCH --output=sortmerna_%j.out
#SBATCH --error=sortmerna_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8             
#SBATCH --mem=32G                     
#SBATCH --time=12:00:00               
#SBATCH --mail-type=FAIL,BEGIN,END
#SBATCH --mail-user=mweibnergebhar@wm.edu

set -ueo pipefail

mkdir -p ./data/filtered

CLEAN_DIR=./data/clean
RNA_DB=./references/databases/smr_v4.3_default_db.fasta
OUT_DIR=./data/filtered

tail -n +2 ./data/metadata.tsv | while IFS=$'\t' read -r study acc desc strain plasmid layout rest; do

	BASE_NAME="${study}_${acc}"
	WORK_DIR="${OUT_DIR}/${BASE_NAME}_work"

	# running a special version for paired end data ensures the corresponding reads get identified as rRNA in both
	if [ "$layout" == "PE" ]; then
		R1="${CLEAN_DIR}/${BASE_NAME}_1_val_1.fq"
        	R2="${CLEAN_DIR}/${BASE_NAME}_2_val_2.fq"
		
		# --fastx: output in fastq fmt
		# --out2: ensures we get a fwd and rev output
		# --aligned: rrna matches--we don't want these data
		# --other: non-rrna data--what we want
		sortmerna --ref $RNA_DB \
                  --reads $R1 --reads $R2 \
                  --workdir $WORK_DIR \
                  --fastx \
                  --aligned $OUT_DIR/${BASE_NAME}_rrna \
                  --other $OUT_DIR/${BASE_NAME}_filtered \
                  --paired_in --out2 \
                  --threads $SLURM_CPUS_PER_TASK

	else
		R1="${CLEAN_DIR}/${BASE_NAME}_1_trimmed.fq"

		sortmerna --ref $RNA_DB \
                  --reads $R1 \
                  --workdir $WORK_DIR \
                  --fastx \
                  --aligned $OUT_DIR/${BASE_NAME}_rrna \
                  --other $OUT_DIR/${BASE_NAME}_filtered \
                  --threads $SLURM_CPUS_PER_TASK
	fi

	rm -rf ${WORK_DIR}
done

# update qc_summary.tsv sheet with data on number and percent of rrna reads 
OUT_DIR="./data/filtered"
TEMP_SUMMARY=$(mktemp)

while IFS=$'\t' read -r study acc raw clean retain rest; do

    # update header
    if [[ "$study" == "Study" || "$study" == "study" ]]; then
        echo -e "${study}\t${acc}\t${raw}\t${clean}\t${retain}\tNon_rRNA_Reads\tNon_rRNA_%" >> $TEMP_SUMMARY
        continue
    fi

    BASE_NAME="${study}_${acc}"

    # identify corresponding file and address paired vs unpaired
    if [ -f "${OUT_DIR}/${BASE_NAME}_filtered_fwd.fq" ]; then
        FILE_TO_COUNT="${OUT_DIR}/${BASE_NAME}_filtered_fwd.fq"
    elif [ -f "${OUT_DIR}/${BASE_NAME}_filtered.fq" ]; then
        FILE_TO_COUNT="${OUT_DIR}/${BASE_NAME}_filtered.fq"
    else
        FILE_TO_COUNT=""
    fi

    # count non-rrna reads and calc percentage of filtered that are non-rrna
    if [ -n "$FILE_TO_COUNT" ]; then
        LINES=$(wc -l < "$FILE_TO_COUNT")
        NON_RRNA_READS=$((LINES / 4))
        
        # STRIP COMMAS from the 'clean' variable for safe math
        CLEAN_NUM="${clean//,/}"
        
        # Calculate percentage (multiply by 100 inside awk)
        NON_RRNA_PCT=$(awk -v non_rrna="$NON_RRNA_READS" -v clean_num="$CLEAN_NUM" 'BEGIN { printf "%.1f", (non_rrna/clean_>
    else
        NON_RRNA_READS="NA"
        NON_RRNA_PCT="NA"
    fi
    
    # update summary tsv
    echo -e "${study}\t${acc}\t${raw}\t${clean}\t${retain}\t${NON_RRNA_READS}\t${NON_RRNA_PCT}%" >> $TEMP_SUMMARY

done < ./data/qc_summary.tsv

# overwrite old qc_summary.tsv to match new info
mv $TEMP_SUMMARY ./data/qc_summary.tsv
