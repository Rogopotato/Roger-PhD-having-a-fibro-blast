#!/bin/bash -l
#SBATCH --job-name=index_bam    # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=4         # Number of CPU cores per task
#SBATCH --mem=24GB                  # Memory allocation
#SBATCH --time=03:00:00             # Time limit
#SBATCH --output=index_bam_%j.log     # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/PROJ_002.RL/4_deduplicate_4
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/5_bam_index_3
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

# copy files to SCRATCH
cp $INPUT_DIR/*.clean.bam $SCRATCH

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# Index each BAM file. This creates an index for each set of ATAC data similar to a genome index.
# .bam index makes peak calling quicker. Not sure howessential it is but supposedly this is easier.
for bamfile in $SCRATCH/*.clean.bam; do
    # Extract the base name (excluding path and extension)
    base=$(basename $bamfile .clean.bam)
    
    # Define the input and output file paths
    input_bam="$bamfile"
    output_bam="$bamfile.bai"
    
    # Run samtools indexing on the .bam
    samtools index $input_bam

    echo "Indexed $bamfile"
    
    # Move the index file to the output directory
    mv $output_bam $OUTPUT_DIR/
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"