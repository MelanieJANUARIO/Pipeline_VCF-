#!/bin/bash
#SBATCH --job-name=multiqc
#SBATCH --partition=std
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4GB
#SBATCH --time=00:30:00
#SBATCH -o logs/multiqc_%j.out
#SBATCH -e logs/multiqc_%j.err

###############################################################################
# MultiQC - aggregates all FastQC reports into one HTML report
#
# Usage (after FastQC jobs are finished):
#   sbatch multiqc.sh
###############################################################################

# LOAD MODULES
module load multiqc/1.31/gcc-py313

# USER SETTINGS
FASTQC_DIR="/path/to/fastqc_results" # Directory containing the FastQC outputs
OUTPUT_DIR="/path/to/multiqc_results"
REPORT_NAME="multiqc_report"

mkdir -p ${OUTPUT_DIR}

# RUN MULTIQC
multiqc ${FASTQC_DIR} -o ${OUTPUT_DIR} -n ${REPORT_NAME}

echo "MultiQC completed: ${OUTPUT_DIR}/${REPORT_NAME}.html"
