#!/bin/bash -l
#SBATCH --job-name=bam_to_bed   # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=4          # Number of CPU cores per task
#SBATCH --mem=24GB                  # Memory allocation
#SBATCH --time=16:00:00             # Time limit
#SBATCH --output=bam_to_bed_%j.log     # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/PROJ_002.RL/4_deduplicate_2
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/7_bam_to_bed_2
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

echo "SCRATCH directory is $SCRATCH"

# Copy files to scratch
cp $INPUT_DIR/*.clean.bam $SCRATCH/

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# Turn .bam into .bed to allow for peak size quantification.
for bamfile in $SCRATCH/*.clean.bam; do
    # Extract the base name (excluding path and extension)
    base=$(basename $bamfile .clean.bam)
    
    # Run bedtools to convert BAM to BED
    bedtools bamtobed -i $bamfile > $SCRATCH/${base}.bed

    # Filter and sort .bed file
     grep -e 'chr' $SCRATCH/${base}.bed | sort -k1,1 -k2,2n > $SCRATCH/${base}.sort.bed

    # Move the BED file to the output directory
    mv $SCRATCH/${base}.sort.bed $OUTPUT_DIR/
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
