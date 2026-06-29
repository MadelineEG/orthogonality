#!/bin/bash
#SBATCH --job-name=trim_galore      
#SBATCH --output=trim_%j.out       
#SBATCH --error=trim_%j.err        
#SBATCH --nodes=1                     
#SBATCH --ntasks=1                    
#SBATCH --cpus-per-task=4             # Trim Galore can utilize multiple cores
#SBATCH --mem=8G                      # 8GB is plenty for Trim Galore
#SBATCH --time=04:00:00
#SBATCH --mail-type=FAIL,BEGIN,END # when to email you
#SBATCH --mail-user=mweibnergebhar@wm.edu # who to email

set -ueo pipefail

CLEAN=./data/clean
LOGS=./data/logs
SUMMARY=./data/qc_summary.tsv

mkdir -p $CLEAN $LOGS
echo -e "study\taccession\traw_reads\tclean_reads\tpct_retained" > $SUMMARY

tail -n +2 ./data/metadata.tsv | while IFS=$'\t' read -r study acc desc strain plasmid layout rest; do
    
	R1=./data/raw/${study}_${acc}_1.fastq
	R2=./data/raw/${study}_${acc}_2.fastq
	
	if [ "$layout" == "PE" ]; then
		trim_galore --fastqc --paired --length 20 --cores 4 --output_dir $CLEAN $R1 $R2
		TLOG="$CLEAN/${study}_${acc}_1.fastq_trimming_report.txt"
	else 
		trim_galore --fastqc --cores 4 --output_dir $CLEAN $R1
		TLOG="$CLEAN/${study}_${acc}.fastq_trimming_report.txt"
	fi

	RAW=$(grep "Total reads processed:" $TLOG | awk '{print $NF}')
	CLEAN_R=$(grep "Reads written (passing filters):" $TLOG | awk '{print $5}')
	RETAIN=$(grep "Reads written (passing filters):" $TLOG | awk '{print $6}' | tr -d '()')

	echo -e "${study}\t${acc}\t${RAW}\t${CLEAN_R}\t${RETAIN}" >> $SUMMARY
	mv ${CLEAN}/${study}_${acc}*_fastqc.{html,zip} $LOGS/
        mv ${CLEAN}/${study}_${acc}*trimming_report.txt $LOGS/

	rm -f ${CLEAN}/${study}_${acc}*trimming_report.json

done

multiqc $LOGS -o $LOGS
