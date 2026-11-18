# Step 1: Quality Control (FastQC + MultiQC)

## Overview

This step assesses the quality of raw paired-end WGS FASTQ files with **FastQC**, then aggregates all individual reports into a single interactive HTML report with **MultiQC**. The scripts are designed for HPC clusters using the **SLURM** workload manager.

- `fastqc.sh` runs FastQC as a **job array** (one array task = one FASTQ file).
- `multiqc.sh` runs once, after FastQC, to summarize all samples in one report.

## Requirements

| Tool | Version |
|------|---------|
| FastQC | fastqc |
| MultiQC | 1.31 |

Modules are loaded with `module load fastqc` and `module load multiqc/1.31/gcc-py313`. Module names depend on your cluster: adapt them if needed.

## Input

- FASTQ files (`*.fastq.gz`) in a single directory. R1 and R2 files are analysed separately.

## Files in this directory

| File | Description |
|------|-------------|
| `fastqc.sh` | SLURM job array script running FastQC on each FASTQ file |
| `multiqc.sh` | SLURM script aggregating FastQC reports with MultiQC |
| `README.md` | This file |

## Configuration

Edit the variables at the top of each script.

**`fastqc.sh`**

| Variable | Description |
|----------|-------------|
| `FASTQ_DIR` | Directory containing the FASTQ files |
| `OUTPUT_DIR` | Output directory for FastQC reports |
| `FASTQ_PATTERN` | File name pattern (default: `*.fastq.gz`) |

**`multiqc.sh`**

| Variable | Description |
|----------|-------------|
| `FASTQC_DIR` | Directory containing the FastQC outputs (same as `OUTPUT_DIR` above) |
| `OUTPUT_DIR` | Output directory for the MultiQC report |
| `REPORT_NAME` | Report name (default: `multiqc_report`) |

You may also need to adapt the `#SBATCH` header (partition, memory, time) to your cluster.

## Usage

1. Create the log directory (required before submission):

```bash
mkdir -p logs
```

2. Submit FastQC (one task per FASTQ file, at most 20 running simultaneously):

```bash
sbatch --array=1-$(ls /path/to/raw_data/*.fastq.gz | wc -l)%20 fastqc.sh
```

3. When all FastQC jobs are finished, submit MultiQC:

```bash
sbatch multiqc.sh
```

**Alternative: chain both jobs automatically**

```bash
N=$(ls /path/to/raw_data/*.fastq.gz | wc -l)
JOBID=$(sbatch --parsable --array=1-${N}%20 fastqc.sh)
sbatch --dependency=afterok:${JOBID} multiqc.sh
```

MultiQC then starts only if all FastQC tasks completed successfully.

Logs are written to `logs/`.

## Output

**FastQC** (one set per FASTQ file, in `OUTPUT_DIR`):

| File | Description |
|------|-------------|
| `<file>_fastqc.html` | Interactive quality report |
| `<file>_fastqc.zip` | Raw data used by MultiQC |

**MultiQC** (in its `OUTPUT_DIR`):

| File | Description |
|------|-------------|
| `multiqc_report.html` | Overview of all samples in one report |
| `multiqc_report_data/` | Summary tables used to build the report |

Download the `.html` report to your computer and open it in a web browser.

## Interpreting the results

Main modules to check in the MultiQC report:

- **Per base sequence quality**: quality should stay high (Phred > 28) along the read.
- **Adapter content**: a high adapter percentage means trimming is needed.
- **Per sequence GC content**: should match the expected GC distribution of the genome.
- **Sequence duplication levels** and **overrepresented sequences**: can indicate library or contamination issues.
- **Number of reads per sample**: look for samples with unexpectedly low or high counts.

Some modules (e.g. *Per base sequence content*) often show warnings on WGS data and do not necessarily indicate a problem.

## Quality control after trimming

The same scripts can be reused after the trimming step to check its effect. Set `FASTQ_DIR` to the trimming output directory, `FASTQ_PATTERN` to `*.trim.paired.fastq.gz`, and use separate output directories (e.g. `fastqc_trimmed`, `multiqc_trimmed`) to avoid mixing raw and trimmed reports.

## Next step

Proceed to the trimming step (`02_trimming`).
