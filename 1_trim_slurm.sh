#!/bin/bash -l
#SBATCH --job-name=trim                   # Job name
#SBATCH --partition=work                   # Partition to use
#SBATCH --nodes=1                         # Number of nodes
#SBATCH --ntasks=1                        # Number of tasks
#SBATCH --cpus-per-task=4                 # Number of CPUs per task
#SBATCH --mem-per-cpu=24GB                # Memory per CPU core
#SBATCH --time=36:00:00                   # Time limit (hh:mm:ss)
#SBATCH --export=NONE                     # Export environment variables

echo "Job started at $(date)"

# Load Conda environment
conda activate /home/rli/.conda/envs/PROJ_001.RL

# Set up directories
SCRATCH=$MYSCRATCH/PROJ_001.RL/$SLURM_JOBID
INPUT=/group/sbs010/rli/PROJ_001.RL/0_merged_data_3
OUTPUT_DIR=/group/sbs010/rli/PROJ_001.RL/1_trimming_2

# Create SCRATCH and OUTPUT_DIR directories
mkdir -p $SCRATCH

echo "SCRATCH directory is $SCRATCH"

# Set up log file
LOG_FILE=$SCRATCH/PROJ_001.RL-$SLURM_JOBID.log

# Copy input files to SCRATCH
echo "Copying input files to SCRATCH directory..."
cp $INPUT/*.merged.fastq.gz $SCRATCH

# Change to SCRATCH directory
cd $SCRATCH

# Run Trim Galore
for i in *_R1.merged.fastq.gz; do
    SAMPLE_NAME="${i%%_R1.merged.fastq.gz}"

    echo "Processing sample: $SAMPLE_NAME"

    READ1="${SAMPLE_NAME}_R1.merged.fastq.gz"
    READ2="${SAMPLE_NAME}_R2.merged.fastq.gz"

    # Run Trim Galore
    trim_galore --paired ${READ1} ${READ2} \
        --output_dir $SCRATCH \

    mv $SCRATCH/${SAMPLE_NAME}_R1.merged_val_1.fq.gz $OUTPUT_DIR/
    mv $SCRATCH/${SAMPLE_NAME}_R2.merged_val_2.fq.gz $OUTPUT_DIR/
done



# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

# Print job finish time
echo "PROJ_001.RL job finished at $(date)"