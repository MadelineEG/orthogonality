#!/bin/bash

module load miniforge3
source "$(conda info --base)/etc/profile.d/conda.sh" 

# main pipeline env
conda env create --file ortho-env.yml

# env to handle htseq dependencies
conda env create --file htseq-env.yml
