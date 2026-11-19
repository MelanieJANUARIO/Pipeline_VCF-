# BCFtools variant calling (SLURM)

SLURM script for joint variant calling from multiple BAM files.

**Pipeline:** `bcftools mpileup` → `bcftools call` → `bcftools index`

## Requirements

- [BCFtools](https://samtools.github.io/bcftools/) (the script uses `module load`, adapt to your cluster)
- Reference genome in FASTA format, **indexed beforehand**:
  ```bash
  samtools faidx genome_reference.fa
  ```
- Sorted BAM files (duplicates marked), **each with its index** (`.bai` or `.csi`):
  ```bash
  samtools index sample.sorted.duplicates.bam
  ```

## Usage

1. Edit the `USER SETTINGS` section of `bcftools_variant_calling.sh`:

   | Variable       | Description                                  |
   |----------------|----------------------------------------------|
   | `genome`       | Path to the indexed reference genome (FASTA) |
   | `mapping_path` | Folder containing the BAM files              |
   | `output_path`  | Output folder (created if missing)           |
   | `prefix`       | Prefix of the output VCF                     |
   | `bam_pattern`  | Glob pattern matching the BAM files          |

2. Adjust the `#SBATCH` header (partition, time, memory) to your cluster and dataset.
3. Submit:
   ```bash
   sbatch bcftools_variant_calling.sh
   ```

## Output

- `<prefix>.variants.raw.vcf.gz`: raw multi-sample VCF (variant sites only)
- `<prefix>.variants.raw.vcf.gz.csi`: index

## Parameters

| Option                  | Purpose                                            |
|-------------------------|----------------------------------------------------|
| `-a FORMAT/AD,FORMAT/DP`| Allelic depth and read depth per sample            |
| `-m`                    | Multiallelic calling model                         |
| `-v`                    | Output variant sites only                          |

## Notes

- **Many samples:** with several hundred BAM files, replace the BAM list on the command line with `-b bam_list.txt`.
- The VCF is **raw**: filter it afterwards (quality, depth, missing data, etc.).
