#!/bin/bash
#SBATCH --job-name=bcftools
#SBATCH --partition=std
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=50GB
#SBATCH --time=24:00:00
#SBATCH -o bcftools.out
#SBATCH -e bcftools.err

###############################################################################
# Variant Calling - BCFtools
#
# Joint variant calling from multiple BAM files.
# BCFtools mpileup -> BCFtools call -> VCF indexing
###############################################################################

# Stop at the first error (also if bcftools mpileup fails inside the pipe)
set -eo pipefail

##################### LOAD MODULES ####################

module load bcftools/1.23.1/gcc

##################### USER SETTINGS ####################

genome="/path/to/genome_reference.fa"      # must be indexed beforehand (.fai)
mapping_path="/path/to/mapping_results"    # folder containing the BAM files
output_path="/path/to/vcf_results"         # output folder
prefix="project"                           # prefix for the output file name
bam_pattern="*.sorted.duplicates.bam"      # pattern matching your BAM files

# Number of threads (taken from the SLURM allocation)
threads=${SLURM_CPUS_PER_TASK}

mkdir -p "$output_path"

##################### INPUT MAPPING FILES ####################

# Retrieve all sorted and duplicate-marked BAM files (each BAM must be indexed)
bam_files=("$mapping_path"/$bam_pattern)

##################### VCF WITH BCFTOOLS ######################

# mpileup: Generate genotype likelihoods from BAM files
# -f: Reference genome
# -q / -Q: Minimum mapping quality / base quality
# -a FORMAT/AD,FORMAT/DP: Add allelic depth and read depth
# -Ou: Output uncompressed BCF for piping
#
# call: Call variants from genotype likelihoods
# -m: Multiallelic variant calling model
# -v: Output variant sites only
# -Oz: Output compressed VCF

bcftools mpileup \
    --threads "${threads}" \
    -f "${genome}" \
    -a FORMAT/DP \
    -Ou \
    "${bam_files[@]}" | \
bcftools call \
    --threads "${threads}" \
    -mv \
    -Oz \
    -o "$output_path/${prefix}.variants.raw.vcf.gz"

##################### INDEX VCF ######################

# Index the compressed VCF file
bcftools index "$output_path/${prefix}.variants.raw.vcf.gz"

##################### COMPLETION ####################

echo "Variant calling completed successfully!"
echo "Output: $output_path/${prefix}.variants.raw.vcf.gz"
