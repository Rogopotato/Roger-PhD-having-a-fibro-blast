#!/bin/bash -l
#SBATCH --job-name=gene_size   # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=4         # Number of CPU cores per task
#SBATCH --mem=24GB                  # Memory allocation
#SBATCH --time=03:00:00             # Time limit
#SBATCH --output=gene_size_%j.log     # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/referencegenome/gencode_files
OUTPUT_DIR=/group/sbs010/rli/referencegenome
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

echo "SCRATCH directory is $SCRATCH"

# Copy FASTA to scratch
cp $INPUT_DIR/GRCh38.primary_assembly.genome.fa $SCRATCH/

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# Index the genome FASTA file using samtools
samtools faidx $SCRATCH/GRCh38.primary_assembly.genome.fa

# Extract chromosome sizes from the index file
cut -f 1,2 -d ' ' $SCRATCH/GRCh38.primary_assembly.genome.fa.fai > GRCh38.chromosome_sizes.txt

# Move the chromosome sizes file to the output directory
mv GRCh38.chromosome_sizes.txt $OUTPUT_DIR/

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
