#!/bin/bash
#SBATCH --job-name=bcftools
#SBATCH --partition=std
#SBATCH --cpus-per-task=30
#SBATCH --mem=100GB
#SBATCH --nodes=1
#SBATCH --time=08:00:00
#SBATCH -o bcftools.out

##################### Modules ####################

module load samtools/1.23.1/gcc
module load bcftools/1.23.1/gcc

##################### Variables ####################

genome="/Path/to/genome_reference.fa"
mapping_path="/Path/to/mapping_results/"
output_path="/Path/to/vcf_results/"

##################### Input mapping files ####################

bam_files=("$mapping_path"/*.sorted.duplicates.bam.gz)

##################### VCF with BCFtools ######################

bcftools mpileup \
    -f "${genome}" \
    -a FORMAT/DP \
    -Ou \
    "${bam_files[@]}" | \
bcftools call \
    -mv \
    -Oz \
    -o "$output_path/VCF.variants.raw.vcf.gz"

##################### Index VCF ######################

bcftools index "$output_path/VCF.variants.raw.vcf.gz"
