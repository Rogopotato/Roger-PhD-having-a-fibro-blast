#!/bin/bash -l
#SBATCH --job-name=raw_qc             # Job name
#SBATCH --partition=work                 # Partition to use
#SBATCH --nodes=1                       # Number of nodes
#SBATCH --ntasks=1                      # Number of tasks
#SBATCH --cpus-per-task=4               # Number of CPU cores per task
#SBATCH --mem=16GB                       # Memory allocation
#SBATCH --time=06:00:00                 # Time limit
#SBATCH --output=raw_qc_%j.log         # Standard output log file
#SBATCH --error=raw_qc_%j.err          # Standard error log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/rawdata/rawdata_03102024_ATAC
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/0_qc
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

# copy files to SCRATCH
cp $INPUT_DIR/*.fastq.gz $SCRATCH

# Quality control with FastQC.
# Check raw data before trimming. We are using Nextera so expect high amounts of that.
# Also, expect high polyG as NovaSeq is used for our ATAC and is a two colour system. 'No signal' is equivalent to 'G'
# Long sequences of G occur at the tail ends where no signal often occurs. 
fastqc -o $SCRATCH $INPUT_DIR/*.fastq.gz

mv $SCRATCH/*fastqc.html $OUTPUT_DIR/

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"
