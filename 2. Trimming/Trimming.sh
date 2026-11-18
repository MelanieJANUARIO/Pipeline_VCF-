#!/bin/bash
#SBATCH --job-name=trimmomatic
#SBATCH --partition=std
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16GB
#SBATCH --time=08:00:00
#SBATCH -o logs/trim_%A_%a.out
#SBATCH -e logs/trim_%A_%a.err

###############################################################################
###############################################################################

# LOAD MODULES
module load trimmomatic/0.39/java    # Adapt to your cluster

# USER SETTINGS
ADAPTER="/path/to/adapters/Adapter.fasta"
FASTQ_DIR="/path/to/raw_data"
OUTPUT_DIR="/path/to/trimming_results"
SAMPLE_LIST="samples.txt"  #create your samples list

# GET SAMPLE NAME FROM ARRAY INDEX
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLE_LIST})

mkdir -p ${OUTPUT_DIR}

echo "Processing sample: ${SAMPLE}"

# RUN TRIMMOMATIC
trimmomatic PE \
    -threads ${SLURM_CPUS_PER_TASK} \
    -phred33 \
    ${FASTQ_DIR}/${SAMPLE}_R1.fastq.gz \
    ${FASTQ_DIR}/${SAMPLE}_R2.fastq.gz \
    ${OUTPUT_DIR}/${SAMPLE}_R1.trim.paired.fastq.gz \
    ${OUTPUT_DIR}/${SAMPLE}_R1.trim.unpaired.fastq.gz \
    ${OUTPUT_DIR}/${SAMPLE}_R2.trim.paired.fastq.gz \
    ${OUTPUT_DIR}/${SAMPLE}_R2.trim.unpaired.fastq.gz \
    ILLUMINACLIP:${ADAPTER}:2:30:10 \
    LEADING:3 \
    TRAILING:3 \
    SLIDINGWINDOW:4:15 \
    MINLEN:100

echo "Trimmomatic completed for sample: ${SAMPLE}"
