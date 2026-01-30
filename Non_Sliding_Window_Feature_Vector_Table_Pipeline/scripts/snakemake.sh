#!/bin/bash
#SBATCH --job-name=feature_vector_pipeline
#SBATCH --partition=pshort_el8
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --time=1:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=5

module load snakemake/6.6.1-foss-2021a
module load Anaconda3/2022.05

# Run Snakemake with necessary parameters
snakemake -j 5 --use-conda --conda-frontend conda