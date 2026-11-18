#!/bin/bash
#SBATCH --job-name=bcftools
#SBATCH --partition=std
#SBATCH --nodes=1
#SBATCH --cpus-per-task=30
#SBATCH --mem=100GB
#SBATCH --time=08:00:00
#SBATCH -o bcftools.out
#SBATCH -e bcftools.err

###############################################################################
# Variant Calling - BCFtools
# Joint variant calling from BAM files.
# BCFtools mpileup -> BCFtools call -> VCF indexing
###############################################################################

# Stop at the first error (also if bcftools mpileup fails inside the pipe)
set -eo pipefail

##################### LOAD MODULES ####################

module load samtools/1.23.1/gcc
module load bcftools/1.23.1/gcc

##################### USER SETTINGS ####################

genome="/Path/to/genome_reference.fa"
mapping_path="/Path/to/mapping_results/"
output_path="/Path/to/vcf_results/"

##################### INPUT MAPPING FILES ####################

# Retrieve all sorted and duplicate-marked BAM files
bam_files=("$mapping_path"/*.sorted.duplicates.bam)

##################### VCF WITH BCFTOOLS ######################

# mpileup: Generate genotype likelihoods from BAM files
# -f: Reference genome
# -a FORMAT/DP: Add read depth information
# -Ou: Output uncompressed BCF for piping
#
# call: Call variants from genotype likelihoods
# -m: Multiallelic variant calling model
# -v: Output variant sites only
# -Oz: Output compressed VCF

bcftools mpileup \
    -f "${genome}" \
    -a FORMAT/DP \
    -Ou \
    "${bam_files[@]}" | \
bcftools call \
    -mv \
    -Oz \
    -o "$output_path/VCF.variants.raw.vcf.gz"

##################### INDEX VCF ######################

# Index the compressed VCF file
bcftools index "$output_path/VCF.variants.raw.vcf.gz"

##################### COMPLETION ####################

echo "Variant calling completed successfully!"
echo "Output: $output_path/VCF.variants.raw.vcf.gz"
