#!/bin/bash
#SBATCH --job-name=mapping
#SBATCH --partition=std
#SBATCH --nodes=1
#SBATCH --cpus-per-task=30
#SBATCH --mem=64GB
#SBATCH --time=12:00:00              # Adapt to your coverage
#SBATCH -o logs/mapping_%A_%a.out
#SBATCH -e logs/mapping_%A_%a.err

###############################################################################
# Read mapping and BAM processing - SLURM job array
# One array task = one sample.
# BWA-MEM -> samtools sort -> Picard MarkDuplicates -> index -> statistics
###############################################################################

# Stop at the first error (also if bwa fails inside the pipe)
set -eo pipefail

# LOAD MODULES
module load bwa/0.7.18/gcc
module load samtools/1.23.1/gcc
module load picard/2.18.29/java

# USER SETTINGS
GENOME="/path/to/genome_reference.fa"           # Must be indexed (bwa index, samtools faidx)
FASTQ_DIR="/path/to/trimming_results"           # Trimmed paired FASTQ files
OUTPUT_DIR="/path/to/mapping_results"
SAMPLE_LIST="samples.txt"
SORT_THREADS=4                                  # Threads for samtools sort (BWA uses the rest)

# GET SAMPLE NAME FROM ARRAY INDEX
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLE_LIST})

FASTQ_R1="${FASTQ_DIR}/${SAMPLE}_R1.trim.paired.fastq.gz"
FASTQ_R2="${FASTQ_DIR}/${SAMPLE}_R2.trim.paired.fastq.gz"

TMP_DIR="${OUTPUT_DIR}/TMP/${SAMPLE}"
mkdir -p ${OUTPUT_DIR} ${TMP_DIR}

echo "Processing sample: ${SAMPLE}"

##################### BWA MAPPING + SORTING ####################
# bwa mem: -t threads, -M marks shorter split hits as secondary (Picard compatible),
#          -R read group (needed by downstream tools such as GATK)
# The output is piped directly into samtools sort (no intermediate unsorted BAM).

bwa mem \
    -t ${SLURM_CPUS_PER_TASK} \
    -M \
    -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tLB:${SAMPLE}\tPL:ILLUMINA" \
    ${GENOME} ${FASTQ_R1} ${FASTQ_R2} \
    | samtools sort \
        -@ ${SORT_THREADS} \
        -m 2G \
        -T ${TMP_DIR}/sort \
        -o ${OUTPUT_DIR}/${SAMPLE}.sorted.bam -

##################### MARK DUPLICATES ####################
picard MarkDuplicates \
    I=${OUTPUT_DIR}/${SAMPLE}.sorted.bam \
    O=${OUTPUT_DIR}/${SAMPLE}.sorted.duplicates.bam \
    M=${OUTPUT_DIR}/${SAMPLE}.metrics_duplicates.txt \
    TMP_DIR=${TMP_DIR} \
    COMPRESSION_LEVEL=5

##################### INDEX ####################
samtools index -@ ${SLURM_CPUS_PER_TASK} ${OUTPUT_DIR}/${SAMPLE}.sorted.duplicates.bam

##################### STATISTICS ####################
samtools stats -@ ${SLURM_CPUS_PER_TASK} ${OUTPUT_DIR}/${SAMPLE}.sorted.duplicates.bam > ${OUTPUT_DIR}/${SAMPLE}.bam.stats
samtools flagstat -@ ${SLURM_CPUS_PER_TASK} ${OUTPUT_DIR}/${SAMPLE}.sorted.duplicates.bam > ${OUTPUT_DIR}/${SAMPLE}.flagstat.txt
samtools coverage -o ${OUTPUT_DIR}/${SAMPLE}_metrics_coverage.txt ${OUTPUT_DIR}/${SAMPLE}.sorted.duplicates.bam

##################### CLEANING ####################
# Remove intermediate files (the final BAM is *.sorted.duplicates.bam)
rm ${OUTPUT_DIR}/${SAMPLE}.sorted.bam
rm -r ${TMP_DIR}

echo "Mapping completed for sample: ${SAMPLE}"
