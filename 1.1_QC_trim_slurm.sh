#!/bin/bash -l
#SBATCH --job-name=post_QC          # Job name
#SBATCH --partition=work                   # Partition to use
#SBATCH --nodes=1                         # Number of nodes
#SBATCH --ntasks=2                        # Number of tasks
#SBATCH --mem-per-cpu=16GB                 # Memory per CPU core
#SBATCH --time=08:00:00                   # Time limit
#SBATCH --export=NONE                     # Export environment variables

echo "Job started at $(date)"

# Load Conda environment
conda activate /home/rli/.conda/envs/PROJ_001.RL

# Set up directories
SCRATCH=$MYSCRATCH/PROJ_001.RL/$SLURM_JOBID
INPUT=/group/sbs010/rli/PROJ_001.RL/1_trimming_2
OUTPUT_DIR=/group/sbs010/rli/PROJ_001.RL/1.2_trimming_qc

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

# Set up log file
LOG_FILE=$SCRATCH/PROJ_001.RL-$SLURM_JOBID.log

# Copy input files to SCRATCH
echo "Copying input files to SCRATCH directory..."
cp $INPUT/*_R1.merged_val_1.fq.gz $SCRATCH
cp $INPUT/*_R2.merged_val_2.fq.gz $SCRATCH

# Change to SCRATCH directory
cd $SCRATCH

for i in *.merged_val_1.fq.gz;do
    SAMPLE_NAME="${i%%_R1.merged_val_1.fq.gz}"
    echo "Sample name:"
    echo $SAMPLE_NAME

    # Run FASTQC in parallel
    echo "Running FASTQC on $SAMPLE_NAME"
    fastqc ${SAMPLE_NAME}_R1.merged_val_1.fq.gz -o $SCRATCH
    fastqc ${SAMPLE_NAME}_R2.merged_val_2.fq.gz -o $SCRATCH

    echo "samples processed:"
    ls $SCRATCH

    echo "Moving FASTQC output to OUTPUT directory..."
    mv $SCRATCH/${SAMPLE_NAME}_R1.merged_val_1_fastqc.html $OUTPUT_DIR/
    mv $SCRATCH/${SAMPLE_NAME}_R2.merged_val_2_fastqc.html $OUTPUT_DIR/    
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

# Print job finish time
echo "PROJ_001.RL job finished at $(date)"