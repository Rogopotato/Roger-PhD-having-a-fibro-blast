#!/bin/bash -l
#SBATCH --job-name=sort_gene_cov   # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=4          # Number of CPU cores per task
#SBATCH --mem=24GB                  # Memory allocation
#SBATCH --time=05:00:00             # Time limit
#SBATCH --output=sort_gene_cov_%j.log     # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/PROJ_002.RL/8_genecov_2
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/9_sorted_genecov_2
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

echo "SCRATCH directory is $SCRATCH"

# Copy files to scratch
cp $INPUT_DIR/*.bg $SCRATCH/

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# Sort each quantified bg file with bedtools genomecov
# Currently outputs an additional blank .bg file. Not sure why but otherwise functionally fine.
# TO DO: fix this for loop to stop generating an extra blank .bg.
for bg in $SCRATCH/*.bg; do
    # Extract the base name (excluding path and extension)
    base=$(basename $bg .bg)

    echo "Processing sample $base"

    sort -k1,1 -k2,2n $SCRATCH/${base}.bg > $SCRATCH/${base}.sorted.bg
    mv $SCRATCH/${base}.sorted.bg $OUTPUT_DIR/
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
