# Pipeline_VCF

**Author:** Melanie Januario

**Whole Genome Sequencing (WGS) Variant Calling Pipeline: from raw FASTQ to unfiltered VCF**

## Overview

This repository contains a step-by-step bioinformatics pipeline for variant calling from Whole Genome Sequencing (WGS) data. It covers the workflow from raw FASTQ quality control to the generation of **unfiltered VCF files**.

The pipeline is **built progressively, one step at a time**. Each step has its own directory containing the SLURM scripts and a dedicated `README.md` with detailed instructions. Steps are added to the repository as they are completed (see the status column below).

All scripts are designed for execution on High-Performance Computing (HPC) clusters using the **SLURM** workload manager, and process samples in parallel with job arrays.

> **Scope:** this pipeline stops at the generation of raw, **unfiltered** VCF files. Variant filtering and annotation are not included.

## Pipeline steps

| Step | Directory | Description | Tools | Status |
|------|-----------|-------------|-------|--------|
| 1 | `01_fastqc/` | **Quality Control:** assessment of raw FASTQ quality, with a global summary report | FastQC, MultiQC | Available |
| 2 | `02_trimming/` | **Read Trimming:** adapter removal and quality-based trimming | Trimmomatic | Available |
| 3 | `03_mapping/` | **Read Mapping and BAM Processing:** alignment to the reference genome, then BAM processing | BWA, Picard, SAMtools | In progress |
| 4 | `04_variant_calling/` | **Variant Calling:** identification of variants and generation of unfiltered VCF files | BCFtools | In progress |

## Workflow

```
Raw FASTQ
   |
   v
[1] FastQC + MultiQC   -> quality reports
   |
   v
[2] Trimmomatic        -> trimmed paired FASTQ
   |
   v
[3] BWA + Picard + SAMtools -> processed BAM
   |
   v
[4] BCFtools           -> unfiltered VCF
```

## Repository structure

```
Pipeline_VCF/
├── 01_fastqc/
│   ├── fastqc.sh
│   ├── multiqc.sh
│   └── README.md
├── 02_trimming/
│   ├── trimmomatic.sh
│   └── README.md
├── 03_mapping/            
├── 04_variant_calling/    
└── README.md
```

## Dependencies

| Tool | Version | Used in step |
|------|---------|--------------|
| FastQC |Fastqc | 1 |
| MultiQC | 1.31 | 1 |
| Trimmomatic | 0.39 | 2 |
| BWA | x.x.x | 3 |
| Picard | x.x.x | 3 |
| SAMtools | x.x | 3, 4 |
| BCFtools | 1.23.1 | 4, 5, 6 |

Make sure all tools are installed (or available as modules) and properly configured in your environment before running the pipeline. Module names in the scripts (`module load ...`) are specific to our cluster and may need to be adapted.

## Usage

1. Start with step 1 and follow the steps in the order shown above, so that the analysis stays consistent and reproducible.
2. For each step, open its directory and follow the instructions in the corresponding `README.md`: variables to edit, how to submit the job, and expected outputs.
3. The output of one step is the input of the next one.

## Input data

- Raw paired-end WGS FASTQ files, named `<sample>_R1.fastq.gz` and `<sample>_R2.fastq.gz`
- A reference genome in FASTA format (details in the mapping step)

No sequencing data or reference genome is included in this repository.

## Computational environment

- **Platform:** High-Performance Computing (HPC) cluster
- **Job scheduler:** SLURM
- **Input:** raw WGS FASTQ files
- **Output:** unfiltered VCF files containing called variants
