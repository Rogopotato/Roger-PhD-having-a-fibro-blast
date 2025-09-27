#!/bin/bash -l
#SBATCH --job-name=bigwig  # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=4          # Number of CPU cores per task
#SBATCH --mem=24GB                  # Memory allocation
#SBATCH --time=03:00:00             # Time limit
#SBATCH --output=bigwig_%j.log     # Standard output log file

# IMPORTANT!
# This script can only use openssl 1.0 and will not run with a newer version. 
# Please run conda install -n YOUR_CONDA_ENVIRONMENT_NAME openssl=1.0 or conda install -c bioconda openssl=1.0
# You may get a bunch of warnings in yellow text but as long as it runs it will be fine.
# You may also wish to make a new environment for this so only ATAC will use the older version.

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/PROJ_002.RL/9_sorted_genecov_2
INPUT_GEN=/group/sbs010/rli/referencegenome/GRCh38.chromosome_sizes.txt
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/10_bigwig
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

echo "SCRATCH directory is $SCRATCH"

# Copy files to scratch
cp $INPUT_DIR/*.bg $SCRATCH/
cp $INPUT_GEN $SCRATCH/

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# Process each bg file with bedtools genomecov to produce a bigwig file for better visualisation.
# The output file can be visualised in IGV web browser to check if peaks occur in expected genes
# Check housekeeping genes GAPDH and ACTB. mTOR is another worth checking.
# For fibros, check ACTA1 (a-SMA), COL1A1 (collagen 1), FN1 (fibronectin) and VIM (vimentin).
for bg in $SCRATCH/*.bg; do
    # Extract the base name for output
    out=$(basename $bg .bg)

     # Convert BEDGraph to BigWig for visualisation.
    bedGraphToBigWig $bg $SCRATCH/GRCh38.chromosome_sizes.txt $SCRATCH/${out}.bw
    
    echo "files in SCRATCH:"
    ls $SCRATCH

    echo "output is $OUTPUT_DIR"

    echo "Moving $SCRATCH/${out}.bw to $OUTPUT_DIR"
    mv $SCRATCH/${out}.bw $OUTPUT_DIR
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at $(date)"