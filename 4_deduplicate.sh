#!/bin/bash -l
#SBATCH --job-name=deDuplicate    # Job name
#SBATCH --partition=work             # Partition to use
#SBATCH --nodes=1                   # Number of nodes
#SBATCH --ntasks=1                  # Number of tasks
#SBATCH --cpus-per-task=8          # Number of CPU cores per task
#SBATCH --mem=24GB                  # Memory allocation
#SBATCH --time=16:00:00             # Time limit
#SBATCH --output=deDuplicate_%j.log     # Standard output log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/PROJ_002.RL/3_convert_to_bam_3
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/4_deduplicate_3
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

# copy files to SCRATCH
cp $INPUT_DIR/*.sorted.bam $SCRATCH

# Verify files are copied
echo "Listing files in SCRATCH directory..."
ls $SCRATCH

# Define read group information
READ_GROUP_ID="rg1"
READ_GROUP_SAMPLE="sample"
READ_GROUP_LIBRARY="library"
READ_GROUP_PLATFORM="illumina"

# De-duplicate the ATAC data. NGS and PCR bias can result in amplification of the same read.
# De-duplication reduces bias and file size making the data more accurate and easier to handle.
for bamfile in $SCRATCH/*.sorted.bam; do
    # Extract the base name (excluding path and extension)
    base=$(basename $bamfile .sorted.bam)
    
    # Define the input and output file paths
    input_bam="$bamfile"
    temp_bam="$SCRATCH/${base}.rg_added.bam"
    output_bam="$SCRATCH/${base}.clean.bam"
    metrics_file="$SCRATCH/${base}_metrics.txt"
    
    # Add or replace read groups using Picard
    picard AddOrReplaceReadGroups \
        I=$input_bam \
        O=$temp_bam \
        RGID=$READ_GROUP_ID \
        RGLB=$READ_GROUP_LIBRARY \
        RGPL=$READ_GROUP_PLATFORM \
        RGPU=$READ_GROUP_ID \
        RGSM=$READ_GROUP_SAMPLE \
        VALIDATION_STRINGENCY=LENIENT

    echo "Files being duplicated"
    ls $SCRATCH

    # Run Picard MarkDuplicates to reduce duplicate reads.
    picard MarkDuplicates INPUT=$temp_bam OUTPUT=$output_bam METRICS_FILE=$metrics_file REMOVE_DUPLICATES=true VALIDATION_STRINGENCY=LENIENT
    
    # Move the output files to the permanent output directory
    mv $output_bam $OUTPUT_DIR/
    mv $metrics_file $OUTPUT_DIR/

    echo "De-duplicated $$base"
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
