#!/bin/bash
#SBATCH --job-name=index_genome
#SBATCH --partition=std
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16GB
#SBATCH --time=04:00:00
#SBATCH -o logs/index_genome_%j.out
#SBATCH -e logs/index_genome_%j.err

###############################################################################
# Reference genome indexing (run once, before the mapping step)
# Creates the indexes required by BWA, SAMtools and Picard.
###############################################################################

# Stop at the first error
set -eo pipefail

# LOAD MODULES
module load bwa/0.7.18/gcc
module load samtools/1.23.1/gcc
module load picard/2.18.29/java

# USER SETTINGS
GENOME="/path/to/genome_reference.fa"    # Reference genome (uncompressed FASTA)

echo "Indexing genome: ${GENOME}"

# BWA index
bwa index ${GENOME}

# SAMtools index
samtools faidx ${GENOME}

# Picard sequence dictionary
picard CreateSequenceDictionary R=${GENOME} O=${GENOME%.*}.dict

echo "Indexing completed for: ${GENOME}"
