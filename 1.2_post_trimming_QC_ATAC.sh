#!/bin/bash -l
#SBATCH --job-name=post_trim_QC             # Job name
#SBATCH --partition=work                 # Partition to use
#SBATCH --nodes=1                       # Number of nodes
#SBATCH --ntasks=1                      # Number of tasks
#SBATCH --cpus-per-task=4               # Number of CPU cores per task
#SBATCH --mem=8GB                       # Memory allocation
#SBATCH --time=05:00:00                 # Time limit
#SBATCH --output=qc_trim_%j.log         # Standard output log file
#SBATCH --error=qc_trim_%j.err          # Standard error log file

echo "Job started at: $(date)"

# Load necessary modules or activate conda environment
conda activate /home/rli/.conda/envs/PROJ_002.RL

# Set up directories and file paths
INPUT_DIR=/group/sbs010/rli/PROJ_002.RL/1_trimming
OUTPUT_DIR=/group/sbs010/rli/PROJ_002.RL/1.2_trimming_qc
SCRATCH=$MYSCRATCH/PROJ_002.RL/$SLURM_JOBID

mkdir -p $OUTPUT_DIR

# Create SCRATCH directory
mkdir -p $SCRATCH
echo "SCRATCH directory is $SCRATCH"

ls $INPUT_DIR

# copy files to SCRATCH
cp $INPUT_DIR/*.fq.gz $SCRATCH

mkdir -p $OUTPUT_DIR

# Quality control with FastQC
# Double check trimming has worked. Adapter content should be minimal.
fastqc -o $SCRATCH $INPUT_DIR/*.fq.gz

mv $SCRATCH/*fastqc.html $OUTPUT_DIR/

# Clean up SCRATCH directory
echo "Cleaning up SCRATCH directory..."
rm -r $SCRATCH

echo "Job finished at: $(date)"


