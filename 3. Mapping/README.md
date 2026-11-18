# Step 3: Read Mapping and BAM Processing (BWA, Picard, SAMtools)

## Overview

This step aligns the trimmed paired-end reads to a reference genome with **BWA-MEM**, sorts the alignments with **SAMtools**, marks duplicate reads with **Picard MarkDuplicates**, indexes the final BAM file and computes mapping statistics. The script is designed for HPC clusters using the **SLURM** workload manager and processes all samples in parallel with a **job array** (one array task = one sample).

Processing order for each sample:

1. BWA-MEM alignment, piped directly into `samtools sort` (no intermediate unsorted BAM)
2. Duplicate marking with Picard MarkDuplicates
3. BAM indexing
4. Statistics (`samtools stats`, `flagstat`, `coverage`)
5. Removal of intermediate files

## Requirements

| Tool | Version |
|------|---------|
| BWA | 0.7.18 |
| SAMtools | 1.23.1 |
| Picard | 2.18.29 |

Modules are loaded with `module load bwa/0.7.18/gcc`, `module load samtools/1.23.1/gcc` and `module load picard/2.18.29/java`. Module names depend on your cluster: adapt them if needed.

## Input

- Trimmed paired FASTQ files from step 2, named `<sample>_R1.trim.paired.fastq.gz` and `<sample>_R2.trim.paired.fastq.gz`
- A reference genome in FASTA format, uncompressed (not `.fa.gz`), **indexed before running the mapping** (see "Reference genome indexing" below)
- A text file `samples.txt` listing the sample names, one per line, without the `_R1` / `_R2` suffix:

```
sample1
sample2
sample3
```

## Files in this directory

| File | Description |
|------|-------------|
| `index_genome.sh` | SLURM script indexing the reference genome (to run once, before mapping) |
| `mapping.sh` | SLURM job array script: BWA-MEM, sort, MarkDuplicates, index, statistics |
| `README.md` | This file |

## Reference genome indexing

The reference genome must be indexed once, before the mapping. Three indexes are required, all written **next to the FASTA file**:

| Index | Tool | Used by |
|-------|------|---------|
| `.amb .ann .bwt .pac .sa` | `bwa index` | BWA (mapping) |
| `.fai` | `samtools faidx` | SAMtools, BCFtools (next steps) |
| `.dict` | `picard CreateSequenceDictionary` | Picard |

### Option A: with the SLURM script (recommended)

Edit the `GENOME` variable in `index_genome.sh`, then submit it:

```bash
sbatch index_genome.sh
```

### Option B: manually

On a login node for a small genome, or in an interactive session (`srun --pty bash`) for a large one:

```bash
module load bwa/0.7.18/gcc samtools/1.23.1/gcc picard/2.18.29/java

GENOME="/path/to/genome_reference.fa"

bwa index ${GENOME}
samtools faidx ${GENOME}
picard CreateSequenceDictionary R=${GENOME} O=${GENOME%.*}.dict
```

### Checking the indexes

The following files must exist next to the FASTA:

```bash
ls /path/to/genome_reference.fa*  /path/to/genome_reference.dict
```

Expected: `.fa`, `.fa.amb`, `.fa.ann`, `.fa.bwt`, `.fa.pac`, `.fa.sa`, `.fa.fai` and `.dict`.

## Configuration

Edit the following variables at the top of `mapping.sh`:

| Variable | Description |
|----------|-------------|
| `GENOME` | Path to the indexed reference genome (FASTA) |
| `FASTQ_DIR` | Directory containing the trimmed paired FASTQ files (output of step 2) |
| `OUTPUT_DIR` | Output directory (created if it does not exist) |
| `SAMPLE_LIST` | Text file listing the sample names (default: `samples.txt`) |
| `SORT_THREADS` | Threads used by `samtools sort` (default: 4, BWA uses all CPUs of the job) |

You may also need to adapt the `#SBATCH` header (partition, CPUs, memory, time) and the module names to your cluster.

## Parameters

| Tool | Option | Description |
|------|--------|-------------|
| BWA-MEM | `-t` | Number of threads (`SLURM_CPUS_PER_TASK`) |
| BWA-MEM | `-M` | Mark shorter split hits as secondary (required for Picard compatibility) |
| BWA-MEM | `-R` | Read group: `ID`, `SM` (sample), `LB` (library), `PL:ILLUMINA` (platform) |
| samtools sort | `-@ 4 -m 2G` | 4 threads, 2 GB memory per thread |
| Picard MarkDuplicates | `COMPRESSION_LEVEL=5` | Compression level of the output BAM |

Duplicates are **marked but not removed**.

## SLURM resources

Default resources requested per sample:

- 30 CPUs
- 64 GB memory
- 12 hours

Adjust the values according to your genome size, coverage and cluster policy.

## Output

For each sample, the following files are written to `OUTPUT_DIR`:

| File | Description |
|------|-------------|
| `<sample>.sorted.duplicates.bam` | Final sorted BAM with duplicates marked |
| `<sample>.sorted.duplicates.bam.bai` | BAM index |
| `<sample>.metrics_duplicates.txt` | Picard duplication metrics |
| `<sample>.bam.stats` | `samtools stats` output |
| `<sample>.flagstat.txt` | `samtools flagstat` output (mapping rate) |
| `<sample>_metrics_coverage.txt` | `samtools coverage` output (coverage per chromosome) |

The intermediate sorted BAM (`<sample>.sorted.bam`) and the `TMP/` directory are deleted at the end of each job. Only the `*.sorted.duplicates.bam` files are used in the next step (variant calling).

## Checking the results

- Check that each job ends with `Mapping completed for sample: <sample>` in the `.out` file, and that the `.err` file contains no error.
- In `<sample>.flagstat.txt`, the percentage of mapped reads is expected to be high.
- In `<sample>.metrics_duplicates.txt`, check the duplication rate (`PERCENT_DUPLICATION`).
- In `<sample>_metrics_coverage.txt`, check the mean depth per chromosome.

All `samtools stats`, `flagstat` and Picard metrics files can be summarized in a single report with MultiQC:

```bash
module load multiqc/1.31/gcc-py313
multiqc /path/to/mapping_results -o /path/to/multiqc_mapping -n multiqc_mapping
```

## Next step

Proceed to the variant calling step (`04_variant_calling`) using the `*.sorted.duplicates.bam` files.
