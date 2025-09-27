#!/bin/bash -l
#SBATCH --job-name=gene_cov   # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=4          # Number of CPU cores per task
#SBATCH --mem=24GB                  # Memory allocation
#SBATCH --time=03:00:00             # Time limit
#SBATCH --output=gene_cov_%j.log     # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/PROJ_002.RL/7_bam_to_bed_2
INPUT_GEN=/group/sbs010/rli/referencegenome/GRCh38.chromosome_sizes.txt
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/8_genecov_2
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

echo "SCRATCH directory is $SCRATCH"

# Copy files to scratch
cp $INPUT_DIR/*.sort.bed $SCRATCH/
cp $INPUT_GEN $SCRATCH/

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# Quantify peak size. You will need a chromosome sizes file generated from a genome file.
# This can be found in script 8.1
for bedfile in $SCRATCH/*.sort.bed; do
    # Extract the base name (excluding path and extension)
    base=$(basename $bedfile .sort.bed)
    
    # Run bedtools to calculate genome-wide coverage in bedGraph format
    bedtools genomecov -i $bedfile -bg -g $SCRATCH/GRCh38.chromosome_sizes.txt > $SCRATCH/${base}.bg

    # Move the bedGraph file to the output directory
    mv $SCRATCH/${base}.bg $OUTPUT_DIR/
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
