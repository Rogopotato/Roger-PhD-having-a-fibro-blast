#!/bin/bash -l
#SBATCH --job-name=pre_QC          # Job name
#SBATCH --partition=work                   # Partition to use
#SBATCH --nodes=1                         # Number of nodes
#SBATCH --ntasks=2                        # Number of tasks
#SBATCh --cpus-per-task=2                   #Number of cpus
#SBATCH --mem-per-cpu=8GB                 # Memory per CPU core
#SBATCH --time=04:00:00                   # Time limit
#SBATCH --export=NONE                     # Export environment variables

echo "Job started at $(date)"

# Load Conda environment
conda activate /home/rli/.conda/envs/PROJ_001.RL

# Set up directories
SCRATCH=$MYSCRATCH/PROJ_001.RL/$SLURM_JOBID
INPUT=/group/sbs010/rli/PROJ_001.RL/0_merged_data_2
OUTPUT_DIR=/group/sbs010/rli/PROJ_001.RL/0.1_qc

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

# Set up log file
LOG_FILE=$SCRATCH/PROJ_001.RL-$SLURM_JOBID.log

# Copy input files to SCRATCH
echo "Copying input files to SCRATCH directory..."
cp $INPUT/*R1.merged.fastq.gz $SCRATCH
cp $INPUT/*R2.merged.fastq.gz $SCRATCH

# Change to SCRATCH directory
cd $SCRATCH

for i in *_R1.merged.fastq.gz;do
    SAMPLE_NAME="${i%%_R1.merged.fastq.gz}"
    echo "Sample name:"
    echo $SAMPLE_NAME

    # Run FASTQC
    echo "Running FASTQC on $SAMPLE_NAME"
    fastqc ${SAMPLE_NAME}_R1.merged.fastq.gz -o $SCRATCH
    fastqc ${SAMPLE_NAME}_R2.merged.fastq.gz -o $SCRATCH

    echo "Sample name:"
    echo $SAMPLE_NAME

    echo "Moving FASTQC output to OUTPUT directory..."
    mv $SCRATCH/${SAMPLE_NAME}_R1.merged_fastqc.html $OUTPUT_DIR/
    mv $SCRATCH/${SAMPLE_NAME}_R2.merged_fastqc.html $OUTPUT_DIR/    
done

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

# Print job finish time
echo "PROJ_001.RL job finished at $(date)"