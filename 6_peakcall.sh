#!/bin/bash -l
#SBATCH --job-name=peak_calling   # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=4          # Number of CPU cores per task
#SBATCH --mem=24GB                  # Memory allocation
#SBATCH --time=08:00:00             # Time limit
#SBATCH --output=peakcall_%j.log     # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_BAM=/group/sbs010/rli/PROJ_002.RL/4_deduplicate_4
INPUT_BAI=/group/sbs010/rli/PROJ_002.RL/5_bam_index_3
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/6_peakcall_ATAC
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_BAM
ls $INPUT_BAI

echo "SCRATCH directory is $SCRATCH"

# Copy files to scratch
cp $INPUT_BAM/*.clean.bam $SCRATCH/
cp $INPUT_BAI/*.bam.bai $SCRATCH/

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# Process each BAM file with MACS2 to generate peak files. 
# Both peak files should have similar overall visualisations.
# The output file can be visualised in IGV web browser to check if peaks occur in expected genes
# Check housekeeping genes GAPDH and ACTB. mTOR is another worth checking.
# For fibros, check ACTA1 (a-SMA), COL1A1 (collagen 1), FN1 (fibronectin) and VIM (vimentin).
for bamfile in $SCRATCH/*.clean.bam; do
    # Extract the base name (excluding path and extension)
    base=$(basename $bamfile .clean.bam)
    
    # Define the output file paths
    macs2_output="$SCRATCH/${base}_peaks.xls"
    macs2_bed="$SCRATCH/${base}_peaks.bed"

    # Run MACS2 to call narrowPeak. narrowPeak focuses on high amplitude but shorter regions often TF sites.
    # Ensure --nomodel is given to avoid analysing CHIP-seq like features
     macs2 callpeak -t $bamfile -f BAM -g hs -n $base --outdir $SCRATCH --nomodel
         mv $SCRATCH/${base}_peaks.narrowPeak $OUTPUT_DIR/
    
    # Run MACS2 to call broadPeak. broadPeak focuses on longer regions often generated around histone modifications.
    # Ensure --nomodel is given to avoid analysing CHIP-seq like features
    # The broadPeak file can be used to analyse gapped regions (no signal), acting as a gappedPeak file.
    macs2 callpeak -t $bamfile -f BAM -g hs -n $base --outdir $SCRATCH --broad --nomodel
        mv $SCRATCH/${base}_peaks.xls $OUTPUT_DIR/
        mv $SCRATCH/${base}_peaks.broadPeak $OUTPUT_DIR/

        echo "Sample $base done at $(date)"

done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
