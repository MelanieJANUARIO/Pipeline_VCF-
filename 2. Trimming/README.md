# Step 2: Read Trimming (Trimmomatic)

## Overview

This step removes sequencing adapters and low-quality bases from raw paired-end WGS FASTQ files using **Trimmomatic**. The script is designed for HPC clusters using the **SLURM** workload manager and processes all samples in parallel with a **job array** (one array task = one sample).

## Requirements

| Tool | Version |
|------|---------|
| Trimmomatic | 0.39 |
| Java | required by Trimmomatic |

The script loads Trimmomatic with `module load trimmomatic/0.39/java`. The module name depends on your cluster: adapt it if needed.

## Input

- Raw paired-end FASTQ files, named `<sample>_R1.fastq.gz` and `<sample>_R2.fastq.gz`
- An adapter file in FASTA format matching your sequencing kit (e.g. `Adapter.fasta`)
- A text file `samples.txt` listing the sample names, one per line, without the `_R1` / `_R2` suffix:

```
sample1
sample2
sample3
```

## Files in this directory

| File | Description |
|------|-------------|
| `trimmomatic.sh` | SLURM job array script running Trimmomatic (PE mode) |
| `README.md` | This file |

## Configuration

Edit the following variables at the top of `trimmomatic.sh`:

| Variable | Description |
|----------|-------------|
| `ADAPTER` | Path to the adapter FASTA file |
| `FASTQ_DIR` | Directory containing the raw FASTQ files |
| `OUTPUT_DIR` | Output directory (created if it does not exist) |
| `SAMPLE_LIST` | Text file listing the sample names (default: `samples.txt`) |

You may also need to adapt the `#SBATCH` header (partition, memory, time) and the module name to your cluster.

If your files are not named `_R1.fastq.gz` / `_R2.fastq.gz`, edit the corresponding file names in the `trimmomatic` command.

## Trimmomatic parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `-phred33` | | Quality score encoding |
| `ILLUMINACLIP` | `<adapter>:2:30:10` | Adapter removal (2 seed mismatches, palindrome clip threshold 30, simple clip threshold 10) |
| `LEADING` | 3 | Remove leading bases with quality below 3 |
| `TRAILING` | 3 | Remove trailing bases with quality below 3 |
| `SLIDINGWINDOW` | 4:15 | Cut when the average quality in a 4-base window falls below 15 |
| `MINLEN` | 100 | Discard reads shorter than 100 bases (suited to 150 bp reads; adjust for shorter reads) |

## SLURM resources

Default resources requested per sample:

- 8 CPUs (used as Trimmomatic threads)
- 16 GB memory
- 8 hours

Adjust according to your file sizes and cluster policy.

## Output

For each sample, four files are written to `OUTPUT_DIR`:

| File | Description |
|------|-------------|
| `<sample>_R1.trim.paired.fastq.gz` | R1 reads whose mate survived trimming |
| `<sample>_R2.trim.paired.fastq.gz` | R2 reads whose mate survived trimming |
| `<sample>_R1.trim.unpaired.fastq.gz` | R1 reads whose mate was discarded |
| `<sample>_R2.trim.unpaired.fastq.gz` | R2 reads whose mate was discarded |

Only the **paired** files are used in the next step (read mapping). The unpaired files can be ignored.

## Next step

Proceed to the mapping step (`03_mapping`) using the `*_R1.trim.paired.fastq.gz` and `*_R2.trim.paired.fastq.gz` files.
