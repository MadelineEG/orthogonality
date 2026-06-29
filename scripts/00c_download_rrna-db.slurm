#!/bin/bash
#SBATCH --job-name=DOWNLOAD_DB
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=24:00:00
#SBATCH --mem=120G
#SBATCH -o DOWNLOAD_DB_%j.out
#SBATCH -e DOWNLOAD_DB_%j.err

set -ueo pipefail

cd ./references/databases

wget https://github.com/biocore/sortmerna/releases/download/v4.3.4/database.tar.gz
tar -xvzf database.tar.gz
rm database.tar.gz

cd ../..
