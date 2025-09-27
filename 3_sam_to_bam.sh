#!/bin/bash -l
#SBATCH --job-name=sam_to_bam    # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=4       # Number of CPU cores per task
#SBATCH --mem=16GB                  # Memory allocation
#SBATCH --time=08:00:00             # Time limit
#SBATCH --output=sam_to_bam_%j.log     # Standard output log file

echo "Job started at: $(date)"
# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/PROJ_002.RL/2_alignment_2
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/3_convert_to_bam_2
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

echo "Files to be copied from input to SCRATCH:"
ls $INPUT_DIR

# copy files to SCRATCH
cp $INPUT_DIR/*.sam $SCRATCH

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# This command turns SAM files into BAM files and renames them.
# SAM files are too large to deal with (15-25 gb) so .bam will make it easier to handle.
for samfile in $SCRATCH/*.sam; do
    # Extract the base name (excluding path and extension)
    # This will also rename the .bam file to be shorter and easier to read
    base=$(basename "$samfile" | sed -r 's/_22KM.*//; s/_L002.sam/.sam/')

    # Define the input and output file paths
    input_sam="$samfile"
    output_bam="$SCRATCH/${base}.bam"
    output_sorted_bam="$SCRATCH/${base}.sorted.bam"
    
    echo "Processing $input_sam at $(date):"

    # Perform SAM to BAM conversion and sorting. This is a two step process so two files are output.
    # .sorted.bam is the one we want for the next step.
    samtools view -q 15 -b $input_sam -o $output_bam
    samtools sort -@ 15 $output_bam -o $output_sorted_bam

    echo "Moving $base to output at $(date):"
    
    mv $SCRATCH/${base}.bam $OUTPUT_DIR/
    mv $SCRATCH/${base}.sorted.bam $OUTPUT_DIR/
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
