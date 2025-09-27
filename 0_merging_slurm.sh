#!/bin/bash -l
#SBATCH --job-name=Merge                  # Job name
#SBATCH --partition=work                   # Partition to use
#SBATCH --nodes=2                         # Number of nodes
#SBATCH --ntasks=2                        # Number of tasks
#SBATCH --mem-per-cpu=16GB                 # Memory per CPU core
#SBATCH --time=04:00:00                   # Time limit
#SBATCH --export=NONE                     # Export environment variables

echo "Job started at $(date)"

# Load Conda environment
conda activate /home/rli/.conda/envs/PROJ_001.RL

# Set up directories
SCRATCH=$MYSCRATCH/PROJ_001.RL/$SLURM_JOBID
INPUT=/group/sbs010/rli/rawdata/rawdata_16092024_RNA
OUTPUT_DIR=/group/sbs010/rli/PROJ_001.RL/0_merged_data_2

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

# Set up log file
LOG_FILE=$SCRATCH/PROJ_001.RL-$SLURM_JOBID.log

# Copy input files to SCRATCH
echo "Copying input files to SCRATCH directory..."
cp $INPUT/*.fastq.gz $SCRATCH

# Change to SCRATCH directory
cd $SCRATCH

# Run Cat
for i in *_L001_R1.fastq.gz;do
    SAMPLE_NAME=${i%%_22KM*}
    echo $SAMPLE_NAME

    cat ${SAMPLE_NAME}*_R1.fastq.gz > ${SCRATCH}/${SAMPLE_NAME}_R1.merged.fastq.gz
    cat ${SAMPLE_NAME}*_R2.fastq.gz > ${SCRATCH}/${SAMPLE_NAME}_R2.merged.fastq.gz

    mv $SCRATCH/${SAMPLE_NAME}_R1.merged.fastq.gz $OUTPUT_DIR/
    mv $SCRATCH/${SAMPLE_NAME}_R2.merged.fastq.gz $OUTPUT_DIR/    
done

echo "Moving merged files to OUTPUT directory..."


# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

# Print job finish time
echo "PROJ_001.RL job finished at $(date)"