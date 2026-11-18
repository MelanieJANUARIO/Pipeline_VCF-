# Pipeline_VCF

Author : Melanie Januario

**Whole Genome Sequencing (WGS) Variant Calling Pipeline**

**Overview**

This repository contains a bioinformatics pipeline for variant calling from Whole Genome Sequencing (WGS) data, covering the entire workflow from raw FASTQ quality control to the generation of unfiltered VCF files.

All scripts are designed and optimized for execution on High-Performance Computing (HPC) clusters using the SLURM workload manager.

The pipeline is organized into separate directories, each containing the scripts required for a specific analysis step, along with a dedicated README.md file providing detailed instructions for execution.

**The pipeline consists of the following steps:**

1. **Quality Control:** Assessment of raw FASTQ sequencing data quality using FastQC.
2. **Read Trimming:** Adapter removal and quality-based trimming of FASTQ reads using Trimmomatic.
3. **Read Mapping and BAM Processing:** Alignment of sequencing reads to a reference genome using BWA, followed by BAM file processing and preprocessing with Picard and SAMtools.
4. **Variant Calling:** Identification of genetic variants and generation of unfiltered VCF files using BCFtools.
Dependencies

**The following software tools are required to run the pipeline:**

- `FastQC`
- `Trimmomatic`
- `BWA`
- `Picard`
- `SAMtools`
- `BCFtools`

Make sure all dependencies are installed and properly configured in your environment before running the pipeline.

**Usage**

Each pipeline step is provided in its own subdirectory. Detailed instructions, including script execution and configuration requirements, are available in the corresponding README.md file.

Follow the steps in the order presented above to ensure a consistent and reproducible analysis workflow.

**Computational Environment**

- Job Scheduler: `SLURM`
- Input: `Raw WGS FASTQ files`
- Output: `Unfiltered VCF files containing called variants`
